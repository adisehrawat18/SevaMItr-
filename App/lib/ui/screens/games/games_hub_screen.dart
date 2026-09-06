import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

/// 11-Module Cognitive Stimulation & Speed Trials Hub for North Eastern Region
class GamesHubScreen extends StatelessWidget {
  final VoidCallback onBackToHome;
  final VoidCallback onSelectPictureMatch;
  final VoidCallback onSelectObjectRecognition;
  final VoidCallback onSelectRoutineSequencing;
  final VoidCallback onSelectProverbs;
  final VoidCallback onSelectMemoryCapsule;
  final VoidCallback onSelectBijuliTap;
  final VoidCallback onSelectBikhamaKhoj;
  final VoidCallback onSelectDoubleDecision;
  final VoidCallback onSelectSoundSweeps;
  final VoidCallback onSelectSpeedMaze;
  final VoidCallback onSelectTargetTracker;

  const GamesHubScreen({
    super.key,
    required this.onBackToHome,
    required this.onSelectPictureMatch,
    required this.onSelectObjectRecognition,
    required this.onSelectRoutineSequencing,
    required this.onSelectProverbs,
    required this.onSelectMemoryCapsule,
    required this.onSelectBijuliTap,
    required this.onSelectBikhamaKhoj,
    required this.onSelectDoubleDecision,
    required this.onSelectSoundSweeps,
    required this.onSelectSpeedMaze,
    required this.onSelectTargetTracker,
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
          // Reassurance Header
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
          const SizedBox(height: 20),

          // ==========================================
          // SECTION 1: BRAINHQ SPEED TRIALS (6 WEBSITE GAMES)
          // ==========================================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DementiaColors.terracotta,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BRAINHQ SPEED TRIALS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Divider(color: DementiaColors.borderCharcoal, thickness: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Bijuli Tap
          _buildGameCard(
            title: "1. ${context.tr('bijuli_tap')}",
            regionalTitle: "Bijuli Tap (Reaction Speed)",
            description: context.tr('bijuli_tap_desc'),
            icon: Icons.bolt,
            accentColor: const Color(0xFFB45309),
            badge: "150-400ms SRT",
            onClick: onSelectBijuliTap,
          ),
          const SizedBox(height: 14),

          // 2. Bikhama Khoj
          _buildGameCard(
            title: "2. ${context.tr('bikhama_khoj')}",
            regionalTitle: "Bikhama Khoj (Visual Search)",
            description: context.tr('bikhama_khoj_desc'),
            icon: Icons.remove_red_eye,
            accentColor: const Color(0xFF0369A1),
            badge: "Odd One Out",
            onClick: onSelectBikhamaKhoj,
          ),
          const SizedBox(height: 14),

          // 3. Sight Speed / Double Decision
          _buildGameCard(
            title: "3. ${context.tr('double_decision')}",
            regionalTitle: "Sight Speed (UFOV Dual-Task)",
            description: context.tr('double_decision_desc'),
            icon: Icons.flash_on,
            accentColor: DementiaColors.actionForestGreen,
            badge: "50-450ms Threshold",
            onClick: onSelectDoubleDecision,
          ),
          const SizedBox(height: 14),

          // 4. Sound Sweeps
          _buildGameCard(
            title: "4. ${context.tr('sound_sweeps')}",
            regionalTitle: "Sound Sweeps (Auditory)",
            description: context.tr('sound_sweeps_desc'),
            icon: Icons.volume_up,
            accentColor: DementiaColors.voiceAssistanceBlue,
            badge: "Binaural ISI",
            onClick: onSelectSoundSweeps,
          ),
          const SizedBox(height: 14),

          // 5. Speed Maze
          _buildGameCard(
            title: "5. ${context.tr('speed_maze')}",
            regionalTitle: "Speed Maze (Spatial Planning)",
            description: context.tr('speed_maze_desc'),
            icon: Icons.explore,
            accentColor: const Color(0xFF6B21A8),
            badge: "Visuomotor",
            onClick: onSelectSpeedMaze,
          ),
          const SizedBox(height: 14),

          // 6. Target Tracker
          _buildGameCard(
            title: "6. ${context.tr('target_tracker')}",
            regionalTitle: "Target Tracker (Attention)",
            description: context.tr('target_tracker_desc'),
            icon: Icons.gps_fixed,
            accentColor: DementiaColors.alertTerracotta,
            badge: "Multi-Object Tracking",
            onClick: onSelectTargetTracker,
          ),
          const SizedBox(height: 24),

          // ==========================================
          // SECTION 2: CULTURAL MEMORY & LIVING
          // ==========================================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DementiaColors.actionForestGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.tr('cultural_modules_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Divider(color: DementiaColors.borderCharcoal, thickness: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 7. Personalized Memory Capsule
          _buildGameCard(
            title: "7. ${context.tr('memory_capsule')}",
            regionalTitle: context.tr('memory_capsule'),
            description: context.tr('memory_capsule_description'),
            icon: Icons.photo_album,
            accentColor: DementiaColors.alertTerracotta,
            badge: context.tr('recommended_today'),
            onClick: onSelectMemoryCapsule,
          ),
          const SizedBox(height: 14),

          // 8. Picture / Memory Matching
          _buildGameCard(
            title: "8. ${context.tr('picture_matching')}",
            regionalTitle: context.tr('picture_matching'),
            description: context.tr('picture_matching_description'),
            icon: Icons.grid_view,
            accentColor: DementiaColors.actionForestGreen,
            onClick: onSelectPictureMatch,
          ),
          const SizedBox(height: 14),

          // 9. Daily Routine Sequencing
          _buildGameCard(
            title: "9. ${context.tr('routine_sequencing')}",
            regionalTitle: context.tr('routine_sequencing'),
            description: context.tr('routine_sequencing_description'),
            icon: Icons.view_timeline,
            accentColor: DementiaColors.ochreWarmAmber,
            onClick: onSelectRoutineSequencing,
          ),
          const SizedBox(height: 14),

          // 10. Regional Proverbs & Word Association
          _buildGameCard(
            title: "10. ${context.tr('proverbs')}",
            regionalTitle: context.tr('proverbs'),
            description: context.tr('proverbs_description'),
            icon: Icons.format_quote,
            accentColor: DementiaColors.voiceAssistanceBlue,
            onClick: onSelectProverbs,
          ),
          const SizedBox(height: 14),

          // 11. Object & Cultural Recognition
          _buildGameCard(
            title: "11. ${context.tr('object_recognition')}",
            regionalTitle: context.tr('object_recognition'),
            description: context.tr('object_recognition_description'),
            icon: Icons.category,
            accentColor: DementiaColors.caregiverShieldGold,
            onClick: onSelectObjectRecognition,
          ),
          const SizedBox(height: 28),
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
          border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
          boxShadow: const [
            BoxShadow(
              color: DementiaColors.borderCharcoal,
              offset: Offset(4, 4),
              blurRadius: 0,
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
                    border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
                  ),
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: DementiaColors.textPrimaryDark,
                        ),
                      ),
                      Text(
                        regionalTitle,
                        style: TextStyle(
                          fontSize: 14,
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
                fontSize: 14,
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
