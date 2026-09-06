import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/location_language_service.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/models/medication_model.dart';
import 'package:dementia_ner_care/ui/components/orientation_clock_card.dart';
import 'package:dementia_ner_care/ui/components/persistent_bottom_nav.dart';
import 'package:dementia_ner_care/ui/components/language_selector_modal.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';


/// Home Dashboard Screen for Dementia Patients in North Eastern Region
class HomeDashboardScreen extends StatefulWidget {
  final MedicationSchedule? nextMedication;
  final VoidCallback onMedicationClick;
  final VoidCallback onVoiceAssistClick;
  final VoidCallback onNavigateGames;
  final VoidCallback onNavigateFamily;
  final VoidCallback onOpenCaregiverPinModal;

  const HomeDashboardScreen({
    super.key,
    this.nextMedication,
    required this.onMedicationClick,
    required this.onVoiceAssistClick,
    required this.onNavigateGames,
    required this.onNavigateFamily,
    required this.onOpenCaregiverPinModal,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  DementiaNavTab _currentTab = DementiaNavTab.home;
  final _locService = LocationLanguageService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _voiceFeedback = '';

  @override
  void initState() {
    super.initState();
    // Automatically detect location and set language on startup
    _locService.detectAndSetLanguageAutomatically();
  }

  void _openLanguagePicker() {
    LanguageSelectorModal.show(context);
  }

  Future<void> _toggleVoiceAssistant() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _voiceFeedback = context.tr('voice_error');
        });
        RegionalTtsService().speak(context.tr('voice_error'));
      },
    );
    if (!mounted) return;

    if (!available) {
      setState(() => _voiceFeedback = context.tr('voice_error'));
      RegionalTtsService().speak(context.tr('voice_error'));
      return;
    }

    await RegionalTtsService().stop();
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _voiceFeedback = context.tr('voice_listening');
    });
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _locService.currentLanguage.ttsLocale,
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: _onSpeechResult,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (words.isEmpty || !mounted) return;
    setState(() =>
        _voiceFeedback = context.tr('voice_heard', values: {'words': words}));
    if (result.finalResult) _handleVoiceCommand(words);
  }

  void _handleVoiceCommand(String words) {
    final command = words.toLowerCase();
    if (_containsAny(command, ['game', 'play', 'games', 'খেল', 'खेल'])) {
      widget.onNavigateGames();
    } else if (_containsAny(
        command, ['medicine', 'medication', 'dawai', 'দवा', 'ওষুধ', 'ঔষধ'])) {
      widget.onMedicationClick();
    } else if (_containsAny(
        command, ['family', 'call', 'phone', 'পরিবার', 'পৰিয়াল', 'परिवार'])) {
      widget.onNavigateFamily();
    } else if (_containsAny(command, ['language', 'भाषा', 'ভাষা'])) {
      _openLanguagePicker();
    } else if (_containsAny(command, ['help', 'सहायता', 'সাহায্য'])) {
      RegionalTtsService().speak(context.tr('voice_help'));
    } else {
      RegionalTtsService().speak(context.tr('voice_not_understood'));
    }
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  void _readHomeSummary() {
    RegionalTtsService().speak([
      _locService.tr('home_safe'),
      _locService.tr('mind_games'),
      _locService.tr('next_up'),
      _locService.tr('call_family'),
    ].join('. '));
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _locService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: DementiaColors.canvasWarmCream,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: Container(
              color: DementiaColors.surfaceDarkNavy,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Patient Greeting
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white70, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: DementiaColors.actionForestGreen,
                                alignment: Alignment.center,
                                child: Text(
                                  _locService.tr('greeting'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locService.tr('patient_greeting'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  context.tr('app_name'),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top Action Controls: Language Switcher + Caregiver Lock
                    Row(
                      children: [
                        // Dedicated Language Switcher Button (Large 48x48dp target)
                        AccessibleTouchWrapper(
                          semanticLabel:
                              "${context.tr('change_language')}: ${_locService.currentLanguage.displayName}",
                          onTap: _openLanguagePicker,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: DementiaColors.voiceAssistanceBlue,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.white70, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.language,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 4),
                                Text(
                                  _locService.currentLanguage.code
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // SevaMitr Cloud Sync Status Indicator
                        ListenableBuilder(
                          listenable: SevaMitrSyncService.instance,
                          builder: (context, _) {
                            final sync = SevaMitrSyncService.instance;
                            final icon = sync.isSyncing
                                ? Icons.sync
                                : (sync.isOnline
                                    ? (sync.unsyncedCount == 0 ? Icons.cloud_done : Icons.cloud_upload)
                                    : Icons.cloud_off);
                            final color = sync.isSyncing
                                ? DementiaColors.voiceAssistanceBlue
                                : (sync.isOnline
                                    ? (sync.unsyncedCount == 0 ? DementiaColors.actionForestGreen : DementiaColors.ochreWarmAmber)
                                    : DementiaColors.alertTerracotta);

                            return AccessibleTouchWrapper(
                              semanticLabel: "SevaMitr Sync: ${sync.lastSyncMessage}",
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("SevaMitr Sync: ${sync.lastSyncMessage} (${sync.unsyncedCount} queued)"),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: color,
                                  ),
                                );
                              },
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white70, width: 1.5),
                                ),
                                child: Icon(icon, color: Colors.white, size: 24),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // Caregiver Mode Discreet PIN Protected Gateway
                        AccessibleTouchWrapper(
                          semanticLabel: context.tr('caregiver_settings'),
                          onTap: widget.onOpenCaregiverPinModal,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: DementiaColors.caregiverShieldGold,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.white60, width: 1.5),
                            ),
                            child: const Icon(Icons.lock,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: PersistentBottomNavBar(
            currentTab: _currentTab,
            onTabSelected: (tab) {
              setState(() => _currentTab = tab);
              if (tab == DementiaNavTab.games) {
                widget.onNavigateGames();
              } else if (tab == DementiaNavTab.family) {
                widget.onNavigateFamily();
              }
            },
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                // Keep two core supports first: a spoken prompt and play.
                _buildVoiceControls(),
                const SizedBox(height: 16),

                _buildActionTile(
                  title: _locService.tr('mind_games'),
                  regionalTitle: _locService.currentLanguage.displayName,
                  description: _locService.tr('mind_games_desc'),
                  icon: Icons.psychology,
                  accentColor: DementiaColors.actionForestGreen,
                  onClick: widget.onNavigateGames,
                ),
                const SizedBox(height: 14),

                // Keep the next care task close to the primary activity.
                _buildNextTaskCard(),
                const SizedBox(height: 16),

                OrientationClockCard(
                  timeString: "09:30 AM",
                  dayOfWeek: "Monday",
                  dayOfWeekRegional: _locService.currentLanguage.regionName,
                  timeOfDayPhase: "Morning",
                  timeOfDayPhaseRegional: _locService.tr('morning'),
                  dateFormatted: "31 August 2026",
                  reassuranceText: _locService.tr('home_safe'),
                ),
                const SizedBox(height: 16),

                _buildActionTile(
                  title: _locService.tr('call_family'),
                  regionalTitle: _locService.currentLanguage.displayName,
                  description: _locService.tr('call_family_desc'),
                  icon: Icons.call,
                  accentColor: DementiaColors.voiceAssistanceBlue,
                  onClick: widget.onNavigateFamily,
                ),
                const SizedBox(height: 14),

                _buildLocationLanguageBanner(),
                const SizedBox(height: 14),

                _buildActionTile(
                  title: context.tr('change_language'),
                  regionalTitle: _locService.currentLanguage.displayName,
                  description: context.tr('change_language_description'),
                  icon: Icons.translate,
                  accentColor: DementiaColors.ochreWarmAmber,
                  onClick: _openLanguagePicker,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationLanguageBanner() {
    return AccessibleTouchWrapper(
      semanticLabel:
          "${context.tr('location')}: ${_locService.detectedRegion}. ${context.tr('tap_to_change')}",
      onTap: _openLanguagePicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DementiaColors.ochreBadgeBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DementiaColors.ochreWarmAmber, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on,
                color: DementiaColors.ochreWarmAmber, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${context.tr('location')}: ",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: DementiaColors.ochreWarmAmber,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _locService.detectedRegion,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: DementiaColors.textPrimaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${context.tr('language')}: ${_locService.currentLanguage.displayName} (${context.tr('tap_to_change')})",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DementiaColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DementiaColors.ochreWarmAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.tr('change'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceAssistantBanner() {
    return AccessibleTouchWrapper(
      semanticLabel: _isListening
          ? context.tr('voice_listening')
          : context.tr('offline_voice_assistant'),
      onTap: _toggleVoiceAssistant,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: DementiaColors.voiceAssistanceBlue,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: DementiaColors.focusBorderHighlight, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.hearing : Icons.mic,
                color: DementiaColors.voiceAssistanceBlue,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isListening
                        ? context.tr('voice_listening')
                        : _locService.tr('tap_to_speak'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900),
                  ),
                  Text(
                    _voiceFeedback.isEmpty
                        ? _locService.tr('speak_hint')
                        : _voiceFeedback,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceControls() {
    // A scrolling parent gives children unconstrained height. Explicitly
    // constrain this row so its stretch layout remains valid on every phone
    // and tablet size.
    return SizedBox(
      height: 104,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildVoiceAssistantBanner()),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: AccessibleTouchWrapper(
              semanticLabel: context.tr('read_home'),
              onTap: _readHomeSummary,
              child: Container(
                decoration: BoxDecoration(
                  color: DementiaColors.actionForestGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DementiaColors.focusBorderHighlight,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('read_aloud'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextTaskCard() {
    final med = widget.nextMedication ??
        MedicationSchedule(
          title: _locService.tr('medicine_default_name'),
          regionalTitle: _locService.tr('medicine_default_name'),
          dosageDescription: _locService.tr('medicine_default_instruction'),
          visualAssetType: "PILL_GREEN",
          scheduledTimeFormatted: "10:00 AM",
          hourOfDay: 10,
          minute: 0,
        );

    return AccessibleTouchWrapper(
      semanticLabel:
          "${_locService.tr('next_up')}: ${med.title} ${med.scheduledTimeFormatted}",
      onTap: widget.onMedicationClick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DementiaColors.ochreBadgeBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DementiaColors.ochreWarmAmber, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: DementiaColors.ochreWarmAmber,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.medication, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _locService.tr('next_up'),
                    style: const TextStyle(
                      color: DementiaColors.ochreWarmAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "${med.title} (${med.regionalTitle})",
                    style: const TextStyle(
                      color: DementiaColors.textPrimaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${context.tr('scheduled')}: ${med.scheduledTimeFormatted} • ${med.dosageDescription}",
                    style: const TextStyle(
                      color: DementiaColors.textSecondaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: DementiaColors.ochreWarmAmber, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String regionalTitle,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onClick,
  }) {
    return AccessibleTouchWrapper(
      semanticLabel: "$title $regionalTitle. $description",
      onTap: onClick,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DementiaColors.surfaceCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: DementiaColors.textPrimaryDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: DementiaColors.textSecondaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.tr('read_aloud'),
              icon: const Icon(
                Icons.volume_up,
                color: DementiaColors.textSecondaryDark,
                size: 28,
              ),
              onPressed: () =>
                  RegionalTtsService().speak('$title. $description'),
            ),
          ],
        ),
      ),
    );
  }
}
