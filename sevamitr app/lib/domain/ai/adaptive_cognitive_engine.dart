import 'package:dementia_ner_care/data/models/cognitive_metric_model.dart';

/// Configuration output from the Adaptive AI Engine
class AdaptiveGameConfig {
  final int gridColumns;
  final int totalPairs;
  final int timeLimitSeconds;
  final bool showVisualHints;
  final String feedbackStyle;

  const AdaptiveGameConfig({
    required this.gridColumns,
    required this.totalPairs,
    required this.timeLimitSeconds,
    required this.showVisualHints,
    required this.feedbackStyle,
  });
}

/// Adaptive AI Engine for Dementia Care
/// Dynamic difficulty scaler that safeguards against patient agitation and neural fatigue.
class AdaptiveCognitiveEngine {
  AdaptiveGameConfig evaluateDifficulty(List<CognitiveMetric> history) {
    if (history.isEmpty) {
      // Baseline: 2x2 grid (2 pairs)
      return const AdaptiveGameConfig(
        gridColumns: 2,
        totalPairs: 2,
        timeLimitSeconds: 120,
        showVisualHints: true,
        feedbackStyle: "reassuring",
      );
    }

    final recentMetrics = history.take(3).toList();
    final avgErrors =
        recentMetrics.map((e) => e.errorCount).reduce((a, b) => a + b) /
            recentMetrics.length;
    final avgTime = recentMetrics
            .map((e) => e.completionTimeSeconds)
            .reduce((a, b) => a + b) /
        recentMetrics.length;
    final avgTremor =
        recentMetrics.map((e) => e.tremorJitterScore).reduce((a, b) => a + b) /
            recentMetrics.length;

    // Rule 1: High errors or high tremor -> Scale down to simple 2-pair matching
    if (avgErrors > 2.5 || avgTime > 90 || avgTremor > 0.5) {
      return const AdaptiveGameConfig(
        gridColumns: 2,
        totalPairs: 2,
        timeLimitSeconds: 180,
        showVisualHints: true,
        feedbackStyle: "reassuring",
      );
    }

    // Rule 2: High consistency (low errors, confident timing) -> Scale to 2x3 grid (3 pairs)
    final consecutiveSuccess = recentMetrics
        .take(2)
        .every((e) => e.errorCount <= 1 && e.calculatedScore >= 80);
    if (consecutiveSuccess) {
      return const AdaptiveGameConfig(
        gridColumns: 2,
        totalPairs: 3, // 6 cards total
        timeLimitSeconds: 120,
        showVisualHints: false,
        feedbackStyle: "celebratory",
      );
    }

    return const AdaptiveGameConfig(
      gridColumns: 2,
      totalPairs: 2,
      timeLimitSeconds: 120,
      showVisualHints: true,
      feedbackStyle: "reassuring",
    );
  }

  double calculateScore({
    required int pairsMatched,
    required int errorCount,
    required int elapsedSeconds,
    required int tremorMisclicks,
  }) {
    final base = pairsMatched * 50.0;
    final errorPenalty = (errorCount * 8.0).clamp(0.0, 40.0);
    final timePenalty = elapsedSeconds > 60
        ? ((elapsedSeconds - 60) * 0.5).clamp(0.0, 20.0)
        : 0.0;
    final tremorPenalty = (tremorMisclicks * 2.0).clamp(0.0, 10.0);

    return (base - errorPenalty - timePenalty - tremorPenalty)
        .clamp(10.0, 100.0);
  }
}
