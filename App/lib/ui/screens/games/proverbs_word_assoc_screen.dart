import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/ui/components/dementia_accessible_button.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';
import 'package:dementia_ner_care/ui/widgets/game_celebration_dialog.dart';

class ProverbItem {
  final String firstPart;
  final String firstPartRegional;
  final String meaning;
  final String correctEnding;
  final String correctEndingRegional;
  final String distractorEnding;
  final String distractorEndingRegional;

  const ProverbItem({
    required this.firstPart,
    required this.firstPartRegional,
    required this.meaning,
    required this.correctEnding,
    required this.correctEndingRegional,
    required this.distractorEnding,
    required this.distractorEndingRegional,
  });
}

/// Regional Proverbs & Word Association Screen
/// Stimulates long-term semantic memory and cultural linguistic recall
/// through deeply ingrained traditional folk idioms of the North East.
class ProverbsWordAssocScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const ProverbsWordAssocScreen({
    super.key,
    required this.onBackToHub,
  });

  @override
  State<ProverbsWordAssocScreen> createState() =>
      _ProverbsWordAssocScreenState();
}

class _ProverbsWordAssocScreenState extends State<ProverbsWordAssocScreen> {
  final List<ProverbItem> _proverbs = const [
    ProverbItem(
      firstPart: "proverb_1_start",
      firstPartRegional: "proverb_1_start",
      meaning: "proverb_1_meaning",
      correctEnding: "proverb_1_end",
      correctEndingRegional: "proverb_1_end",
      distractorEnding: "proverb_1_wrong",
      distractorEndingRegional: "proverb_1_wrong",
    ),
    ProverbItem(
      firstPart: "proverb_2_start",
      firstPartRegional: "proverb_2_start",
      meaning: "proverb_2_meaning",
      correctEnding: "proverb_2_end",
      correctEndingRegional: "proverb_2_end",
      distractorEnding: "proverb_2_wrong",
      distractorEndingRegional: "proverb_2_wrong",
    ),
    ProverbItem(
      firstPart: "proverb_3_start",
      firstPartRegional: "proverb_3_start",
      meaning: "proverb_3_meaning",
      correctEnding: "proverb_3_end",
      correctEndingRegional: "proverb_3_end",
      distractorEnding: "proverb_3_wrong",
      distractorEndingRegional: "proverb_3_wrong",
    ),
  ];

  int _currentIndex = 0;
  int? _selectedOption; // 0 = correct, 1 = distractor
  bool _isAnswered = false;
  DateTime? _startTime;
  int _correctCount = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  void _onOptionSelected(int optionIndex) {
    if (_isAnswered) return;

    if (optionIndex == 0) {
      _correctCount++;
    } else {
      _errorCount++;
    }

    setState(() {
      _selectedOption = optionIndex;
      _isAnswered = true;
    });

    final current = _proverbs[_currentIndex];
    final answer =
        '${context.tr(current.firstPartRegional)} ${context.tr(current.correctEndingRegional)}';
    RegionalTtsService().speak(
      optionIndex == 0
          ? '${context.tr('correct')} $answer'
          : context.tr('correct_answer', values: {'answer': answer}),
    );
  }

  void _nextProverb() {
    if (_currentIndex < _proverbs.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
    }
  }

  Future<void> _recordCompletionAndExit() async {
    final elapsed =
        DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    final score =
        ((_correctCount / (_proverbs.isNotEmpty ? _proverbs.length : 1)) *
                100.0)
            .clamp(35.0, 100.0);
    try {
      final metric = CognitiveMetric(
        gameType: 'PROVERBS_WORD_ASSOC',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        gridDimension: 2,
        totalMoves: _correctCount + _errorCount,
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
      debugPrint('Error saving proverbs metric: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: score.toInt(),
        biomarker: 'Language Recall: $_correctCount/${_proverbs.length} Proverbs Completed • ${elapsed}s',
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _currentIndex = 0;
            _selectedOption = null;
            _isAnswered = false;
            _correctCount = 0;
            _errorCount = 0;
            _startTime = DateTime.now();
          });
        },
        onBackToHub: () {
          Navigator.of(context).pop();
          widget.onBackToHub();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proverb = _proverbs[_currentIndex];
    final firstPart = context.tr(proverb.firstPart);

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
                  context.tr('proverbs'),
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
          children: [
            // Instructions Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DementiaColors.ochreBadgeBg,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: DementiaColors.ochreWarmAmber, width: 2),
              ),
              child: Text(
                context.tr('complete_saying'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: DementiaColors.ochreWarmAmber,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Proverb Incomplete Prompt Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DementiaColors.surfaceCardLight,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: DementiaColors.dividerColor, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.format_quote,
                      color: DementiaColors.actionForestGreen, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    firstPart,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: DementiaColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.tr('what_comes_next'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DementiaColors.actionForestGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Two Massive Single-Tap Choices (80dp height)
            _buildOptionButton(
              title: context.tr(proverb.correctEnding),
              optionIndex: 0,
              isCorrect: true,
            ),
            const SizedBox(height: 14),

            _buildOptionButton(
              title: context.tr(proverb.distractorEnding),
              optionIndex: 1,
              isCorrect: false,
            ),
            const SizedBox(height: 24),

            if (_isAnswered) ...[
              DementiaAccessibleButton(
                text: _currentIndex < _proverbs.length - 1
                    ? context.tr('next_saying')
                    : context.tr('completed'),
                icon: Icons.arrow_forward,
                backgroundColor: DementiaColors.actionForestGreen,
                contentColor: Colors.white,
                onClick: () {
                  if (_currentIndex < _proverbs.length - 1) {
                    _nextProverb();
                  } else {
                    _recordCompletionAndExit();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required int optionIndex,
    required bool isCorrect,
  }) {
    Color bg = DementiaColors.surfaceCardLight;
    Color border = DementiaColors.dividerColor;
    Color fg = DementiaColors.textPrimaryDark;

    if (_isAnswered) {
      if (isCorrect) {
        bg = DementiaColors.actionGreenLight;
        border = DementiaColors.actionForestGreen;
        fg = DementiaColors.actionForestGreen;
      } else if (_selectedOption == optionIndex) {
        bg = DementiaColors.alertTerracottaBg;
        border = DementiaColors.alertTerracotta;
        fg = DementiaColors.alertTerracotta;
      }
    }

    return AccessibleTouchWrapper(
      semanticLabel: title,
      onTap: () => _onOptionSelected(optionIndex),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 3),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: border,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _isAnswered && isCorrect ? Icons.check : Icons.touch_app,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: fg),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
