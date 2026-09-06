import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

/// Caregiver 4-Digit Secure PIN Authentication Modal
class CaregiverPinDialog extends StatefulWidget {
  final String correctPin;
  final VoidCallback onPinSuccess;
  final VoidCallback onDismiss;

  const CaregiverPinDialog({
    super.key,
    this.correctPin = "1234",
    required this.onPinSuccess,
    required this.onDismiss,
  });

  @override
  State<CaregiverPinDialog> createState() => _CaregiverPinDialogState();
}

class _CaregiverPinDialogState extends State<CaregiverPinDialog> {
  String _enteredPin = "";
  bool _isError = false;

  void _onKeyPress(String key) {
    if (key == context.tr('cancel')) {
      widget.onDismiss();
    } else if (key == context.tr('delete')) {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _isError = false;
        });
      }
    } else {
      if (_enteredPin.length < 4) {
        final newPin = _enteredPin + key;
        setState(() {
          _enteredPin = newPin;
          if (newPin.length == 4) {
            if (newPin == widget.correctPin) {
              widget.onPinSuccess();
            } else {
              _isError = true;
              _enteredPin = "";
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      [context.tr('cancel'), "0", context.tr('delete')]
    ];

    return Dialog.fullscreen(
      backgroundColor: DementiaColors.surfaceDarkNavy.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security,
                color: DementiaColors.caregiverShieldGold, size: 64),
            const SizedBox(height: 12),
            Text(
              context.tr('caregiver_mode'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              context.tr('enter_pin'),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? DementiaColors.caregiverShieldGold
                        : Colors.white24,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                );
              }),
            ),

            if (_isError) ...[
              const SizedBox(height: 12),
              Text(
                context.tr('incorrect_pin'),
                style: const TextStyle(
                    color: DementiaColors.alertTerracottaBg,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: 28),

            // Numeric Keypad
            Column(
              children: keys.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map((key) {
                      final isSpecial = key == context.tr('cancel') ||
                          key == context.tr('delete');
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AccessibleTouchWrapper(
                          semanticLabel: "${context.tr('key')} $key",
                          onTap: () => _onKeyPress(key),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: isSpecial
                                  ? DementiaColors.surfaceCardLight
                                  : DementiaColors.surfaceDarkNavy,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: DementiaColors.dividerColor, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              key,
                              style: TextStyle(
                                fontSize: isSpecial ? 15 : 28,
                                fontWeight: FontWeight.bold,
                                color: isSpecial
                                    ? DementiaColors.textPrimaryDark
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
