import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/data/models/patient_profile_model.dart';
import 'package:dementia_ner_care/ui/screens/onboarding/patient_setup_screen.dart';
import 'package:dementia_ner_care/ui/components/neo_widgets.dart';

void main() {
  testWidgets('PatientSetupScreen renders Neo-Brutalist elements and prefills sample', (tester) async {
    PatientProfile? savedProfile;

    await tester.pumpWidget(
      MaterialApp(
        theme: DementiaTheme.lightTheme,
        home: PatientSetupScreen(
          onSaved: (profile) => savedProfile = profile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Header Badge Pair from DESIGN_SYSTEM.md
    expect(find.byType(NeoHeaderBadgePair), findsOneWidget);
    expect(find.text('PATIENT REGISTRATION REQUIRED'), findsOneWidget);

    // Check title and prefill button
    expect(find.text('ADD A PATIENT TO START GAMES'), findsOneWidget);
    expect(find.text('SAMPLE (ASSAM)'), findsOneWidget);

    // Tap the sample prefill button
    await tester.tap(find.text('SAMPLE (ASSAM)'));
    await tester.pumpAndSettle();

    // Verify fields were prefilled with Assamese sample data
    expect(find.text('Bhaben Baruah'), findsOneWidget);
    expect(find.text('Tezpur, Sonitpur, Assam'), findsOneWidget);

    // Check the primary tactile NeoButton
    expect(find.text('SAVE PATIENT & START GAMES'), findsOneWidget);

    // Scroll down to submit button and tap it
    await tester.ensureVisible(find.text('SAVE PATIENT & START GAMES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE PATIENT & START GAMES'));
    await tester.pumpAndSettle();

    // Verify that the saved profile contains the expanded fields
    expect(savedProfile, isNotNull);
    expect(savedProfile!.fullName, 'Bhaben Baruah');
    expect(savedProfile!.region, 'Tezpur, Sonitpur, Assam');
    expect(savedProfile!.primaryLanguage, 'as');
    expect(savedProfile!.dementiaStage, 'Mild');
    expect(savedProfile!.gender, 'Male');
    expect(savedProfile!.enableKiosk, isTrue);
    expect(savedProfile!.kioskIdentifier, 'bhaben');
    expect(savedProfile!.kioskPin, '1234');
  });
}
