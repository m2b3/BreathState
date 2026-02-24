import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/guided_breathing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GuidedBreathingScreen extends StatelessWidget {
  const GuidedBreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_BreathingOption> breathingOptions = [
      _BreathingOption(
        title: "Box Breathing",
        description: "Inhale • Hold • Exhale • Hold",
        color: AppTheme.softTeal, 
        icon: Icons.crop_square_rounded,
        inhale: 4,
        hold: 4,
        exhale: 4,
      ),
      _BreathingOption(
        title: "Equal Breathing",
        description: "Balanced inhale and exhale",
        color: AppTheme.calmBlue, 
        icon: Icons.waves_rounded,
        inhale: 4,
        hold: 0,
        exhale: 4,
      ),
      _BreathingOption(
        title: "4-7-8 Breathing",
        description: "Relaxation and calmness",
        color: const Color(0xFF818CF8), 
        icon: Icons.nightlight_round,
        inhale: 4,
        hold: 7,
        exhale: 8,
      ),
      _BreathingOption(
        title: "Resonance Frequency",
        description: "Your personalized breathing rate",
        color: AppTheme.roseAccent, 
        icon: Icons.favorite_rounded,
        inhale: 0,
        hold: 0,
        exhale: 0,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppTheme.darkBackgroundGradient 
              : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "Guided Sessions",
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Select a pattern to begin",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.88,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final option = breathingOptions[index];
                          return _BreathingCard(option: option, index: index);
                        },
                        childCount: breathingOptions.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BreathingOption {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final int inhale;
  final int hold;
  final int exhale;

  _BreathingOption({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.inhale,
    required this.hold,
    required this.exhale,
  });
}

class _BreathingCard extends StatelessWidget {
  final _BreathingOption option;
  final int index;

  const _BreathingCard({required this.option, required this.index});

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgOpacity = isDark ? 0.22 : 0.08; 
    final iconBgOpacity = isDark ? 0.40 : 0.60; 
    final shadowOpacity = isDark ? 0.4 : 0.08;

    return GestureDetector(
      onTap: () {
        if (index == 3) {
          final freq = ResonanceFrequency.userResonanceFreq;
          if (freq == 0) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text("Resonance Frequency Needed", style: Theme.of(context).textTheme.titleLarge),
                content: Text(
                  "You need to measure your resonance frequency first before starting guided breathing.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<NavBarProvider>().changeIndex(2);
                    },
                    child: const Text("Go to Measure", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          } else {
            final cycleDurationMs = (60000 / freq).round();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuidedBreathing(
                  inhaleDuration: Duration(milliseconds: cycleDurationMs ~/ 2),
                  holdDuration: const Duration(milliseconds: 0),
                  exhaleDuration: Duration(milliseconds: cycleDurationMs ~/ 2),
                ),
              ),
            );
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuidedBreathing(
                inhaleDuration: Duration(seconds: option.inhale),
                holdDuration: Duration(seconds: option.hold),
                exhaleDuration: Duration(seconds: option.exhale),
              ),
            ),
          );
        }
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        borderRadius: 28,
        color: option.color.withOpacity(cardBgOpacity),
        hasBorder: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: option.color.withOpacity(iconBgOpacity),
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(
                    color: option.color.withOpacity(shadowOpacity),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                   ),
                ]
              ),
              child: Icon(option.icon, size: 32, color: isDark ? Colors.white : Colors.black),
            ),
            const Spacer(flex: 2),
            Text(
              option.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: isDark 
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black87,
                height: 1.3,
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
