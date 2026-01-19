import 'dart:async';
import 'dart:developer' as developer;
import 'package:breath_state/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:breath_state/widgets/guided_breathing.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/services/heart_rate/polar_connect.dart';

class ResonanceFrequencyTrainer extends StatefulWidget {
  final ResonanceFrequency rf;
  final PolarConnect polar;

  const ResonanceFrequencyTrainer({
    super.key,
    required this.rf,
    required this.polar,
  });

  @override
  State<ResonanceFrequencyTrainer> createState() =>
      _ResonanceFrequencyTrainerState();
}

class _ResonanceFrequencyTrainerState extends State<ResonanceFrequencyTrainer> {
  double _currentRate = 5.0;
  final double _maxRate = 7.0;
  final double _step = 0.2;
  final Duration _testDuration = const Duration(seconds: 90);

  bool _isRunning = false;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _startTest();
  }

  void _startTest() {
    setState(() => _isRunning = true);
    _runStep(); 
  }

  Future<void> _runStep() async {
    if (!mounted || _currentRate > _maxRate) {
      _finishTest();
      return;
    }

    developer.log("Starting test at $_currentRate BPM");

    widget.rf.calculateRMSSDForBreathingRate(
      breathingRate: _currentRate,
      polar: widget.polar,
    );

    _stepTimer = Timer(_testDuration, () {
      if (!mounted) return;

      setState(() {
        _currentRate = double.parse((_currentRate + _step).toStringAsFixed(1));
      });

      _runStep(); 
    });
  }

  void _finishTest() {
    developer.log("All rates tested");
    developer.log("RMSSD results: ${widget.rf.rmssdResults}");
    developer.log("Best rate: ${widget.rf.getResonanceBreathingRate()}");

    if (mounted) {
      setState(() => _isRunning = false);
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel(); 
    try {
      widget.polar.stopRecording();
      developer.log("Polar recording stopped in dispose()");
    } catch (e) {
      developer.log("Error stopping Polar recording in dispose(): $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cycleSeconds = 60.0 / _currentRate;
    final inhaleMs = (cycleSeconds * 500).toInt();
    final exhaleMs = inhaleMs;

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
            children: [
              AppBar(
                title: const Text("Resonance Frequency Test"),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              Expanded(
                child: Center(
                  child: _isRunning
                      ? Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "Testing rate",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "$_currentRate BPM",
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppTheme.calmBlue,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Expanded(
                              child: GuidedBreathing(
                                inhaleDuration: Duration(milliseconds: inhaleMs),
                                holdDuration: Duration.zero,
                                exhaleDuration: Duration(milliseconds: exhaleMs),
                                showStopButton: false,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                               padding: const EdgeInsets.all(24),
                               decoration: BoxDecoration(
                                 color: AppTheme.softTeal.withOpacity(0.1),
                                 shape: BoxShape.circle,
                               ),
                               child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppTheme.softTeal,
                                size: 80,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              "Test Completed!",
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 40),
                            Text(
                              "Best Rate",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${widget.rf.getResonanceBreathingRate()} BPM",
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 56,
                                color: AppTheme.softTeal,
                              ),
                            ),
                            const SizedBox(height: 60),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              ),
                              child: const Text("Done"),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
