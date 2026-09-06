import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/models/patient_profile_model.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';

class _AllowRealNetworkHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowRealNetworkHttpOverrides();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SevaMitrSyncService.instance.setHttpClientForTesting(http.Client());
  });

  test(
    'Live Production Vercel: Flutter SQLite syncs with https://seva-mitr.vercel.app',
    () async {
    final syncService = SevaMitrSyncService.instance;
    await syncService.init();
    await syncService.setServerBaseUrl('https://seva-mitr.vercel.app');

    // 1. Verify live connectivity with production Vercel server
    final isOnline = await syncService.checkConnectivity();
    expect(isOnline, isTrue, reason: 'https://seva-mitr.vercel.app should be online and reachable');

    // 2. Insert test patient in SQLite
    final testPatient = PatientProfile(
      fullName: 'Pranjal Saikia',
      preferredName: 'Pranjal',
      age: 71,
      gender: 'Male',
      region: 'Jorhat, Assam',
      primaryLanguage: 'as',
      dementiaStage: 'Mild',
      emergencyContact: '+91 94352 88990',
      caregiverName: 'Barun Saikia',
      caregiverPhone: '+91 94352 88990',
      careNotes: 'Daily tea and prayer reminders',
      createdAt: DateTime.now(),
    );
    await OfflineDatabase.instance.savePatientProfile(testPatient);

    // 3. Insert unsynced cognitive metrics in SQLite
    final now = DateTime.now().millisecondsSinceEpoch;
    await OfflineDatabase.instance.insertCognitiveMetric(
      CognitiveMetric(
        gameType: 'MEMORY_MATCH',
        timestamp: now,
        gridDimension: 2,
        totalMoves: 4,
        errorCount: 0,
        completionTimeSeconds: 27,
        tremorJitterScore: 0.10,
        calculatedScore: 92.0,
        recommendedGridSize: 2,
        isSynced: false,
      ),
    );
    await OfflineDatabase.instance.insertCognitiveMetric(
      CognitiveMetric(
        gameType: 'ROUTINE_SEQUENCE',
        timestamp: now + 60000,
        gridDimension: 2,
        totalMoves: 3,
        errorCount: 0,
        completionTimeSeconds: 22,
        tremorJitterScore: 0.08,
        calculatedScore: 95.0,
        recommendedGridSize: 2,
        isSynced: false,
      ),
    );

    // 4. Run full sync against live Vercel deployment
    final syncResult = await syncService.syncAll();
    expect(syncResult.success, isTrue);
    expect(syncResult.recordsSynced, greaterThanOrEqualTo(2));

    // 5. Verify patient profile updated with SevaMitr Cloud UUID in SQLite
    final updatedProfile = await OfflineDatabase.instance.getPatientProfile();
    expect(updatedProfile?.serverPatientId.isNotEmpty, isTrue);

    // 6. Verify SQLite marks metrics synced
    final unsynced = await OfflineDatabase.instance.getUnsyncedMetrics();
    expect(unsynced.isEmpty, isTrue);

    // 7. Verify analytics fetched/derived and saved in SQLite
    expect(syncService.latestAnalytics, isNotNull);
    final cached = await OfflineDatabase.instance.getCachedAnalytics(updatedProfile!.serverPatientId);
    expect(cached, isNotNull);
    expect(cached!.overallDci, isNotNull);
    expect(cached.sessionsCount, greaterThanOrEqualTo(2));
    },
    skip: Platform.environment['RUN_LIVE_E2E'] != 'true'
        ? 'Set RUN_LIVE_E2E=true to run against the live SevaMitr deployment.'
        : false,
  );
}
