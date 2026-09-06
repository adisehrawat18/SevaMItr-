import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/localization/location_language_service.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/ui/screens/caregiver/caregiver_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CaregiverDashboardScreen renders SevaMitr sync card and cognitive analytics', (tester) async {
    final locService = LocationLanguageService();

    await tester.pumpWidget(
      AppLanguageScope(
        languageService: locService,
        child: MaterialApp(
          theme: DementiaTheme.lightTheme,
          home: CaregiverDashboardScreen(
            onExitCaregiverMode: () {},
            onEditPatientDetails: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and patient details edit button
    expect(find.text('Edit patient and family contact details'), findsOneWidget);

    // Verify SevaMitr Cloud Synchronization Card is present
    expect(find.text('SevaMitr Cloud Synchronization'), findsOneWidget);
    expect(find.textContaining('Sync Now'), findsOneWidget);

    // Verify Dynamic Cognitive Index (DCI) card is present
    expect(find.text('Dynamic Cognitive Index (DCI)'), findsOneWidget);

    // Verify 5-Domain Cognitive Breakdown is rendered
    expect(find.text('5-Domain Cognitive Breakdown (SevaMitr Cloud)'), findsOneWidget);
    expect(find.textContaining('Memory (Smriti Setu)'), findsOneWidget);
    expect(find.textContaining('Attention (Rang & Tanti)'), findsOneWidget);
    expect(find.textContaining('Executive (Doharani)'), findsOneWidget);
    expect(find.textContaining('Auditory (Shabda Tarang)'), findsOneWidget);
    expect(find.textContaining('Market Math (Bazaar Saathi)'), findsOneWidget);

    // Verify server config dialog opens on settings tap
    final settingsIcon = find.byIcon(Icons.settings);
    expect(settingsIcon, findsOneWidget);
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();

    expect(find.text('SevaMitr Server Config'), findsOneWidget);
    expect(find.text('Save & Test'), findsOneWidget);
  });
}
