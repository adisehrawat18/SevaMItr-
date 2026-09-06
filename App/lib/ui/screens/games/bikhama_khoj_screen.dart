import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/core/audio/synthesized_audio_service.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';
import 'package:dementia_ner_care/ui/widgets/game_celebration_dialog.dart';

class BikhamaRound {
  final int gridSize; // 3 = 3x3 (9 items), 4 = 4x4 (16 items)
  final String title;
  final String distractorEmoji;
  final String targetEmoji;
  final bool isOrientationFlip;

  const BikhamaRound({
    required this.gridSize,
    required this.title,
    required this.distractorEmoji,
    required this.targetEmoji,
    this.isOrientationFlip = false,
  });
}

class BikhamaKhojScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const BikhamaKhojScreen({super.key, required this.onBackToHub});

  @override
  State<BikhamaKhojScreen> createState() => _BikhamaKhojScreenState();
}

class _BikhamaKhojScreenState extends State<BikhamaKhojScreen> {
  static const List<BikhamaRound> _allRounds = [
    BikhamaRound(
      gridSize: 3,
      title: 'Assam Tea Garden',
      distractorEmoji: '🍵',
      targetEmoji: '🫖',
    ),
    BikhamaRound(
      gridSize: 3,
      title: 'Brahmaputra Fish',
      distractorEmoji: '🐟',
      targetEmoji: '🐠',
      isOrientationFlip: true,
    ),
    BikhamaRound(
      gridSize: 4,
      title: 'Monsoon Flora',
      distractorEmoji: '🪷',
      targetEmoji: '🌻',
    ),
    BikhamaRound(
      gridSize: 4,
      title: 'Bihu Folk Rhythm',
      distractorEmoji: '🥁',
      targetEmoji: '🪈',
    ),
    BikhamaRound(
      gridSize: 4,
      title: 'Forest Foliage',
      distractorEmoji: '🍃',
      targetEmoji: '🍂',
    ),
  ];

  int _currentRoundIdx = 0;
  int _targetCellIdx = 0;
  int? _tappedWrongCell;
  bool _isHintActive = false;
  int _distractorTaps = 0;
  final List<int> _latenciesMs = [];
  int _roundStartTime = 0;
  final DateTime _sessionStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _setupRound(0);
  }

  void _setupRound(int roundIdx) {
    final round = _allRounds[roundIdx];
    final totalCells = round.gridSize * round.gridSize;
    _targetCellIdx = math.Random().nextInt(totalCells);
    _tappedWrongCell = null;
    _isHintActive = false;
    _roundStartTime = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _currentRoundIdx = roundIdx;
    });
  }

  void _handleCellTap(int cellIdx) {
    if (cellIdx == _targetCellIdx) {
      // Correct target tap!
      final now = DateTime.now().millisecondsSinceEpoch;
      final latency = now - _roundStartTime;
      _latenciesMs.add(latency);
      SynthesizedAudioService.instance.playSuccessChime();

      if (_currentRoundIdx + 1 < _allRounds.length) {
        Timer(const Duration(milliseconds: 600), () {
          if (mounted) _setupRound(_currentRoundIdx + 1);
        });
      } else {
        _finishGame();
      }
    } else {
      // Wrong distractor tap
      _distractorTaps++;
      SynthesizedAudioService.instance.playGentleError();
      setState(() {
        _tappedWrongCell = cellIdx;
      });
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _tappedWrongCell = null);
      });
    }
  }

  void _triggerHint() {
    SynthesizedAudioService.instance.playStepTick();
    setState(() {
      _isHintActive = true;
    });
  }

  Future<void> _finishGame() async {
    final avgLatency = _latenciesMs.isNotEmpty
        ? (_latenciesMs.reduce((a, b) => a + b) / _latenciesMs.length).round()
        : 950;

    // Clinical scoring matching SevaMitr grading engine
    const accuracyPts = 70; // 5/5 rounds completed
    int speedBonus = 10;
    if (avgLatency <= 700) {
      speedBonus = 30;
    } else if (avgLatency <= 1100) {
      speedBonus = 22;
    } else if (avgLatency <= 1600) {
      speedBonus = 15;
    }

    final penalty = _distractorTaps * 4;
    final finalScore = (accuracyPts + speedBonus - penalty).clamp(0, 100);
    final biomarker = 'Visual Search: ${avgLatency}ms';

    final elapsedSec = DateTime.now().difference(_sessionStart).inSeconds;
    final metric = CognitiveMetric(
      gameType: 'BIKHAMA_KHOJ',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      gridDimension: _allRounds[_currentRoundIdx].gridSize,
      totalMoves: _allRounds.length + _distractorTaps,
      errorCount: _distractorTaps,
      completionTimeSeconds: elapsedSec > 0 ? elapsedSec : 30,
      tremorJitterScore: (_distractorTaps * 0.12).clamp(0.05, 0.9),
      calculatedScore: finalScore.toDouble(),
      recommendedGridSize: 3,
      isSynced: false,
    );

    try {
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Bikhama metric save warning: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: finalScore,
        biomarker: biomarker,
        customTitle: 'Bikhama Khoj Complete!',
        onPlayAgain: () {
          Navigator.of(context).pop();
          _distractorTaps = 0;
          _latenciesMs.clear();
          _setupRound(0);
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
    final round = _allRounds[_currentRoundIdx];
    final totalCells = round.gridSize * round.gridSize;

    return Scaffold(
      backgroundColor: DementiaColors.paleSageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          color: DementiaColors.borderCharcoal,
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
                      color: DementiaColors.pureSurfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: DementiaColors.borderCharcoal, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Bikhama Khoj (Visual Search)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DementiaColors.skyGlacier,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'Round ${_currentRoundIdx + 1}/${_allRounds.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DementiaColors.borderCharcoal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Instruction Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: DementiaColors.pureSurfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                  boxShadow: const [
                    BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: DementiaColors.skyGlacier,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                      ),
                      child: const Icon(Icons.remove_red_eye, color: DementiaColors.skyGlacierDark, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            round.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DementiaColors.textDimStone),
                          ),
                          Text(
                            'Find the unique ${round.targetEmoji} among the ${round.distractorEmoji}!',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DementiaColors.textMainCharcoal),
                          ),
                        ],
                      ),
                    ),
                    // Hint Button
                    IconButton(
                      icon: Icon(Icons.lightbulb, color: _isHintActive ? const Color(0xFFEAB308) : Colors.grey, size: 28),
                      onPressed: _triggerHint,
                      tooltip: 'Show Hint',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Visual Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DementiaColors.pureSurfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(4, 4), blurRadius: 0),
                        ],
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: round.gridSize,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: totalCells,
                        itemBuilder: (context, idx) {
                          final isTarget = idx == _targetCellIdx;
                          final isWrong = idx == _tappedWrongCell;
                          final isHighlightedByHint = isTarget && _isHintActive;

                          Color bgColor = DementiaColors.inputBg;
                          Color borderColor = DementiaColors.borderCharcoal;
                          if (isWrong) {
                            bgColor = const Color(0xFFFEE2E2);
                            borderColor = const Color(0xFFDC2626);
                          } else if (isHighlightedByHint) {
                            bgColor = const Color(0xFFFEF9C3);
                            borderColor = const Color(0xFFEAB308);
                          }

                          return GestureDetector(
                            onTap: () => _handleCellTap(idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor, width: isHighlightedByHint ? 3 : 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: borderColor,
                                    offset: isHighlightedByHint ? const Offset(1, 1) : const Offset(3, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.diagonal3Values(
                                  isTarget && round.isOrientationFlip ? -1.0 : 1.0,
                                  1.0,
                                  1.0,
                                ),
                                child: Text(
                                  isTarget ? round.targetEmoji : round.distractorEmoji,
                                  style: TextStyle(fontSize: round.gridSize == 3 ? 38 : 28),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
