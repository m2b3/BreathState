import 'dart:math';

class HrvTimeDomainResult {
  final double meanNN;
  final double sdnn;
  final double rmssd;
  final double sdsd;
  final double cvnn;
  final double cvsd;
  final double medianNN;
  final double madNN;
  final double mcvnn;
  final double iqrnn;
  final double sdrmssd;
  final double prc20nn;
  final double prc80nn;
  final double pnn50;
  final double pnn20;
  final double minNN;
  final double maxNN;
  final double hti;
  final double tinn;
  final double? sdann1;
  final double? sdann2;
  final double? sdann5;
  final double? sdnni1;
  final double? sdnni2;
  final double? sdnni5;

  const HrvTimeDomainResult({
    required this.meanNN,
    required this.sdnn,
    required this.rmssd,
    required this.sdsd,
    required this.cvnn,
    required this.cvsd,
    required this.medianNN,
    required this.madNN,
    required this.mcvnn,
    required this.iqrnn,
    required this.sdrmssd,
    required this.prc20nn,
    required this.prc80nn,
    required this.pnn50,
    required this.pnn20,
    required this.minNN,
    required this.maxNN,
    required this.hti,
    required this.tinn,
    this.sdann1,
    this.sdann2,
    this.sdann5,
    this.sdnni1,
    this.sdnni2,
    this.sdnni5,
  });

  Map<String, double?> toMap() => {
        'HRV_MeanNN': meanNN,
        'HRV_SDNN': sdnn,
        'HRV_RMSSD': rmssd,
        'HRV_SDSD': sdsd,
        'HRV_CVNN': cvnn,
        'HRV_CVSD': cvsd,
        'HRV_MedianNN': medianNN,
        'HRV_MadNN': madNN,
        'HRV_MCVNN': mcvnn,
        'HRV_IQRNN': iqrnn,
        'HRV_SDRMSSD': sdrmssd,
        'HRV_Prc20NN': prc20nn,
        'HRV_Prc80NN': prc80nn,
        'HRV_pNN50': pnn50,
        'HRV_pNN20': pnn20,
        'HRV_MinNN': minNN,
        'HRV_MaxNN': maxNN,
        'HRV_HTI': hti,
        'HRV_TINN': tinn,
        'HRV_SDANN1': sdann1,
        'HRV_SDANN2': sdann2,
        'HRV_SDANN5': sdann5,
        'HRV_SDNNI1': sdnni1,
        'HRV_SDNNI2': sdnni2,
        'HRV_SDNNI5': sdnni5,
      };

  String _formatValue(double value, int decimals) {
    if (!value.isFinite) {
      return '—';
    }
    return value.toStringAsFixed(decimals);
  }

  Map<String, String> essentials() {
    final double heartRate = 60000.0 / meanNN;
    final double cvPercent = cvsd * 100.0;

    return {
      'Heart Rate': '${_formatValue(heartRate, 1)} bpm',
      'RMSSD': '${_formatValue(rmssd, 1)} ms',
      'SDNN': '${_formatValue(sdnn, 1)} ms',
      'pNN50': '${_formatValue(pnn50, 1)}%',
      'pNN20': '${_formatValue(pnn20, 1)}%',
      'LF/HF Proxy': _formatValue(sdrmssd, 2),
      'CV%': '${_formatValue(cvPercent, 1)}%',
    };
  }
  Map<String, double> stressIndicators() => {
        'RMSSD': rmssd,
        'SDNN': sdnn,
        'pNN50': pnn50,
        'SDRMSSD': sdrmssd,
        'CVSD': cvsd,
      };

  @override
  String toString() => toMap()
      .entries
      .where((e) => e.value != null && e.value!.isFinite)
      .map((e) => '${e.key}: ${e.value!.toStringAsFixed(2)}')
      .join('\n');
}

class HrvTimeDomain {
  HrvTimeDomain._(); 

  static HrvTimeDomainResult compute(
    List<double> rrIntervalsMs, {
    double binSize = 7.8125,
  }) {
    if (rrIntervalsMs.length < 2) {
      throw ArgumentError('Need at least 2 RR intervals, '
          'got ${rrIntervalsMs.length}');
    }

    final rri = _clean(rrIntervalsMs);
    if (rri.length < 2) {
      throw ArgumentError('After removing NaN/Inf, fewer than 2 intervals remain');
    }

    final diff = _successiveDiff(rri);
    final absDiff = diff.map((d) => d.abs()).toList();

    final meanNN = _mean(rri);
    final sdnn = _std(rri);

    final rmssd = sqrt(_mean(diff.map((d) => d * d).toList()));
    final sdsd = _std(diff);

    final cvnn = meanNN == 0 ? double.nan : sdnn / meanNN;
    final cvsd = meanNN == 0 ? double.nan : rmssd / meanNN;

    final medianNN = _median(rri);
    final madNN = _mad(rri);
    final mcvnn = medianNN == 0 ? double.nan : madNN / medianNN;
    final iqrnn = _iqr(rri);
    final sdrmssd = rmssd == 0 ? double.nan : sdnn / rmssd;
    final prc20nn = _percentile(rri, 20);
    final prc80nn = _percentile(rri, 80);

    final nn50 = absDiff.where((d) => d > 50).length;
    final nn20 = absDiff.where((d) => d > 20).length;
    final denom = diff.length;
    final pnn50 = denom == 0 ? double.nan : nn50 / denom * 100.0;
    final pnn20 = denom == 0 ? double.nan : nn20 / denom * 100.0;
    final minNN = _min(rri);
    final maxNN = _max(rri);

    final hti = _computeHTI(rri, binSize);
    final tinn = _computeTINN(rri, binSize);

    final sdann1 = _sdann(rri, windowMinutes: 1);
    final sdann2 = _sdann(rri, windowMinutes: 2);
    final sdann5 = _sdann(rri, windowMinutes: 5);
    final sdnni1 = _sdnni(rri, windowMinutes: 1);
    final sdnni2 = _sdnni(rri, windowMinutes: 2);
    final sdnni5 = _sdnni(rri, windowMinutes: 5);

    return HrvTimeDomainResult(
      meanNN: meanNN,
      sdnn: sdnn,
      rmssd: rmssd,
      sdsd: sdsd,
      cvnn: cvnn,
      cvsd: cvsd,
      medianNN: medianNN,
      madNN: madNN,
      mcvnn: mcvnn,
      iqrnn: iqrnn,
      sdrmssd: sdrmssd,
      prc20nn: prc20nn,
      prc80nn: prc80nn,
      pnn50: pnn50,
      pnn20: pnn20,
      minNN: minNN,
      maxNN: maxNN,
      hti: hti,
      tinn: tinn,
      sdann1: sdann1,
      sdann2: sdann2,
      sdann5: sdann5,
      sdnni1: sdnni1,
      sdnni2: sdnni2,
      sdnni5: sdnni5,
    );
  }

  static HrvTimeDomainResult computeFromPeakTimestamps(
    List<double> peakTimestampsMs, {
    double binSize = 7.8125,
  }) {
    if (peakTimestampsMs.length < 3) {
      throw ArgumentError('Need at least 3 peak timestamps');
    }
    final rri = _successiveDiff(peakTimestampsMs);
    return compute(rri, binSize: binSize);
  }

  static HrvTimeDomainResult computeFromPeakSamples(
    List<int> peakSampleIndices, {
    required int samplingRate,
    double binSize = 7.8125,
  }) {
    if (peakSampleIndices.length < 3) {
      throw ArgumentError('Need at least 3 peak sample indices');
    }
    final rri = <double>[];
    for (int i = 1; i < peakSampleIndices.length; i++) {
      rri.add((peakSampleIndices[i] - peakSampleIndices[i - 1]) /
          samplingRate *
          1000.0);
    }
    return compute(rri, binSize: binSize);
  }
  static List<double> _clean(List<double> v) =>
      v.where((x) => x.isFinite).toList();

  static List<double> _successiveDiff(List<double> v) =>
      [for (int i = 1; i < v.length; i++) v[i] - v[i - 1]];

  static double _mean(List<double> v) {
    if (v.isEmpty) return double.nan;
    double sum = 0;
    for (final x in v) {
      sum += x;
    }
    return sum / v.length;
  }

  static double _std(List<double> v) {
    if (v.length < 2) return double.nan;
    final m = _mean(v);
    double ss = 0;
    for (final x in v) {
      final d = x - m;
      ss += d * d;
    }
    return sqrt(ss / (v.length - 1));
  }

  static double _median(List<double> v) {
    if (v.isEmpty) return double.nan;
    final s = List<double>.from(v)..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2.0;
  }

  static double _mad(List<double> v) {
    if (v.isEmpty) return double.nan;
    final med = _median(v);
    return _median(v.map((x) => (x - med).abs()).toList());
  }

  static double _percentile(List<double> v, double q) {
    if (v.isEmpty) return double.nan;
    final s = List<double>.from(v)..sort();
    final idx = (q / 100.0) * (s.length - 1);
    final lo = idx.floor();
    final hi = idx.ceil();
    if (lo == hi) return s[lo];
    return s[lo] + (s[hi] - s[lo]) * (idx - lo);
  }

  static double _iqr(List<double> v) =>
      _percentile(v, 75) - _percentile(v, 25);

  static double _min(List<double> v) =>
      v.isEmpty ? double.nan : v.reduce(min);

  static double _max(List<double> v) =>
      v.isEmpty ? double.nan : v.reduce(max);

  static double _computeHTI(List<double> rri, double binSize) {
    if (rri.length < 2) return double.nan;
    final maxRR = _max(rri);
    final nBins = ((maxRR + binSize) / binSize).ceil();
    final counts = List<int>.filled(nBins, 0);
    for (final rr in rri) {
      final idx = (rr / binSize).floor();
      if (idx >= 0 && idx < nBins) counts[idx]++;
    }
    final peak = counts.reduce(max);
    return peak == 0 ? double.nan : rri.length / peak.toDouble();
  }

  static double _computeTINN(List<double> rri, double binSize) {
    if (rri.length < 10) return double.nan;

    final maxRR = _max(rri);
    final minRR = _min(rri);

    final List<double> edges = [];
    for (double e = 0; e <= maxRR + binSize; e += binSize) {
      edges.add(e);
    }
    final nBins = edges.length - 1;
    if (nBins < 3) return double.nan;

    final counts = List<int>.filled(nBins, 0);
    for (final rr in rri) {
      final idx = ((rr - edges[0]) / binSize).floor();
      if (idx >= 0 && idx < nBins) counts[idx]++;
    }

    int peakIdx = 0;
    for (int i = 1; i < nBins; i++) {
      if (counts[i] > counts[peakIdx]) peakIdx = i;
    }
    final double peakX = edges[peakIdx];
    final double peakY = counts[peakIdx].toDouble();
    if (peakY == 0) return double.nan;

    int nStart = 0;
    for (int i = 0; i < edges.length; i++) {
      if (edges[i] > minRR) {
        nStart = i;
        break;
      }
    }

    double minError = double.infinity;
    double bestN = 0, bestM = 0;

    for (int ni = nStart; ni < peakIdx; ni++) {
      for (int mi = peakIdx + 1; mi < nBins && edges[mi] < maxRR; mi++) {
        double error = 0;
        final double nX = edges[ni];
        final double mX = edges[mi];
        final double leftDenom = peakX - nX;
        final double rightDenom = mX - peakX;

        for (int k = ni; k <= mi && k < nBins; k++) {
          double q;
          if (k <= peakIdx) {
            q = leftDenom == 0
                ? peakY
                : peakY * (edges[k] - nX) / leftDenom;
          } else {
            q = rightDenom == 0
                ? peakY
                : peakY * (mX - edges[k]) / rightDenom;
          }
          final diff = counts[k] - q;
          error += diff * diff;
        }

        if (error < minError) {
          minError = error;
          bestN = nX;
          bestM = mX;
        }
      }
    }
    return bestM - bestN;
  }

  static List<double> _cumulativeMs(List<double> rri) {
    final cum = List<double>.filled(rri.length, 0);
    cum[0] = rri[0];
    for (int i = 1; i < rri.length; i++) {
      cum[i] = cum[i - 1] + rri[i];
    }
    return cum;
  }

  static List<List<double>> _windowSegments(
      List<double> rri, double windowMs) {
    final cum = _cumulativeMs(rri);
    final totalMs = cum.last;
    final nWindows = (totalMs / windowMs).round();
    if (nWindows < 3) return [];

    final segments = <List<double>>[];
    for (int w = 0; w < nWindows; w++) {
      final wStart = w * windowMs;
      final wEnd = wStart + windowMs;
      final seg = <double>[];
      for (int i = 0; i < rri.length; i++) {
        if (cum[i] >= wStart && cum[i] < wEnd) seg.add(rri[i]);
      }
      if (seg.isNotEmpty) segments.add(seg);
    }
    return segments;
  }

  static double? _sdann(List<double> rri, {required int windowMinutes}) {
    final segs = _windowSegments(rri, windowMinutes * 60000.0);
    if (segs.length < 3) return null;
    final means = segs.map(_mean).toList();
    return _std(means);
  }

  static double? _sdnni(List<double> rri, {required int windowMinutes}) {
    final segs = _windowSegments(rri, windowMinutes * 60000.0);
    if (segs.length < 3) return null;
    final stds =
        segs.where((s) => s.length >= 2).map(_std).toList();
    return stds.isEmpty ? null : _mean(stds);
  }
}