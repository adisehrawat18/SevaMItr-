import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Tremor-Resistant Debounced Touch Wrapper
/// Drops accidental rapid double-clicks (tremor jitter) within 650ms.
/// Triggers heavy haptic confirmation for sensory verification.
class AccessibleTouchWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;
  final Duration debounceDuration;
  final bool enableHaptics;

  const AccessibleTouchWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.debounceDuration = const Duration(milliseconds: 650),
    this.enableHaptics = true,
  });

  @override
  State<AccessibleTouchWrapper> createState() => _AccessibleTouchWrapperState();
}

class _AccessibleTouchWrapperState extends State<AccessibleTouchWrapper> {
  int _lastClickTime = 0;

  void _handleTap() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastClickTime >=
        widget.debounceDuration.inMilliseconds) {
      _lastClickTime = currentTime;
      if (widget.enableHaptics) {
        HapticFeedback.heavyImpact();
      }
      widget.onTap();
    }
  }

  void _readAloud() {
    final text = widget.semanticLabel;
    if (text == null || text.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    RegionalTtsService().speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onLongPress: _readAloud,
      onLongPressHint: 'Read aloud',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _handleTap,
          onLongPress: _readAloud,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Regional Text-To-Speech Audio Feedback Service for Dementia Patients
class RegionalTtsService {
  static final RegionalTtsService _instance = RegionalTtsService._internal();
  factory RegionalTtsService() => _instance;
  RegionalTtsService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _flutterTts = FlutterTts();

    // Set speech rate slower for cognitive comprehension
    await _flutterTts?.setSpeechRate(0.42);
    await _flutterTts?.setPitch(1.0);

    // Attempt regional language (fallback to English/Bengali/Hindi)
    final languages = await _flutterTts?.getLanguages;
    if (languages != null && (languages as List).contains('as-IN')) {
      await _flutterTts?.setLanguage('as-IN'); // Assamese
    } else if (languages != null && (languages as List).contains('bn-IN')) {
      await _flutterTts?.setLanguage('bn-IN'); // Bengali
    } else {
      await _flutterTts?.setLanguage('en-IN');
    }
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _flutterTts?.stop();
    await _flutterTts?.speak(text);
  }

  Future<void> setLanguage(String locale) async {
    if (!_isInitialized) await init();
    try {
      await _flutterTts?.setLanguage(locale);
    } catch (_) {
      await _flutterTts?.setLanguage('en-IN');
    }
  }

  Future<void> stop() async {
    await _flutterTts?.stop();
  }
}
