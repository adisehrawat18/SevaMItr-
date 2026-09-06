import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

class GameCelebrationDialog extends StatelessWidget {
  final int score;
  final String biomarker;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToHub;
  final String? customTitle;

  const GameCelebrationDialog({
    super.key,
    required this.score,
    required this.biomarker,
    required this.onPlayAgain,
    required this.onBackToHub,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Standard clinical grading thresholds matching web gradingEngine
    final safeScore = score.clamp(0, 100);
    final String letterGrade;
    final String gradeLabel;
    final Color badgeBg;
    final Color badgeColor;
    final int stars;

    if (safeScore >= 90) {
      letterGrade = 'A+';
      gradeLabel = 'Optimal Cognitive Function';
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF15803D);
      stars = 3;
    } else if (safeScore >= 80) {
      letterGrade = 'A';
      gradeLabel = 'Strong Performance';
      badgeBg = const Color(0xFFE0F2FE);
      badgeColor = const Color(0xFF0369A1);
      stars = 3;
    } else if (safeScore >= 65) {
      letterGrade = 'B';
      gradeLabel = 'Good & Stable';
      badgeBg = const Color(0xFFFEF9C3);
      badgeColor = const Color(0xFFA16207);
      stars = 2;
    } else if (safeScore >= 50) {
      letterGrade = 'C';
      gradeLabel = 'Fair • Monitor Variations';
      badgeBg = const Color(0xFFFFEDD5);
      badgeColor = const Color(0xFFC2410C);
      stars = 2;
    } else {
      letterGrade = 'Needs Support';
      gradeLabel = 'Mild Variation';
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFB91C1C);
      stars = 1;
    }

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: DementiaColors.pureSurfaceWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DementiaColors.borderCharcoal, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: DementiaColors.borderCharcoal,
                offset: Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Trophy Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: DementiaColors.amberMugaLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: DementiaColors.borderCharcoal,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 40,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                customTitle ?? context.tr('well_done'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: DementiaColors.textMainCharcoal,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),

              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (idx) {
                  final filled = idx < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.star,
                      size: 28,
                      color: filled ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // Score Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: DementiaColors.paleSageBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$safeScore',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: DementiaColors.primaryKazirangaForest,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: DementiaColors.textMutedSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Letter Grade Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                      ),
                      child: Text(
                        '$letterGrade • $gradeLabel',
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Clinical Biomarker Telemetry
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DementiaColors.pureSurfaceWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DementiaColors.borderSubtle, width: 1),
                      ),
                      child: Text(
                        biomarker,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DementiaColors.textMutedSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AccessibleTouchWrapper(
                      semanticLabel: context.tr('play_again'),
                      onTap: onPlayAgain,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: DementiaColors.pureSurfaceWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: DementiaColors.borderCharcoal,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh, size: 20, color: DementiaColors.textMainCharcoal),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('play_again'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: DementiaColors.textMainCharcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AccessibleTouchWrapper(
                      semanticLabel: context.tr('back_to_games'),
                      onTap: onBackToHub,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: DementiaColors.primaryKazirangaForest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: DementiaColors.borderCharcoal,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, size: 20, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('back_to_games'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
