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

enum DdPhase {
  ready,
  flashing,
  mask,
  centerInput,
  peripheralInput,
  feedback,
  complete,
}

class CenterPair {
  final String itemA;
  final String nameA;
  final String itemB;
  final String nameB;

  const CenterPair({
    required this.itemA,
    required this.nameA,
    required this.itemB,
    required this.nameB,
  });
}

class DoubleDecisionScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const DoubleDecisionScreen({super.key, required this.onBackToHub});

  @override
  State<DoubleDecisionScreen> createState() => _DoubleDecisionScreenState();
}

class _DoubleDecisionScreenState extends State<DoubleDecisionScreen> {
  static const int _totalTrials = 5;
  static const List<double> _radialAngles = [0, 45, 90, 135, 180, 225, 270, 315];

  static const List<CenterPair> _pairs = [
    CenterPair(itemA: '🚗', nameA: 'Car', itemB: '🛺', nameB: 'Auto'),
    CenterPair(itemA: '🍃', nameA: 'Leaf', itemB: '🪷', nameB: 'Lotus'),
    CenterPair(itemA: '🛶', nameA: 'Boat', itemB: '🚲', nameB: 'Bicycle'),
    CenterPair(itemA: '🏮', nameA: 'Lantern', itemB: '🪔', nameB: 'Diya'),
    CenterPair(itemA: '🍎', nameA: 'Apple', itemB: '🥭', nameB: 'Mango'),
  ];

  int _currentTrial = 1;
  int _exposureMs = 450;
  DdPhase _phase = DdPhase.ready;

  int _pairIdx = 0;
  bool _showItemA = true;
  int _targetAngleIdx = 0;

  bool? _centerCorrect;
  bool? _angleCorrect;
  int _correctTrials = 0;
  final List<int> _thresholdsAchieved = [];
  final DateTime _sessionStart = DateTime.now();

  Timer? _flashTimer;
  Timer? _maskTimer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    _maskTimer?.cancel();
    super.dispose();
  }

  void _launchTrial() {
    _pairIdx = math.Random().nextInt(_pairs.length);
    _showItemA = math.Random().nextBool();
    _targetAngleIdx = math.Random().nextInt(_radialAngles.length);
    _centerCorrect = null;
    _angleCorrect = null;

    SynthesizedAudioService.instance.playStepTick();

    setState(() {
      _phase = DdPhase.flashing;
    });

    _flashTimer = Timer(Duration(milliseconds: _exposureMs), () {
      if (!mounted) return;
      setState(() {
        _phase = DdPhase.mask;
      });

      _maskTimer = Timer(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        setState(() {
          _phase = DdPhase.centerInput;
        });
      });
    });
  }

  void _handleCenterChoice(bool pickedItemA) {
    final isCorrect = pickedItemA == _showItemA;
    _centerCorrect = isCorrect;
    SynthesizedAudioService.instance.playStepTick();

    setState(() {
      _phase = DdPhase.peripheralInput;
    });
  }

  void _handleAngleChoice(int angleIdx) {
    final isCorrect = angleIdx == _targetAngleIdx;
    _angleCorrect = isCorrect;

    final trialSuccess = (_centerCorrect == true) && (_angleCorrect == true);

    if (trialSuccess) {
      _correctTrials++;
      _thresholdsAchieved.add(_exposureMs);
      SynthesizedAudioService.instance.playSuccessChime();
      // Adaptive staircase: decrease exposure (faster)
      _exposureMs = math.max(120, (_exposureMs * 0.78).round());
    } else {
      SynthesizedAudioService.instance.playGentleError();
      // Increase exposure (more time to see)
      _exposureMs = math.min(500, (_exposureMs * 1.22).round());
    }

    setState(() {
      _phase = DdPhase.feedback;
    });

    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_currentTrial >= _totalTrials) {
        _finishGame();
      } else {
        setState(() {
          _currentTrial++;
          _phase = DdPhase.ready;
        });
      }
    });
  }

  Future<void> _finishGame() async {
    setState(() {
      _phase = DdPhase.complete;
    });

    final bestThreshold = _thresholdsAchieved.isNotEmpty
        ? _thresholdsAchieved.reduce(math.min)
        : _exposureMs;

    // SevaMitr Clinical Scoring for Double Decision
    final accuracyPct = (_correctTrials / _totalTrials) * 70;
    int speedBonus = 10;
    if (bestThreshold <= 120) {
      speedBonus = 30;
    } else if (bestThreshold <= 200) {
      speedBonus = 25;
    } else if (bestThreshold <= 350) {
      speedBonus = 20;
    } else if (bestThreshold <= 450) {
      speedBonus = 15;
    }

    final finalScore = (accuracyPct + speedBonus).round().clamp(0, 100);
    final biomarker = 'UFOV Threshold: ${bestThreshold}ms';

    final elapsedSec = DateTime.now().difference(_sessionStart).inSeconds;
    final metric = CognitiveMetric(
      gameType: 'DOUBLE_DECISION',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      gridDimension: 2,
      totalMoves: _totalTrials * 2,
      errorCount: _totalTrials - _correctTrials,
      completionTimeSeconds: elapsedSec > 0 ? elapsedSec : 35,
      tremorJitterScore: ((bestThreshold / 500) * 0.4).clamp(0.05, 0.8),
      calculatedScore: finalScore.toDouble(),
      recommendedGridSize: 2,
      isSynced: false,
    );

    try {
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Double decision metric save warning: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: finalScore,
        biomarker: biomarker,
        customTitle: 'Sight Speed UFOV Complete!',
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _currentTrial = 1;
            _exposureMs = 450;
            _correctTrials = 0;
            _thresholdsAchieved.clear();
            _phase = DdPhase.ready;
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
                    'Sight Speed (UFOV Dual-Task)',
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
                    '$_exposureMs ms',
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
              // Top Step & Instruction
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
                        color: DementiaColors.primaryMintSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                      ),
                      child: const Icon(Icons.flash_on, color: DementiaColors.primaryKazirangaForest, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getInstructionText(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DementiaColors.textMainCharcoal),
                      ),
                    ),
                    Text(
                      'Trial $_currentTrial/$_totalTrials',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DementiaColors.textDimStone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Interactive Dual-Task Arena
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DementiaColors.pureSurfaceWhite,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(4, 4), blurRadius: 0),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 8 Peripheral Radial Positions
                          ...List.generate(_radialAngles.length, (idx) {
                            final angleDeg = _radialAngles[idx];
                            final angleRad = angleDeg * (math.pi / 180);
                            const radius = 115.0;
                            final x = radius * math.cos(angleRad);
                            final y = radius * math.sin(angleRad);

                            final isTargetAngle = idx == _targetAngleIdx;
                            final isFlashing = _phase == DdPhase.flashing;
                            final isPeripheralInput = _phase == DdPhase.peripheralInput;

                            return Transform.translate(
                              offset: Offset(x, y),
                              child: GestureDetector(
                                onTap: isPeripheralInput ? () => _handleAngleChoice(idx) : null,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isFlashing && isTargetAngle)
                                        ? const Color(0xFFFEF08A)
                                        : (isPeripheralInput ? DementiaColors.paleSageBg : Colors.transparent),
                                    border: Border.all(
                                      color: isPeripheralInput ? DementiaColors.borderCharcoal : Colors.grey.shade300,
                                      width: isPeripheralInput ? 2 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isFlashing && isTargetAngle
                                      ? const Text('⭐', style: TextStyle(fontSize: 22))
                                      : (isPeripheralInput
                                          ? const Icon(Icons.touch_app, size: 20, color: DementiaColors.textMutedSlate)
                                          : null),
                                ),
                              ),
                            );
                          }),

                          // Center Target Area
                          _buildCenterContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Control Area
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_phase) {
      case DdPhase.ready:
        return 'Watch center symbol AND peripheral star!';
      case DdPhase.flashing:
        return 'Memorize both items!';
      case DdPhase.mask:
        return 'Processing...';
      case DdPhase.centerInput:
        return 'Step 1: Which symbol appeared in the center?';
      case DdPhase.peripheralInput:
        return 'Step 2: Tap the circle where the star flashed!';
      case DdPhase.feedback:
        return (_centerCorrect == true && _angleCorrect == true)
            ? 'Correct! Sharp attention!'
            : 'Close try! Adjusting speed...';
      case DdPhase.complete:
        return 'Speed Trial Finished!';
    }
  }

  Widget _buildCenterContent() {
    final pair = _pairs[_pairIdx];

    switch (_phase) {
      case DdPhase.ready:
        return GestureDetector(
          onTap: _launchTrial,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: DementiaColors.primaryKazirangaForest,
              shape: BoxShape.circle,
              border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 36),
                Text('READY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        );

      case DdPhase.flashing:
        return Text(
          _showItemA ? pair.itemA : pair.itemB,
          style: const TextStyle(fontSize: 54),
        );

      case DdPhase.mask:
        return Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1C1B1B),
          ),
          alignment: Alignment.center,
          child: const Text('▦', style: TextStyle(color: Colors.white, fontSize: 40)),
        );

      case DdPhase.centerInput:
      case DdPhase.peripheralInput:
      case DdPhase.feedback:
      case DdPhase.complete:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DementiaColors.paleSageBg,
            border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.adjust, size: 16, color: DementiaColors.borderCharcoal),
        );
    }
  }

  Widget _buildBottomControls() {
    if (_phase == DdPhase.centerInput) {
      final pair = _pairs[_pairIdx];
      return Row(
        children: [
          Expanded(
            child: AccessibleTouchWrapper(
              semanticLabel: pair.nameA,
              onTap: () => _handleCenterChoice(true),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: DementiaColors.pureSurfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                  boxShadow: const [
                    BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(pair.itemA, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(pair.nameA, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AccessibleTouchWrapper(
              semanticLabel: pair.nameB,
              onTap: () => _handleCenterChoice(false),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: DementiaColors.pureSurfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                  boxShadow: const [
                    BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(3, 3), blurRadius: 0),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(pair.itemB, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(pair.nameB, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_phase == DdPhase.ready) {
      return AccessibleTouchWrapper(
        semanticLabel: 'Launch Flash Trial',
        onTap: _launchTrial,
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
              Text(
                'START TRIAL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox(height: 54);
  }
}
