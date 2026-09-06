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

class SweepPatternDef {
  final String id;
  final bool s1Up;
  final bool s2Up;
  final String label;

  const SweepPatternDef({
    required this.id,
    required this.s1Up,
    required this.s2Up,
    required this.label,
  });
}

class SoundSweepsScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const SoundSweepsScreen({super.key, required this.onBackToHub});

  @override
  State<SoundSweepsScreen> createState() => _SoundSweepsScreenState();
}

class _SoundSweepsScreenState extends State<SoundSweepsScreen> with SingleTickerProviderStateMixin {
  static const int _totalTrials = 5;
  static const List<SweepPatternDef> _patterns = [
    SweepPatternDef(id: 'up_up', s1Up: true, s2Up: true, label: 'Up • Up'),
    SweepPatternDef(id: 'up_down', s1Up: true, s2Up: false, label: 'Up • Down'),
    SweepPatternDef(id: 'down_up', s1Up: false, s2Up: true, label: 'Down • Up'),
    SweepPatternDef(id: 'down_down', s1Up: false, s2Up: false, label: 'Down • Down'),
  ];

  int _currentTrial = 1;
  int _isiMs = 300;
  bool _isPlayingAudio = false;
  SweepPatternDef _currentPattern = _patterns[0];
  String? _selectedPatternId;
  bool? _lastCorrect;

  int _correctTrials = 0;
  final List<int> _thresholdsAchieved = [];
  final DateTime _sessionStart = DateTime.now();
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pickAndPlayPattern();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _pickAndPlayPattern() async {
    setState(() {
      _currentPattern = _patterns[math.Random().nextInt(_patterns.length)];
      _selectedPatternId = null;
      _lastCorrect = null;
      _isPlayingAudio = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    await SynthesizedAudioService.instance.playSequentialSweeps(
      _currentPattern.s1Up,
      _currentPattern.s2Up,
      _isiMs,
    );

    if (mounted) {
      setState(() {
        _isPlayingAudio = false;
      });
    }
  }

  Future<void> _replayCurrent() async {
    if (_isPlayingAudio) return;
    setState(() => _isPlayingAudio = true);
    await SynthesizedAudioService.instance.playSequentialSweeps(
      _currentPattern.s1Up,
      _currentPattern.s2Up,
      _isiMs,
    );
    if (mounted) {
      setState(() => _isPlayingAudio = false);
    }
  }

  void _handleChoice(String patternId) {
    if (_isPlayingAudio) return;
    final isCorrect = patternId == _currentPattern.id;

    setState(() {
      _selectedPatternId = patternId;
      _lastCorrect = isCorrect;
    });

    if (isCorrect) {
      SynthesizedAudioService.instance.playSuccessChime();
      _correctTrials++;
      _thresholdsAchieved.add(_isiMs);
      // Adaptive 2-down 1-up staircase: reduce ISI temporal gap
      _isiMs = math.max(60, (_isiMs * 0.75).round());
    } else {
      SynthesizedAudioService.instance.playGentleError();
      // Increase ISI to give ear more temporal resolution
      _isiMs = math.min(500, (_isiMs * 1.25).round());
    }

    Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (_currentTrial >= _totalTrials) {
        _finishGame();
      } else {
        setState(() {
          _currentTrial++;
        });
        _pickAndPlayPattern();
      }
    });
  }

  Future<void> _finishGame() async {
    final bestThreshold = _thresholdsAchieved.isNotEmpty
        ? _thresholdsAchieved.reduce(math.min)
        : _isiMs;

    // SevaMitr Clinical Scoring for Sound Sweeps
    final accuracyPct = (_correctTrials / _totalTrials) * 70;
    int temporalBonus = 10;
    if (bestThreshold <= 80) {
      temporalBonus = 30;
    } else if (bestThreshold <= 150) {
      temporalBonus = 25;
    } else if (bestThreshold <= 250) {
      temporalBonus = 20;
    } else if (bestThreshold <= 380) {
      temporalBonus = 15;
    }

    final finalScore = (accuracyPct + temporalBonus).round().clamp(0, 100);
    final biomarker = 'Temporal ISI: ${bestThreshold}ms';

    final elapsedSec = DateTime.now().difference(_sessionStart).inSeconds;
    final metric = CognitiveMetric(
      gameType: 'SOUND_SWEEPS',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      gridDimension: 2,
      totalMoves: _totalTrials,
      errorCount: _totalTrials - _correctTrials,
      completionTimeSeconds: elapsedSec > 0 ? elapsedSec : 30,
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
      debugPrint('Sound sweeps metric save warning: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: finalScore,
        biomarker: biomarker,
        customTitle: 'Sound Sweeps Complete!',
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _currentTrial = 1;
            _isiMs = 300;
            _correctTrials = 0;
            _thresholdsAchieved.clear();
          });
          _pickAndPlayPattern();
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
                    'Sound Sweeps (Auditory)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DementiaColors.voiceAssistanceBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'ISI: $_isiMs ms',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DementiaColors.voiceAssistanceBlue),
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
              // Top Audio Instruction Card
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
                        color: DementiaColors.voiceAssistanceBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                      ),
                      child: const Icon(Icons.volume_up, color: DementiaColors.voiceAssistanceBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Listen to 2 frequency sweeps. Did each tone sweep UP or DOWN?',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DementiaColors.textMainCharcoal),
                      ),
                    ),
                    Text(
                      'Trial $_currentTrial/$_totalTrials',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DementiaColors.textDimStone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Audio Wave Visualizer & Replay Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DementiaColors.pureSurfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DementiaColors.borderCharcoal, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(4, 4), blurRadius: 0),
                  ],
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(7, (i) {
                            final barHeight = _isPlayingAudio
                                ? 20 + 35 * math.sin((_waveController.value * math.pi) + (i * 0.5)).abs()
                                : 14.0;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: _isPlayingAudio ? DementiaColors.voiceAssistanceBlue : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isPlayingAudio ? 'Playing Sweeps...' : 'Select the matching sweep pattern below',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _isPlayingAudio ? DementiaColors.voiceAssistanceBlue : DementiaColors.textMutedSlate,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AccessibleTouchWrapper(
                      semanticLabel: 'Replay Sounds',
                      onTap: _replayCurrent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: DementiaColors.paleSageBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay, size: 18, color: DementiaColors.borderCharcoal),
                            SizedBox(width: 6),
                            Text(
                              'Replay Sounds',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DementiaColors.borderCharcoal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4 Direction Pattern Buttons (2x2 Grid)
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: _patterns.map((pat) {
                    final isSelected = _selectedPatternId == pat.id;
                    final isCorrect = _lastCorrect;

                    Color bg = DementiaColors.pureSurfaceWhite;
                    Color border = DementiaColors.borderCharcoal;
                    if (isSelected && isCorrect != null) {
                      bg = isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
                      border = isCorrect ? const Color(0xFF15803D) : const Color(0xFFDC2626);
                    }

                    return AccessibleTouchWrapper(
                      semanticLabel: pat.label,
                      onTap: () => _handleChoice(pat.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border, width: 2),
                          boxShadow: [
                            BoxShadow(color: border, offset: const Offset(3, 3), blurRadius: 0),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  pat.s1Up ? Icons.north_east : Icons.south_east,
                                  color: pat.s1Up ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  size: 28,
                                ),
                                const SizedBox(width: 6),
                                const Text('•', style: TextStyle(fontSize: 20, color: DementiaColors.textDimStone)),
                                const SizedBox(width: 6),
                                Icon(
                                  pat.s2Up ? Icons.north_east : Icons.south_east,
                                  color: pat.s2Up ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pat.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: DementiaColors.textMainCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
