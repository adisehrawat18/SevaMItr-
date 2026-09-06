import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';

/// Master Neo-Brutalist Card Component
/// Solid 2px #1C1B1B border, unblurred 4px drop shadow, 24px corner radius.
class NeoCard extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double shadowOffset;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = DementiaColors.pureSurfaceWhite,
    this.borderColor = DementiaColors.borderCharcoal,
    this.shadowColor = DementiaColors.borderCharcoal,
    this.shadowOffset = DementiaDimensions.shadowOffsetCard,
    this.borderRadius = DementiaDimensions.cardCornerRadius,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveOffset = _isPressed && widget.onTap != null
        ? DementiaDimensions.shadowOffsetActive
        : widget.shadowOffset;
    final translateDelta = _isPressed && widget.onTap != null
        ? widget.shadowOffset - DementiaDimensions.shadowOffsetActive
        : 0.0;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: Transform.translate(
        offset: Offset(translateDelta, translateDelta),
        child: Container(
          width: double.infinity,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.borderColor,
              width: DementiaDimensions.borderWidthThick,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                offset: Offset(effectiveOffset, effectiveOffset),
                blurRadius: 0,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Neo-Brutalist Pill Badge
/// Pill radius (9999px), 2px solid border, 2px drop shadow.
enum NeoPillVariant { green, terracotta, amber, purple, charcoal, rose, white }

class NeoPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final NeoPillVariant variant;
  final Color? customBg;
  final Color? customFg;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const NeoPill({
    super.key,
    required this.text,
    this.icon,
    this.variant = NeoPillVariant.green,
    this.customBg,
    this.customFg,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case NeoPillVariant.green:
        bg = DementiaColors.primaryKazirangaForest;
        fg = Colors.white;
        break;
      case NeoPillVariant.terracotta:
        bg = DementiaColors.terracotta;
        fg = DementiaColors.borderCharcoal;
        break;
      case NeoPillVariant.amber:
        bg = DementiaColors.amberMuga;
        fg = DementiaColors.borderCharcoal;
        break;
      case NeoPillVariant.purple:
        bg = DementiaColors.gentleLavender;
        fg = DementiaColors.gentleLavenderDark;
        break;
      case NeoPillVariant.charcoal:
        bg = DementiaColors.borderCharcoal;
        fg = Colors.white;
        break;
      case NeoPillVariant.rose:
        bg = DementiaColors.gentleRose;
        fg = DementiaColors.gentleRoseDark;
        break;
      case NeoPillVariant.white:
        bg = Colors.white;
        fg = DementiaColors.borderCharcoal;
        break;
    }

    if (customBg != null) bg = customBg!;
    if (customFg != null) fg = customFg!;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fg, size: fontSize + 4),
            const SizedBox(width: 6),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactile Neo-Brutalist Primary Action Button
/// Realistic push-down on click, 2px border, 3px solid shadow.
class NeoButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool fullWidth;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const NeoButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.backgroundColor = DementiaColors.primaryKazirangaForest,
    this.textColor = Colors.white,
    this.borderColor = DementiaColors.borderCharcoal,
    this.borderRadius = DementiaDimensions.pillCornerRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final effectiveShadow = _isPressed && isEnabled
        ? DementiaDimensions.shadowOffsetActive
        : DementiaDimensions.shadowOffsetStandard;
    final translateDelta = _isPressed && isEnabled
        ? DementiaDimensions.shadowOffsetStandard - DementiaDimensions.shadowOffsetActive
        : 0.0;

    Widget buttonContent = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, color: widget.textColor, size: 22),
          const SizedBox(width: 10),
        ],
        Text(
          widget.text.toUpperCase(),
          style: TextStyle(
            color: widget.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: Transform.translate(
        offset: Offset(translateDelta, translateDelta),
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: isEnabled ? widget.backgroundColor : DementiaColors.mutedStoneSand,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.borderColor,
              width: DementiaDimensions.borderWidthThick,
            ),
            boxShadow: [
              BoxShadow(
                color: DementiaColors.borderCharcoal,
                offset: Offset(effectiveShadow, effectiveShadow),
                blurRadius: 0,
              ),
            ],
          ),
          child: buttonContent,
        ),
      ),
    );
  }
}

/// Spaced-Out Header Icon & Badge Pair
/// Section 5.D of DESIGN_SYSTEM.md
class NeoHeaderBadgePair extends StatelessWidget {
  final IconData icon;
  final String badgeText;
  final Color iconBg;
  final Color iconColor;
  final Color badgeBg;
  final Color badgeColor;

  const NeoHeaderBadgePair({
    super.key,
    this.icon = Icons.person_add_alt_1,
    this.badgeText = 'PATIENT REGISTRATION REQUIRED',
    this.iconBg = DementiaColors.primaryMintSoft,
    this.iconColor = DementiaColors.primaryKazirangaForest,
    this.badgeBg = DementiaColors.primaryKazirangaForest,
    this.badgeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 52x52 Icon Box
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DementiaColors.borderCharcoal,
              width: DementiaDimensions.borderWidthThick,
            ),
            boxShadow: const [
              BoxShadow(
                color: DementiaColors.borderCharcoal,
                offset: Offset(
                  DementiaDimensions.shadowOffsetStandard,
                  DementiaDimensions.shadowOffsetStandard,
                ),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 14),
        // Aligned Neo-Pill Badge
        NeoPill(
          text: badgeText,
          customBg: badgeBg,
          customFg: badgeColor,
          fontSize: 13,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ],
    );
  }
}

/// Segmented Toggle Switcher (e.g. Female / Male / Other, or Stages)
/// Section 5.E of DESIGN_SYSTEM.md
class NeoSegmentedToggle<T> extends StatelessWidget {
  final List<T> items;
  final T selectedItem;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final String Function(T)? subLabelBuilder;

  const NeoSegmentedToggle({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    required this.labelBuilder,
    this.subLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) {
        final isSelected = item == selectedItem;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DementiaColors.primaryKazirangaForest
                      : DementiaColors.pureSurfaceWhite,
                  borderRadius: BorderRadius.circular(DementiaDimensions.inputCornerRadius),
                  border: Border.all(
                    color: DementiaColors.borderCharcoal,
                    width: DementiaDimensions.borderWidthThick,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: DementiaColors.borderCharcoal,
                            offset: Offset(
                              DementiaDimensions.shadowOffsetSmall,
                              DementiaDimensions.shadowOffsetSmall,
                            ),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labelBuilder(item),
                      style: TextStyle(
                        color: isSelected ? Colors.white : DementiaColors.borderCharcoal,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subLabelBuilder != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subLabelBuilder!(item),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : DementiaColors.textDimStone,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Supervising Caregiver Callout Box
class NeoSupervisorCallout extends StatelessWidget {
  final String caregiverName;

  const NeoSupervisorCallout({
    super.key,
    required this.caregiverName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DementiaColors.paleSageBg,
        borderRadius: BorderRadius.circular(DementiaDimensions.inputCornerRadius),
        border: Border.all(
          color: DementiaColors.primaryKazirangaForest,
          width: DementiaDimensions.borderSubtleWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user,
            color: DementiaColors.primaryKazirangaForest,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: DementiaColors.primaryKazirangaForest,
                  fontSize: 13,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'This patient will be supervised under '),
                  TextSpan(
                    text: caregiverName.isNotEmpty ? caregiverName : 'Primary Caregiver',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(
                    text: '. Daily cognitive metrics and activity sessions will automatically stream to your caregiver dashboard.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
