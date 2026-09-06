import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dementia_ner_care/core/localization/location_language_service.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/services/caregiver_auth_service.dart';
import 'package:dementia_ner_care/ui/widgets/game_celebration_dialog.dart';
import 'package:dementia_ner_care/core/audio/synthesized_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SevaMitr 11 Cognitive Games & Clinical Biomarkers', () {
    test('All 11 cognitive games create metrics and map cleanly', () {
      final games = [
        'BIJULI_TAP',
        'BIKHAMA_KHOJ',
        'DOUBLE_DECISION',
        'SOUND_SWEEPS',
        'SPEED_MAZE',
        'TARGET_TRACKER',
        'MEMORY_MATCH',
        'OBJECT_RECOGNITION',
        'ROUTINE_SEQUENCE',
        'PROVERBS_WORD_ASSOC',
        'MEMORY_CAPSULE',
      ];

      for (final game in games) {
        final metric = CognitiveMetric(
          gameType: game,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          gridDimension: 2,
          totalMoves: 5,
          errorCount: 1,
          completionTimeSeconds: 15,
          tremorJitterScore: 0.1,
          calculatedScore: 88.0,
          recommendedGridSize: 2,
          isSynced: false,
        );

        expect(metric.gameType, game);
        expect(metric.calculatedScore, 88.0);
        final map = metric.toMap();
        expect(map['gameType'], game);
        final fromMap = CognitiveMetric.fromMap(map);
        expect(fromMap.gameType, game);
      }
    });

    testWidgets('GameCelebrationDialog displays score and biomarkers correctly',
        (tester) async {
      bool playAgainTapped = false;
      bool backToHubTapped = false;
      final locService = LocationLanguageService();

      await tester.pumpWidget(
        AppLanguageScope(
          languageService: locService,
          child: MaterialApp(
            home: Scaffold(
              body: GameCelebrationDialog(
                score: 95,
                biomarker: 'Reaction Time: 230ms • 100% Accuracy',
                onPlayAgain: () => playAgainTapped = true,
                onBackToHub: () => backToHubTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('95'), findsOneWidget);
      expect(find.text('A+ • Optimal Cognitive Function'), findsOneWidget);
      expect(find.text('Reaction Time: 230ms • 100% Accuracy'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(playAgainTapped, isTrue);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      expect(backToHubTapped, isTrue);
    });

    test('SynthesizedAudioService initializes and synthesizes sweeps without errors', () async {
      final audio = SynthesizedAudioService.instance;
      audio.init();

      await audio.playSweep(true, durationSec: 0.05);
      await audio.playSweep(false, durationSec: 0.05);
      await audio.playSuccessChime();
      await audio.playGentleError();
      audio.playStepTick();
    });
  });

  group('CaregiverAuthService Phone & Password Sync', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('login with phone number and password succeeds with mock client', () async {
      final auth = CaregiverAuthService.instance;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/auth')) {
          final body = jsonDecode(request.body);
          if (body['action'] == 'login' &&
              body['identifier'] == '9435012345' &&
              body['password'] == 'care123') {
            return http.Response(
              jsonEncode({
                'success': true,
                'user': {
                  'id': 'demo-caregiver-001',
                  'fullName': 'Anuradha Baruah',
                  'identifier': '9435012345',
                  'role': 'CAREGIVER',
                  'region': 'Guwahati, Assam',
                },
              }),
              200,
            );
          }
        }
        return http.Response(jsonEncode({'success': false, 'error': 'Invalid credentials'}), 401);
      });

      auth.setHttpClientForTesting(mockClient);
      final res = await auth.login(identifier: '9435012345', password: 'care123');

      expect(res.success, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.caregiverId, 'demo-caregiver-001');
      expect(auth.caregiverPhone, '9435012345');
      expect(auth.caregiverName, 'Anuradha Baruah');

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.caregiverId, isEmpty);
    });

    test('signUp with phone number succeeds with mock client', () async {
      final auth = CaregiverAuthService.instance;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/auth')) {
          final body = jsonDecode(request.body);
          if (body['action'] == 'signup') {
            return http.Response(
              jsonEncode({
                'success': true,
                'user': {
                  'id': 'cg-ner-new-123',
                  'fullName': body['fullName'],
                  'identifier': body['identifier'],
                  'role': 'CAREGIVER',
                  'region': body['region'],
                },
              }),
              201,
            );
          }
        }
        return http.Response(jsonEncode({'success': false}), 400);
      });

      auth.setHttpClientForTesting(mockClient);
      final res = await auth.signUp(
        fullName: 'Pranjal Saikia',
        identifier: '9876543210',
        password: 'passWord456',
      );

      expect(res.success, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.caregiverName, 'Pranjal Saikia');
      expect(auth.caregiverPhone, '9876543210');
      expect(auth.caregiverId, 'cg-ner-new-123');

      await auth.logout();
    });
  });
}

