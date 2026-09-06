import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/data/models/medication_model.dart';
import 'package:dementia_ner_care/ui/components/dementia_accessible_button.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

/// Full-Screen Medication Reminder Alert Screen
/// Built to comply strictly with Dementia Ergonomics:
/// 1. Single-tap confirmation (no swipe to dismiss).
/// 2. Oversized 78dp touch target with haptic and spoken feedback.
/// 3. WCAG AAA high contrast (Forest Green for confirm, Amber for snooze).
/// 4. Soothing presentation (avoids sudden startling panic).
class MedicationAlertScreen extends StatefulWidget {
  final MedicationSchedule? medication;
  final VoidCallback onMedicineTaken;
  final VoidCallback onSnooze;
  final VoidCallback onCallCaregiver;

  const MedicationAlertScreen({
    super.key,
    this.medication,
    required this.onMedicineTaken,
    required this.onSnooze,
    required this.onCallCaregiver,
  });

  @override
  State<MedicationAlertScreen> createState() => _MedicationAlertScreenState();
}

class _MedicationAlertScreenState extends State<MedicationAlertScreen> {
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final med = widget.medication ??
        MedicationSchedule(
          title: context.tr('medicine_default_name'),
          regionalTitle: context.tr('medicine_default_name'),
          dosageDescription: context.tr('medicine_default_instruction'),
          visualAssetType: "PILL_GREEN",
          scheduledTimeFormatted: "08:00 AM",
          hourOfDay: 8,
          minute: 0,
        );

    return Scaffold(
      backgroundColor: DementiaColors.canvasWarmCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gentle Urgency Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: DementiaColors.ochreBadgeBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: DementiaColors.ochreWarmAmber, width: 2.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm,
                        color: DementiaColors.ochreWarmAmber, size: 32),
                    SizedBox(width: 12),
                    Text(
                      context.tr('time_for_medicine_title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: DementiaColors.ochreWarmAmber,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Visual Medicine Recognition Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DementiaColors.surfaceCardLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: DementiaColors.dividerColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Enormous Pill Visual Token (Clear & unconfusable)
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: DementiaColors.actionForestGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.medication,
                            color: Colors.white, size: 68),
                      ),
                      const SizedBox(height: 20),

                      // Medicine Title
                      Text(
                        med.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: DementiaColors.textPrimaryDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        med.regionalTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: DementiaColors.actionForestGreen,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Explicit Dosage Instruction
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: DementiaColors.dividerColor, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop,
                                color: DementiaColors.voiceAssistanceBlue,
                                size: 28),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                med.dosageDescription,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: DementiaColors.textPrimaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (!_isConfirmed) ...[
                // Primary Confirmation Button (Oversized 78dp)
                DementiaAccessibleButton(
                  text: context.tr('i_took_it'),
                  icon: Icons.check_circle,
                  backgroundColor: DementiaColors.actionForestGreen,
                  contentColor: Colors.white,
                  borderColor: DementiaColors.focusBorderHighlight,
                  minHeight: DementiaDimensions.alertTouchTarget,
                  onClick: () {
                    setState(() => _isConfirmed = true);
                    widget.onMedicineTaken();
                  },
                ),
                const SizedBox(height: 14),

                // Remind in 10 mins (64dp)
                DementiaAccessibleButton(
                  text: context.tr('remind_10_min'),
                  icon: Icons.snooze,
                  backgroundColor: DementiaColors.ochreBadgeBg,
                  contentColor: DementiaColors.ochreWarmAmber,
                  borderColor: DementiaColors.ochreWarmAmber,
                  minHeight: DementiaDimensions.minTouchTarget,
                  onClick: widget.onSnooze,
                ),
                const SizedBox(height: 12),

                // Caregiver Help Call
                DementiaAccessibleButton(
                  text: context.tr('call_caregiver_help'),
                  icon: Icons.phone_in_talk,
                  backgroundColor: DementiaColors.alertTerracottaBg,
                  contentColor: DementiaColors.alertTerracotta,
                  borderColor: DementiaColors.alertTerracotta,
                  minHeight: 58,
                  onClick: widget.onCallCaregiver,
                ),
              ] else ...[
                // Feedback confirmation state
                Container(
                  width: double.infinity,
                  height: 84,
                  decoration: BoxDecoration(
                    color: DementiaColors.actionForestGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 36),
                      SizedBox(width: 12),
                      Text(
                        context.tr('medicine_confirmed'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
