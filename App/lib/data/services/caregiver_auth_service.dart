import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? userId;
  final String? identifier;
  final String? fullName;

  const AuthResult({
    required this.success,
    required this.message,
    this.userId,
    this.identifier,
    this.fullName,
  });
}

/// Caregiver Identity & Authentication Service
/// Connects mobile caregiver credentials (phone number + password)
/// with SevaMitr Cloud (Neon PostgreSQL) for unified patient data scoping.
class CaregiverAuthService extends ChangeNotifier {
  static final CaregiverAuthService instance = CaregiverAuthService._internal();

  CaregiverAuthService._internal();

  static const String _keyLoggedIn = 'sevamitr_caregiver_logged_in';
  static const String _keyUserId = 'sevamitr_caregiver_user_id';
  static const String _keyIdentifier = 'sevamitr_caregiver_identifier';
  static const String _keyFullName = 'sevamitr_caregiver_full_name';
  static const String _keyRole = 'sevamitr_caregiver_role';

  bool _isLoggedIn = false;
  String _caregiverId = '';
  String _caregiverPhone = '';
  String _caregiverName = '';
  String _caregiverRole = 'CAREGIVER';

  bool get isLoggedIn => _isLoggedIn;
  String get caregiverId => _caregiverId;
  String get caregiverPhone => _caregiverPhone;
  String get caregiverName => _caregiverName;
  String get caregiverRole => _caregiverRole;

  http.Client _client = http.Client();

  @visibleForTesting
  void setHttpClientForTesting(http.Client client) {
    _client = client;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      _caregiverId = prefs.getString(_keyUserId) ?? '';
      _caregiverPhone = prefs.getString(_keyIdentifier) ?? '';
      _caregiverName = prefs.getString(_keyFullName) ?? '';
      _caregiverRole = prefs.getString(_keyRole) ?? 'CAREGIVER';
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing CaregiverAuthService: $e');
    }
  }

  String get _baseUrl => SevaMitrSyncService.instance.serverBaseUrl;

  /// Log in with Phone Number or Email and Password
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdent = identifier.trim();
    if (cleanIdent.isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Please enter both phone/email and password.',
      );
    }

    try {
      final url = Uri.parse('$_baseUrl/api/auth');
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'action': 'login',
              'identifier': cleanIdent,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'];
        _caregiverId = user['id'] ?? '';
        _caregiverPhone = user['identifier'] ?? cleanIdent;
        _caregiverName = user['fullName'] ?? 'Caregiver';
        _caregiverRole = user['role'] ?? 'CAREGIVER';
        _isLoggedIn = true;

        await _saveCredentialsToPrefs();
        await _syncProfileWithCaregiverInfo();

        notifyListeners();

        // Trigger immediate background sync under new caregiver scope
        unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));

        return AuthResult(
          success: true,
          message: 'Welcome back, $_caregiverName!',
          userId: _caregiverId,
          identifier: _caregiverPhone,
          fullName: _caregiverName,
        );
      } else {
        final errorMsg =
            data['error'] ?? 'Login failed. Please check credentials.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('Caregiver login exception: $e');
      return const AuthResult(
        success: false,
        message:
            'Unable to connect to SevaMitr Cloud server. Please check your network.',
      );
    }
  }

  /// Register a new Caregiver account
  Future<AuthResult> signUp({
    required String fullName,
    required String identifier,
    required String password,
    String? region,
    String? role,
  }) async {
    final cleanName = fullName.trim();
    final cleanIdent = identifier.trim();

    if (cleanName.isEmpty || cleanIdent.isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Please fill in all required fields.',
      );
    }

    try {
      final url = Uri.parse('$_baseUrl/api/auth');
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'action': 'signup',
              'fullName': cleanName,
              'identifier': cleanIdent,
              'password': password,
              'role': role ?? 'CAREGIVER',
              'region': region ?? 'Assam, North Eastern Region',
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final user = data['user'];
        _caregiverId = user['id'] ?? '';
        _caregiverPhone = user['identifier'] ?? cleanIdent;
        _caregiverName = user['fullName'] ?? cleanName;
        _caregiverRole = user['role'] ?? 'CAREGIVER';
        _isLoggedIn = true;

        await _saveCredentialsToPrefs();
        await _syncProfileWithCaregiverInfo();

        notifyListeners();

        unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));

        return AuthResult(
          success: true,
          message: 'Account created! Synced as $_caregiverName.',
          userId: _caregiverId,
          identifier: _caregiverPhone,
          fullName: _caregiverName,
        );
      } else {
        final errorMsg =
            data['error'] ?? 'Sign up failed. Please try a different phone/email.';
        return AuthResult(success: false, message: errorMsg);
      }
    } catch (e) {
      debugPrint('Caregiver sign up exception: $e');
      return const AuthResult(
        success: false,
        message:
            'Unable to connect to SevaMitr Cloud server. Please check your network.',
      );
    }
  }

  /// Sign in with pre-configured Hackathon Demo account
  Future<AuthResult> useDemoAccount() async {
    return login(identifier: 'anuradha@sevamitr.org', password: 'care123');
  }

  /// Sign out and clear caregiver session
  Future<void> logout() async {
    _isLoggedIn = false;
    _caregiverId = '';
    _caregiverPhone = '';
    _caregiverName = '';
    _caregiverRole = 'CAREGIVER';

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLoggedIn);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyIdentifier);
      await prefs.remove(_keyFullName);
      await prefs.remove(_keyRole);
    } catch (e) {
      debugPrint('Error clearing caregiver prefs: $e');
    }

    notifyListeners();
  }

  Future<void> _saveCredentialsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, _isLoggedIn);
      await prefs.setString(_keyUserId, _caregiverId);
      await prefs.setString(_keyIdentifier, _caregiverPhone);
      await prefs.setString(_keyFullName, _caregiverName);
      await prefs.setString(_keyRole, _caregiverRole);
    } catch (e) {
      debugPrint('Error saving credentials to prefs: $e');
    }
  }

  Future<void> _syncProfileWithCaregiverInfo() async {
    try {
      final profile = await OfflineDatabase.instance.getPatientProfile();
      String resolvedServerPatientId = profile?.serverPatientId ?? '';

      // Query cloud to see if caregiver already has registered patients
      if (_caregiverId.isNotEmpty) {
        try {
          final patientsUrl = Uri.parse('$_baseUrl/api/patients?caregiverId=$_caregiverId');
          final pRes = await _client.get(
            patientsUrl,
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 5));

          if (pRes.statusCode == 200) {
            final pData = jsonDecode(pRes.body);
            final patients = pData['patients'] as List<dynamic>?;
            if (patients != null && patients.isNotEmpty) {
              // Prioritize:
              // 1. Patient matching local profile name
              // 2. Patient with the highest sessionsCount
              // 3. First patient
              dynamic bestMatch;
              final cleanLocalName = profile?.fullName.trim().toLowerCase() ?? '';

              for (final p in patients) {
                final pName = (p['fullName'] as String? ?? '').trim().toLowerCase();
                if (cleanLocalName.isNotEmpty && pName == cleanLocalName) {
                  bestMatch = p;
                  break;
                }
              }

              if (bestMatch == null) {
                final sortedList = List<dynamic>.from(patients);
                sortedList.sort((a, b) {
                  final sA = (a['sessionsCount'] as num? ?? 0);
                  final sB = (b['sessionsCount'] as num? ?? 0);
                  return sB.compareTo(sA);
                });
                bestMatch = sortedList.first;
              }

              if (bestMatch != null && bestMatch['id'] != null) {
                resolvedServerPatientId = bestMatch['id'] as String;
                await OfflineDatabase.instance.updatePatientServerSync(
                  resolvedServerPatientId,
                  DateTime.now().millisecondsSinceEpoch,
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching caregiver patients during auth sync: $e');
        }
      }

      if (profile != null) {
        final updated = profile.copyWith(
          caregiverName: _caregiverName.isNotEmpty ? _caregiverName : profile.caregiverName,
          caregiverPhone: _caregiverPhone.isNotEmpty ? _caregiverPhone : profile.caregiverPhone,
          serverPatientId: resolvedServerPatientId.isNotEmpty ? resolvedServerPatientId : profile.serverPatientId,
        );
        await OfflineDatabase.instance.savePatientProfile(updated);
      }
    } catch (e) {
      debugPrint('Error updating local profile with auth details: $e');
    }
  }
}
