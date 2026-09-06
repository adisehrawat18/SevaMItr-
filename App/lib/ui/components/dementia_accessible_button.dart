import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';

/// Accessible Large Button Component for Elderly & Dementia Patients
class DementiaAccessibleButton extends StatefulWidget {
  final String text;
  final String? subText;
  final IconData? icon;
  final Color backgroundColor;
  final Color contentColor;
  final Color borderColor;
  final double minHeight;
  final VoidCallback onClick;

  const DementiaAccessibleButton({
    super.key,
    required this.text,
    this.subText,
    this.icon,
    this.backgroundColor = DementiaColors.primaryKazirangaForest,
    this.contentColor = Colors.white,
    this.borderColor = DementiaColors.borderCharcoal,
    this.minHeight = DementiaDimensions.minTouchTarget,
    required this.onClick,
  });

  @override
  State<DementiaAccessibleButton> createState() =>
      _DementiaAccessibleButtonState();
}

class _DementiaAccessibleButtonState extends State<DementiaAccessibleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = _isPressed
        ? DementiaDimensions.shadowOffsetActive
        : DementiaDimensions.shadowOffsetStandard;
    final translateDelta = _isPressed
        ? DementiaDimensions.shadowOffsetStandard -
            DementiaDimensions.shadowOffsetActive
        : 0.0;

    return AccessibleTouchWrapper(
      semanticLabel: "${widget.text} ${widget.subText ?? ''}",
      onTap: widget.onClick,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Transform.translate(
          offset: Offset(translateDelta, translateDelta),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius:
                  BorderRadius.circular(DementiaDimensions.cardCornerRadius),
              border: Border.all(
                color: widget.borderColor,
                width: DementiaDimensions.borderWidthThick,
              ),
              boxShadow: [
                BoxShadow(
                  color: DementiaColors.borderCharcoal,
                  blurRadius: 0,
                  offset: Offset(effectiveShadow, effectiveShadow),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.contentColor, size: 32),
                  const SizedBox(width: 14),
                ],
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: widget.icon != null
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.contentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        textAlign: widget.icon != null
                            ? TextAlign.start
                            : TextAlign.center,
                      ),
                      if (widget.subText != null &&
                          widget.subText!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subText!,
                          style: TextStyle(
                            color: widget.contentColor.withValues(alpha: 0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: widget.icon != null
                              ? TextAlign.start
                              : TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
