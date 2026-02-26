import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:polar/polar.dart';
import 'package:breath_state/services/heart_rate/polar_connect.dart';
import 'package:breath_state/services/file_service/file_write.dart';
import 'package:breath_state/constants/file_constants.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';

class ResonanceFrequency {

  static double userResonanceFreq=0;
  final List<PolarEcgSample> _ecgBuffer = [];
  final List<int> _rPeaksTimestamps = [];

  final Map<double, double> rmssdResults = {};
  final Map<double, HrvTimeDomainResult> hrvResults = {};

  final int _timeInterval = 65;//TODO- To be changed

  final int _smoothWindowSize = 10;
  final int _minGapMs = 200;

  PolarConnect? _polar;
  StreamSubscription? _ecgSub;

  final fileWriter = FileWriterService();

  ResonanceFrequency();

  Future<void> _getEcgData() async {
    if (_polar == null) {
      developer.log("Polar device not set!");
      return;
    }
    final ecgStream = await _polar!.getECG();
    _ecgSub = ecgStream.listen(
      (sampleBatch) {
        _ecgBuffer.addAll(sampleBatch);
      },
      onError: (err) {
        developer.log("ECG Stream Error: $err");
      },
    );
  }

  Future<void> calculateRMSSDForBreathingRate({
    required double breathingRate,
    required PolarConnect polar,
  }) async {
    _polar = polar;
    _ecgBuffer.clear();

    developer.log(
      "Starting ECG collection for breathing rate $breathingRate...",
    );
    await _getEcgData();

    await Future.delayed(Duration(seconds: _timeInterval));

    await polar.stopRecording();

    developer.log("ECG data so far: ${_ecgBuffer.length} samples");

    List<double> smoothed = _detectRPeaks(_ecgBuffer);

    try {
      final timestamp = DateTime.now().toIso8601String();
      final data = {
        "timestamp": timestamp,
        "breathingRate": breathingRate,
        "ecgSmoothed": smoothed,
      };
      await fileWriter.writeStringToFile(
        jsonEncode(data),
        ECG_FILE_NAME, 
      );
    } catch (e) {
      developer.log("Error saving ECG data: $e");
    }
    List<double> rrIntervals = [];
    for (int i = 1; i < _rPeaksTimestamps.length; i++) {
      final interval = (_rPeaksTimestamps[i] - _rPeaksTimestamps[i - 1]).toDouble();
      rrIntervals.add(interval);
      developer.log("RR Interval ${i - 1}: ${interval.toInt()} ms");
    }

    if (rrIntervals.length >= 2) {
      final hrvResult = HrvTimeDomain.compute(rrIntervals);
      rmssdResults[breathingRate] = hrvResult.rmssd;
      hrvResults[breathingRate] = hrvResult;
      developer.log("RMSSD at $breathingRate BPM breathing: ${hrvResult.rmssd}");
    } else {
      rmssdResults[breathingRate] = 0.0;
      developer.log("Not enough RR intervals at $breathingRate BPM");
    }

    await _ecgSub?.cancel();
  }

  List<double> _detectRPeaks(List<PolarEcgSample> samples) {
    _rPeaksTimestamps.clear();

    List<double> smoothed = [];
    for (int i = 0; i < samples.length; i++) {
      int start = (i - _smoothWindowSize ~/ 2).clamp(0, samples.length - 1);
      int end = (i + _smoothWindowSize ~/ 2).clamp(0, samples.length - 1);
      double sum = 0;
      for (int j = start; j <= end; j++) {
        sum += samples[j].voltage.toDouble();
      }
      smoothed.add(double.parse((sum / (end - start + 1)).toStringAsFixed(3)));
    }

    double avgVoltage = smoothed.reduce((a, b) => a + b) / smoothed.length;

    bool above = false;
    int lastPeakTime = -_minGapMs;

    for (int i = 0; i < smoothed.length; i++) {
      double val = smoothed[i];
      int timeMs = samples[i].timeStamp.millisecondsSinceEpoch;

      if (!above && val > avgVoltage) {
        if (timeMs - lastPeakTime >= _minGapMs) {
          _rPeaksTimestamps.add(timeMs);
          lastPeakTime = timeMs;
        }
        above = true;
      } else if (above && val < avgVoltage) {
        above = false;
      }
    }
    return smoothed;
  }

  double getResonanceBreathingRate() {
    if (rmssdResults.isEmpty) {
      developer.log("No RMSSD results available.");
      return 0.0;
    }
    double maxRmssd = rmssdResults.values.reduce((a, b) => a > b ? a : b);
    userResonanceFreq= rmssdResults.entries
        .firstWhere((entry) => entry.value == maxRmssd)
        .key;
    return userResonanceFreq;
  }

  HrvTimeDomainResult? getWinningHrvResult() {
    final winningRate = getResonanceBreathingRate();
    return hrvResults[winningRate];
  }
}
