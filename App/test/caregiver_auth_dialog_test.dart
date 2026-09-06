import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/ui/screens/caregiver/caregiver_auth_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CaregiverAuthDialog renders unified design matching SevaMitr website', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DementiaTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CaregiverAuthDialog.show(context),
              child: const Text('Open Auth'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to open auth dialog
    await tester.tap(find.text('Open Auth'));
    await tester.pumpAndSettle();

    // 1. Verify Brand Header
    expect(find.text('SEVA'), findsOneWidget);
    expect(find.text('MITR'), findsOneWidget);
    expect(find.text('Cognitive health & circadian memory care platform.'), findsOneWidget);

    // 2. Verify Segmented Pill Tabs
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('REGISTER'), findsOneWidget);

    // 3. In Log In Tab by default
    expect(find.text('PHONE / USERNAME'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('Use Hackathon Demo Account'), findsOneWidget);

    // Try submitting empty login form to verify error banner
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter both phone/username and password.'), findsOneWidget);

    // 4. Switch to REGISTER Tab
    await tester.tap(find.text('REGISTER'));
    await tester.pumpAndSettle();

    // Error banner should clear on tab change
    expect(find.text('Please enter both phone/username and password.'), findsNothing);

    // Verify Registration Fields & Caregiver Guidance Banner
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.textContaining('Caregiver Registration:'), findsOneWidget);
    expect(find.text('CAREGIVER DESIGNATION'), findsOneWidget);
    expect(find.text('Family Member / Primary Caregiver'), findsOneWidget);
    expect(find.text('PHONE / ID'), findsOneWidget);
    expect(find.text('REGION'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);

    // Try submitting empty registration form
    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();
    expect(find.text('Please fill in all required fields.'), findsOneWidget);

    // Test Designation dropdown interaction
    await tester.tap(find.text('Family Member / Primary Caregiver'));
    await tester.pumpAndSettle();
    expect(find.text('ASHA / Anganwadi Community Health Worker').last, findsOneWidget);
    expect(find.text('Clinical Doctor / Medical Officer').last, findsOneWidget);

    // Select ASHA worker
    await tester.tap(find.text('ASHA / Anganwadi Community Health Worker').last);
    await tester.pumpAndSettle();
    expect(find.text('ASHA / Anganwadi Community Health Worker'), findsOneWidget);
  });
}
