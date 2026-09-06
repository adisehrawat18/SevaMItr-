import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/location_language_service.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/patient_profile_model.dart';
import 'package:dementia_ner_care/ui/screens/home/home_dashboard_screen.dart';
import 'package:dementia_ner_care/ui/screens/reminder/medication_alert_screen.dart';
import 'package:dementia_ner_care/ui/screens/games/games_hub_screen.dart';
import 'package:dementia_ner_care/ui/screens/games/cognitive_games_screen.dart';
import 'package:dementia_ner_care/ui/screens/games/object_recognition_screen.dart';
import 'package:dementia_ner_care/ui/screens/games/routine_sequencing_screen.dart';
import 'package:dementia_ner_care/ui/screens/games/proverbs_word_assoc_screen.dart';
import 'package:dementia_ner_care/ui/screens/games/memory_capsule_screen.dart';
import 'package:dementia_ner_care/ui/screens/caregiver/caregiver_pin_dialog.dart';
import 'package:dementia_ner_care/ui/screens/caregiver/caregiver_dashboard_screen.dart';
import 'dart:async';
import 'package:dementia_ner_care/ui/screens/onboarding/patient_setup_screen.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline SQLite DB, TTS voice service, and SevaMitr cloud sync
  await OfflineDatabase.instance.database;
  await OfflineDatabase.instance.seedSampleMetricsIfEmpty();
  final patientProfile = await OfflineDatabase.instance.getPatientProfile();
  await LocationLanguageService().restore();
  await RegionalTtsService().init();
  await SevaMitrSyncService.instance.init();

  // Attempt initial background sync if internet is available
  unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));

  runApp(DementiaNERCareApp(initialProfile: patientProfile));
}


enum AppRoute {
  patientSetup,
  home,
  medicationAlert,
  gamesHub,
  gamePictureMatch,
  gameObjectRecognition,
  gameRoutineSequencing,
  gameProverbs,
  gameMemoryCapsule,
  caregiverDashboard,
}

class DementiaNERCareApp extends StatefulWidget {
  final PatientProfile? initialProfile;

  const DementiaNERCareApp({super.key, this.initialProfile});

  @override
  State<DementiaNERCareApp> createState() => _DementiaNERCareAppState();
}

class _DementiaNERCareAppState extends State<DementiaNERCareApp> with WidgetsBindingObserver {
  late AppRoute _currentRoute;
  final _locService = LocationLanguageService();
  PatientProfile? _profile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profile = widget.initialProfile;
    _currentRoute = _profile == null ? AppRoute.patientSetup : AppRoute.home;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    }
  }

  void _navigateTo(AppRoute route) {
    setState(() => _currentRoute = route);
  }

  Future<void> _saveProfile(PatientProfile profile) async {
    await OfflineDatabase.instance.savePatientProfile(profile);
    unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _currentRoute = AppRoute.home;
    });
  }

  Future<void> _callCaregiver(BuildContext context) async {
    final phone = _profile?.caregiverPhone.trim() ?? '';
    if (phone.isEmpty) {
      _navigateTo(AppRoute.patientSetup);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locService.tr('dialer_unavailable'))),
      );
    }
  }

  void _handleBack(BuildContext context) {
    if (_currentRoute != AppRoute.home) {
      _navigateTo(AppRoute.home);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_locService.tr('already_home'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
        languageService: _locService,
        child: ListenableBuilder(
          listenable: _locService,
          builder: (context, _) => MaterialApp(
          title: _locService.tr('app_name'),
          debugShowCheckedModeBanner: false,
          theme: DementiaTheme.lightTheme,
          locale: Locale(_locService.currentLanguage.materialCode),
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('bn'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => PopScope(
              canPop: false,
              onPopInvokedWithResult: (_, __) => _handleBack(context),
              child: Builder(builder: (context) {
              switch (_currentRoute) {
                case AppRoute.patientSetup:
                  return PatientSetupScreen(profile: _profile, onSaved: _saveProfile);
                case AppRoute.home:
                  return HomeDashboardScreen(
                    onMedicationClick: () =>
                        _navigateTo(AppRoute.medicationAlert),
                    onVoiceAssistClick: () {
                      RegionalTtsService().speak(
                        "${_locService.tr('tap_to_speak')}. ${_locService.tr('voice_assist_prompt')}",
                      );
                    },
                    onNavigateGames: () => _navigateTo(AppRoute.gamesHub),
                    onNavigateFamily: () => _callCaregiver(context),
                    onOpenCaregiverPinModal: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => CaregiverPinDialog(
                          correctPin: "1234",
                          onPinSuccess: () {
                            Navigator.of(ctx).pop();
                            _navigateTo(AppRoute.caregiverDashboard);
                          },
                          onDismiss: () => Navigator.of(ctx).pop(),
                        ),
                      );
                    },
                  );

                case AppRoute.medicationAlert:
                  return MedicationAlertScreen(
                    onMedicineTaken: () async {
                      await OfflineDatabase.instance.markMedicationTaken(1);
                      RegionalTtsService()
                          .speak(_locService.tr('recorded_thanks'));
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) _navigateTo(AppRoute.home);
                      });
                    },
                    onSnooze: () => _navigateTo(AppRoute.home),
                    onCallCaregiver: () => _callCaregiver(context),
                  );

                case AppRoute.gamesHub:
                  return GamesHubScreen(
                    onBackToHome: () => _navigateTo(AppRoute.home),
                    onSelectPictureMatch: () =>
                        _navigateTo(AppRoute.gamePictureMatch),
                    onSelectObjectRecognition: () =>
                        _navigateTo(AppRoute.gameObjectRecognition),
                    onSelectRoutineSequencing: () =>
                        _navigateTo(AppRoute.gameRoutineSequencing),
                    onSelectProverbs: () => _navigateTo(AppRoute.gameProverbs),
                    onSelectMemoryCapsule: () =>
                        _navigateTo(AppRoute.gameMemoryCapsule),
                  );

                case AppRoute.gamePictureMatch:
                  return CognitiveGamesScreen(
                    onBackToHome: () => _navigateTo(AppRoute.gamesHub),
                  );

                case AppRoute.gameObjectRecognition:
                  return ObjectRecognitionScreen(
                    onBackToHub: () => _navigateTo(AppRoute.gamesHub),
                  );

                case AppRoute.gameRoutineSequencing:
                  return RoutineSequencingScreen(
                    onBackToHub: () => _navigateTo(AppRoute.gamesHub),
                  );

                case AppRoute.gameProverbs:
                  return ProverbsWordAssocScreen(
                    onBackToHub: () => _navigateTo(AppRoute.gamesHub),
                  );

                case AppRoute.gameMemoryCapsule:
                  return MemoryCapsuleScreen(
                    onBackToHub: () => _navigateTo(AppRoute.gamesHub),
                  );

                case AppRoute.caregiverDashboard:
                  return CaregiverDashboardScreen(
                    onExitCaregiverMode: () => _navigateTo(AppRoute.home),
                    onEditPatientDetails: () => _navigateTo(AppRoute.patientSetup),
                  );
              }
            }),
            ),
          ),
        )));
  }
}
