/// Supported Regional Languages in the North Eastern Region of India
enum AppLanguage {
  assamese('as', 'অসমীয়া (Assamese)', 'Assam', 'as-IN'),
  manipuri('mni', 'মৈতৈলোন্ / Manipuri', 'Manipur', 'bn-IN'),
  bengali('bn', 'বাংলা (Bengali)', 'Tripura / Cachar', 'bn-IN'),
  khasi('kha', 'Khasi', 'Meghalaya', 'en-IN'),
  mizo('lus', 'Mizo ṭawng', 'Mizoram', 'en-IN'),
  hindi('hi', 'हिन्दी (Hindi)', 'Arunachal / Sikkim', 'hi-IN'),
  english('en', 'English', 'General', 'en-IN');

  final String code;
  final String displayName;
  final String regionName;
  final String ttsLocale;

  const AppLanguage(
      this.code, this.displayName, this.regionName, this.ttsLocale);

  /// Flutter Material widgets only ship a subset of locales. App copy still
  /// uses [code]; this keeps DatePicker and similar widgets from crashing.
  String get materialCode {
    switch (this) {
      case AppLanguage.bengali:
      case AppLanguage.manipuri:
        return 'bn';
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.assamese:
      case AppLanguage.khasi:
      case AppLanguage.mizo:
      case AppLanguage.english:
        return 'en';
    }
  }

  bool get prefersRegionalContent => this != AppLanguage.english;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}
