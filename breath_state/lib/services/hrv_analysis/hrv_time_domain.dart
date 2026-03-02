/// BreathState — HRV Time-Domain Analysis Module
///
/// Pure-Dart translation of NeuroKit2's `hrv_time` function.
/// Computes 20+ time-domain HRV indices entirely offline with zero
/// external package dependencies.
///
/// Usage:
/// ```dart
/// // From RR intervals (ms) — typical Polar H10 output
/// final rri = [812.0, 798.0, 825.0, 801.0, 790.0, ...];
/// final hrv = HrvTimeDomain.compute(rri);
///
/// print(hrv.rmssd);            // single metric
/// print(hrv.essentials());     // key metrics for quick UI display
/// print(hrv.toMap());          // all 20+ metrics as Map<String, double?>
///
/// // From R-peak timestamps (ms)
/// final peaks = [0.0, 812.0, 1610.0, 2435.0, ...];
/// final hrv2 = HrvTimeDomain.computeFromPeakTimestamps(peaks);
/// ```
///
/// References:
///   Pham T. et al. (2021) Sensors 21(12):3998
///   https://doi.org/10.3390/s21123998
///
///   NeuroKit2 source: neurokit2/hrv/hrv_time.py
///   https://github.com/neuropsychology/NeuroKit

import 'dart:math';

// ═════════════════════════════════════════════════════════════════════
//  RESULT MODEL
// ═════════════════════════════════════════════════════════════════════

/// Holds every computed HRV time-domain metric.
///
/// All values are in **milliseconds** unless stated otherwise
/// (ratios and percentages are dimensionless / %).
class HrvTimeDomainResult {
  // ── Deviation-based (from NN intervals directly) ─────────────
  /// Mean of RR intervals (ms).
  final double meanNN;

  /// Standard deviation of RR intervals (ms) — overall HRV.
  final double sdnn;

  // ── Difference-based (from successive NN differences) ────────
  /// Root mean square of successive differences (ms) — parasympathetic.
  final double rmssd;

  /// Standard deviation of successive differences (ms).
  final double sdsd;

  // ── Normalised ───────────────────────────────────────────────
  /// SDNN / MeanNN — coefficient of variation.
  final double cvnn;

  /// RMSSD / MeanNN — normalised parasympathetic index.
  final double cvsd;

  // ── Robust ───────────────────────────────────────────────────
  /// Median of RR intervals (ms).
  final double medianNN;

  /// Median absolute deviation of RR intervals (ms).
  final double madNN;

  /// MadNN / MedianNN — robust normalised dispersion.
  final double mcvnn;

  /// Interquartile range of RR intervals (ms).
  final double iqrnn;

  /// SDNN / RMSSD — time-domain proxy for the LF/HF ratio
  /// (sympatho-vagal balance). Sollers et al. 2007.
  final double sdrmssd;

  /// 20th percentile of RR intervals (ms).
  final double prc20nn;

  /// 80th percentile of RR intervals (ms).
  final double prc80nn;

  // ── Count / Extreme ──────────────────────────────────────────
  /// % of successive differences > 50 ms — parasympathetic marker.
  final double pnn50;

  /// % of successive differences > 20 ms — more sensitive than pNN50.
  final double pnn20;

  /// Minimum RR interval (ms).
  final double minNN;

  /// Maximum RR interval (ms).
  final double maxNN;

  // ── Geometric ────────────────────────────────────────────────
  /// HRV Triangular Index — total NN count / histogram peak height.
  final double hti;

  /// Triangular Interpolation of NN histogram baseline width (ms).
  final double tinn;

  // ── Long-duration windowed (null if recording too short) ─────
  /// SD of mean RR in 1-min windows. Needs ≥ 3 min.
  final double? sdann1;

  /// SD of mean RR in 2-min windows. Needs ≥ 6 min.
  final double? sdann2;

  /// SD of mean RR in 5-min windows. Needs ≥ 15 min.
  final double? sdann5;

  /// Mean of SD of RR in 1-min windows. Needs ≥ 3 min.
  final double? sdnni1;

  /// Mean of SD of RR in 2-min windows. Needs ≥ 6 min.
  final double? sdnni2;

  /// Mean of SD of RR in 5-min windows. Needs ≥ 15 min.
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

  /// All metrics as a map, prefixed with `HRV_` (NeuroKit convention).
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

  /// The most clinically actionable metrics for quick UI display.
  Map<String, String> essentials() => {
        'Heart Rate': '${(60000.0 / meanNN).toStringAsFixed(1)} bpm',
        'RMSSD': '${rmssd.toStringAsFixed(1)} ms',
        'SDNN': '${sdnn.toStringAsFixed(1)} ms',
        'pNN50': '${pnn50.toStringAsFixed(1)}%',
        'pNN20': '${pnn20.toStringAsFixed(1)}%',
        'LF/HF Proxy': sdrmssd.toStringAsFixed(2),
        'CV%': '${(cvsd * 100).toStringAsFixed(1)}%',
      };

  /// Stress-relevant subset (higher SDRMSSD & lower RMSSD → more stress).
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

// ═════════════════════════════════════════════════════════════════════
//  COMPUTATION ENGINE
// ═════════════════════════════════════════════════════════════════════

/// Static, stateless HRV time-domain calculator.
///
/// All inputs are **RR intervals in milliseconds**.
class HrvTimeDomain {
  HrvTimeDomain._(); // non-instantiable utility class

  // ─────────────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Compute every time-domain HRV index from [rrIntervalsMs].
  ///
  /// * [rrIntervalsMs] — successive RR (NN) intervals in milliseconds.
  ///   Must contain ≥ 2 values.
  /// * [binSize] — histogram bin width for geometric indices.
  ///   Default 7.8125 ms matches NeuroKit's `(1/128) * 1000`.
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

    // ── Deviation-based ──────────────────────────────────────
    final meanNN = _mean(rri);
    final sdnn = _std(rri);

    // ── Difference-based ─────────────────────────────────────
    final rmssd = sqrt(_mean(diff.map((d) => d * d).toList()));
    final sdsd = _std(diff);

    // ── Normalised ───────────────────────────────────────────
    final cvnn = meanNN == 0 ? double.nan : sdnn / meanNN;
    final cvsd = meanNN == 0 ? double.nan : rmssd / meanNN;

    // ── Robust ───────────────────────────────────────────────
    final medianNN = _median(rri);
    final madNN = _mad(rri);
    final mcvnn = medianNN == 0 ? double.nan : madNN / medianNN;
    final iqrnn = _iqr(rri);
    final sdrmssd = rmssd == 0 ? double.nan : sdnn / rmssd;
    final prc20nn = _percentile(rri, 20);
    final prc80nn = _percentile(rri, 80);

    // ── Count / Extreme ──────────────────────────────────────
    // Denominator is (diff.length + 1) == rri.length  — matches NeuroKit
    final nn50 = absDiff.where((d) => d > 50).length;
    final nn20 = absDiff.where((d) => d > 20).length;
    final denom = diff.length + 1;
    final pnn50 = nn50 / denom * 100.0;
    final pnn20 = nn20 / denom * 100.0;
    final minNN = _min(rri);
    final maxNN = _max(rri);

    // ── Geometric ────────────────────────────────────────────
    final hti = _computeHTI(rri, binSize);
    final tinn = _computeTINN(rri, binSize);

    // ── Long-duration windowed ───────────────────────────────
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

  /// Convenience: compute from R-peak timestamps (ms) instead of
  /// RR intervals.  Needs ≥ 3 peak timestamps.
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

  /// Convenience: compute from R-peak sample indices + sampling rate.
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

  // ─────────────────────────────────────────────────────────────
  //  PRIVATE — Statistical helpers  (replaces numpy / scipy)
  // ─────────────────────────────────────────────────────────────

  /// Remove NaN and infinite values.
  static List<double> _clean(List<double> v) =>
      v.where((x) => x.isFinite).toList();

  /// Successive differences: v[1]-v[0], v[2]-v[1], …
  static List<double> _successiveDiff(List<double> v) =>
      [for (int i = 1; i < v.length; i++) v[i] - v[i - 1]];

  /// Arithmetic mean.
  static double _mean(List<double> v) {
    if (v.isEmpty) return double.nan;
    double sum = 0;
    for (final x in v) {
      sum += x;
    }
    return sum / v.length;
  }

  /// Sample standard deviation (Bessel-corrected, ddof = 1).
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

  /// Median.
  static double _median(List<double> v) {
    if (v.isEmpty) return double.nan;
    final s = List<double>.from(v)..sort();
    final mid = s.length ~/ 2;
    return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2.0;
  }

  /// Median Absolute Deviation.
  static double _mad(List<double> v) {
    if (v.isEmpty) return double.nan;
    final med = _median(v);
    return _median(v.map((x) => (x - med).abs()).toList());
  }

  /// Percentile using linear interpolation (q in 0–100).
  static double _percentile(List<double> v, double q) {
    if (v.isEmpty) return double.nan;
    final s = List<double>.from(v)..sort();
    final idx = (q / 100.0) * (s.length - 1);
    final lo = idx.floor();
    final hi = idx.ceil();
    if (lo == hi) return s[lo];
    return s[lo] + (s[hi] - s[lo]) * (idx - lo);
  }

  /// Interquartile range (Q75 − Q25).
  static double _iqr(List<double> v) =>
      _percentile(v, 75) - _percentile(v, 25);

  static double _min(List<double> v) =>
      v.isEmpty ? double.nan : v.reduce(min);

  static double _max(List<double> v) =>
      v.isEmpty ? double.nan : v.reduce(max);

  // ─────────────────────────────────────────────────────────────
  //  PRIVATE — Geometric indices
  // ─────────────────────────────────────────────────────────────

  /// HRV Triangular Index = N(total) / max(histogram).
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

  /// TINN — baseline width of a least-squares triangular fit to the
  /// NN-interval histogram.
  static double _computeTINN(List<double> rri, double binSize) {
    if (rri.length < 10) return double.nan;

    final maxRR = _max(rri);
    final minRR = _min(rri);

    // Build histogram -------------------------------------------------
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

    // Find peak bin ---------------------------------------------------
    int peakIdx = 0;
    for (int i = 1; i < nBins; i++) {
      if (counts[i] > counts[peakIdx]) peakIdx = i;
    }
    final double peakX = edges[peakIdx];
    final double peakY = counts[peakIdx].toDouble();
    if (peakY == 0) return double.nan;

    // First edge above min(RR) ----------------------------------------
    int nStart = 0;
    for (int i = 0; i < edges.length; i++) {
      if (edges[i] > minRR) {
        nStart = i;
        break;
      }
    }

    // Brute-force search for optimal N (left foot) & M (right foot) ---
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

  // ─────────────────────────────────────────────────────────────
  //  PRIVATE — Long-duration windowed measures
  // ─────────────────────────────────────────────────────────────

  /// Cumulative elapsed time (ms) at the *end* of each RR interval.
  static List<double> _cumulativeMs(List<double> rri) {
    final cum = List<double>.filled(rri.length, 0);
    cum[0] = rri[0];
    for (int i = 1; i < rri.length; i++) {
      cum[i] = cum[i - 1] + rri[i];
    }
    return cum;
  }

  /// Gather RR intervals that fall into each time window.
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

  /// SDANN: SD of per-window mean RR.
  /// Returns `null` if recording is shorter than 3 × window.
  static double? _sdann(List<double> rri, {required int windowMinutes}) {
    final segs = _windowSegments(rri, windowMinutes * 60000.0);
    if (segs.length < 3) return null;
    final means = segs.map(_mean).toList();
    return _std(means);
  }

  /// SDNNI: mean of per-window SD of RR.
  /// Returns `null` if recording is shorter than 3 × window.
  static double? _sdnni(List<double> rri, {required int windowMinutes}) {
    final segs = _windowSegments(rri, windowMinutes * 60000.0);
    if (segs.length < 3) return null;
    final stds =
        segs.where((s) => s.length >= 2).map(_std).toList();
    return stds.isEmpty ? null : _mean(stds);
  }
}