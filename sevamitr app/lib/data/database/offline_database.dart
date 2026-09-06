import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dementia_ner_care/data/models/medication_model.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/models/memory_capsule_model.dart';
import 'package:dementia_ner_care/data/models/patient_profile_model.dart';
import 'package:dementia_ner_care/data/models/server_analytics_model.dart';

class OfflineDatabase {
  static final OfflineDatabase instance = OfflineDatabase._init();
  static Database? _database;

  OfflineDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dementia_ner_offline_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Medication Schedules Table
    await db.execute('''
      CREATE TABLE medication_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        regionalTitle TEXT NOT NULL,
        dosageDescription TEXT NOT NULL,
        visualAssetType TEXT NOT NULL,
        scheduledTimeFormatted TEXT NOT NULL,
        hourOfDay INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        audioChimeKey TEXT NOT NULL,
        isCompletedToday INTEGER NOT NULL,
        completedAtTimestamp INTEGER,
        caregiverPhone TEXT NOT NULL
      )
    ''');

    // 2. Cognitive Metrics Table
    await db.execute('''
      CREATE TABLE cognitive_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gameType TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        gridDimension INTEGER NOT NULL,
        totalMoves INTEGER NOT NULL,
        errorCount INTEGER NOT NULL,
        completionTimeSeconds INTEGER NOT NULL,
        tremorJitterScore REAL NOT NULL,
        calculatedScore REAL NOT NULL,
        recommendedGridSize INTEGER NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        serverSessionId TEXT NOT NULL DEFAULT ''
      )
    ''');

    // 3. Offline Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        queueId INTEGER PRIMARY KEY AUTOINCREMENT,
        eventType TEXT NOT NULL,
        payloadJson TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        syncAttempts INTEGER NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');

    // 4. Memory Capsules Table (Personalized Reminiscence)
    await db.execute('''
      CREATE TABLE memory_capsules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        relationTag TEXT NOT NULL,
        photoAssetPath TEXT NOT NULL,
        audioStoryText TEXT NOT NULL,
        audioStoryTextRegional TEXT NOT NULL,
        recordedDateFormatted TEXT NOT NULL,
        quizQuestion TEXT NOT NULL,
        quizQuestionRegional TEXT NOT NULL,
        quizOptions TEXT NOT NULL,
        correctOptionIndex INTEGER NOT NULL
      )
    ''');

    await _createPatientProfileTable(db);
    await _createAnalyticsCacheTable(db);

    // Seed default regional medication schedule
    await db.insert('medication_schedules', {
      'title': 'Morning Blood Pressure Tablet',
      'regionalTitle': 'ৰাতিপুৱাৰ ৰক্তচাপৰ ঔষধ',
      'dosageDescription': '1 Green Round Pill with warm water',
      'visualAssetType': 'PILL_GREEN',
      'scheduledTimeFormatted': '09:00 AM',
      'hourOfDay': 9,
      'minute': 0,
      'audioChimeKey': 'chime_flute_calm',
      'isCompletedToday': 0,
      'completedAtTimestamp': null,
      'caregiverPhone': '+919876543210',
    });

    await db.insert('medication_schedules', {
      'title': 'Afternoon Hydration / Water',
      'regionalTitle': 'দুপৰীয়াৰ পানী খোৱাৰ সময়',
      'dosageDescription': 'Drink 1 Full Glass of Fresh Filtered Water',
      'visualAssetType': 'WATER_GLASS',
      'scheduledTimeFormatted': '02:00 PM',
      'hourOfDay': 14,
      'minute': 0,
      'audioChimeKey': 'chime_water_calm',
      'isCompletedToday': 0,
      'completedAtTimestamp': null,
      'caregiverPhone': '+919876543210',
    });

    // Seed default Memory Capsules (NER Reminiscence)
    await db.insert('memory_capsules', {
      'title': 'Rohan’s University Convocation',
      'relationTag': 'Grandson Rohan (নাতি ৰোহণ)',
      'photoAssetPath': 'assets/images/rohan_convocation.png',
      'audioStoryText':
          'This is your grandson Rohan. He graduated with high honours in Guwahati. You gave him a beautiful silk Gamosa and blessed him.',
      'audioStoryTextRegional':
          'এইয়া আপোনাৰ মৰমৰ নাতি ৰোহণ। গুৱাহাটী বিশ্ববিদ্যালয়ৰ সমাৱৰ্তনত আপুনি তাক ফুলাম গামোচা পিন্ধাই আশীৰ্বাদ দিছিল।',
      'recordedDateFormatted': '15 May 2026',
      'quizQuestion': 'Who is celebrating his graduation in this photo?',
      'quizQuestionRegional':
          'এইখন ছবিত কোনে স্নাতক ডিগ্ৰী লাভ কৰা উদযাপন কৰিছে?',
      'quizOptions':
          'Grandson Rohan (নাতি ৰোহণ)|Dr. Barua (Family Friend)|Barun (Son)',
      'correctOptionIndex': 0,
    });

    await db.insert('memory_capsules', {
      'title': 'Bohu Jalpan in Ancestral Home (Tezpur)',
      'relationTag': 'Tezpur Home & Family (তেজপুৰৰ ঘৰ)',
      'photoAssetPath': 'assets/images/tezpur_home.png',
      'audioStoryText':
          'Rongali Bihu morning in your courtyard in Tezpur. Everyone gathered for Komal Saul, curd, and fresh jaggery together.',
      'audioStoryTextRegional':
          'তেজপুৰৰ চোতালত ৰঙালী বিহুৰ জলপান। কোমল চাউল, দৈ আৰু গুৰেৰে সকলো পৰিয়াল একেলগে আনন্দ কৰিছিল।',
      'recordedDateFormatted': '14 April 2026',
      'quizQuestion': 'Which special festival breakfast is prepared here?',
      'quizQuestionRegional': 'ইয়াত কোনটো বিহুৰ জলপান খাবলৈ সকলো একেলগে বহিছে?',
      'quizOptions':
          'Bihu Jalpan & Curd (বিহুৰ জলপান)|Diwali Sweets|Sunday Lunch',
      'correctOptionIndex': 0,
    });

    // Seed default cognitive metrics for offline baseline
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('cognitive_metrics', {
      'gameType': 'MEMORY_MATCH',
      'timestamp': now - (86400000 * 2),
      'gridDimension': 2,
      'totalMoves': 6,
      'errorCount': 1,
      'completionTimeSeconds': 45,
      'tremorJitterScore': 0.18,
      'calculatedScore': 86.0,
      'recommendedGridSize': 2,
      'isSynced': 0,
      'serverSessionId': '',
    });
    await db.insert('cognitive_metrics', {
      'gameType': 'ROUTINE_SEQUENCE',
      'timestamp': now - 86400000,
      'gridDimension': 2,
      'totalMoves': 4,
      'errorCount': 0,
      'completionTimeSeconds': 32,
      'tremorJitterScore': 0.12,
      'calculatedScore': 94.0,
      'recommendedGridSize': 2,
      'isSynced': 0,
      'serverSessionId': '',
    });
    await db.insert('cognitive_metrics', {
      'gameType': 'OBJECT_RECOGNITION',
      'timestamp': now - (3600000 * 2),
      'gridDimension': 2,
      'totalMoves': 3,
      'errorCount': 1,
      'completionTimeSeconds': 29,
      'tremorJitterScore': 0.22,
      'calculatedScore': 80.0,
      'recommendedGridSize': 2,
      'isSynced': 0,
      'serverSessionId': '',
    });
  }


  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createPatientProfileTable(db);
    if (oldVersion < 3) {
      final migrations = [
        "ALTER TABLE patient_profile ADD COLUMN gender TEXT NOT NULL DEFAULT 'Female'",
        "ALTER TABLE patient_profile ADD COLUMN region TEXT NOT NULL DEFAULT 'Kamrup Rural, Assam'",
        "ALTER TABLE patient_profile ADD COLUMN primaryLanguage TEXT NOT NULL DEFAULT 'en'",
        "ALTER TABLE patient_profile ADD COLUMN dementiaStage TEXT NOT NULL DEFAULT 'Mild'",
        "ALTER TABLE patient_profile ADD COLUMN emergencyContact TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE patient_profile ADD COLUMN enableKiosk INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE patient_profile ADD COLUMN kioskIdentifier TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE patient_profile ADD COLUMN kioskPin TEXT NOT NULL DEFAULT ''",
      ];
      for (final sql in migrations) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }
    }
    if (oldVersion < 4) {
      final migrationsV4 = [
        "ALTER TABLE patient_profile ADD COLUMN serverPatientId TEXT NOT NULL DEFAULT ''",
        "ALTER TABLE patient_profile ADD COLUMN serverSyncedAt INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE cognitive_metrics ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE cognitive_metrics ADD COLUMN serverSessionId TEXT NOT NULL DEFAULT ''",
      ];
      for (final sql in migrationsV4) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }
      try {
        await _createAnalyticsCacheTable(db);
      } catch (_) {}
    }
  }

  Future<void> _createPatientProfileTable(Database db) => db.execute('''
    CREATE TABLE patient_profile (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      fullName TEXT NOT NULL,
      preferredName TEXT NOT NULL,
      age INTEGER NOT NULL,
      caregiverName TEXT NOT NULL,
      caregiverPhone TEXT NOT NULL,
      careNotes TEXT NOT NULL DEFAULT '',
      createdAt INTEGER NOT NULL,
      gender TEXT NOT NULL DEFAULT 'Female',
      region TEXT NOT NULL DEFAULT 'Kamrup Rural, Assam',
      primaryLanguage TEXT NOT NULL DEFAULT 'en',
      dementiaStage TEXT NOT NULL DEFAULT 'Mild',
      emergencyContact TEXT NOT NULL DEFAULT '',
      enableKiosk INTEGER NOT NULL DEFAULT 0,
      kioskIdentifier TEXT NOT NULL DEFAULT '',
      kioskPin TEXT NOT NULL DEFAULT '',
      serverPatientId TEXT NOT NULL DEFAULT '',
      serverSyncedAt INTEGER NOT NULL DEFAULT 0
    )
  ''');

  Future<void> _createAnalyticsCacheTable(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS cached_server_analytics (
      patientId TEXT PRIMARY KEY,
      overallDci REAL,
      sessionsCount INTEGER NOT NULL DEFAULT 0,
      memoryScore REAL NOT NULL DEFAULT 0,
      executiveScore REAL NOT NULL DEFAULT 0,
      attentionScore REAL NOT NULL DEFAULT 0,
      auditoryScore REAL NOT NULL DEFAULT 0,
      mathScore REAL NOT NULL DEFAULT 0,
      sundowningDetected INTEGER NOT NULL DEFAULT 0,
      sundowningHasData INTEGER NOT NULL DEFAULT 0,
      latencyDivergencePct REAL NOT NULL DEFAULT 0,
      sundowningRecommendation TEXT NOT NULL DEFAULT '',
      motorHesitationScore REAL NOT NULL DEFAULT 0,
      motorStatus TEXT NOT NULL DEFAULT 'pending',
      lastSyncedTimestamp INTEGER NOT NULL,
      rawJson TEXT NOT NULL DEFAULT ''
    )
  ''');

  Future<PatientProfile?> getPatientProfile() async {
    final db = await database;
    final rows = await db.query('patient_profile', limit: 1);
    return rows.isEmpty ? null : PatientProfile.fromMap(rows.first);
  }

  Future<void> savePatientProfile(PatientProfile profile) async {
    final db = await database;
    await db.insert(
      'patient_profile',
      profile.copyWith().toMap()..['id'] = 1,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Medication Operations ---
  Future<List<MedicationSchedule>> getAllMedications() async {
    final db = await database;
    final maps = await db.query(
      'medication_schedules',
      orderBy: 'hourOfDay ASC, minute ASC',
    );
    return maps.map((e) => MedicationSchedule.fromMap(e)).toList();
  }

  Future<MedicationSchedule?> getNextPendingMedication() async {
    final db = await database;
    final maps = await db.query(
      'medication_schedules',
      where: 'isCompletedToday = ?',
      whereArgs: [0],
      orderBy: 'hourOfDay ASC, minute ASC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return MedicationSchedule.fromMap(maps.first);
    }
    return null;
  }

  Future<void> markMedicationTaken(int id) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'medication_schedules',
      {
        'isCompletedToday': 1,
        'completedAtTimestamp': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Queue for sync
    await enqueueSync('MED_TAKEN', '{"medicationId": $id, "timestamp": $now}');
  }

  // --- Memory Capsule Operations ---
  Future<List<MemoryCapsule>> getAllMemoryCapsules() async {
    final db = await database;
    final maps = await db.query('memory_capsules', orderBy: 'id DESC');
    return maps.map((e) => MemoryCapsule.fromMap(e)).toList();
  }

  Future<int> insertMemoryCapsule(MemoryCapsule capsule) async {
    final db = await database;
    final id = await db.insert('memory_capsules', capsule.toMap());
    await enqueueSync(
        'CAPSULE_ADDED', '{"capsuleId": $id, "title": "${capsule.title}"}');
    return id;
  }

  // --- Cognitive Metrics ---
  Future<int> insertCognitiveMetric(CognitiveMetric metric) async {
    final db = await database;
    final id = await db.insert('cognitive_metrics', metric.toMap());
    await enqueueSync('GAME_COMPLETED',
        '{"metricId": $id, "score": ${metric.calculatedScore}}');
    return id;
  }

  Future<List<CognitiveMetric>> getRecentMetrics() async {
    final db = await database;
    final maps = await db.query(
      'cognitive_metrics',
      orderBy: 'timestamp DESC',
      limit: 20,
    );
    return maps.map((e) => CognitiveMetric.fromMap(e)).toList();
  }

  // --- Offline Sync Queue ---
  Future<void> enqueueSync(String eventType, String payloadJson) async {
    final db = await database;
    await db.insert('sync_queue', {
      'eventType': eventType,
      'payloadJson': payloadJson,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'syncAttempts': 0,
      'isSynced': 0,
    });
  }

  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    final db = await database;
    final maps = await db.query(
      'sync_queue',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return maps.map((e) => SyncQueueItem.fromMap(e)).toList();
  }

  Future<void> markItemSynced(int queueId) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'isSynced': 1},
      where: 'queueId = ?',
      whereArgs: [queueId],
    );
  }

  // --- Cloud Synchronization & 2G Edge Batching ---
  Future<List<CognitiveMetric>> getUnsyncedMetrics() async {
    final db = await database;
    final maps = await db.query(
      'cognitive_metrics',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return maps.map((e) => CognitiveMetric.fromMap(e)).toList();
  }

  Future<int> getUnsyncedMetricsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cognitive_metrics WHERE isSynced = 0',
    );
    if (result.isNotEmpty && result.first['count'] != null) {
      return Sqflite.firstIntValue(result) ?? 0;
    }
    return 0;
  }

  Future<void> markMetricsSynced(List<int> metricIds) async {
    if (metricIds.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final id in metricIds) {
      batch.update(
        'cognitive_metrics',
        {'isSynced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updatePatientServerSync(String serverPatientId, int timestamp) async {
    final db = await database;
    await db.update(
      'patient_profile',
      {
        'serverPatientId': serverPatientId,
        'serverSyncedAt': timestamp,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> saveCachedAnalytics(ServerAnalytics analytics) async {
    final db = await database;
    await db.insert(
      'cached_server_analytics',
      analytics.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ServerAnalytics?> getCachedAnalytics(String patientId) async {
    final db = await database;
    if (patientId.isNotEmpty) {
      final rows = await db.query(
        'cached_server_analytics',
        where: 'patientId = ?',
        whereArgs: [patientId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return ServerAnalytics.fromMap(rows.first);
      }
    }
    final allRows = await db.query('cached_server_analytics', limit: 1);
    if (allRows.isNotEmpty) {
      return ServerAnalytics.fromMap(allRows.first);
    }
    return null;
  }

  Future<void> seedSampleMetricsIfEmpty() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM cognitive_metrics');
    final count = Sqflite.firstIntValue(result) ?? 0;

    if (count == 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('cognitive_metrics', {
        'gameType': 'MEMORY_MATCH',
        'timestamp': now - (86400000 * 2),
        'gridDimension': 2,
        'totalMoves': 6,
        'errorCount': 1,
        'completionTimeSeconds': 45,
        'tremorJitterScore': 0.18,
        'calculatedScore': 86.0,
        'recommendedGridSize': 2,
        'isSynced': 0,
        'serverSessionId': '',
      });
      await db.insert('cognitive_metrics', {
        'gameType': 'ROUTINE_SEQUENCE',
        'timestamp': now - 86400000,
        'gridDimension': 2,
        'totalMoves': 4,
        'errorCount': 0,
        'completionTimeSeconds': 32,
        'tremorJitterScore': 0.12,
        'calculatedScore': 94.0,
        'recommendedGridSize': 2,
        'isSynced': 0,
        'serverSessionId': '',
      });
      await db.insert('cognitive_metrics', {
        'gameType': 'OBJECT_RECOGNITION',
        'timestamp': now - (3600000 * 2),
        'gridDimension': 2,
        'totalMoves': 3,
        'errorCount': 1,
        'completionTimeSeconds': 29,
        'tremorJitterScore': 0.22,
        'calculatedScore': 80.0,
        'recommendedGridSize': 2,
        'isSynced': 0,
        'serverSessionId': '',
      });
    }
  }
}
