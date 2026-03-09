library;
import 'dart:math' as math;
import 'signal_processing.dart';
enum PsdMethod { welch, lombScargle }

class FrequencyBand {
  final String name;
  final double low; 
  final double high; 
  const FrequencyBand(this.name, this.low, this.high);
}

class BandResult {
  final String name;
  final double absolutePower;
  final double? peakFrequency;
  final double relativePower;
  final double logPower;
  final double? normalizedPower;

  const BandResult({
    required this.name,
    required this.absolutePower,
    this.peakFrequency,
    required this.relativePower,
    required this.logPower,
    this.normalizedPower,
  });
}

class HrvFrequencyDomainResult {
  final BandResult ulf;
  final BandResult vlf;
  final BandResult lf;
  final BandResult hf;
  final BandResult vhf;

  final double totalPower; 
  final double lfHfRatio;

  final List<double> frequencies;
  final List<double> psd;

  final PsdMethod method;
  final int interpolationRate;

  final String? durationWarning;

  const HrvFrequencyDomainResult({
    required this.ulf,
    required this.vlf,
    required this.lf,
    required this.hf,
    required this.vhf,
    required this.totalPower,
    required this.lfHfRatio,
    required this.frequencies,
    required this.psd,
    required this.method,
    this.interpolationRate = 4,
    this.durationWarning,
  });

  Map<String, String> essentials() {
    return {
      'LF Power': '${lf.absolutePower.toStringAsFixed(1)} ms²',
      'HF Power': '${hf.absolutePower.toStringAsFixed(1)} ms²',
      'LF/HF': lfHfRatio.isFinite
          ? lfHfRatio.toStringAsFixed(2)
          : 'N/A',
      'Total Power': '${totalPower.toStringAsFixed(1)} ms²',
    };
  }

  Map<String, List<({String label, double? value, String unit})>>
      allBandMetrics() {
    final Map<String, List<({String label, double? value, String unit})>>
        groups = {};

    for (final b in [ulf, vlf, lf, hf, vhf]) {
      groups[b.name] = [
        (label: '${b.name} Power', value: b.absolutePower, unit: 'ms²'),
        (label: '${b.name} Peak', value: b.peakFrequency, unit: 'Hz'),
        (
          label: '${b.name} Relative',
          value: b.relativePower * 100,
          unit: '%'
        ),
        (label: '${b.name} Log', value: b.logPower, unit: 'ln(ms²)'),
        if (b.normalizedPower != null)
          (
            label: '${b.name} Norm',
            value: b.normalizedPower! * 100,
            unit: 'n.u.'
          ),
      ];
    }
    return groups;
  }

  Map<String, double?> toNeuroKitMap() {
    final m = <String, double?>{};
    for (final b in [ulf, vlf, lf, hf, vhf]) {
      m['HRV_${b.name}'] = b.absolutePower;
      m['HRV_${b.name}Peak'] = b.peakFrequency;
      m['HRV_${b.name}Relative'] = b.relativePower;
      m['HRV_${b.name}Log'] =
          b.logPower.isFinite ? b.logPower : null;
      if (b.normalizedPower != null) {
        m['HRV_${b.name}n'] = b.normalizedPower;
      }
    }
    m['HRV_TP'] = totalPower;
    m['HRV_LFHF'] = lfHfRatio.isFinite ? lfHfRatio : null;
    return m;
  }
}

class HrvFrequencyDomainAnalyzer {
  static const FrequencyBand _ulf = FrequencyBand('ULF', 0.0, 0.0033);
  static const FrequencyBand _vlf = FrequencyBand('VLF', 0.0033, 0.04);
  static const FrequencyBand _lf = FrequencyBand('LF', 0.04, 0.15);
  static const FrequencyBand _hf = FrequencyBand('HF', 0.15, 0.4);
  static const FrequencyBand _vhf = FrequencyBand('VHF', 0.4, 0.5);

  static HrvFrequencyDomainResult analyze(
    List<double> rrIntervalsMs, {
    PsdMethod method = PsdMethod.welch,
    int interpolationRate = 4,
    int nFreqs = 500,
    bool normalize = true,
    double minFrequency = 0.0,
    double maxFrequency = 0.5,
    int? nperseg,
  }) {
    if (rrIntervalsMs.length < 3) {
      throw ArgumentError(
          'Need ≥ 3 RR intervals for frequency analysis '
          '(got ${rrIntervalsMs.length})');
    }

    final int nRR = rrIntervalsMs.length;
    final times = List<double>.filled(nRR, 0.0);
    times[0] = rrIntervalsMs[0] / 1000.0;
    for (int i = 1; i < nRR; i++) {
      times[i] = times[i - 1] + rrIntervalsMs[i] / 1000.0;
    }

    final double durationSec = times.last - times.first;

    String? durationWarning;
    if (durationSec < 60) {
      durationWarning =
          'Recording < 1 min (${durationSec.toStringAsFixed(0)}s). '
          'Frequency-domain results may be unreliable.';
    } else if (durationSec < 120) {
      durationWarning =
          'Recording < 2 min. VLF and LF power estimates '
          'have limited reliability.';
    }

    List<double> freq;
    List<double> psd;

    switch (method) {
      case PsdMethod.welch:
        final (_, interpRRI) = cubicInterpolate(
          times,
          rrIntervalsMs,
          interpolationRate.toDouble(),
        );

        final double mean =
            interpRRI.reduce((a, b) => a + b) / interpRRI.length;
        final detrended = interpRRI.map((v) => v - mean).toList();

        final effectiveNperseg =
            nperseg ?? detrended.length;

        (freq, psd) = welchPSD(
          detrended,
          interpolationRate.toDouble(),
          nperseg: effectiveNperseg.clamp(4, detrended.length),
        );

      case PsdMethod.lombScargle:
        final double fMin =
            minFrequency <= 0 ? 0.003 : minFrequency;
        freq = List<double>.generate(
          nFreqs,
          (i) => fMin + i * (maxFrequency - fMin) / (nFreqs - 1),
        );
        psd = lombScarglePSD(times, rrIntervalsMs, freq);
    }

    final double totalPower =
        freq.length >= 2 ? trapz(freq, psd) : 0.0;

    BandResult _band(FrequencyBand band) {
      final idx = <int>[];
      for (int i = 0; i < freq.length; i++) {
        if (freq[i] >= band.low && freq[i] < band.high) idx.add(i);
      }
      if (idx.isEmpty) {
        return BandResult(
          name: band.name,
          absolutePower: 0.0,
          peakFrequency: null,
          relativePower: 0.0,
          logPower: double.negativeInfinity,
        );
      }

      final bF = idx.map((i) => freq[i]).toList();
      final bP = idx.map((i) => psd[i]).toList();

      final double absPow =
          bF.length >= 2 ? trapz(bF, bP) : bP[0] * (band.high - band.low);

      int peakI = 0;
      for (int i = 1; i < bP.length; i++) {
        if (bP[i] > bP[peakI]) peakI = i;
      }

      return BandResult(
        name: band.name,
        absolutePower: absPow,
        peakFrequency: bF[peakI],
        relativePower: totalPower > 0 ? absPow / totalPower : 0.0,
        logPower: absPow > 0 ? math.log(absPow) : double.negativeInfinity,
      );
    }

    final ulfR = _band(_ulf);
    final vlfR = _band(_vlf);
    BandResult lfR = _band(_lf);
    BandResult hfR = _band(_hf);
    final vhfR = _band(_vhf);

    if (normalize) {
      final double lfHfSum = lfR.absolutePower + hfR.absolutePower;
      if (lfHfSum > 0) {
        lfR = BandResult(
          name: lfR.name,
          absolutePower: lfR.absolutePower,
          peakFrequency: lfR.peakFrequency,
          relativePower: lfR.relativePower,
          logPower: lfR.logPower,
          normalizedPower: lfR.absolutePower / lfHfSum,
        );
        hfR = BandResult(
          name: hfR.name,
          absolutePower: hfR.absolutePower,
          peakFrequency: hfR.peakFrequency,
          relativePower: hfR.relativePower,
          logPower: hfR.logPower,
          normalizedPower: hfR.absolutePower / lfHfSum,
        );
      }
    }

    final double lfHf = hfR.absolutePower > 0
        ? lfR.absolutePower / hfR.absolutePower
        : double.infinity;

    return HrvFrequencyDomainResult(
      ulf: ulfR,
      vlf: vlfR,
      lf: lfR,
      hf: hfR,
      vhf: vhfR,
      totalPower: totalPower,
      lfHfRatio: lfHf,
      frequencies: freq,
      psd: psd,
      method: method,
      interpolationRate: interpolationRate,
      durationWarning: durationWarning,
    );
  }
}