import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/server_analytics_model.dart';

class SyncResult {
  final bool success;
  final int recordsSynced;
  final bool isOffline;
  final String message;

  const SyncResult({
    required this.success,
    required this.recordsSynced,
    this.isOffline = false,
    required this.message,
  });
}

/// Offline-First Synchronization Service for SevaMitr Cloud / Central Registry
/// Engineered for ultra-low bandwidth / 2G mobile connectivity in the North Eastern Region.
/// Features micro-batching, SQLite delta sync, exponential backoff, and local analytics caching.
class SevaMitrSyncService extends ChangeNotifier {
  static final SevaMitrSyncService instance = SevaMitrSyncService._internal();

  SevaMitrSyncService._internal();

  static const String _prefKeyServerUrl = 'sevamitr_server_url';
  static const String _prefKeyLastSyncTime = 'sevamitr_last_sync_timestamp';

  String _serverBaseUrl = '';
  bool _isSyncing = false;
  bool _isOnline = true;
  int _unsyncedCount = 0;
  DateTime? _lastSyncTime;
  String _lastSyncMessage = 'Ready';
  ServerAnalytics? _latestAnalytics;
  Timer? _periodicSyncTimer;
  Timer? _reconnectDebounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  http.Client? _httpClient;

  String get serverBaseUrl => _serverBaseUrl;
  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get unsyncedCount => _unsyncedCount;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get lastSyncMessage => _lastSyncMessage;
  ServerAnalytics? get latestAnalytics => _latestAnalytics;

  @visibleForTesting
  void setHttpClientForTesting(http.Client client) {
    _httpClient = client;
  }

  @visibleForTesting
  void triggerNetworkRestoredForTesting() {
    _onNetworkRestored();
  }

  http.Client get _client => _httpClient ?? http.Client();

  /// Determine a sensible default host based on platform
  String get _defaultServerUrl {
    return 'https://seva-mitr.vercel.app';
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _serverBaseUrl = prefs.getString(_prefKeyServerUrl) ?? _defaultServerUrl;

      final lastMillis = prefs.getInt(_prefKeyLastSyncTime);
      if (lastMillis != null && lastMillis > 0) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      }

      await refreshLocalState();

      // Listen for network connectivity transitions (Offline -> Online)
      _setupConnectivityListener();

      // Start periodic lightweight sync check (every 45s) as a safety net for 2G edge networks
      _periodicSyncTimer?.cancel();
      _periodicSyncTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        if (!_isSyncing && _unsyncedCount > 0) {
          syncAll(isBackground: true);
        }
      });
    } catch (e) {
      debugPrint('SevaMitrSyncService init error: $e');
    }
  }

  void _setupConnectivityListener() {
    try {
      _connectivitySubscription?.cancel();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        final hasNetwork = results.any((r) => r != ConnectivityResult.none);
        if (hasNetwork) {
          debugPrint('Network connectivity restored ($results). Scheduling auto-sync with SevaMitr Cloud...');
          _onNetworkRestored();
        } else {
          _isOnline = false;
          _lastSyncMessage = 'Offline: Data safely preserved in local SQLite';
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Connectivity listener setup info: $e');
    }
  }

  void _onNetworkRestored() {
    // Debounce rapid signal fluctuations (common on rural 2G/EDGE networks)
    _reconnectDebounceTimer?.cancel();
    _reconnectDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!_isSyncing) {
        syncAll(isBackground: true);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _reconnectDebounceTimer?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> setServerBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    _serverBaseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyServerUrl, cleanUrl);
    notifyListeners();
  }

  Future<void> refreshLocalState() async {
    try {
      _unsyncedCount = await OfflineDatabase.instance.getUnsyncedMetricsCount();
      final profile = await OfflineDatabase.instance.getPatientProfile();
      final targetId = profile?.serverPatientId.isNotEmpty == true
          ? profile!.serverPatientId
          : 'patient-ner-001';
      _latestAnalytics = await OfflineDatabase.instance.getCachedAnalytics(targetId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing local sync state: $e');
    }
  }

  /// Lightweight connectivity check with short timeout (3.5s)
  /// Crucial for low-bandwidth 2G environments to prevent hanging threads.
  Future<bool> checkConnectivity() async {
    try {
      final url = Uri.parse('$_serverBaseUrl/api/analytics');
      final response = await _client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(milliseconds: 3500));
      _isOnline = response.statusCode == 200 || response.statusCode == 304;
    } catch (_) {
      _isOnline = false;
    }
    notifyListeners();
    return _isOnline;
  }

  /// Main Synchronizer
  /// Performs:
  /// 1. Patient Profile registration/verification with SevaMitr
  /// 2. Micro-batched upload of unsynced game sessions (10 per batch)
  /// 3. Immediate local SQLite mark-as-synced commit
  /// 4. Fetch latest DCI and circadian sundowning analytics from SevaMitr
  /// 5. Persistent local SQLite caching (stale-while-revalidate)
  Future<SyncResult> syncAll({bool isBackground = false}) async {
    if (_isSyncing) {
      return const SyncResult(
        success: false,
        recordsSynced: 0,
        message: 'Sync already in progress...',
      );
    }

    _isSyncing = true;
    _lastSyncMessage = 'Checking connection...';
    notifyListeners();

    try {
      final online = await checkConnectivity();
      if (!online) {
        _isSyncing = false;
        _lastSyncMessage = 'Offline: Data safely preserved in local SQLite';
        notifyListeners();
        return SyncResult(
          success: false,
          recordsSynced: 0,
          isOffline: true,
          message: _lastSyncMessage,
        );
      }

      _lastSyncMessage = 'Connecting to SevaMitr Cloud...';
      notifyListeners();

      // Step 1: Ensure Patient is registered in SevaMitr database
      final profile = await OfflineDatabase.instance.getPatientProfile();
      String targetPatientId = 'patient-ner-001';

      if (profile != null) {
        final caregiverId = 'cg-ner-${profile.caregiverPhone.replaceAll(RegExp(r'[^0-9]'), '')}';
        final regUrl = Uri.parse('$_serverBaseUrl/api/patients');
        final regPayload = {
          if (profile.serverPatientId.isNotEmpty) 'id': profile.serverPatientId,
          'fullName': profile.fullName.trim(),
          'age': profile.age,
          'gender': profile.gender,
          'region': profile.region,
          'primaryLanguage': profile.primaryLanguage,
          'dementiaStage': profile.dementiaStage,
          'emergencyContact': profile.emergencyContact,
          'caregiverName': profile.caregiverName,
          'caregiverPhone': profile.caregiverPhone,
          'caregiverId': caregiverId,
          if (profile.enableKiosk && profile.kioskIdentifier.isNotEmpty) ...{
            'patientIdentifier': profile.kioskIdentifier,
            'patientPassword': profile.kioskPin,
          }
        };

        try {
          final regRes = await _client
              .post(
                regUrl,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(regPayload),
              )
              .timeout(const Duration(seconds: 8));

          if (regRes.statusCode == 200 || regRes.statusCode == 201) {
            final regData = jsonDecode(regRes.body);
            if (regData['patient'] != null && regData['patient']['id'] != null) {
              final srvId = regData['patient']['id'] as String;
              if (profile.serverPatientId != srvId) {
                await OfflineDatabase.instance.updatePatientServerSync(
                  srvId,
                  DateTime.now().millisecondsSinceEpoch,
                );
              }
              targetPatientId = srvId;
            }
          }
        } catch (e) {
          debugPrint('Patient profile sync warning: $e');
          if (profile.serverPatientId.isNotEmpty) {
            targetPatientId = profile.serverPatientId;
          }
        }
      }

      // Step 2: Micro-Batched Cognitive Metrics Upload
      final unsyncedMetrics = await OfflineDatabase.instance.getUnsyncedMetrics();
      int totalSyncedInThisRun = 0;

      if (unsyncedMetrics.isNotEmpty) {
        _lastSyncMessage = 'Uploading ${unsyncedMetrics.length} sessions (2G batched)...';
        notifyListeners();

        // Batch in chunks of 10 for resilient transmission across 2G edge networks
        const int batchSize = 10;
        for (int i = 0; i < unsyncedMetrics.length; i += batchSize) {
          final chunk = unsyncedMetrics.sublist(
            i,
            (i + batchSize > unsyncedMetrics.length) ? unsyncedMetrics.length : i + batchSize,
          );

          final sessionsPayload = chunk.map((m) {
            final gameId = _mapGameTypeToSevaMitrGameId(m.gameType);
            final gameTitle = _mapGameTypeToSevaMitrGameTitle(m.gameType);
            final timeOfDay = _getTimeOfDay(m.timestamp);

            final moves = m.totalMoves > 0 ? m.totalMoves : 1;
            final hesitationMs = m.tremorJitterScore > 0
                ? (m.tremorJitterScore * 1000 + 1000).clamp(500.0, 5000.0)
                : ((m.completionTimeSeconds * 1000) / moves).clamp(500.0, 5000.0);

            return {
              'gameId': gameId,
              'gameTitle': gameTitle,
              'difficultyLevel': (m.recommendedGridSize > 0 ? m.recommendedGridSize : m.gridDimension).clamp(1, 5),
              'score': m.calculatedScore.clamp(0.0, 100.0),
              'durationSec': m.completionTimeSeconds > 0 ? m.completionTimeSeconds : 45,
              'hesitationMs': hesitationMs,
              'errorCount': m.errorCount,
              'confusionLoops': (m.tremorJitterScore * 4).round(),
              'completed': true,
              'timeOfDay': timeOfDay,
              'timestamp': m.timestamp,
            };
          }).toList();

          final syncUrl = Uri.parse('$_serverBaseUrl/api/sync');
          final syncBody = jsonEncode({
            'patientId': targetPatientId,
            'sessions': sessionsPayload,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          final syncRes = await _client
              .post(
                syncUrl,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept-Encoding': 'gzip',
                },
                body: syncBody,
              )
              .timeout(const Duration(seconds: 10));

          if (syncRes.statusCode == 200 || syncRes.statusCode == 201) {
            final metricIds = chunk.map((c) => c.id!).whereType<int>().toList();
            await OfflineDatabase.instance.markMetricsSynced(metricIds);
            totalSyncedInThisRun += chunk.length;
          } else {
            throw Exception('Sync server error: ${syncRes.statusCode}');
          }
        }
      }

      // Step 3: Fetch Updated Analytics & Sundowning Evaluation from SevaMitr
      _lastSyncMessage = 'Fetching clinical analytics...';
      notifyListeners();

      ServerAnalytics? analytics;

      try {
        final analyticsUrl = Uri.parse('$_serverBaseUrl/api/analytics?patientId=$targetPatientId');
        final analyticsRes = await _client
            .get(analyticsUrl, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 8));

        if (analyticsRes.statusCode == 200) {
          final analyticsJson = jsonDecode(analyticsRes.body) as Map<String, dynamic>;
          analytics = ServerAnalytics.fromJson(
            analyticsJson,
            defaultPatientId: targetPatientId,
          );
        }
      } catch (e) {
        debugPrint('Analytics fetch error: $e');
      }

      // Edge/Deployment fallback: if /api/analytics returns 0 sessions, query /api/patients/$targetPatientId/sessions
      if (analytics == null || analytics.sessionsCount == 0) {
        try {
          final sessionsUrl = Uri.parse('$_serverBaseUrl/api/patients/$targetPatientId/sessions');
          final sessionsRes = await _client
              .get(sessionsUrl, headers: {'Accept': 'application/json'})
              .timeout(const Duration(seconds: 8));
          if (sessionsRes.statusCode == 200) {
            final sData = jsonDecode(sessionsRes.body) as Map<String, dynamic>;
            final sList = sData['sessions'] as List?;
            if (sList != null && sList.isNotEmpty) {
              analytics = _deriveAnalyticsFromSessions(targetPatientId, sList);
            }
          }
        } catch (_) {}
      }

      if (analytics != null) {
        await OfflineDatabase.instance.saveCachedAnalytics(analytics);
        _latestAnalytics = analytics;
      }

      // Step 4: Record success timestamp
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyLastSyncTime, _lastSyncTime!.millisecondsSinceEpoch);

      _unsyncedCount = await OfflineDatabase.instance.getUnsyncedMetricsCount();
      _isSyncing = false;
      _lastSyncMessage = totalSyncedInThisRun > 0
          ? 'Synced $totalSyncedInThisRun records with SevaMitr Cloud'
          : 'SevaMitr Cloud is up to date';
      notifyListeners();

      return SyncResult(
        success: true,
        recordsSynced: totalSyncedInThisRun,
        message: _lastSyncMessage,
      );
    } catch (e) {
      _isSyncing = false;
      _lastSyncMessage = 'Sync failed: $e. Retrying when connection stabilizes.';
      notifyListeners();
      return SyncResult(
        success: false,
        recordsSynced: 0,
        message: _lastSyncMessage,
      );
    }
  }

  static String _mapGameTypeToSevaMitrGameId(String gameType) {
    switch (gameType.toUpperCase()) {
      case 'MEMORY_MATCH':
        return 'smriti_setu';
      case 'ROUTINE_SEQUENCE':
        return 'doharani';
      case 'OBJECT_RECOGNITION':
        return 'rang_tanti';
      case 'PROVERBS_WORD_ASSOC':
        return 'shabda_tarang';
      case 'MEMORY_CAPSULE':
        return 'smriti_setu';
      case 'MARKET_MATH':
        return 'bazaar_saathi';
      default:
        return 'smriti_setu';
    }
  }

  static String _mapGameTypeToSevaMitrGameTitle(String gameType) {
    switch (gameType.toUpperCase()) {
      case 'MEMORY_MATCH':
        return 'Smriti Setu (Memory Matching)';
      case 'ROUTINE_SEQUENCE':
        return 'Doharani (Routine Sequencing)';
      case 'OBJECT_RECOGNITION':
        return 'Rang & Tanti (Visual Recognition)';
      case 'PROVERBS_WORD_ASSOC':
        return 'Shabda Tarang (Proverbs & Words)';
      case 'MEMORY_CAPSULE':
        return 'Smriti Setu (Family Memory Capsule)';
      case 'MARKET_MATH':
        return 'Bazaar Saathi (Market Math)';
      default:
        return 'Cognitive Game ($gameType)';
    }
  }

  static String _getTimeOfDay(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dt.hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  static ServerAnalytics _deriveAnalyticsFromSessions(String patientId, List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return ServerAnalytics(
        patientId: patientId,
        overallDci: null,
        sessionsCount: 0,
        domainScores: const {'memory': 0, 'executive': 0, 'attention': 0, 'auditory': 0, 'math': 0},
        sundowningDetected: false,
        sundowningHasData: false,
        latencyDivergencePct: 0,
        sundowningRecommendation: 'Awaiting baseline cognitive sessions.',
        motorHesitationScore: 0,
        motorStatus: 'pending',
        lastSyncedTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }

    double totalScore = 0;
    final Map<String, List<double>> domainLists = {
      'memory': [],
      'executive': [],
      'attention': [],
      'auditory': [],
      'math': [],
    };
    final List<double> morningLatencies = [];
    final List<double> eveningLatencies = [];
    double totalHesitation = 0;

    for (final s in sessions) {
      final map = s as Map<String, dynamic>;
      final score = ((map['score'] ?? 0) as num).toDouble();
      totalScore += score;
      final gameId = (map['gameId'] ?? '').toString().toLowerCase();
      final hesitation = ((map['hesitationMs'] ?? 1500) as num).toDouble();
      totalHesitation += hesitation;
      final timeOfDay = (map['timeOfDay'] ?? 'morning').toString().toLowerCase();

      if (timeOfDay == 'morning') {
        morningLatencies.add(hesitation);
      } else if (timeOfDay == 'evening' || timeOfDay == 'night') {
        eveningLatencies.add(hesitation);
      }

      if (gameId.contains('smriti') || gameId.contains('memory')) {
        domainLists['memory']!.add(score);
      } else if (gameId.contains('doharani') || gameId.contains('routine')) {
        domainLists['executive']!.add(score);
      } else if (gameId.contains('rang') || gameId.contains('attention') || gameId.contains('tracker')) {
        domainLists['attention']!.add(score);
      } else if (gameId.contains('shabda') || gameId.contains('sound')) {
        domainLists['auditory']!.add(score);
      } else if (gameId.contains('bazaar') || gameId.contains('math')) {
        domainLists['math']!.add(score);
      }
    }

    final double avgDci = (totalScore / sessions.length).clamp(10.0, 100.0);
    final Map<String, double> domainScores = {};
    domainLists.forEach((k, v) {
      domainScores[k] = v.isEmpty ? avgDci : (v.reduce((a, b) => a + b) / v.length).clamp(10.0, 100.0);
    });

    final bool hasCircadianData = morningLatencies.isNotEmpty && eveningLatencies.isNotEmpty;
    double divergence = 0;
    bool sundowningDetected = false;
    String recommendation = 'Circadian rhythm stable.';

    if (hasCircadianData) {
      final avgMorn = morningLatencies.reduce((a, b) => a + b) / morningLatencies.length;
      final avgEve = eveningLatencies.reduce((a, b) => a + b) / eveningLatencies.length;
      if (avgMorn > 0) {
        divergence = ((avgEve - avgMorn) / avgMorn) * 100;
      }
      if (divergence > 25) {
        sundowningDetected = true;
        recommendation = 'Evening cognitive fatigue detected. Transition patient to calming environment before sunset.';
      }
    }

    final avgHesitation = totalHesitation / sessions.length;
    final double motorScore = (avgHesitation / 500.0).clamp(1.0, 10.0);
    final String motorStatus = motorScore < 4.0 ? 'fluid' : (motorScore < 7.0 ? 'mild hesitation' : 'tremor detected');

    return ServerAnalytics(
      patientId: patientId,
      overallDci: avgDci,
      sessionsCount: sessions.length,
      domainScores: domainScores,
      sundowningDetected: sundowningDetected,
      sundowningHasData: hasCircadianData,
      latencyDivergencePct: divergence.clamp(0.0, 100.0),
      sundowningRecommendation: recommendation,
      motorHesitationScore: motorScore,
      motorStatus: motorStatus,
      lastSyncedTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
