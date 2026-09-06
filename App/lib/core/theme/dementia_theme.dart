import 'package:flutter/material.dart';

/// SevaMitr Neo-Brutalist Organic Healthtech Design System Colors
/// Rooted in the North Eastern Region of India (Assam, Kaziranga, Majuli).
/// High contrast, dementia-safe, with hard solid borders and offsets.
class DementiaColors {
  // Primary Palette
  static const Color primaryKazirangaForest = Color(0xFF214935); // --color-primary
  static const Color primaryKazirangaDark = Color(0xFF1B4332);
  static const Color primaryTeaGardenLeaf = Color(0xFF2D6A4F);   // --color-primary-light
  static const Color primaryMintSoft = Color(0xFFE8F5E9);        // --color-primary-soft
  static const Color paleSageBg = Color(0xFFF4F7F4);             // --color-bg (Low glare canvas)
  static const Color pureSurfaceWhite = Color(0xFFFFFFFF);       // --color-surface
  static const Color mutedStoneSand = Color(0xFFE5DFD5);         // --color-surface-subtle
  static const Color inputBg = Color(0xFFFCFBF9);                // Neo-form input background

  // Text & Border Tokens
  static const Color borderCharcoal = Color(0xFF1C1B1B);         // --color-border, all 2px borders & shadows
  static const Color textMainCharcoal = Color(0xFF1C1B1B);       // --color-text-main
  static const Color textMutedSlate = Color(0xFF57534E);         // --color-text-muted
  static const Color textDimStone = Color(0xFF78716C);           // --color-text-dim
  static const Color borderSubtle = Color(0xFFDBE6DD);           // --color-border-subtle

  // Vibrant Accents & Pill Badges
  static const Color terracotta = Color(0xFFFE8357);             // UFOV / Action required
  static const Color terracottaDark = Color(0xFFC85A32);
  static const Color amberMuga = Color(0xFFF0BC93);              // Auditory / Tips
  static const Color amberMugaLight = Color(0xFFFBEFAF);
  static const Color herbalMint = Color(0xFFC0EDD1);             // Attention / Success
  static const Color herbalMintDark = Color(0xFF073220);
  static const Color skyGlacier = Color(0xFFE0F2FE);             // Speed / Search / Telemetry
  static const Color skyGlacierDark = Color(0xFF0369A1);
  static const Color gentleLavender = Color(0xFFE9D5FF);         // Category / Doctor report
  static const Color gentleLavenderDark = Color(0xFF581C87);
  static const Color gentleRose = Color(0xFFFEE2E2);             // Alerts / Sundowning
  static const Color gentleRoseDark = Color(0xFF991B1B);

  // Backwards compatibility aliases for existing screens
  static const Color canvasWarmCream = paleSageBg;
  static const Color surfaceCardLight = pureSurfaceWhite;
  static const Color surfaceDarkNavy = borderCharcoal;
  static const Color textPrimaryDark = textMainCharcoal;
  static const Color textSecondaryDark = textMutedSlate;
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color actionForestGreen = primaryKazirangaForest;
  static const Color actionGreenLight = primaryMintSoft;
  static const Color textOnActionGreen = Color(0xFFFFFFFF);
  static const Color alertTerracotta = terracottaDark;
  static const Color alertTerracottaBg = gentleRose;
  static const Color textOnAlert = Color(0xFFFFFFFF);
  static const Color ochreWarmAmber = amberMuga;
  static const Color ochreBadgeBg = amberMugaLight;
  static const Color voiceAssistanceBlue = Color(0xFF0F4C81);
  static const Color voiceAssistanceBg = skyGlacier;
  static const Color dividerColor = borderCharcoal;
  static const Color caregiverShieldGold = primaryKazirangaForest;
  static const Color focusBorderHighlight = primaryTeaGardenLeaf;
}

/// SevaMitr Neo-Brutalist Geometry, Shadows & Elevation Rules
class DementiaDimensions {
  static const double minTouchTarget = 56.0;
  static const double alertTouchTarget = 78.0;
  static const double iconSizeLarge = 38.0;
  static const double iconSizeExtraLarge = 52.0;

  // Neo-Brutalism Rules from DESIGN_SYSTEM.md:
  // 1. Every card, button, pill, input uses 2px solid #1c1b1b
  static const double borderWidthThick = 2.0;
  static const double borderSubtleWidth = 1.5;

  // 2. Shadows are completely opaque with zero blur:
  static const double shadowOffsetSmall = 2.0; // Pills & chips: 2px 2px 0px #1c1b1b
  static const double shadowOffsetStandard = 3.0; // Standard buttons: 3px 3px 0px #1c1b1b
  static const double shadowOffsetCard = 4.0; // Standard cards: 4px 4px 0px #1c1b1b
  static const double shadowOffsetActive = 1.0; // Active / pressed: 1px 1px 0px #1c1b1b

  // 3. Corner Radiuses:
  static const double cardCornerRadius = 24.0; // Cards & containers: 24px or 26px
  static const double inputCornerRadius = 12.0; // Input fields & icon boxes: 12px or 16px
  static const double pillCornerRadius = 9999.0; // Pills, buttons & bottom dock: full pill

  static const double standardPadding = 20.0;
}

class DementiaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DementiaColors.paleSageBg,
      colorScheme: const ColorScheme.light(
        primary: DementiaColors.primaryKazirangaForest,
        onPrimary: Colors.white,
        primaryContainer: DementiaColors.primaryMintSoft,
        onPrimaryContainer: DementiaColors.primaryKazirangaForest,
        secondary: DementiaColors.amberMuga,
        surface: DementiaColors.pureSurfaceWhite,
        error: DementiaColors.gentleRoseDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DementiaColors.paleSageBg,
        foregroundColor: DementiaColors.textMainCharcoal,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: DementiaColors.pureSurfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DementiaDimensions.cardCornerRadius),
          side: const BorderSide(
            color: DementiaColors.borderCharcoal,
            width: DementiaDimensions.borderWidthThick,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DementiaColors.borderCharcoal,
        thickness: DementiaDimensions.borderWidthThick,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DementiaColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          color: DementiaColors.textMainCharcoal,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: DementiaColors.textDimStone,
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DementiaDimensions.inputCornerRadius),
          borderSide: const BorderSide(
            color: DementiaColors.borderCharcoal,
            width: DementiaDimensions.borderWidthThick,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DementiaDimensions.inputCornerRadius),
          borderSide: const BorderSide(
            color: DementiaColors.borderCharcoal,
            width: DementiaDimensions.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DementiaDimensions.inputCornerRadius),
          borderSide: const BorderSide(
            color: DementiaColors.gentleRoseDark,
            width: DementiaDimensions.borderWidthThick,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DementiaDimensions.inputCornerRadius),
          borderSide: const BorderSide(
            color: DementiaColors.gentleRoseDark,
            width: DementiaDimensions.borderWidthThick,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: DementiaColors.borderCharcoal,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: DementiaColors.textMainCharcoal,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: DementiaColors.textMainCharcoal,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: DementiaColors.textMainCharcoal,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DementiaColors.textMainCharcoal,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: DementiaColors.textMutedSlate,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
