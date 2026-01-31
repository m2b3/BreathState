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
        color: const Color(0xFF60A5FA), 
        icon: Icons.crop_square_rounded,
        inhale: 4,
        hold: 4,
        exhale: 4,
      ),
      _BreathingOption(
        title: "Equal Breathing",
        description: "Balanced inhale and exhale",
        color: const Color(0xFF34D399), 
        icon: Icons.waves_rounded,
        inhale: 4,
        hold: 0,
        exhale: 4,
      ),
      _BreathingOption(
        title: "4-7-8 Breathing",
        description: "Relaxation and calmness",
        color: const Color(0xFFA78BFA), 
        icon: Icons.nightlight_round,
        inhale: 4,
        hold: 7,
        exhale: 8,
      ),
      _BreathingOption(
        title: "Resonance Frequency",
        description: "Your personalized breathing rate",
        color: const Color(0xFFF472B6), 
        icon: Icons.favorite_rounded,
        inhale: 0,
        hold: 0,
        exhale: 0,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
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
                          color: AppTheme.textDim,
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
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          final freq = ResonanceFrequency.userResonanceFreq;
          if (freq == 0) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.midnightBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text("Resonance Frequency Needed", style: Theme.of(context).textTheme.titleLarge),
                content: Text(
                  "You need to measure your resonance frequency first before starting guided breathing.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.read<NavBarProvider>().changeIndex(2); // Go to Record/Measure
                    },
                    child: Text("Go to Measure", style: TextStyle(color: AppTheme.softTeal)),
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
        padding: const EdgeInsets.all(20),
        borderRadius: 32,
        color: option.color.withOpacity(0.15),
        hasBorder: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(
                    color: option.color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                   ),
                ]
              ),
              child: Icon(option.icon, size: 36, color: option.color),
            ),
            const Spacer(),
            Text(
              option.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12, 
                color: AppTheme.textDim,
                height: 1.2,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
