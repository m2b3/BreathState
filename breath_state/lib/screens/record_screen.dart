import 'dart:developer' as developer;
import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/services/breath_rate/record.dart';
import 'package:breath_state/services/heart_rate/polar_connect.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:breath_state/services/resonance_service/rf_trainer.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            breathingRate = rate;
            isRecordingBR = false;
          });
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

  Future<void> _stopHRRecording() async {
    final polarConnectProvider = context.read<PolarConnectProvider>();
    PolarConnect? polar = polarConnectProvider.getPolarConnect();
    if (polar != null) {
      try {
        await polar.stopRecording();
        setState(() {
          _hrStream = null;
          isRecordingHR = false;
        });
        developer.log("HR recording stopped");
        _checkStopEffect();
      } catch (e) {
        developer.log("Error stopping HR recording: $e");
      }
    }
    setState(() {
      isRecordingHR = false;
    });
    _checkStopEffect();
  }

  void _checkStopEffect() {
    if (!isRecordingHR && !isRecordingBR) {
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

  void _showRecordDialog() {
    bool recordBR = false;
    bool recordHR = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
              return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text("Select what to record", style: Theme.of(context).textTheme.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withOpacity(0.05) 
                          : AppTheme.softTeal.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text("Breathing Rate", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text("Using Microphone", style: Theme.of(context).textTheme.bodySmall),
                      value: recordBR,
                      activeColor: AppTheme.softTeal,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onChanged: (val) => setStateDialog(() => recordBR = val ?? false),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withOpacity(0.05) 
                          : AppTheme.roseAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                         color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text("Heart Rate", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text("Using Polar Device", style: Theme.of(context).textTheme.bodySmall),
                      value: recordHR,
                      activeColor: AppTheme.roseAccent,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onChanged: (val) => setStateDialog(() => recordHR = val ?? false),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (recordBR || recordHR) {
                      _startRecording(recordBR: recordBR, recordHR: recordHR);
                    }
                  },
                  child: const Text("Start Recording"),
                ),
              ],
            );
          },
        );
      },
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
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 48),

                      Center(
                        child: GestureDetector(
                          onTap: isActive
                              ? (isRecordingHR ? _stopHRRecording : null)
                              : _showRecordDialog,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + (_pulseController.value * 0.1);
                              final shadowOpacity = 0.5 - (_pulseController.value * 0.3);
                              
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 200,
                                  height: 200,
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
                                        blurRadius: 30,
                                        spreadRadius: 10,
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
                                                size: 48,
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
                                                size: 64,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "START",
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

                      const SizedBox(height: 56),

                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.air, color: AppTheme.softTeal, size: 32),
                                  const SizedBox(height: 8),
                                  Text("Breathing Rate", style: Theme.of(context).textTheme.labelMedium),
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
                                     Text("Measuring...", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 10)),
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
                      
                      const SizedBox(height: 24),
                      
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
                      const SizedBox(height: 100),
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
