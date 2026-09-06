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

class MazeCoord {
  final int x;
  final int y;
  const MazeCoord(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MazeCoord && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class MazeLevel {
  final int size;
  final List<List<int>> grid; // 0 = open path, 1 = wall
  final MazeCoord start;
  final MazeCoord goal;
  final String levelTitle;

  const MazeLevel({
    required this.size,
    required this.grid,
    required this.start,
    required this.goal,
    required this.levelTitle,
  });
}

class SpeedMazeScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const SpeedMazeScreen({super.key, required this.onBackToHub});

  @override
  State<SpeedMazeScreen> createState() => _SpeedMazeScreenState();
}

class _SpeedMazeScreenState extends State<SpeedMazeScreen> {
  static const List<MazeLevel> _levels = [
    // Level 1: 5x5 Garden Walkway
    MazeLevel(
      size: 5,
      levelTitle: 'Garden Walkway',
      start: MazeCoord(0, 0),
      goal: MazeCoord(4, 4),
      grid: [
        [0, 0, 1, 0, 0],
        [1, 0, 1, 0, 1],
        [0, 0, 0, 0, 0],
        [0, 1, 1, 1, 0],
        [0, 0, 0, 1, 0],
      ],
    ),
    // Level 2: 5x5 Village Path
    MazeLevel(
      size: 5,
      levelTitle: 'Village Bamboo Path',
      start: MazeCoord(0, 0),
      goal: MazeCoord(4, 4),
      grid: [
        [0, 1, 0, 0, 0],
        [0, 1, 0, 1, 0],
        [0, 0, 0, 1, 0],
        [1, 1, 0, 0, 0],
        [0, 0, 0, 1, 0],
      ],
    ),
    // Level 3: 6x6 Kaziranga Forest Trail
    MazeLevel(
      size: 6,
      levelTitle: 'Tea Estate Trail',
      start: MazeCoord(0, 0),
      goal: MazeCoord(5, 5),
      grid: [
        [0, 0, 0, 1, 0, 0],
        [1, 1, 0, 1, 0, 1],
        [0, 0, 0, 0, 0, 0],
        [0, 1, 1, 1, 1, 0],
        [0, 0, 0, 1, 0, 0],
        [1, 1, 0, 0, 0, 0],
      ],
    ),
  ];

  int _currentLevelIdx = 0;
  late MazeCoord _playerPos;
  final Set<String> _visitedCells = {};

  int _wallHits = 0;
  int _backtracks = 0;
  final List<int> _stepDeltas = [];
  int _lastStepTimestamp = 0;
  final DateTime _sessionStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLevel(0);
  }

  void _loadLevel(int levelIdx) {
    final lvl = _levels[levelIdx];
    _playerPos = lvl.start;
    _visitedCells.clear();
    _visitedCells.add('${_playerPos.x},${_playerPos.y}');
    _lastStepTimestamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _currentLevelIdx = levelIdx;
    });
  }

  void _tryMove(int dx, int dy) {
    final lvl = _levels[_currentLevelIdx];
    final nextX = _playerPos.x + dx;
    final nextY = _playerPos.y + dy;

    // Check bounds & walls
    if (nextX < 0 || nextX >= lvl.size || nextY < 0 || nextY >= lvl.size || lvl.grid[nextY][nextX] == 1) {
      // Wall collision
      _wallHits++;
      SynthesizedAudioService.instance.playGentleError();
      return;
    }

    // Valid movement
    final now = DateTime.now().millisecondsSinceEpoch;
    _stepDeltas.add(now - _lastStepTimestamp);
    _lastStepTimestamp = now;

    final nextKey = '$nextX,$nextY';
    if (_visitedCells.contains(nextKey)) {
      _backtracks++;
    }

    SynthesizedAudioService.instance.playStepTick();
    setState(() {
      _playerPos = MazeCoord(nextX, nextY);
      _visitedCells.add(nextKey);
    });

    // Check goal arrival
    if (_playerPos.x == lvl.goal.x && _playerPos.y == lvl.goal.y) {
      SynthesizedAudioService.instance.playSuccessChime();
      if (_currentLevelIdx + 1 < _levels.length) {
        Timer(const Duration(milliseconds: 700), () {
          if (mounted) _loadLevel(_currentLevelIdx + 1);
        });
      } else {
        _finishGame();
      }
    }
  }

  Future<void> _finishGame() async {
    final avgHesitation = _stepDeltas.isNotEmpty
        ? (_stepDeltas.reduce((a, b) => a + b) / _stepDeltas.length).round()
        : 1100;

    // SevaMitr Clinical Scoring for Speed Maze
    const base = 60; // 3/3 levels completed
    final wallSafety = math.max(0, 20 - _wallHits * 3);
    final efficiency = math.max(0, 20 - _backtracks * 2);
    final finalScore = (base + wallSafety + efficiency).clamp(0, 100);
    final biomarker = 'Planning Hesitation: ${avgHesitation}ms';

    final elapsedSec = DateTime.now().difference(_sessionStart).inSeconds;
    final metric = CognitiveMetric(
      gameType: 'SPEED_MAZE',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      gridDimension: _levels[_currentLevelIdx].size,
      totalMoves: _visitedCells.length + _wallHits,
      errorCount: _wallHits,
      completionTimeSeconds: elapsedSec > 0 ? elapsedSec : 35,
      tremorJitterScore: (_wallHits * 0.1).clamp(0.05, 0.8),
      calculatedScore: finalScore.toDouble(),
      recommendedGridSize: 5,
      isSynced: false,
    );

    try {
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Speed maze metric save warning: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: finalScore,
        biomarker: biomarker,
        customTitle: 'Speed Maze Completed!',
        onPlayAgain: () {
          Navigator.of(context).pop();
          _wallHits = 0;
          _backtracks = 0;
          _stepDeltas.clear();
          _loadLevel(0);
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
    final lvl = _levels[_currentLevelIdx];

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
                    'Speed Maze (Navigation)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9D5FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'Level ${_currentLevelIdx + 1}/${_levels.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF581C87)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Level Title & Instruction
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                      ),
                      child: const Icon(Icons.explore, color: Color(0xFF6B21A8), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lvl.levelTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DementiaColors.textDimStone)),
                          const Text('Guide the traveler to Safe Home 🏡', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DementiaColors.textMainCharcoal)),
                        ],
                      ),
                    ),
                    Text('Hits: $_wallHits', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DementiaColors.alertTerracotta)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Maze Board Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
                          crossAxisCount: lvl.size,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: lvl.size * lvl.size,
                        itemBuilder: (context, idx) {
                          final x = idx % lvl.size;
                          final y = idx ~/ lvl.size;
                          final isWall = lvl.grid[y][x] == 1;
                          final isPlayer = _playerPos.x == x && _playerPos.y == y;
                          final isGoal = lvl.goal.x == x && lvl.goal.y == y;
                          final isVisited = _visitedCells.contains('$x,$y');

                          Color cellColor = DementiaColors.inputBg;
                          if (isWall) {
                            cellColor = const Color(0xFF475569);
                          } else if (isPlayer) {
                            cellColor = const Color(0xFFDCFCE7);
                          } else if (isGoal) {
                            cellColor = const Color(0xFFFEF9C3);
                          } else if (isVisited) {
                            cellColor = const Color(0xFFF1F5F9);
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isWall ? const Color(0xFF1E293B) : DementiaColors.borderSubtle,
                                width: isWall ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isPlayer
                                ? const Text('🦏', style: TextStyle(fontSize: 26))
                                : (isGoal ? const Text('🏡', style: TextStyle(fontSize: 26)) : null),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Ergonomic D-Pad Directional Controls
              _buildDPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDPad() {
    return Column(
      children: [
        // Up Button
        _buildDirectionButton(Icons.keyboard_arrow_up, 'Up', () => _tryMove(0, -1)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Button
            _buildDirectionButton(Icons.keyboard_arrow_left, 'Left', () => _tryMove(-1, 0)),
            const SizedBox(width: 50),
            // Right Button
            _buildDirectionButton(Icons.keyboard_arrow_right, 'Right', () => _tryMove(1, 0)),
          ],
        ),
        const SizedBox(height: 6),
        // Down Button
        _buildDirectionButton(Icons.keyboard_arrow_down, 'Down', () => _tryMove(0, 1)),
      ],
    );
  }

  Widget _buildDirectionButton(IconData icon, String label, VoidCallback onTap) {
    return AccessibleTouchWrapper(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: 62,
        height: 52,
        decoration: BoxDecoration(
          color: DementiaColors.pureSurfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
          boxShadow: const [
            BoxShadow(color: DementiaColors.borderCharcoal, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 36, color: DementiaColors.borderCharcoal),
      ),
    );
  }
}
