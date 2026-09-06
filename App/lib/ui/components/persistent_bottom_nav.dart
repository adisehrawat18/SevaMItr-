import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/core/accessibility/accessible_touch_wrapper.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

enum DementiaNavTab { home, games, family }

/// Persistent Bottom Navigation Bar
/// Strictly eliminates hamburger menus, hidden drawers, and gesture slides.
class PersistentBottomNavBar extends StatelessWidget {
  final DementiaNavTab currentTab;
  final ValueChanged<DementiaNavTab> onTabSelected;

  const PersistentBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DementiaColors.paleSageBg,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: DementiaColors.pureSurfaceWhite,
            borderRadius: BorderRadius.circular(DementiaDimensions.pillCornerRadius),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              _buildNavItem(
                tab: DementiaNavTab.home,
                title: context.tr('home_tab'),
                icon: Icons.home,
              ),
              const SizedBox(width: 6),
              _buildNavItem(
                tab: DementiaNavTab.games,
                title: context.tr('games_tab'),
                icon: Icons.psychology,
              ),
              const SizedBox(width: 6),
              _buildNavItem(
                tab: DementiaNavTab.family,
                title: context.tr('family_tab'),
                icon: Icons.call,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required DementiaNavTab tab,
    required String title,
    required IconData icon,
  }) {
    final isSelected = currentTab == tab;

    return Expanded(
      child: AccessibleTouchWrapper(
        semanticLabel: title,
        onTap: () => onTabSelected(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? DementiaColors.primaryKazirangaForest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DementiaDimensions.pillCornerRadius),
            border: isSelected
                ? Border.all(
                    color: DementiaColors.borderCharcoal,
                    width: DementiaDimensions.borderWidthThick,
                  )
                : null,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : DementiaColors.borderCharcoal,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : DementiaColors.borderCharcoal,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
