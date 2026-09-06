import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';
import 'package:dementia_ner_care/ui/widgets/game_celebration_dialog.dart';

class NERGameCard {
  final int id;
  final String key;
  final String title;
  final String regionalTitle;
  final IconData icon;
  final Color cardColor;
  bool isMatched;

  NERGameCard({
    required this.id,
    required this.key,
    required this.title,
    required this.regionalTitle,
    required this.icon,
    required this.cardColor,
    this.isMatched = false,
  });
}

/// Adaptive Memory Matching Game for North Eastern Region
class CognitiveGamesScreen extends StatefulWidget {
  final VoidCallback onBackToHome;

  const CognitiveGamesScreen({
    super.key,
    required this.onBackToHome,
  });

  @override
  State<CognitiveGamesScreen> createState() => _CognitiveGamesScreenState();
}

class _CognitiveGamesScreenState extends State<CognitiveGamesScreen> {
  late List<NERGameCard> _cards;
  List<int> _selectedIndices = [];
  int _matchedCount = 0;
  bool _gameWon = false;
  DateTime? _startTime;
  int _totalMoves = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _startTime = DateTime.now();
    _totalMoves = 0;
    _errorCount = 0;
    final base = [
      NERGameCard(
        id: 1,
        key: "GAMOSA",
        title: "card_gamosa",
        regionalTitle: "card_gamosa",
        icon: Icons.dry_cleaning,
        cardColor: DementiaColors.alertTerracotta,
      ),
      NERGameCard(
        id: 2,
        key: "XORAI",
        title: "object_xorai_name",
        regionalTitle: "object_xorai_name",
        icon: Icons.emoji_events,
        cardColor: DementiaColors.actionForestGreen,
      ),
      NERGameCard(
        id: 3,
        key: "DHOL",
        title: "object_dhol_name",
        regionalTitle: "object_dhol_name",
        icon: Icons.album,
        cardColor: DementiaColors.voiceAssistanceBlue,
      ),
      NERGameCard(
        id: 4,
        key: "JAPI",
        title: "card_japi",
        regionalTitle: "card_japi",
        icon: Icons.emoji_nature,
        cardColor: DementiaColors.ochreWarmAmber,
      ),
    ];
    final duplicated = [...base, ...base];
    duplicated.shuffle();
    _cards = duplicated;
    _selectedIndices = [];
    _matchedCount = 0;
    _gameWon = false;
  }

  void _onCardTap(int index) {
    if (_cards[index].isMatched || _selectedIndices.contains(index)) return;

    if (_selectedIndices.length == 2) {
      _selectedIndices = [index];
    } else {
      _selectedIndices.add(index);
      if (_selectedIndices.length == 2) {
        _totalMoves++;
        final first = _cards[_selectedIndices[0]];
        final second = _cards[_selectedIndices[1]];

        if (first.key == second.key) {
          first.isMatched = true;
          second.isMatched = true;
          _matchedCount++;
          if (_matchedCount >= _cards.length ~/ 2) {
            _gameWon = true;
            _recordGameCompletion();
          }
          _selectedIndices = [];
        } else {
          _errorCount++;
        }
      }
    }
    setState(() {});
  }

  Future<void> _recordGameCompletion() async {
    final elapsed =
        DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    final score = (100.0 - (_errorCount * 6) - (elapsed > 50 ? 10 : 0))
        .clamp(40.0, 100.0);
    try {
      final metric = CognitiveMetric(
        gameType: 'MEMORY_MATCH',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        gridDimension: 2,
        totalMoves: _totalMoves > 0 ? _totalMoves : 4,
        errorCount: _errorCount,
        completionTimeSeconds: elapsed > 0 ? elapsed : 25,
        tremorJitterScore: (_errorCount * 0.08).clamp(0.05, 0.8),
        calculatedScore: score,
        recommendedGridSize: 2,
        isSynced: false,
      );
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Error recording game metric: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: score.toInt(),
        biomarker: 'Working Memory: ${(100 - _errorCount * 8).clamp(50, 100)}% Match Efficiency • ${elapsed}s',
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _resetGame();
          });
        },
        onBackToHub: () {
          Navigator.of(context).pop();
          widget.onBackToHome();
        },
      ),
    );
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
                  onTap: widget.onBackToHome,
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
                  context.tr('memory_matching_title'),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
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
                context.tr('memory_matching_instruction'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DementiaColors.actionForestGreen,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Adaptive 2x2 Grid
            Expanded(
              child: GridView.builder(
                itemCount: _cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final isRevealed =
                      card.isMatched || _selectedIndices.contains(index);
                  final cardTitle = context.tr(card.title);
                  final regionalTitle = context.tr(card.regionalTitle);

                  return AccessibleTouchWrapper(
                    semanticLabel: isRevealed
                        ? "$cardTitle $regionalTitle"
                        : context.tr('hidden_card'),
                    onTap: () => _onCardTap(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isRevealed
                            ? card.cardColor
                            : DementiaColors.surfaceCardLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: card.isMatched
                              ? DementiaColors.actionForestGreen
                              : DementiaColors.dividerColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: isRevealed
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(card.icon,
                                      color: Colors.white, size: 52),
                                  const SizedBox(height: 6),
                                  Text(
                                    "$cardTitle ($regionalTitle)",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(
                                Icons.question_mark,
                                color: DementiaColors.textSecondaryDark,
                                size: 44,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_gameWon) ...[
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: DementiaColors.actionForestGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.white, size: 36),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('well_done'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                context.tr('take_your_time'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: DementiaColors.textSecondaryDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
