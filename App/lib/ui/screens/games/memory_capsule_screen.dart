import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/data/models/memory_capsule_model.dart';
import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/data/services/sevamitr_sync_service.dart';
import 'package:dementia_ner_care/ui/components/dementia_accessible_button.dart';
import 'package:dementia_ner_care/ui/widgets/game_celebration_dialog.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';
import 'package:dementia_ner_care/core/localization/app_language.dart';

/// Personalized Family Reminiscence Screen (Memory Capsule Module)
/// Plays familiar family photos with soothing audio narrations recorded by caregivers.
/// Includes a gentle recognition quiz with large single-tap options to promote recall without anxiety.
class MemoryCapsuleScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const MemoryCapsuleScreen({
    super.key,
    required this.onBackToHub,
  });

  @override
  State<MemoryCapsuleScreen> createState() => _MemoryCapsuleScreenState();
}

class _MemoryCapsuleScreenState extends State<MemoryCapsuleScreen> {
  List<MemoryCapsule> _capsules = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  int? _selectedQuizOption;
  bool _isAnswerChecked = false;
  bool _isPlayingAudio = false;
  DateTime? _startTime;
  int _correctAnswers = 0;
  int _totalAnswers = 0;

  @override
  void initState() {
    super.initState();
    _loadCapsules();
  }

  Future<void> _loadCapsules() async {
    final list = await OfflineDatabase.instance.getAllMemoryCapsules();
    setState(() {
      _capsules = list;
      _isLoading = false;
      _startTime = DateTime.now();
      _correctAnswers = 0;
      _totalAnswers = 0;
    });
  }

  Future<void> _recordSessionAndCelebrate() async {
    _stopStoryAudio();
    final elapsed =
        DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    final total = _totalAnswers > 0 ? _totalAnswers : (_capsules.isNotEmpty ? _capsules.length : 1);
    final score = ((_correctAnswers / total) * 100.0).clamp(50.0, 100.0);
    try {
      final metric = CognitiveMetric(
        gameType: 'MEMORY_CAPSULE',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        gridDimension: 2,
        totalMoves: total,
        errorCount: (total - _correctAnswers).clamp(0, total),
        completionTimeSeconds: elapsed > 0 ? elapsed : 30,
        tremorJitterScore: 0.1,
        calculatedScore: score,
        recommendedGridSize: 2,
        isSynced: false,
      );
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Error recording memory capsule metric: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: score.toInt(),
        biomarker: 'Reminiscence: $_correctAnswers/$total Memories Recalled • ${elapsed}s',
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(() {
            _currentIndex = 0;
            _selectedQuizOption = null;
            _isAnswerChecked = false;
            _startTime = DateTime.now();
            _correctAnswers = 0;
            _totalAnswers = 0;
          });
        },
        onBackToHub: () {
          Navigator.of(context).pop();
          widget.onBackToHub();
        },
      ),
    );
  }

  String _localizedStory(BuildContext context, MemoryCapsule capsule) {
    final language = AppLanguageScope.of(context).currentLanguage;
    final regionalStory = capsule.audioStoryTextRegional.trim();
    return language == AppLanguage.assamese && regionalStory.isNotEmpty
        ? regionalStory
        : capsule.audioStoryText;
  }

  String _localizedQuestion(BuildContext context, MemoryCapsule capsule) {
    final language = AppLanguageScope.of(context).currentLanguage;
    final regionalQuestion = capsule.quizQuestionRegional.trim();
    return language == AppLanguage.assamese && regionalQuestion.isNotEmpty
        ? regionalQuestion
        : capsule.quizQuestion;
  }

  void _playStoryAudio(BuildContext context, MemoryCapsule capsule) {
    setState(() => _isPlayingAudio = true);
    RegionalTtsService().speak(_localizedStory(context, capsule));
  }

  void _stopStoryAudio() {
    RegionalTtsService().stop();
    setState(() => _isPlayingAudio = false);
  }

  @override
  void dispose() {
    RegionalTtsService().stop();
    super.dispose();
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
                  onTap: () {
                    _stopStoryAudio();
                    widget.onBackToHub();
                  },
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
                  context.tr('memory_capsule'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _capsules.isEmpty
              ? _buildEmptyState()
              : _buildCapsuleViewer(_capsules[_currentIndex]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_album,
                size: 72, color: DementiaColors.ochreWarmAmber),
            const SizedBox(height: 16),
            Text(
              context.tr('no_memories'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DementiaColors.textPrimaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('no_memories_description'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, color: DementiaColors.textSecondaryDark),
            ),
            const SizedBox(height: 24),
            DementiaAccessibleButton(
              text: context.tr('back_to_games'),
              icon: Icons.arrow_back,
              onClick: widget.onBackToHub,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapsuleViewer(MemoryCapsule capsule) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Relation Tag Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: DementiaColors.ochreBadgeBg,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: DementiaColors.ochreWarmAmber, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite,
                    color: DementiaColors.alertTerracotta, size: 24),
                const SizedBox(width: 8),
                Text(
                  capsule.relationTag,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: DementiaColors.ochreWarmAmber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Memory Photo Placeholder Container
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              color: DementiaColors.surfaceDarkNavy,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DementiaColors.dividerColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder family memory illustration
                  Container(
                    color: DementiaColors.surfaceCardLight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.family_restroom,
                            size: 84, color: DementiaColors.actionForestGreen),
                        const SizedBox(height: 8),
                        Text(
                          capsule.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DementiaColors.textPrimaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "${context.tr('date')}: ${capsule.recordedDateFormatted}",
                          style: const TextStyle(
                              fontSize: 14,
                              color: DementiaColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),

                  // Floating Audio Play Trigger
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: AccessibleTouchWrapper(
                      semanticLabel: _isPlayingAudio
                          ? context.tr('stop_story')
                          : context.tr('play_story'),
                      onTap: () {
                        if (_isPlayingAudio) {
                          _stopStoryAudio();
                        } else {
                          _playStoryAudio(context, capsule);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isPlayingAudio
                              ? DementiaColors.alertTerracotta
                              : DementiaColors.actionForestGreen,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isPlayingAudio ? Icons.stop : Icons.volume_up,
                                color: Colors.white, size: 26),
                            const SizedBox(width: 8),
                            Text(
                              _isPlayingAudio
                                  ? context.tr('stop_story')
                                  : context.tr('listen_story'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Spoken Story Narration Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DementiaColors.actionGreenLight,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: DementiaColors.actionForestGreen, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.record_voice_over,
                        color: DementiaColors.actionForestGreen, size: 24),
                    SizedBox(width: 8),
                    Text(
                      context.tr('family_story'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: DementiaColors.actionForestGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _localizedStory(context, capsule),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: DementiaColors.textPrimaryDark,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Gentle Memory Quiz
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DementiaColors.surfaceCardLight,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: DementiaColors.dividerColor, width: 2.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedQuestion(context, capsule),
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: DementiaColors.textPrimaryDark),
                ),
                const SizedBox(height: 14),

                // Large Option Tiles (70dp touch targets)
                ...capsule.quizOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedQuizOption == index;
                  final isCorrect = index == capsule.correctOptionIndex;

                  Color optionBg = DementiaColors.canvasWarmCream;
                  Color optionBorder = DementiaColors.dividerColor;

                  if (_isAnswerChecked) {
                    if (isCorrect) {
                      optionBg = DementiaColors.actionGreenLight;
                      optionBorder = DementiaColors.actionForestGreen;
                    } else if (isSelected) {
                      optionBg = DementiaColors.alertTerracottaBg;
                      optionBorder = DementiaColors.alertTerracotta;
                    }
                  } else if (isSelected) {
                    optionBg = DementiaColors.ochreBadgeBg;
                    optionBorder = DementiaColors.ochreWarmAmber;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AccessibleTouchWrapper(
                      semanticLabel: option,
                      onTap: () {
                        if (!_isAnswerChecked) {
                          _totalAnswers++;
                          if (isCorrect) {
                            _correctAnswers++;
                          }
                        }
                        setState(() {
                          _selectedQuizOption = index;
                          _isAnswerChecked = true;
                        });
                        if (isCorrect) {
                          RegionalTtsService().speak(context.tr('correct'));
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 68),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: optionBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: optionBorder, width: 2.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DementiaColors.actionForestGreen
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: DementiaColors.dividerColor,
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : DementiaColors.textPrimaryDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: DementiaColors.textPrimaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Navigation Between Memories
          Row(
            children: [
              if (_currentIndex > 0) ...[
                Expanded(
                  child: DementiaAccessibleButton(
                    text: context.tr('previous'),
                    icon: Icons.chevron_left,
                    backgroundColor: DementiaColors.surfaceCardLight,
                    contentColor: DementiaColors.textPrimaryDark,
                    onClick: () {
                      _stopStoryAudio();
                      setState(() {
                        _currentIndex--;
                        _selectedQuizOption = null;
                        _isAnswerChecked = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (_currentIndex < _capsules.length - 1) ...[
                Expanded(
                  child: DementiaAccessibleButton(
                    text: context.tr('next_memory'),
                    icon: Icons.chevron_right,
                    backgroundColor: DementiaColors.actionForestGreen,
                    contentColor: Colors.white,
                    onClick: () {
                      _stopStoryAudio();
                      setState(() {
                        _currentIndex++;
                        _selectedQuizOption = null;
                        _isAnswerChecked = false;
                      });
                    },
                  ),
                ),
              ] else ...[
                Expanded(
                  child: DementiaAccessibleButton(
                    text: context.tr('completed'),
                    icon: Icons.check_circle,
                    backgroundColor: DementiaColors.actionForestGreen,
                    contentColor: Colors.white,
                    onClick: _recordSessionAndCelebrate,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
