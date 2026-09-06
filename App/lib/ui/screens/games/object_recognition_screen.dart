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

class CulturalObjectItem {
  final String name;
  final String regionalName;
  final String description;
  final IconData icon;
  final List<String> options;
  final int correctIndex;

  const CulturalObjectItem({
    required this.name,
    required this.regionalName,
    required this.description,
    required this.icon,
    required this.options,
    required this.correctIndex,
  });
}

/// Object & Cultural Item Recognition Screen
/// Tests visual naming and semantic recognition of deeply ingrained North Eastern artifacts.
class ObjectRecognitionScreen extends StatefulWidget {
  final VoidCallback onBackToHub;

  const ObjectRecognitionScreen({
    super.key,
    required this.onBackToHub,
  });

  @override
  State<ObjectRecognitionScreen> createState() =>
      _ObjectRecognitionScreenState();
}

class _ObjectRecognitionScreenState extends State<ObjectRecognitionScreen> {
  final List<CulturalObjectItem> _items = const [
    CulturalObjectItem(
      name: "object_xorai_name",
      regionalName: "object_xorai_name",
      description: "object_xorai_desc",
      icon: Icons.emoji_events,
      options: [
        "object_opt_xorai",
        "object_opt_japi",
        "object_opt_dhol",
      ],
      correctIndex: 0,
    ),
    CulturalObjectItem(
      name: "object_pepa_name",
      regionalName: "object_pepa_name",
      description: "object_pepa_desc",
      icon: Icons.music_note,
      options: [
        "object_opt_flute",
        "object_pepa_name",
        "object_opt_khol",
      ],
      correctIndex: 1,
    ),
    CulturalObjectItem(
      name: "object_dhol_name",
      regionalName: "object_dhol_name",
      description: "object_dhol_desc",
      icon: Icons.album,
      options: [
        "object_dhol_name",
        "object_opt_mridanga",
        "object_opt_xorai",
      ],
      correctIndex: 0,
    ),
  ];

  int _currentIndex = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  DateTime? _startTime;
  int _correctCount = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  void _selectOption(int index) {
    if (_isAnswered) return;
    final current = _items[_currentIndex];
    if (index == current.correctIndex) {
      _correctCount++;
    } else {
      _errorCount++;
    }

    setState(() {
      _selectedOption = index;
      _isAnswered = true;
    });

    final prefix =
        index == current.correctIndex ? '${context.tr('correct')} ' : '';
    RegionalTtsService().speak('$prefix${context.tr(current.regionalName)}');
  }

  void _nextItem() {
    if (_currentIndex < _items.length - 1) {
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
        ((_correctCount / (_items.isNotEmpty ? _items.length : 1)) * 100.0)
            .clamp(30.0, 100.0);
    try {
      final metric = CognitiveMetric(
        gameType: 'OBJECT_RECOGNITION',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        gridDimension: 2,
        totalMoves: _correctCount + _errorCount,
        errorCount: _errorCount,
        completionTimeSeconds: elapsed > 0 ? elapsed : 25,
        tremorJitterScore: (_errorCount * 0.1).clamp(0.05, 0.7),
        calculatedScore: score,
        recommendedGridSize: 2,
        isSynced: false,
      );
      await OfflineDatabase.instance.insertCognitiveMetric(metric);
      await SevaMitrSyncService.instance.refreshLocalState();
      unawaited(SevaMitrSyncService.instance.syncAll(isBackground: true));
    } catch (e) {
      debugPrint('Error saving object recognition metric: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameCelebrationDialog(
        score: score.toInt(),
        biomarker: 'Object Naming: $_correctCount/${_items.length} Identified • ${elapsed}s',
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
    final item = _items[_currentIndex];
    final itemDescription = context.tr(item.description);

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
                  context.tr('object_recognition'),
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
                color: DementiaColors.actionGreenLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: DementiaColors.actionForestGreen, width: 2),
              ),
              child: Text(
                context.tr('object_instruction'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: DementiaColors.actionForestGreen,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Large Artifact Visual Display
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: DementiaColors.surfaceDarkNavy,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: DementiaColors.ochreWarmAmber, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: DementiaColors.ochreBadgeBg, size: 88),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      itemDescription,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3 Large Option Buttons (72dp height)
            ...item.options.asMap().entries.map((entry) {
              final index = entry.key;
              final optionText = context.tr(entry.value);
              final isSelected = _selectedOption == index;
              final isCorrect = index == item.correctIndex;

              Color bg = DementiaColors.surfaceCardLight;
              Color border = DementiaColors.dividerColor;

              if (_isAnswered) {
                if (isCorrect) {
                  bg = DementiaColors.actionGreenLight;
                  border = DementiaColors.actionForestGreen;
                } else if (isSelected) {
                  bg = DementiaColors.alertTerracottaBg;
                  border = DementiaColors.alertTerracotta;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AccessibleTouchWrapper(
                  semanticLabel: optionText,
                  onTap: () => _selectOption(index),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 72),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: border, width: 2.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: border,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _isAnswered && isCorrect
                                  ? Icons.check
                                  : Icons.touch_app,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            optionText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
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
            const SizedBox(height: 16),

            if (_isAnswered) ...[
              DementiaAccessibleButton(
                text: _currentIndex < _items.length - 1
                    ? context.tr('next_item')
                    : context.tr('completed'),
                icon: Icons.arrow_forward,
                backgroundColor: DementiaColors.actionForestGreen,
                contentColor: Colors.white,
                onClick: () {
                  if (_currentIndex < _items.length - 1) {
                    _nextItem();
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
}
