import 'dart:async';
import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GuidedBreathing extends StatefulWidget {
  final Duration inhaleDuration;
  final Duration holdDuration;
  final Duration exhaleDuration;

  final bool showStopButton;

  const GuidedBreathing({
    super.key,
    required this.inhaleDuration,
    required this.holdDuration,
    required this.exhaleDuration,
    this.showStopButton = true,
  });

  @override
  State<GuidedBreathing> createState() => _GuidedBreathingState();
}

class _GuidedBreathingState extends State<GuidedBreathing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _phaseTimer;
  Timer? _introTimer;
  Timer? _countdownTimer;

  String _phaseText = "Relax...";
  double minSize = 100;
  double maxSize = 220;

  int _introSecondsLeft = 5;
  int _phaseSecondsLeft = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.inhaleDuration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );

    _introTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_introSecondsLeft == 1) {
        timer.cancel();
        setState(() => _introSecondsLeft = 0);
        _startCycle();
      } else {
        setState(() => _introSecondsLeft--);
      }
    });
  }

  void _startCycle() => _doInhale();

  void _doInhale() {
    if (!mounted) return;
    setState(() => _phaseText = "Inhale");
    _controller.duration = widget.inhaleDuration;
    _startCountdown(widget.inhaleDuration);
    _controller.forward().whenComplete(() {
      if (!mounted) return;
      if (widget.holdDuration == Duration.zero) {
        _doExhale();
        return;
      }
      _doHold(afterInhale: true);
    });
  }

  void _doExhale() {
    if (!mounted) return;
    setState(() => _phaseText = "Exhale");
    _controller.duration = widget.exhaleDuration;
    _startCountdown(widget.exhaleDuration);
    _controller.reverse().whenComplete(() {
      if (!mounted) return;
      if (widget.holdDuration == Duration.zero) {
        _doInhale();
        return;
      }
      _doHold(afterInhale: false);
    });
  }

  void _doHold({required bool afterInhale}) {
    if (!mounted) return;
    setState(() => _phaseText = "Hold");
    _startCountdown(widget.holdDuration);
    _phaseTimer = Timer(widget.holdDuration, () {
      if (!mounted) return;
      if (afterInhale) {
        _doExhale();
      } else {
        _doInhale();
      }
    });
  }

  void _startCountdown(Duration duration) {
    _countdownTimer?.cancel();
    int msLeft = duration.inMilliseconds;
    setState(() => _phaseSecondsLeft = (msLeft / 1000).ceil());

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      msLeft -= 200;
      if (msLeft <= 0) {
        timer.cancel();
        setState(() => _phaseSecondsLeft = 0);
      } else {
        setState(() => _phaseSecondsLeft = (msLeft / 1000).ceil());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _phaseTimer?.cancel();
    _introTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepOceanBlue,
              AppTheme.midnightBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Center(
                child: SizedBox(
                   width: maxSize + 100,
                   height: maxSize + 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                       // Outer glow
                      Container(
                        width: maxSize + 60,
                        height: maxSize + 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.softTeal.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                      ),
                      
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final currentSize = minSize + (maxSize - minSize) * _animation.value;
                          return Container(
                            width: currentSize,
                            height: currentSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.softTeal.withOpacity(0.8),
                                  AppTheme.calmBlue.withOpacity(0.4),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.softTeal.withOpacity(0.4),
                                  blurRadius: 30 + (20 * _animation.value),
                                  spreadRadius: 5 + (10 * _animation.value),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _introSecondsLeft > 0
                                  ? const SizedBox.shrink()
                                  : AnimatedOpacity(
                                      opacity: _phaseSecondsLeft <= 3 ? 0.3 : 1.0, 
                                       duration: const Duration(milliseconds: 300),
                                      child: Text(
                                        '$_phaseSecondsLeft',
                                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontSize: 48,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              Text(
                _introSecondsLeft > 0
                    ? "Relax... $_introSecondsLeft"
                    : _phaseText,
                style: Theme.of(context).textTheme.displayMedium,
              ),

              const Spacer(flex: 2),

              if (widget.showStopButton)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Text("End Session"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
