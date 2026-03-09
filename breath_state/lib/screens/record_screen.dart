import 'dart:async';
import 'dart:developer' as developer;
import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/services/breath_rate/belt_breath_rate.dart';
import 'package:breath_state/services/breath_rate/record.dart';
import 'package:breath_state/services/heart_rate/polar_connect.dart';
import 'package:breath_state/services/hrv_analysis/hrv_frequency_domain.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/services/resonance_service/rf_trainer.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/hrv_frequency_result_card.dart';
import 'package:breath_state/widgets/hrv_result_card.dart';
import 'package:breath_state/widgets/respiration_waveform_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with SingleTickerProviderStateMixin {
  SoundRecorder? _recorder;
  Stream<int>? _hrStream;
  late AnimationController _pulseController;

  bool isRecordingHR = false;
  bool isRecordingBR = false;
  int breathingRate = -2;

  bool _beltActiveForSession = false;
  String _breathSource = 'Microphone';
  final List<double> _beltForceValues = [];
  StreamSubscription<double>? _beltSub;
  DateTime? _beltStartTime;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _recorder?.dispose();
    _stopHRRecording();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording({
    required bool recordBR,
    required bool recordHR,
  }) async {
    WakelockPlus.enable();

    final gdProvider = context.read<GoDirectProvider>();
    if (gdProvider.isConnected) {
      try {
        await gdProvider.startMeasurements(sensorNumbers: [1], periodMs: 100);
        _beltActiveForSession = true;
        _breathSource = 'Respiration Belt';
        _beltForceValues.clear();
        _beltStartTime = DateTime.now();
        _beltSub = gdProvider.respirationForceStream.listen((v) {
          _beltForceValues.add(v);
        });
      } catch (e) {
        developer.log('Belt start failed, falling back to mic: $e');
        _beltActiveForSession = false;
        _breathSource = 'Microphone';
      }
    } else {
      _beltActiveForSession = false;
      _breathSource = 'Microphone';
    }

    if (recordBR) {
      _recorder = SoundRecorder();
      setState(() {
        breathingRate = -1;
        isRecordingBR = true;
      });
      _pulseController.repeat(reverse: true);
      _recorder!.startRecord().then((rate) {
        if (mounted) {
          setState(() {
            if (_beltActiveForSession && _beltForceValues.length >= 30) {
              final result = estimateBreathRateFromForce(
                _beltForceValues,
                sampleRateHz: 10.0,
              );
              breathingRate = result.bpm.round();
            } else {
              breathingRate = rate;
              _breathSource = 'Microphone';
            }
            isRecordingBR = false;
          });
          _stopBelt();
          _checkStopEffect();
        }
      });
    } else if (_beltActiveForSession) {
      setState(() {
        breathingRate = -1;
        isRecordingBR = true;
      });
      _pulseController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _beltActiveForSession) {
          final result = estimateBreathRateFromForce(
            _beltForceValues,
            sampleRateHz: 10.0,
          );
          setState(() {
            breathingRate = result.bpm.round();
            isRecordingBR = false;
          });
          _stopBelt();
          _checkStopEffect();
        }
      });
    }

    if (recordHR) {
      final polarConnectProvider = context.read<PolarConnectProvider>();
      PolarConnect? polar = polarConnectProvider.getPolarConnect();
      if (polar == null) {
        if (mounted) {
          _showNotConnectedDialog();
        }
      } else {
        try {
          final hrStream = await polar.getHeartRate();
          setState(() {
            _hrStream = hrStream;
            isRecordingHR = true;
          });
          if (!isRecordingBR) {
            _pulseController.repeat(reverse: true);
          }
          developer.log("HR recording started");
        } catch (e) {
          developer.log("HR recording error: $e");
        }
      }
    }
  }

  Future<void> _stopBelt() async {
    _beltSub?.cancel();
    _beltSub = null;
    final gdProvider = context.read<GoDirectProvider>();
    if (gdProvider.isStreaming) {
      await gdProvider.stopMeasurements();
    }
    _beltActiveForSession = false;
  }

  Future<void> _stopHRRecording() async {
    final polarConnectProvider = context.read<PolarConnectProvider>();
    PolarConnect? polar = polarConnectProvider.getPolarConnect();
    if (polar != null) {
      try {
        final rrIntervals = List<double>.from(polar.sessionRrIntervals);

        await polar.stopRecording();
        final hrvResult = polar.lastSessionHrv;
        setState(() {
          _hrStream = null;
          isRecordingHR = false;
        });
        developer.log("HR recording stopped");
        _checkStopEffect();

        if (hrvResult != null && mounted) {
          HrvFrequencyDomainResult? freqResult;
          try {
            freqResult = HrvFrequencyDomainAnalyzer.analyze(rrIntervals);
          } catch (e) {
            debugPrint('Frequency-domain HRV skipped: $e');
          }

          _showHrvResultSheet(hrvResult, freqResult);
        }
      } catch (e) {
        developer.log("Error stopping HR recording: $e");
      }
    }
    setState(() {
      isRecordingHR = false;
    });
    _checkStopEffect();
  }

  void _showHrvResultSheet(
    HrvTimeDomainResult result, [
    HrvFrequencyDomainResult? freqResult,
  ]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.midnightBlue : AppTheme.pureWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Session Results",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                HrvResultCard(result: result),
                if (freqResult != null) ...[
                  const SizedBox(height: 16),
                  HrvFrequencyResultCard(result: freqResult),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkStopEffect() {
    if (!isRecordingHR && !isRecordingBR) {
      WakelockPlus.disable();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _showNotConnectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Device Not Connected", style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          "Please connect to the Polar device in Settings.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NavBarProvider>().changeIndex(3);
            },
            child: const Text("Go to Settings", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleStartRecording() {
    final gdProvider = context.read<GoDirectProvider>();
    final isBeltConnected = gdProvider.isConnected;

    if (isBeltConnected) {
      _startRecording(recordBR: true, recordHR: true);
    } else {
      _showMicFallbackCaution();
    }
  }

  void _showMicFallbackCaution() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Colors.amber.shade600,
          size: 48,
        ),
        title: Text(
          "Respiration Belt Not Connected",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Breathing rate will be measured using the microphone, which may be less accurate.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.softTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.softTeal.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.air_rounded, color: AppTheme.softTeal, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Connect a Vernier Go Direct Respiration Belt for better accuracy.",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.softTeal,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NavBarProvider>().changeIndex(3);
            },
            child: const Text("Go to Settings"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startRecording(recordBR: true, recordHR: true);
            },
            child: const Text("Continue with Mic"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = isRecordingBR || isRecordingHR;

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
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Live Record",
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Monitor your biometrics in real-time.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: GestureDetector(
                          onTap: isActive
                              ? (isRecordingHR ? _stopHRRecording : null)
                              : _handleStartRecording,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + (_pulseController.value * 0.1);
                              final shadowOpacity = 0.5 - (_pulseController.value * 0.3);
                              
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isActive
                                          ? [AppTheme.coralRose, AppTheme.roseAccent]
                                          : [AppTheme.softTeal, AppTheme.calmBlue],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isActive
                                            ? AppTheme.coralRose.withOpacity(shadowOpacity)
                                            : AppTheme.softTeal.withOpacity(shadowOpacity),
                                        blurRadius: 15, 
                                        spreadRadius: 2, 
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: isActive
                                        ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.mic,
                                                size: 32,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Recording...",
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isRecordingHR)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    "Tap to stop HR",
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 48,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "START",
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.air, color: AppTheme.softTeal, size: 32),
                                  const SizedBox(height: 8),
                                  Text("Breath Rate", style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 8),
                                  if (breathingRate == -1)
                                     const SizedBox(
                                       height: 24, 
                                       width: 24, 
                                       child: CircularProgressIndicator(strokeWidth: 2)
                                     )
                                  else
                                    Text(
                                      breathingRate > 0 ? "$breathingRate bpm" : "--",
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppTheme.softTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (isRecordingBR)
                                     Text("Measuring...", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10))
                                  else if (breathingRate > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _breathSource == 'Respiration Belt'
                                            ? AppTheme.softTeal.withOpacity(0.15)
                                            : AppTheme.calmBlue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _breathSource == 'Respiration Belt' ? 'Belt ✓' : 'Mic',
                                        style: TextStyle(
                                          color: _breathSource == 'Respiration Belt'
                                              ? AppTheme.softTeal
                                              : AppTheme.calmBlue,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.favorite, color: AppTheme.roseAccent, size: 32),
                                  const SizedBox(height: 8),
                                  Text("Heart Rate", style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 8),
                                  StreamBuilder<int>(
                                    stream: _hrStream,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting && isRecordingHR) {
                                        return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2));
                                      }
                                      return Text(
                                        snapshot.hasData ? "${snapshot.data} bpm" : "--",
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: AppTheme.roseAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                   const SizedBox(height: 4),
                                   if (isRecordingHR)
                                     Text("Live", style: TextStyle(color: AppTheme.coralRose, fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      Consumer<GoDirectProvider>(
                        builder: (context, gdProvider, _) {
                          if (!gdProvider.isStreaming) {
                            return const SizedBox.shrink();
                          }
                          return RespirationWaveformCard(
                            forceStream: gdProvider.respirationForceStream,
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      
                      Consumer<PolarConnectProvider>(
                        builder: (context, provider, child) {
                          return GlassCard(
                            padding: EdgeInsets.zero,
                            color: Theme.of(context).primaryColor,
                            child: InkWell(
                              onTap: () {
                                 _stopHRRecording();
                                 
                                 final polar = provider.getPolarConnect();
                                 if (polar != null) {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (context) => ResonanceFrequencyTrainer(
                                         rf: ResonanceFrequency(),
                                         polar: polar,
                                       ),
                                     ),
                                   );
                                 } else {
                                    _showNotConnectedDialog();
                                 }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.favorite_rounded, 
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Resonance Frequency",
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Train your optimal breathing rate",
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios, 
                                      size: 16, 
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
