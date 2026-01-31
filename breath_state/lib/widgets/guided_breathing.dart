import 'dart:async';
import 'dart:ui';
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

class _GuidedBreathingState extends State<GuidedBreathing> {
  Timer? _logicTimer;
  Timer? _introTimer;
  Timer? _countdownTimer;

  // Manual Animation State
  Timer? _animationTimer;
  DateTime? _phaseStartTime;
  double _startSize = 100.0;
  double _endSize = 100.0;
  Duration _currentPhaseDuration = Duration.zero;

  String _phaseText = "Relax...";
  final double _minSize = 100.0;
  final double _maxSize = 220.0;
  double _currentSize = 100.0;

  int _introSecondsLeft = 5;
  int _phaseSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _currentSize = _minSize;
    _startSize = _minSize;
    _endSize = _minSize;

    _introTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_introSecondsLeft == 1) {
        timer.cancel();
        setState(() => _introSecondsLeft = 0);
        _startCycle();
      } else {
        setState(() => _introSecondsLeft--);
      }
    });

    // Start 60fps manual animation loop
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), _updateAnimation);
  }

  void _updateAnimation(Timer timer) {
    if (_phaseStartTime == null || !mounted) return;

    final now = DateTime.now();
    final elapsed = now.difference(_phaseStartTime!);
    
    // Calculate progress 0.0 to 1.0
    double t = 0.0;
    if (_currentPhaseDuration.inMilliseconds > 0) {
      t = (elapsed.inMilliseconds / _currentPhaseDuration.inMilliseconds).clamp(0.0, 1.0);
    } else {
      t = 1.0;
    }

    // Apply curve manually
    final curveValue = Curves.easeInOutSine.transform(t);

    // Lerp size manually
    final newSize = lerpDouble(_startSize, _endSize, curveValue) ?? _minSize;

    setState(() {
      _currentSize = newSize;
    });
  }

  void _startCycle() => _doInhale();

  void _doInhale() {
    if (!mounted) return;
    setState(() {
      _phaseText = "Inhale";
      // Setup Manual Animation Target
      _phaseStartTime = DateTime.now();
      _startSize = _minSize;
      _endSize = _maxSize;
      _currentPhaseDuration = widget.inhaleDuration;
    });

    _startCountdown(widget.inhaleDuration);
    _logicTimer?.cancel();
    _logicTimer = Timer(widget.inhaleDuration, () {
      if (!mounted) return;
      if (widget.holdDuration == Duration.zero) {
        _doExhale();
      } else {
        _doHold(afterInhale: true);
      }
    });
  }

  void _doExhale() {
    if (!mounted) return;
    setState(() {
      _phaseText = "Exhale";
      // Setup Manual Animation Target
      _phaseStartTime = DateTime.now();
      _startSize = _maxSize;
      _endSize = _minSize;
      _currentPhaseDuration = widget.exhaleDuration;
    });

    _startCountdown(widget.exhaleDuration);
    _logicTimer?.cancel();
    _logicTimer = Timer(widget.exhaleDuration, () {
      if (!mounted) return;
      if (widget.holdDuration == Duration.zero) {
        _doInhale();
      } else {
        _doHold(afterInhale: false);
      }
    });
  }

  void _doHold({required bool afterInhale}) {
    if (!mounted) return;
    setState(() {
      _phaseText = "Hold";
      // Setup Manual Animation Target (Static)
      _phaseStartTime = DateTime.now();
      _startSize = _currentSize;
      _endSize = _currentSize;
      _currentPhaseDuration = widget.holdDuration;
    });
    
    _startCountdown(widget.holdDuration);
    _logicTimer?.cancel();
    _logicTimer = Timer(widget.holdDuration, () {
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

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
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
    _animationTimer?.cancel();
    _logicTimer?.cancel();
    _introTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Manually calculate shadow properties
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
                   width: _maxSize + 100,
                   height: _maxSize + 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                       // Outer glow
                      Container(
                        width: _maxSize + 60,
                        height: _maxSize + 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.softTeal.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                      ),
                      
                      Container(
                        width: _currentSize,
                        height: _currentSize,
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
                              // Snap shadow values based on proximity to max size or interpolate if needed
                              blurRadius: (_currentSize - _minSize) / (_maxSize - _minSize) * 20 + 30, // 30 to 50
                              spreadRadius: (_currentSize - _minSize) / (_maxSize - _minSize) * 10 + 5, // 5 to 15
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
