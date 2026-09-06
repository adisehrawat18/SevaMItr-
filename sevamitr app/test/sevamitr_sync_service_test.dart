import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/models/patient_profile_model.dart';
import 'package:dementia_ner_care/data/models/server_analytics_model.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SevaMitrSyncService.instance.setHttpClientForTesting(http.Client());
  });

  group('ServerAnalytics Model Tests', () {
    test('Correctly parses SevaMitr /api/analytics JSON response', () {
      final jsonResponse = {
        'patientId': 'patient-ner-001',
        'timestamp': 1725612345000,
        'totalSessionsRecorded': 12,
        'analysis': {
          'overallDci': 84.0,
          'sessionsCount': 12,
          'domainScores': {
            'memory': 88.0,
            'executive': 80.0,
            'attention': 85.0,
            'auditory': 78.0,
            'math': 82.0,
          },
          'sundowning': {
            'detected': true,
            'hasEnoughData': true,
            'latencyDivergencePct': 42.0,
            'recommendation': 'Evening cognitive fatigue detected. Reduce sensory clutter after 5:00 PM.',
          },
          'motorHesitation': {
            'tremorHesitationScore': 3.2,
            'status': 'fluid',
          },
        },
      };

      final analytics = ServerAnalytics.fromJson(jsonResponse);

      expect(analytics.patientId, 'patient-ner-001');
      expect(analytics.overallDci, 84.0);
      expect(analytics.sessionsCount, 12);
      expect(analytics.memoryScore, 88.0);
      expect(analytics.attentionScore, 85.0);
      expect(analytics.sundowningDetected, isTrue);
      expect(analytics.latencyDivergencePct, 42.0);
      expect(analytics.sundowningRecommendation, contains('Evening cognitive fatigue detected'));
      expect(analytics.motorHesitationScore, 3.2);
      expect(analytics.motorStatus, 'fluid');
    });

    test('Handles null overallDci and empty domains gracefully', () {
      final emptyResponse = {
        'patientId': 'patient-ner-002',
        'timestamp': 1725612345000,
        'analysis': {
          'overallDci': null,
          'sessionsCount': 0,
          'domainScores': {},
          'sundowning': {
            'detected': false,
            'hasEnoughData': false,
          },
          'motorHesitation': {
            'tremorHesitationScore': 0,
            'status': 'pending',
          },
        },
      };

      final analytics = ServerAnalytics.fromJson(emptyResponse);
      expect(analytics.overallDci, isNull);
      expect(analytics.sessionsCount, 0);
      expect(analytics.memoryScore, 0.0);
      expect(analytics.sundowningDetected, isFalse);
      expect(analytics.motorStatus, 'pending');
    });
  });

  group('SevaMitrSyncService Low-Bandwidth & 2G Sync Tests', () {
    test('Simulates successful cloud sync with patient registration and batched upload', () async {
      final syncService = SevaMitrSyncService.instance;

      final mockPatientRes = {
        'success': true,
        'patient': {
          'id': 'patient-cloud-999',
          'fullName': 'Mridula Hazarika',
        },
      };

      final mockSyncRes = {
        'success': true,
        'recordsSynced': 2,
        'payloadSizeBytes': 450,
        'serverTime': 1725612345000,
        'status': 'Synced with SevaMitr Cloud',
      };

      final mockAnalyticsRes = {
        'patientId': 'patient-cloud-999',
        'timestamp': 1725612345000,
        'totalSessionsRecorded': 6,
        'analysis': {
          'overallDci': 82.0,
          'sessionsCount': 6,
          'domainScores': {
            'memory': 85.0,
            'executive': 80.0,
            'attention': 82.0,
            'auditory': 78.0,
            'math': 80.0,
          },
          'sundowning': {
            'detected': false,
            'hasEnoughData': true,
            'latencyDivergencePct': 10.0,
            'recommendation': 'Circadian rhythm is stable.',
          },
          'motorHesitation': {
            'tremorHesitationScore': 2.5,
            'status': 'fluid',
          },
        },
      };

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/api/patients')) {
          return http.Response(jsonEncode(mockPatientRes), 200, headers: {'content-type': 'application/json'});
        } else if (path.endsWith('/api/sync')) {
          return http.Response(jsonEncode(mockSyncRes), 200, headers: {'content-type': 'application/json'});
        } else if (path.endsWith('/api/analytics')) {
          return http.Response(jsonEncode(mockAnalyticsRes), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      syncService.setHttpClientForTesting(mockClient);
      await syncService.init();

      // Seed a test patient profile
      final testProfile = PatientProfile(
        fullName: 'Mridula Hazarika',
        preferredName: 'Mridula',
        age: 72,
        caregiverName: 'Anuradha Baruah',
        caregiverPhone: '+91 94350 98765',
        createdAt: DateTime.now(),
        serverPatientId: '', // Needs registration
      );
      await OfflineDatabase.instance.savePatientProfile(testProfile);

      // Seed unsynced metrics
      await OfflineDatabase.instance.insertCognitiveMetric(
        CognitiveMetric(
          gameType: 'MEMORY_MATCH',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          gridDimension: 2,
          totalMoves: 4,
          errorCount: 0,
          completionTimeSeconds: 30,
          tremorJitterScore: 0.1,
          calculatedScore: 95.0,
          recommendedGridSize: 2,
          isSynced: false,
        ),
      );

      final result = await syncService.syncAll();

      expect(result.success, isTrue);
      expect(result.isOffline, isFalse);
      expect(syncService.latestAnalytics, isNotNull);
      expect(syncService.latestAnalytics!.overallDci, 82.0);

      // Verify patient was assigned serverPatientId
      final updatedProfile = await OfflineDatabase.instance.getPatientProfile();
      expect(updatedProfile?.serverPatientId, 'patient-cloud-999');

      // Verify unsynced metrics are now synced
      final remainingUnsynced = await OfflineDatabase.instance.getUnsyncedMetrics();
      expect(remainingUnsynced.isEmpty, isTrue);
    });

    test('Gracefully handles complete offline state without errors', () async {
      final syncService = SevaMitrSyncService.instance;

      // Mock client that throws SocketException (no internet)
      final offlineClient = MockClient((_) async {
        throw http.ClientException('Failed to connect to host (offline)');
      });

      syncService.setHttpClientForTesting(offlineClient);
      final result = await syncService.syncAll();

      expect(result.success, isFalse);
      expect(result.isOffline, isTrue);
      expect(syncService.isOnline, isFalse);
      expect(result.message, contains('Offline: Data safely preserved'));
    });

    test('Auto-sync triggers when network connection is restored', () async {
      final syncService = SevaMitrSyncService.instance;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/api/patients')) {
          return http.Response('{"success": true, "patient": {"id": "patient-ner-restored"}}', 200, headers: {'content-type': 'application/json'});
        } else if (path.endsWith('/api/sync')) {
          return http.Response('{"success": true, "recordsSynced": 0}', 200, headers: {'content-type': 'application/json'});
        } else if (path.endsWith('/api/analytics')) {
          return http.Response('{"patientId": "patient-ner-restored", "analysis": {"overallDci": 80.0}}', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('OK', 200);
      });

      syncService.setHttpClientForTesting(mockClient);

      // Simulate connection restored
      syncService.triggerNetworkRestoredForTesting();

      // Wait for debounce timer (1500ms)
      await Future.delayed(const Duration(milliseconds: 1700));

      expect(syncService.isOnline, isTrue);
      expect(syncService.latestAnalytics?.overallDci, 80.0);
    });

    test('Saves and restores cached analytics from SQLite for instant 0ms offline rendering', () async {
      const analytics = ServerAnalytics(
        patientId: 'patient-test-offline-render',
        overallDci: 88.0,
        sessionsCount: 15,
        domainScores: {
          'memory': 90.0,
          'executive': 85.0,
          'attention': 86.0,
          'auditory': 84.0,
          'math': 82.0,
        },
        sundowningDetected: false,
        sundowningHasData: true,
        latencyDivergencePct: 8.0,
        sundowningRecommendation: 'Normal circadian alertness pattern.',
        motorHesitationScore: 1.8,
        motorStatus: 'fluid',
        lastSyncedTimestamp: 1725612345000,
      );

      await OfflineDatabase.instance.saveCachedAnalytics(analytics);

      final cached = await OfflineDatabase.instance.getCachedAnalytics('patient-test-offline-render');
      expect(cached, isNotNull);
      expect(cached!.overallDci, 88.0);
      expect(cached.memoryScore, 90.0);
      expect(cached.sundowningDetected, isFalse);
      expect(cached.motorStatus, 'fluid');
    });
  });
}
