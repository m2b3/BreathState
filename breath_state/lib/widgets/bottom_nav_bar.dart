import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), 
      child: GlassCard(
        borderRadius: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), 
        color: const Color(0xFF0F172A).withOpacity(0.8), 
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
                  icon: Icons.spa_rounded,
                  label: "Breath",
                  index: 1,
                  currentIndex: navBarProvider.getIndex(),
                  onTap: () => navBarProvider.changeIndex(1),
                ),
                _NavBarItem(
                  icon: Icons.monitor_heart_outlined,
                  activeIcon: Icons.monitor_heart_rounded,
                  label: "Record",
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
    );
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack, 
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12, 
          vertical: 10
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.softTeal.withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (activeIcon ?? icon) : icon,
              color: isSelected ? AppTheme.softTeal : AppTheme.textDim,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.softTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 13, 
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
