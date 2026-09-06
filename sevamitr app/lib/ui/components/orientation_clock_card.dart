import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';

/// Temporal Orientation Card for Cognitive Grounding
class OrientationClockCard extends StatelessWidget {
  final String timeString;
  final String dayOfWeek;
  final String dayOfWeekRegional;
  final String timeOfDayPhase;
  final String timeOfDayPhaseRegional;
  final String dateFormatted;
  final String reassuranceText;

  const OrientationClockCard({
    super.key,
    this.timeString = "09:30 AM",
    this.dayOfWeek = "Monday",
    this.dayOfWeekRegional = "সোমবাৰ",
    this.timeOfDayPhase = "Morning",
    this.timeOfDayPhaseRegional = "ৰাতিপুৱা",
    this.dateFormatted = "31 August 2026",
    this.reassuranceText = "You are safe at home • আপুনি ঘৰত সুৰক্ষিত",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DementiaColors.pureSurfaceWhite,
        borderRadius: BorderRadius.circular(DementiaDimensions.cardCornerRadius),
        border: Border.all(
          color: DementiaColors.borderCharcoal,
          width: DementiaDimensions.borderWidthThick,
        ),
        boxShadow: const [
          BoxShadow(
            color: DementiaColors.borderCharcoal,
            offset: Offset(
              DementiaDimensions.shadowOffsetCard,
              DementiaDimensions.shadowOffsetCard,
            ),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Time Phase Badge (Neo-Pill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: DementiaColors.amberMuga,
              borderRadius: BorderRadius.circular(DementiaDimensions.pillCornerRadius),
              border: Border.all(
                color: DementiaColors.borderCharcoal,
                width: DementiaDimensions.borderWidthThick,
              ),
              boxShadow: const [
                BoxShadow(
                  color: DementiaColors.borderCharcoal,
                  offset: Offset(
                    DementiaDimensions.shadowOffsetSmall,
                    DementiaDimensions.shadowOffsetSmall,
                  ),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny,
                    color: DementiaColors.borderCharcoal, size: 22),
                const SizedBox(width: 8),
                Text(
                  "$timeOfDayPhase ($timeOfDayPhaseRegional)".toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DementiaColors.borderCharcoal,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Extra Large Time
          Text(
            timeString,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: DementiaColors.borderCharcoal,
              letterSpacing: -0.5,
            ),
          ),

          // Day and Date
          Text(
            "$dayOfWeek ($dayOfWeekRegional)",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: DementiaColors.borderCharcoal,
            ),
          ),
          Text(
            dateFormatted,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DementiaColors.textMutedSlate,
            ),
          ),
          const SizedBox(height: 14),

          // Reassurance Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: DementiaColors.herbalMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DementiaColors.borderCharcoal,
                width: DementiaDimensions.borderWidthThick,
              ),
              boxShadow: const [
                BoxShadow(
                  color: DementiaColors.borderCharcoal,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              reassuranceText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DementiaColors.herbalMintDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
