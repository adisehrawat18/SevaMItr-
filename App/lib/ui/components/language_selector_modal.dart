import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_language.dart';
import 'package:dementia_ner_care/core/localization/location_language_service.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

/// Dementia & Elderly Accessible Language Selection Modal
/// Extra-large touch targets (72dp height), clear state boundaries, and instant audio feedback.
class LanguageSelectorModal extends StatelessWidget {
  const LanguageSelectorModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LanguageSelectorModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locService = LocationLanguageService();

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: DementiaColors.canvasWarmCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: DementiaColors.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Title & Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.language,
                        color: DementiaColors.actionForestGreen, size: 30),
                    SizedBox(width: 10),
                    Text(
                      context.tr('select_language'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: DementiaColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
                AccessibleTouchWrapper(
                  semanticLabel: context.tr('close'),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: DementiaColors.surfaceCardLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: DementiaColors.textPrimaryDark, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // Automatic GPS Re-detect Action Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: AccessibleTouchWrapper(
              semanticLabel: context.tr('auto_detect'),
              onTap: () async {
                Navigator.of(context).pop();
                await locService.detectAndSetLanguageAutomatically(force: true);
                RegionalTtsService().speak(locService.tr('language_updated'));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DementiaColors.ochreBadgeBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: DementiaColors.ochreWarmAmber, width: 2.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location,
                        color: DementiaColors.ochreWarmAmber, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('auto_detect'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: DementiaColors.ochreWarmAmber,
                            ),
                          ),
                          Text(
                            context.tr('auto_detect_description'),
                            style: const TextStyle(
                                fontSize: 13,
                                color: DementiaColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.refresh, color: DementiaColors.ochreWarmAmber),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Divider(color: DementiaColors.dividerColor),
          ),

          // List of Available Languages (72dp touch targets)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              children: AppLanguage.values.map((lang) {
                final isSelected = locService.currentLanguage == lang;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AccessibleTouchWrapper(
                    semanticLabel: "${lang.displayName} language",
                    onTap: () {
                      locService.setLanguage(lang,
                          customRegion: "${lang.regionName} (Manual)");
                      _speakConfirmation(lang);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 72),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DementiaColors.actionGreenLight
                            : DementiaColors.surfaceCardLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? DementiaColors.actionForestGreen
                              : DementiaColors.dividerColor,
                          width: isSelected ? 3.0 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? DementiaColors.actionForestGreen
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: DementiaColors.dividerColor,
                                  width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                lang.code.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected
                                      ? Colors.white
                                      : DementiaColors.textPrimaryDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.displayName,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: DementiaColors.textPrimaryDark,
                                  ),
                                ),
                                Text(
                                  "${context.tr('region')}: ${lang.regionName}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: DementiaColors.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: DementiaColors.actionForestGreen,
                                size: 28),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _speakConfirmation(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.assamese:
        RegionalTtsService().speak("অসমীয়া ভাষা বাছনি কৰা হ'ল।");
        break;
      case AppLanguage.manipuri:
        RegionalTtsService().speak("মণিপুৰী লোন খল্লে।");
        break;
      case AppLanguage.bengali:
        RegionalTtsService().speak("বাংলা ভাষা নির্বাচন করা হয়েছে।");
        break;
      case AppLanguage.khasi:
        RegionalTtsService().speak("La jied ia ka ktien Khasi.");
        break;
      case AppLanguage.mizo:
        RegionalTtsService().speak("Mizo tawng thlan a ni ta.");
        break;
      case AppLanguage.hindi:
        RegionalTtsService().speak("हिन्दी भाषा चुनी गई है।");
        break;
      case AppLanguage.english:
        RegionalTtsService().speak("Language set to English.");
        break;
    }
  }
}
