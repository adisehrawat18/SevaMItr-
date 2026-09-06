import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/ui/components/dementia_accessible_button.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';


class RoutineStep {
  final int correctOrderIndex;
  final String title;
  final String regionalTitle;
  final IconData icon;
  final Color color;

  const RoutineStep({
    required this.correctOrderIndex,
    required this.title,
    required this.regionalTitle,
    required this.icon,
    required this.color,
  });
}

/// Daily Routine Sequencing Game
/// Uses single-tap slotting (zero drag-and-drop) to accommodate elderly motor tremors.
/// Promotes procedural memory through familiar daily rituals of the North Eastern Region.
class RoutineSequencingScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const RoutineSequencingScreen({
    super.key,
    required this.onBackToHub,
  });

  @override
  State<RoutineSequencingScreen> createState() =>
      _RoutineSequencingScreenState();
}

class _RoutineSequencingScreenState extends State<RoutineSequencingScreen> {
  // Morning Routine sequence:
  // 1. Morning Red Tea / Lal Saah (ৰঙা চাহ)
  // 2. Brush & Bath (গা ধোৱা)
  // 3. Morning Prayer / Naam Prasanga (নাম-প্ৰসংগ / পূজা)
  // 4. Breakfast & Morning Medicine (জলপান আৰু ঔষধ)
  final List<RoutineStep> _allSteps = const [
    RoutineStep(
      correctOrderIndex: 0,
      title: "1. Morning Tea (Lal Saah)",
      regionalTitle: "পুৱাৰ ৰঙা চাহ খোৱা",
      icon: Icons.coffee,
      color: DementiaColors.ochreWarmAmber,
    ),
    RoutineStep(
      correctOrderIndex: 1,
      title: "2. Brush & Bath",
      regionalTitle: "হাত-মুখ ধুই গা ধোৱা",
      icon: Icons.bathtub,
      color: DementiaColors.voiceAssistanceBlue,
    ),
    RoutineStep(
      correctOrderIndex: 2,
      title: "3. Morning Prayer / Puja",
      regionalTitle: "নামঘৰত বন্তি প্ৰজ্বলন / প্ৰাৰ্থনা",
      icon: Icons.self_improvement,
      color: DementiaColors.alertTerracotta,
    ),
    RoutineStep(
      correctOrderIndex: 3,
      title: "4. Breakfast & Medicines",
      regionalTitle: "পুৱাৰ জলপান আৰু ঔষধ",
      icon: Icons.medication,
      color: DementiaColors.actionForestGreen,
    ),
  ];

  late List<RoutineStep> _availableOptions;
  final List<RoutineStep> _placedSteps = [];
  bool _isCompleted = false;
  String? _feedbackMessage;
  DateTime? _startTime;
  int _totalAttempts = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _startTime = DateTime.now();
    _totalAttempts = 0;
    _errorCount = 0;
    final shuffled = List<RoutineStep>.from(_allSteps)..shuffle();
    setState(() {
      _availableOptions = shuffled;
      _placedSteps.clear();
      _isCompleted = false;
      _feedbackMessage = null;
    });
  }

  void _onStepTapped(RoutineStep step) {
    _totalAttempts++;
    final nextTargetIndex = _placedSteps.length;

    if (step.correctOrderIndex == nextTargetIndex) {
      // Correct step tapped!
      setState(() {
        _placedSteps.add(step);
        _availableOptions.remove(step);
        _feedbackMessage = context.tr('great_next');
      });

      RegionalTtsService().speak(context.tr('correct'));

      if (_placedSteps.length == _allSteps.length) {
        setState(() {
          _isCompleted = true;
          _feedbackMessage = context.tr('routine_complete_feedback');
        });
        RegionalTtsService().speak(context.tr('routine_complete_feedback'));
        _recordGameCompletion();
      }
    } else {
      _errorCount++;
      // Gentle encouragement
      setState(() {
        _feedbackMessage = context.tr('try_again');
      });
      RegionalTtsService().speak(context.tr('try_again'));
    }
  }

  Future<void> _recordGameCompletion() async {
    try {
      final elapsed = DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
      final score = (100.0 - (_errorCount * 8) - (elapsed > 40 ? 8 : 0)).clamp(40.0, 100.0);
      final metric = CognitiveMetric(
        gameType: 'ROUTINE_SEQUENCE',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        gridDimension: 2,
        totalMoves: _totalAttempts > 0 ? _totalAttempts : 4,
        errorCount: _errorCount,
        completionTimeSeconds: elapsed > 0 ? elapsed : 20,
        tremorJitterScore: (_errorCount * 0.1).clamp(0.05, 0.7),
        calculatedScore: score,
        recommendedGridSize: 2,
        isSynced: false,
      );
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Error recording routine sequencing metric: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DementiaColors.canvasWarmCream,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: DementiaColors.surfaceDarkNavy,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                AccessibleTouchWrapper(
                  semanticLabel: context.tr('back_to_games'),
                  onTap: widget.onBackToHub,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DementiaColors.surfaceCardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: DementiaColors.textPrimaryDark, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  context.tr('morning_routine'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DementiaColors.actionGreenLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: DementiaColors.actionForestGreen, width: 2),
              ),
              child: Text(
                _feedbackMessage ?? context.tr('routine_instruction'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: DementiaColors.actionForestGreen,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Sequenced Slots (Steps 1 to 4)
            Text(
              context.tr('your_morning_order'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: DementiaColors.textPrimaryDark),
            ),
            const SizedBox(height: 10),

            ...List.generate(4, (index) {
              final isFilled = index < _placedSteps.length;
              final step = isFilled ? _placedSteps[index] : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 64),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? DementiaColors.surfaceCardLight
                        : DementiaColors.canvasWarmCream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFilled
                          ? DementiaColors.actionForestGreen
                          : DementiaColors.dividerColor,
                      width: isFilled ? 2.5 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? DementiaColors.actionForestGreen
                              : DementiaColors.dividerColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: isFilled
                            ? Row(
                                children: [
                                  Icon(step!.icon, color: step.color, size: 28),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                DementiaColors.textPrimaryDark,
                                          ),
                                        ),
                                        Text(
                                          step.regionalTitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: DementiaColors
                                                .textSecondaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.check_circle,
                                      color: DementiaColors.actionForestGreen,
                                      size: 26),
                                ],
                              )
                            : Text(
                                context.tr('waiting_for_step'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: DementiaColors.textSecondaryDark,
                                    fontStyle: FontStyle.italic),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Available Cards to Tap
            if (!_isCompleted) ...[
              Text(
                context.tr('tap_next_step'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: DementiaColors.textPrimaryDark),
              ),
              const SizedBox(height: 10),
              ..._availableOptions.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AccessibleTouchWrapper(
                    semanticLabel: "${option.title} ${option.regionalTitle}",
                    onTap: () => _onStepTapped(option),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 72),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: DementiaColors.surfaceCardLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: option.color, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: option.color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(option.icon,
                                color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: DementiaColors.textPrimaryDark,
                                  ),
                                ),
                                Text(
                                  option.regionalTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: option.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.touch_app,
                              color: DementiaColors.textSecondaryDark,
                              size: 26),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else ...[
              // Completion celebration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DementiaColors.actionForestGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.white, size: 54),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('routine_complete'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    DementiaAccessibleButton(
                      text: context.tr('play_again'),
                      icon: Icons.refresh,
                      backgroundColor: Colors.white,
                      contentColor: DementiaColors.actionForestGreen,
                      onClick: _resetGame,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
