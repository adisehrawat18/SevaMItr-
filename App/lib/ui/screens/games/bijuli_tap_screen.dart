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

enum BijuliPhase {
  intro,
  waiting,
  stimulus,
  feedback,
  falseStart,
  complete,
}

enum StimulusType {
  go,
  noGo,
}

class BijuliTapScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const BijuliTapScreen({super.key, required this.onBackToHub});

  @override
  State<BijuliTapScreen> createState() => _BijuliTapScreenState();
}

class _BijuliTapScreenState extends State<BijuliTapScreen> {
  static const int _totalTrials = 5;
  int _currentTrial = 1;
  BijuliPhase _phase = BijuliPhase.intro;
  StimulusType _stimulusType = StimulusType.go;

  int? _lastReactionMs;
  String _feedbackMessage = '';
  int _falseStarts = 0;
  final List<int> _reactionTimes = [];
  final DateTime _sessionStart = DateTime.now();

  Timer? _waitTimer;
  Timer? _noGoTimer;
  int _stimulusStartTime = 0;

  @override
  void dispose() {
    _waitTimer?.cancel();
    _noGoTimer?.cancel();
    super.dispose();
  }

  void _startTrial(int trialNum) {
    _waitTimer?.cancel();
    _noGoTimer?.cancel();

    setState(() {
      _phase = BijuliPhase.waiting;
      _lastReactionMs = null;
      _feedbackMessage = '';
      // Trial 4 is the No-Go test
      _stimulusType = (trialNum == 4) ? StimulusType.noGo : StimulusType.go;
    });

    // Unpredictable jitter interval between 1500ms and 3200ms
    final jitterMs = 1500 + math.Random().nextInt(1700);
    _waitTimer = Timer(Duration(milliseconds: jitterMs), () {
      if (!mounted) return;
      _stimulusStartTime = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _phase = BijuliPhase.stimulus;
      });

      if (_stimulusType == StimulusType.noGo) {
        SynthesizedAudioService.instance.playGentleError();
        // If user withholds for 1600ms, award successful inhibition!
        _noGoTimer = Timer(const Duration(milliseconds: 1600), () {
          _handleNoGoSuccess(trialNum);
        });
      } else {
        SynthesizedAudioService.instance.playSuccessChime();
      }
    });
  }

  void _handleNoGoSuccess(int trialNum) {
    if (!mounted) return;
    SynthesizedAudioService.instance.playSuccessChime();
    setState(() {
      _phase = BijuliPhase.feedback;
      _feedbackMessage = 'Great Restraint! No-Go Passed';
      _lastReactionMs = null;
    });

    Timer(const Duration(milliseconds: 1300), () {
      _advanceTrial(trialNum);
    });
  }

  void _handlePadTap() {
    switch (_phase) {
      case BijuliPhase.intro:
        _startTrial(1);
        break;

      case BijuliPhase.waiting:
        // False Start: Tapped while waiting
        _waitTimer?.cancel();
        _falseStarts++;
        SynthesizedAudioService.instance.playGentleError();
        setState(() {
          _phase = BijuliPhase.falseStart;
          _feedbackMessage = 'Wait for the signal!';
        });

        Timer(const Duration(milliseconds: 1200), () {
          if (mounted) _startTrial(_currentTrial);
        });
        break;

      case BijuliPhase.stimulus:
        final now = DateTime.now().millisecondsSinceEpoch;
        final rt = now - _stimulusStartTime;

        if (_stimulusType == StimulusType.noGo) {
          // Commission Error: Tapped on Red Distractor!
          _noGoTimer?.cancel();
          SynthesizedAudioService.instance.playGentleError();
          setState(() {
            _phase = BijuliPhase.feedback;
            _feedbackMessage = 'Avoid tapping on Red Gong!';
            _lastReactionMs = null;
          });

          Timer(const Duration(milliseconds: 1500), () {
            _advanceTrial(_currentTrial);
          });
          return;
        }

        // Valid GO Reaction!
        _reactionTimes.add(rt);
        SynthesizedAudioService.instance.playStepTick();

        String msg = 'Sharp & Focused!';
        if (rt < 260) {
          msg = '⚡ Lightning Fast!';
        } else if (rt < 380) {
          msg = 'Excellent Reflex!';
        } else {
          msg = 'Good Response!';
        }

        setState(() {
          _phase = BijuliPhase.feedback;
          _lastReactionMs = rt;
          _feedbackMessage = msg;
        });

        Timer(const Duration(milliseconds: 1300), () {
          _advanceTrial(_currentTrial);
        });
        break;

      case BijuliPhase.feedback:
      case BijuliPhase.falseStart:
      case BijuliPhase.complete:
        break;
    }
  }

  void _advanceTrial(int completedTrial) {
    if (!mounted) return;
    if (completedTrial >= _totalTrials) {
      _finishGame();
    } else {
      setState(() {
        _currentTrial = completedTrial + 1;
      });
      _startTrial(_currentTrial);
    }
  }

  Future<void> _finishGame() async {
    setState(() {
      _phase = BijuliPhase.complete;
    });

    final avgRt = _reactionTimes.isNotEmpty
        ? (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length).round()
        : 350;

    // Grading algorithm matching SevaMitr Clinical Grading Engine
    int rtScore = 65;
    if (avgRt > 250) {
      rtScore = math.max(15, 65 - ((avgRt - 250) / 8).round());
    }
    final accuracyScore = math.max(0, 35 - _falseStarts * 10);
    final finalScore = (rtScore + accuracyScore).clamp(0, 100);
    final biomarker = 'Mean Reaction: ${avgRt}ms';

    // Record session into SQLite
    final elapsedSec = DateTime.now().difference(_sessionStart).inSeconds;
    final metric = CognitiveMetric(
      gameType: 'BIJULI_TAP',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      gridDimension: 1,
      totalMoves: _reactionTimes.length + _falseStarts,
      errorCount: _falseStarts,
      completionTimeSeconds: elapsedSec > 0 ? elapsedSec : 25,
      tremorJitterScore: (_falseStarts * 0.15).clamp(0.05, 0.9),
      calculatedScore: finalScore.toDouble(),
      recommendedGridSize: 1,
      isSynced: false,
    );

    try {
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Bijuli metric save warning: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: finalScore,
        biomarker: biomarker,
        customTitle: 'Bijuli Speed Trial Complete!',
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _currentTrial = 1;
            _falseStarts = 0;
            _reactionTimes.clear();
          });
          _startTrial(1);
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
                    'Bijuli Tap (Reaction Speed)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DementiaColors.amberMuga,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'Trial $_currentTrial/$_totalTrials',
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
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top Instruction Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                      ),
                      child: const Icon(Icons.bolt, color: Color(0xFFB45309), size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tap fast when lightning appears! Withhold tap if red gong shows.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DementiaColors.textMainCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Central Tap Pad Area
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTapDown: (_) => _handlePadTap(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getPadColor(),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: DementiaColors.borderCharcoal,
                            offset: _phase == BijuliPhase.stimulus ? const Offset(2, 2) : const Offset(6, 6),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _buildPadContent(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Status & Telemetry
              if (_lastReactionMs != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF15803D), width: 1.5),
                  ),
                  child: Text(
                    '$_lastReactionMs ms',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPadColor() {
    switch (_phase) {
      case BijuliPhase.intro:
        return const Color(0xFFE0F2FE);
      case BijuliPhase.waiting:
        return const Color(0xFFFEF9C3);
      case BijuliPhase.stimulus:
        return _stimulusType == StimulusType.go ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
      case BijuliPhase.feedback:
        return const Color(0xFFDCFCE7);
      case BijuliPhase.falseStart:
        return const Color(0xFFFEE2E2);
      case BijuliPhase.complete:
        return DementiaColors.pureSurfaceWhite;
    }
  }

  Widget _buildPadContent() {
    switch (_phase) {
      case BijuliPhase.intro:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 56, color: DementiaColors.borderCharcoal),
            SizedBox(height: 8),
            Text(
              'TAP TO START',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: DementiaColors.borderCharcoal),
            ),
          ],
        );

      case BijuliPhase.waiting:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Color(0xFFA16207)),
            SizedBox(height: 8),
            Text(
              'WAIT FOR SIGNAL...',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFFA16207)),
            ),
          ],
        );

      case BijuliPhase.stimulus:
        if (_stimulusType == StimulusType.go) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, size: 84, color: Color(0xFF15803D)),
              SizedBox(height: 4),
              Text(
                'TAP NOW!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF15803D)),
              ),
            ],
          );
        } else {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off, size: 76, color: Color(0xFF991B1B)),
              SizedBox(height: 4),
              Text(
                'HOLD! DO NOT TAP',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF991B1B)),
              ),
            ],
          );
        }

      case BijuliPhase.feedback:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 54, color: Color(0xFF15803D)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _feedbackMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF15803D)),
              ),
            ),
          ],
        );

      case BijuliPhase.falseStart:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 54, color: Color(0xFF991B1B)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _feedbackMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        );

      case BijuliPhase.complete:
        return const Icon(Icons.celebration, size: 54, color: DementiaColors.borderCharcoal);
    }
  }
}
