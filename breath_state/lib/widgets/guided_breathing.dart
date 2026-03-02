import 'dart:async';
import 'dart:ui';
import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GuidedBreathing extends StatefulWidget {
  final Duration inhaleDuration;
  final Duration holdDuration;
  final Duration exhaleDuration;
  final Duration? totalDuration; 
  final double? resonanceFrequency;

  final bool showStopButton;

  const GuidedBreathing({
    super.key,
    required this.inhaleDuration,
    required this.holdDuration,
    required this.exhaleDuration,
    this.totalDuration,
    this.resonanceFrequency,
    this.showStopButton = true,
  });

  @override
  State<GuidedBreathing> createState() => _GuidedBreathingState();
}

class _GuidedBreathingState extends State<GuidedBreathing> {
  Timer? _logicTimer;
  Timer? _introTimer;
  Timer? _countdownTimer;

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

  Timer? _totalSessionTimer;
  int _totalSecondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _currentSize = _minSize;
    _startSize = _minSize;
    _endSize = _minSize;

    _introTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_introSecondsLeft == 1) {
        timer.cancel();
        setState(() => _introSecondsLeft = 0);
        _startCycle();
        _startTotalSessionTimer();
      } else {
        setState(() => _introSecondsLeft--);
      }
    });

    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), _updateAnimation);
  }

  void _startTotalSessionTimer() {
    if (widget.totalDuration == null) return;
    
    _totalSessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _totalSecondsElapsed++;
      });
      
      if (_totalSecondsElapsed >= widget.totalDuration!.inSeconds) {
        timer.cancel();
        _endSessionComplete();
      }
    });
  }

  void _endSessionComplete() {
    if (!mounted) return;
    
    _animationTimer?.cancel();
    _logicTimer?.cancel();
    _countdownTimer?.cancel();
    
    Navigator.of(context).pop();
  }

  void _updateAnimation(Timer timer) {
    if (_phaseStartTime == null || !mounted) return;

    final now = DateTime.now();
    final elapsed = now.difference(_phaseStartTime!);
    
    double t = 0.0;
    if (_currentPhaseDuration.inMilliseconds > 0) {
      t = (elapsed.inMilliseconds / _currentPhaseDuration.inMilliseconds).clamp(0.0, 1.0);
    } else {
      t = 1.0;
    }

    final curveValue = Curves.easeInOutSine.transform(t);

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
    WakelockPlus.disable();
    _animationTimer?.cancel();
    _logicTimer?.cancel();
    _introTimer?.cancel();
    _countdownTimer?.cancel();
    _totalSessionTimer?.cancel();
    super.dispose();
  }

  String _formatTimer() {
    if (widget.totalDuration == null) return '';
    final remaining = widget.totalDuration!.inSeconds - _totalSecondsElapsed;
    final clampedRemaining = remaining < 0 ? 0 : remaining;
    final m = (clampedRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (clampedRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isResonance = widget.resonanceFrequency != null;
    final baseColor = isDark ? Colors.white : AppTheme.darkTeal;
    final dimColor = baseColor.withOpacity(0.6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.deepOceanBlue,
                    AppTheme.midnightBlue,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.paleTeal,
                    Color(0xFFE0F2FE),
                  ],
                ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top-right timer pill (only for non-resonance sessions)
              if (widget.totalDuration != null && !isResonance)
                Positioned(
                  top: 16,
                  right: 24,
                  child: Builder(
                    builder: (context) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: baseColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined, 
                              size: 16, 
                              color: dimColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTimer(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: baseColor,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Resonance frequency label above the bubble
                  if (isResonance)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: AppTheme.roseAccent.withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.resonanceFrequency!.toStringAsFixed(1)} bpm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: dimColor,
                              letterSpacing: 0.5,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),

                  Center(
                    child: SizedBox(
                      width: _maxSize + 100,
                      height: _maxSize + 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
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
                                colors: isDark 
                                    ? [
                                        AppTheme.softTeal.withOpacity(0.8),
                                        AppTheme.calmBlue.withOpacity(0.4),
                                      ]
                                    : [
                                        AppTheme.softTeal.withOpacity(0.85),
                                        AppTheme.calmBlue.withOpacity(0.45),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark 
                                      ? AppTheme.softTeal.withOpacity(0.4)
                                      : AppTheme.calmBlue.withOpacity(0.5),
                                  blurRadius: (_currentSize - _minSize) / (_maxSize - _minSize) * (isDark ? 20 : 30) + (isDark ? 30 : 20),
                                  spreadRadius: (_currentSize - _minSize) / (_maxSize - _minSize) * (isDark ? 10 : 15) + 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _introSecondsLeft > 0
                                  ? const SizedBox.shrink()
                                  : Text(
                                      '$_phaseSecondsLeft',
                                      style: TextStyle(
                                        fontSize: 48,
                                        color: baseColor,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _introSecondsLeft > 0
                        ? "Relax... $_introSecondsLeft"
                        : _phaseText,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: baseColor,
                    ),
                  ),

                  // Elegant inline timer for resonance mode
                  if (isResonance && widget.totalDuration != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _formatTimer(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: dimColor,
                          letterSpacing: 1.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),

                  const Spacer(flex: 2),
                  if (widget.showStopButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: ElevatedButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: baseColor.withOpacity(0.1),
                          foregroundColor: baseColor,
                          side: BorderSide(color: baseColor.withOpacity(0.2)),
                        ),
                        child: const Text("End Session"),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
