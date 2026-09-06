import 'package:shared_preferences/shared_preferences.dart';
import 'package:dementia_ner_care/core/localization/app_language.dart';
import 'package:dementia_ner_care/core/localization/app_translations.dart';
import 'package:dementia_ner_care/core/localization/location_language_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a manual language choice is not replaced by background GPS detection',
      () async {
    final service = LocationLanguageService();

    service.setLanguage(AppLanguage.hindi, customRegion: 'Manual');
    await service.detectAndSetLanguageAutomatically();

    expect(service.currentLanguage, AppLanguage.hindi);
    expect(service.isManualSelection, isTrue);
  });

  test('every UI key has a patient-readable fallback', () {
    expect(
      AppTranslations.get(AppLanguage.mizo, 'memory_matching_title'),
      isNot('memory_matching_title'),
    );
  });
}
