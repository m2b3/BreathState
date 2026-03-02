import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/guided_breathing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({super.key});

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen> {

  void _startSession(BuildContext context, int index, _BreathingOption option, int durationMinutes) {
    if (index == 0) {
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
                  context.read<NavBarProvider>().changeIndex(1);
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
              totalDuration: Duration(minutes: durationMinutes),
              resonanceFrequency: freq,
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
            totalDuration: Duration(minutes: durationMinutes),
          ),
        ),
      );
    }
  }

  void _showDurationPicker(BuildContext context, int index, _BreathingOption option) {
    int selectedVal = 5;
    final scrollController = FixedExtentScrollController(initialItem: 4); // index 4 = 5 min

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.only(top: 20, bottom: 28, left: 24, right: 24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.midnightBlue : AppTheme.pureWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Session Duration",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Scroll to select duration",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Highlight band for selection
                        Container(
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 60),
                          decoration: BoxDecoration(
                            color: AppTheme.softTeal.withOpacity(isDark ? 0.15 : 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.softTeal.withOpacity(isDark ? 0.3 : 0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Scroll wheel
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 180,
                              child: ListWheelScrollView.useDelegate(
                                controller: scrollController,
                                itemExtent: 48,
                                perspective: 0.003,
                                diameterRatio: 1.4,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (i) {
                                  setModalState(() => selectedVal = i + 1);
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (context, i) {
                                    final val = i + 1;
                                    final isSelected = val == selectedVal;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 28 : 20,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                          color: isSelected
                                              ? (isDark ? Colors.white : Colors.black)
                                              : (isDark ? Colors.white38 : Colors.black26),
                                        ),
                                        child: Text('$val'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "min",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                        // Top and bottom fade overlays
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 50,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (isDark ? AppTheme.midnightBlue : AppTheme.pureWhite),
                                    (isDark ? AppTheme.midnightBlue : AppTheme.pureWhite).withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 50,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    (isDark ? AppTheme.midnightBlue : AppTheme.pureWhite),
                                    (isDark ? AppTheme.midnightBlue : AppTheme.pureWhite).withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startSession(context, index, option, selectedVal);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.softTeal,
                      ),
                      child: const Text("Start"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_BreathingOption> breathingOptions = [
      _BreathingOption(
        title: "Resonance Frequency",
        description: "Your personalized breathing rate",
        color: AppTheme.roseAccent, 
        icon: Icons.favorite_rounded,
        inhale: 0,
        hold: 0,
        exhale: 0,
      ),
      _BreathingOption(
        title: "Box Breathing",
        description: "• Inhale • Hold\n• Exhale • Hold",
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
        icon: Icons.balance_rounded,
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
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final option = breathingOptions[index];
                          return _BreathingCard(
                            option: option, 
                            index: index,
                            onStart: (duration) => _startSession(context, index, option, duration),
                            onSettingsTap: () => _showDurationPicker(context, index, option),
                          );
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
  final Function(int) onStart;
  final VoidCallback onSettingsTap;

  const _BreathingCard({
    required this.option, 
    required this.index,
    required this.onStart,
    required this.onSettingsTap,
  });

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgOpacity = isDark ? 0.22 : 0.08; 
    final iconBgOpacity = isDark ? 0.40 : 0.60; 
    final shadowOpacity = isDark ? 0.4 : 0.08;

    return GestureDetector(
      onTap: () => onStart(5),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        borderRadius: 28,
        color: option.color.withOpacity(cardBgOpacity),
        hasBorder: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            Container(
              padding: const EdgeInsets.all(12),
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
              child: Icon(option.icon, size: 28, color: isDark ? Colors.white : Colors.black),
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
            const SizedBox(height: 4),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "5 mins",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: option.color,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Prevent card tap trigger
                  },
                  child: IconButton(
                    icon: Icon(
                      Icons.settings_rounded, 
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    onPressed: onSettingsTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
