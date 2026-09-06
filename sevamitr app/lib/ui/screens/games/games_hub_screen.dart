import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

/// 5-Module Cognitive Stimulation Hub for North Eastern Region
class GamesHubScreen extends StatelessWidget {
  final VoidCallback onBackToHome;
  final VoidCallback onSelectPictureMatch;
  final VoidCallback onSelectObjectRecognition;
  final VoidCallback onSelectRoutineSequencing;
  final VoidCallback onSelectProverbs;
  final VoidCallback onSelectMemoryCapsule;

  const GamesHubScreen({
    super.key,
    required this.onBackToHome,
    required this.onSelectPictureMatch,
    required this.onSelectObjectRecognition,
    required this.onSelectRoutineSequencing,
    required this.onSelectProverbs,
    required this.onSelectMemoryCapsule,
  });

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
                  semanticLabel: context.tr('back_to_home'),
                  onTap: onBackToHome,
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
                  context.tr('games_title'),
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Introductory Reassurance Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DementiaColors.actionGreenLight,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: DementiaColors.actionForestGreen, width: 2),
            ),
            child: Text(
              context.tr('games_intro'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: DementiaColors.actionForestGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Personalized Memory Capsule (Featured Spotlight)
          _buildGameCard(
            title: "1. ${context.tr('memory_capsule')}",
            regionalTitle: context.tr('memory_capsule'),
            description: context.tr('memory_capsule_description'),
            icon: Icons.photo_album,
            accentColor: DementiaColors.alertTerracotta,
            badge: context.tr('recommended_today'),
            onClick: onSelectMemoryCapsule,
          ),
          const SizedBox(height: 14),

          // 2. Picture / Memory Matching
          _buildGameCard(
            title: "2. ${context.tr('picture_matching')}",
            regionalTitle: context.tr('picture_matching'),
            description: context.tr('picture_matching_description'),
            icon: Icons.grid_view,
            accentColor: DementiaColors.actionForestGreen,
            onClick: onSelectPictureMatch,
          ),
          const SizedBox(height: 14),

          // 3. Daily Routine Sequencing
          _buildGameCard(
            title: "3. ${context.tr('routine_sequencing')}",
            regionalTitle: context.tr('routine_sequencing'),
            description: context.tr('routine_sequencing_description'),
            icon: Icons.view_timeline,
            accentColor: DementiaColors.ochreWarmAmber,
            onClick: onSelectRoutineSequencing,
          ),
          const SizedBox(height: 14),

          // 4. Regional Proverbs & Word Association
          _buildGameCard(
            title: "4. ${context.tr('proverbs')}",
            regionalTitle: context.tr('proverbs'),
            description: context.tr('proverbs_description'),
            icon: Icons.format_quote,
            accentColor: DementiaColors.voiceAssistanceBlue,
            onClick: onSelectProverbs,
          ),
          const SizedBox(height: 14),

          // 5. Object & Cultural Recognition
          _buildGameCard(
            title: "5. ${context.tr('object_recognition')}",
            regionalTitle: context.tr('object_recognition'),
            description: context.tr('object_recognition_description'),
            icon: Icons.category,
            accentColor: DementiaColors.caregiverShieldGold,
            onClick: onSelectObjectRecognition,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String regionalTitle,
    required String description,
    required IconData icon,
    required Color accentColor,
    String? badge,
    required VoidCallback onClick,
  }) {
    return AccessibleTouchWrapper(
      semanticLabel: "$title $regionalTitle. $description",
      onTap: onClick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DementiaColors.surfaceCardLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ],
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: DementiaColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        regionalTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: accentColor, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: DementiaColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
