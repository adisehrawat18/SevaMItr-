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

enum TrackerPhase {
  ready,
  highlightTargets,
  tracking,
  selecting,
  feedback,
  complete,
}

class TrackingOrb {
  final int id;
  double x;
  double y;
  double vx;
  double vy;
  final bool isTarget;
  final String emoji;

  TrackingOrb({
    required this.id,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.isTarget,
    required this.emoji,
  });
}

class TargetTrackerScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const TargetTrackerScreen({super.key, required this.onBackToHub});

  @override
  State<TargetTrackerScreen> createState() => _TargetTrackerScreenState();
}

class _TargetTrackerScreenState extends State<TargetTrackerScreen> with SingleTickerProviderStateMixin {
  static const int _maxRounds = 4;
  static const double _orbRadius = 26.0;

  int _round = 1;
  TrackerPhase _phase = TrackerPhase.ready;
  List<TrackingOrb> _orbs = [];
  final Set<int> _selectedIds = {};

  int _correctRounds = 0;
  final DateTime _sessionStart = DateTime.now();
  Timer? _highlightTimer;
  Timer? _motionTimer;
  DateTime? _trackingStartTime;

  static const List<String> _emojiPool = ['🌺', '🌾', '🥭', '🏮', '🦏', '🐟'];

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _motionTimer?.cancel();
    super.dispose();
  }

  void _setupRound() {
    _highlightTimer?.cancel();
    _motionTimer?.cancel();
    _selectedIds.clear();

    // Pick 2 target indices
    final indices = [0, 1, 2, 3, 4, 5]..shuffle();
    final targetSet = {indices[0], indices[1]};

    final newOrbs = <TrackingOrb>[];
    for (int i = 0; i < 6; i++) {
      final col = i % 3;
      final row = i ~/ 3;
      final startX = 45.0 + col * 95.0;
      final startY = 45.0 + row * 110.0;

      final angle = math.Random().nextDouble() * 2 * math.pi;
      final speed = 1.4 + (_round - 1) * 0.25;

      newOrbs.add(TrackingOrb(
        id: i,
        x: startX,
        y: startY,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        isTarget: targetSet.contains(i),
        emoji: _emojiPool[i % _emojiPool.length],
      ));
    }

    setState(() {
      _orbs = newOrbs;
      _phase = TrackerPhase.ready;
    });
  }

  void _startSequence() {
    SynthesizedAudioService.instance.playStepTick();
    setState(() {
      _phase = TrackerPhase.highlightTargets;
    });

    // Highlight for 2.2 seconds
    _highlightTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _phase = TrackerPhase.tracking;
      });

      _trackingStartTime = DateTime.now();

      // Motion timer running at ~30 FPS for 4.2 seconds
      _motionTimer = Timer.periodic(const Duration(milliseconds: 32), (t) {
        if (!mounted) return;
        final elapsed = DateTime.now().difference(_trackingStartTime!).inMilliseconds;
        if (elapsed >= 4200) {
          t.cancel();
          SynthesizedAudioService.instance.playStepTick();
          setState(() {
            _phase = TrackerPhase.selecting;
          });
          return;
        }

        const arenaW = 290.0;
        const arenaH = 260.0;

        for (final orb in _orbs) {
          orb.x += orb.vx * 1.5;
          orb.y += orb.vy * 1.5;

          if (orb.x <= _orbRadius) {
            orb.x = _orbRadius;
            orb.vx = -orb.vx;
          } else if (orb.x >= arenaW - _orbRadius) {
            orb.x = arenaW - _orbRadius;
            orb.vx = -orb.vx;
          }

          if (orb.y <= _orbRadius) {
            orb.y = _orbRadius;
            orb.vy = -orb.vy;
          } else if (orb.y >= arenaH - _orbRadius) {
            orb.y = arenaH - _orbRadius;
            orb.vy = -orb.vy;
          }
        }
        setState(() {});
      });
    });
  }

  void _handleOrbTap(int orbId) {
    if (_phase != TrackerPhase.selecting) return;
    if (_selectedIds.contains(orbId)) return;

    SynthesizedAudioService.instance.playStepTick();
    setState(() {
      _selectedIds.add(orbId);
    });

    // When 2 orbs selected, evaluate
    if (_selectedIds.length == 2) {
      _evaluateRound();
    }
  }

  void _evaluateRound() {
    final targets = _orbs.where((o) => o.isTarget).map((o) => o.id).toSet();
    final bothCorrect = _selectedIds.containsAll(targets);

    if (bothCorrect) {
      _correctRounds++;
      SynthesizedAudioService.instance.playSuccessChime();
    } else {
      SynthesizedAudioService.instance.playGentleError();
    }

    setState(() {
      _phase = TrackerPhase.feedback;
    });

    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_round >= _maxRounds) {
        _finishGame();
      } else {
        setState(() {
          _round++;
        });
        _setupRound();
      }
    });
  }

  Future<void> _finishGame() async {
    setState(() {
      _phase = TrackerPhase.complete;
    });

    final elapsedSec = DateTime.now().difference(_sessionStart).inSeconds;

    // SevaMitr Clinical Scoring for Target Tracker
    final accuracyPct = (_correctRounds / _maxRounds) * 80;
    final paceBonus = elapsedSec <= 35 ? 20 : (elapsedSec <= 50 ? 15 : 10);
    final finalScore = (accuracyPct + paceBonus).round().clamp(0, 100);
    final accuracy = ((_correctRounds / _maxRounds) * 100).round();
    final biomarker = 'Tracking Accuracy: $accuracy%';

    final metric = CognitiveMetric(
      gameType: 'TARGET_TRACKER',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      gridDimension: 2,
      totalMoves: _maxRounds * 2,
      errorCount: _maxRounds - _correctRounds,
      completionTimeSeconds: elapsedSec > 0 ? elapsedSec : 35,
      tremorJitterScore: ((1.0 - (_correctRounds / _maxRounds)) * 0.6).clamp(0.05, 0.8),
      calculatedScore: finalScore.toDouble(),
      recommendedGridSize: 2,
      isSynced: false,
    );

    try {
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Target tracker metric save warning: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: finalScore,
        biomarker: biomarker,
        customTitle: 'Target Tracker Complete!',
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _round = 1;
            _correctRounds = 0;
          });
          _setupRound();
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
                    'Target Tracker (Attention)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DementiaColors.terracotta,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'Round $_round/$_maxRounds',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
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
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                      ),
                      child: const Icon(Icons.gps_fixed, color: Color(0xFFC85A32), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getInstructionText(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DementiaColors.textMainCharcoal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bouncing Orbs Motion Arena
              Expanded(
                child: Center(
                  child: Container(
                    width: 310,
                    height: 280,
                    decoration: BoxDecoration(
                      color: DementiaColors.pureSurfaceWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: DementiaColors.borderCharcoal, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(4, 4), blurRadius: 0),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Stack(
                        children: _orbs.map((orb) {
                          final isTarget = orb.isTarget;
                          final isHighlight = _phase == TrackerPhase.highlightTargets && isTarget;
                          final isSelected = _selectedIds.contains(orb.id);
                          final isFeedback = _phase == TrackerPhase.feedback;

                          Color ringColor = Colors.transparent;
                          if (isHighlight) {
                            ringColor = const Color(0xFFEAB308);
                          } else if (isSelected) {
                            if (isFeedback) {
                              ringColor = isTarget ? const Color(0xFF15803D) : const Color(0xFFDC2626);
                            } else {
                              ringColor = DementiaColors.primaryKazirangaForest;
                            }
                          } else if (isFeedback && isTarget) {
                            ringColor = const Color(0xFF15803D);
                          }

                          return Positioned(
                            left: orb.x - _orbRadius,
                            top: orb.y - _orbRadius,
                            child: GestureDetector(
                              onTap: () => _handleOrbTap(orb.id),
                              child: Container(
                                width: _orbRadius * 2,
                                height: _orbRadius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DementiaColors.paleSageBg,
                                  border: Border.all(
                                    color: ringColor != Colors.transparent ? ringColor : DementiaColors.borderCharcoal,
                                    width: (isHighlight || isSelected || isFeedback) ? 3.5 : 1.5,
                                  ),
                                  boxShadow: isHighlight
                                      ? [
                                          const BoxShadow(color: Color(0xFFEAB308), blurRadius: 8, spreadRadius: 2),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(orb.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Action Button
              if (_phase == TrackerPhase.ready)
                AccessibleTouchWrapper(
                  semanticLabel: 'Start Tracking',
                  onTap: _startSequence,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: DementiaColors.primaryKazirangaForest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                      boxShadow: const [
                        BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(3, 3), blurRadius: 0),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text('START TRACKING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: 54),
            ],
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_phase) {
      case TrackerPhase.ready:
        return 'Watch closely: 2 target orbs will be highlighted.';
      case TrackerPhase.highlightTargets:
        return 'Remember these 2 glowing target orbs!';
      case TrackerPhase.tracking:
        return 'Keep your eyes on the moving targets!';
      case TrackerPhase.selecting:
        return 'Tap the 2 original target orbs you tracked!';
      case TrackerPhase.feedback:
        return _selectedIds.length == 2 && _orbs.where((o) => o.isTarget).every((o) => _selectedIds.contains(o.id))
            ? 'Great tracking! Both targets identified!'
            : 'Reviewing positions... Next round starting.';
      case TrackerPhase.complete:
        return 'Target Tracker completed!';
    }
  }
}
