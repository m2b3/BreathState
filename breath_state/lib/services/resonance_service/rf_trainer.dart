import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:breath_state/widgets/guided_breathing.dart';
import 'package:breath_state/widgets/hrv_result_card.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/services/heart_rate/polar_connect.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:breath_state/services/db_service/database_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  HrvTimeDomainResult? _winningHrv;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
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

  void _finishTest() async {
    final bestRate = widget.rf.getResonanceBreathingRate();
    final winningHrv = widget.rf.getWinningHrvResult();

    developer.log("All rates tested");
    developer.log("RMSSD results: ${widget.rf.rmssdResults}");
    developer.log("Best rate: $bestRate");

    if (winningHrv != null) {
      try {
        await DatabaseService.instance.insertHrvResult(
          sessionId: 'resonance_${DateTime.now().millisecondsSinceEpoch}',
          result: winningHrv,
        );
        developer.log("Winning HRV result saved to database");
      } catch (e) {
        developer.log("Error saving winning HRV: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isRunning = false;
        _winningHrv = winningHrv;
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
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
      backgroundColor: const Color.fromARGB(255, 53, 53, 53),
      appBar: AppBar(
        title: const Text(
          "Resonance Frequency Test",
          style: TextStyle(color: Colors.white), 
        ),
        backgroundColor: const Color.fromARGB(255, 53, 53, 53),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child:
            _isRunning
                ? Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Testing rate: $_currentRate BPM",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        foreground:
                            Paint()
                              ..shader = const LinearGradient(
                                colors: <Color>[
                                  Colors.lightBlueAccent,
                                  Colors.cyanAccent,
                                ],
                              ).createShader(
                                const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                              ),
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),
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
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [Colors.lightBlueAccent, Colors.cyanAccent],
                            ).createShader(bounds),
                        child: const Text(
                          "Test Completed!",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Text(
                        "Best Rate",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        "${widget.rf.getResonanceBreathingRate()} BPM",
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          shadows: [
                            Shadow(
                              blurRadius: 12.0,
                              color: Colors.black54,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                      ),

                      if (_winningHrv != null) ...[
                        const SizedBox(height: 30),
                        HrvResultCard(result: _winningHrv!),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
      ),
    );
  }
}
