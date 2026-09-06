import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'app_language.dart';
import 'app_translations.dart';

/// Service that coordinates Automatic Location Detection and Regional Language Adaptation
class LocationLanguageService extends ChangeNotifier {
  static const _languagePrefKey = 'app_language_code';
  static const _manualPrefKey = 'app_language_manual';
  static const _regionPrefKey = 'app_language_region';

  static final LocationLanguageService _instance =
      LocationLanguageService._internal();
  factory LocationLanguageService() => _instance;
  LocationLanguageService._internal();

  AppLanguage _currentLanguage = AppLanguage.english;
  String _detectedRegion = "Detecting location...";
  bool _isDetecting = false;
  bool _hasDetected = false;
  bool _isManualSelection = false;
  bool _restored = false;

  AppLanguage get currentLanguage => _currentLanguage;
  String get detectedRegion => _detectedRegion;
  bool get isDetecting => _isDetecting;
  bool get hasDetected => _hasDetected;
  bool get isManualSelection => _isManualSelection;

  String tr(String key) => AppTranslations.get(_currentLanguage, key);

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_languagePrefKey);
    if (code == null) return;
    _currentLanguage = AppLanguage.fromCode(code);
    _isManualSelection = prefs.getBool(_manualPrefKey) ?? false;
    _detectedRegion = prefs.getString(_regionPrefKey) ?? _detectedRegion;
    _hasDetected = true;
    _updateTtsLocale(_currentLanguage);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefKey, _currentLanguage.code);
    await prefs.setBool(_manualPrefKey, _isManualSelection);
    await prefs.setString(_regionPrefKey, _detectedRegion);
  }

  void setLanguage(AppLanguage language, {String? customRegion}) {
    _currentLanguage = language;
    _isManualSelection = true;
    if (customRegion != null) {
      _detectedRegion = customRegion;
    }
    _updateTtsLocale(language);
    notifyListeners();
    _persist();
  }

  Future<void> detectAndSetLanguageAutomatically({bool force = false}) async {
    // A deliberate language choice must never be replaced when a screen is
    // revisited. GPS detection remains available as an explicit user action.
    if (_isManualSelection && !force) return;
    if (_hasDetected && !force) return;

    _isManualSelection = false;
    _isDetecting = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackToDefault("GPS Disabled • Default: English");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fallbackToDefault("Permission Denied • Default: English");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _fallbackToDefault("Permission Denied • Default: English");
        return;
      }

      // Query current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final lat = position.latitude;
      final lon = position.longitude;

      final matched = _classifyNERLocation(lat, lon);
      _currentLanguage = matched.language;
      _detectedRegion =
          "${matched.regionName} (${lat.toStringAsFixed(2)}°N, ${lon.toStringAsFixed(2)}°E)";
      _hasDetected = true;
      _isDetecting = false;

      _updateTtsLocale(_currentLanguage);
      notifyListeners();
      _persist();
    } catch (e) {
      _fallbackToDefault("Location Unavailable • Default: English");
    }
  }

  void _fallbackToDefault(String reason) {
    _currentLanguage = AppLanguage.english;
    _detectedRegion = reason;
    _isDetecting = false;
    _hasDetected = true;
    _updateTtsLocale(_currentLanguage);
    notifyListeners();
    _persist();
  }

  void _updateTtsLocale(AppLanguage language) {
    // TTS is an enhancement. A missing voice on a device must not prevent the
    // selected written language from updating everywhere in the interface.
    RegionalTtsService().setLanguage(language.ttsLocale).catchError((_) {});
  }

  /// Evaluates GPS coordinates against North Eastern Region State Geographic Boundaries
  _NERRegionMatch _classifyNERLocation(double lat, double lon) {
    // 1. Manipur: 23.8° to 25.7° N, 93.0° to 94.8° E
    if (lat >= 23.8 && lat <= 25.7 && lon >= 93.0 && lon <= 94.8) {
      return _NERRegionMatch(AppLanguage.manipuri, "Manipur (মণিপুৰ)");
    }

    // 2. Tripura: 22.9° to 24.5° N, 91.1° to 92.4° E
    if (lat >= 22.9 && lat <= 24.5 && lon >= 91.1 && lon <= 92.4) {
      return _NERRegionMatch(AppLanguage.bengali, "Tripura (ত্রিপুরা)");
    }

    // 3. Meghalaya: 25.0° to 26.1° N, 89.8° to 92.8° E
    if (lat >= 25.0 && lat <= 26.1 && lon >= 89.8 && lon <= 92.8) {
      return _NERRegionMatch(AppLanguage.khasi, "Meghalaya (Khasi)");
    }

    // 4. Mizoram: 21.9° to 24.5° N, 92.2° to 93.5° E
    if (lat >= 21.9 && lat <= 24.5 && lon >= 92.2 && lon <= 93.5) {
      return _NERRegionMatch(AppLanguage.mizo, "Mizoram (Mizo)");
    }

    // 5. Nagaland: 25.1° to 27.0° N, 93.3° to 95.2° E
    if (lat >= 25.1 && lat <= 27.0 && lon >= 93.3 && lon <= 95.2) {
      return _NERRegionMatch(AppLanguage.english, "Nagaland (English)");
    }

    // 6. Arunachal Pradesh: 26.4° to 29.5° N, 91.5° to 97.5° E
    if (lat >= 26.4 && lat <= 29.5 && lon >= 91.5 && lon <= 97.5) {
      return _NERRegionMatch(AppLanguage.hindi, "Arunachal Pradesh (Hindi)");
    }

    // 7. Sikkim: 27.0° to 28.1° N, 88.0° to 88.9° E
    if (lat >= 27.0 && lat <= 28.1 && lon >= 88.0 && lon <= 88.9) {
      return _NERRegionMatch(AppLanguage.hindi, "Sikkim (Hindi/Nepali)");
    }

    // 8. Assam (Broad Brahmaputra & Barak Valley): 24.0° to 28.0° N, 89.5° to 96.0° E
    if (lat >= 24.0 && lat <= 28.0 && lon >= 89.5 && lon <= 96.0) {
      return _NERRegionMatch(AppLanguage.assamese, "Assam (অসমীয়া)");
    }

    // Default for any location OUTSIDE the North Eastern Region -> English
    return _NERRegionMatch(AppLanguage.english, "Outside NER • English");
  }
}

class _NERRegionMatch {
  final AppLanguage language;
  final String regionName;
  _NERRegionMatch(this.language, this.regionName);
}
