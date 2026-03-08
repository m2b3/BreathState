import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28), 
        child: GlassCard(
          borderRadius: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), 
          color: isDark 
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.9),
        child: Consumer<NavBarProvider>(
          builder: (context, navBarProvider, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  index: 0,
                  currentIndex: navBarProvider.getIndex(),
                  onTap: () => navBarProvider.changeIndex(0),
                ),
                _NavBarItem(
                  icon: Icons.monitor_heart_outlined,
                  activeIcon: Icons.monitor_heart_rounded,
                  label: "Record",
                  index: 1,
                  currentIndex: navBarProvider.getIndex(),
                  onTap: () => navBarProvider.changeIndex(1),
                ),
                _NavBarItem(
                  icon: Icons.spa_rounded,
                  label: "Breath",
                  index: 2,
                  currentIndex: navBarProvider.getIndex(),
                  onTap: () => navBarProvider.changeIndex(2),
                ),
                _NavBarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: "Settings",
                  index: 3,
                  currentIndex: navBarProvider.getIndex(),
                  onTap: () => navBarProvider.changeIndex(3),
                ),
              ],
            );
          },
        ),
      ),
    ));
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeColor = AppTheme.softTeal;
    final inactiveColor = isDark 
        ? Colors.white.withOpacity(0.45)
        : Colors.black.withOpacity(0.4);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic, 
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12, 
          vertical: 10
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withOpacity(isDark ? 0.2 : 0.12) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [
            BoxShadow(
              color: activeColor.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? (activeIcon ?? icon) : icon,
                key: ValueKey(isSelected),
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: isSelected 
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: activeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13, 
                          ),
                    ),
                  )
                : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
