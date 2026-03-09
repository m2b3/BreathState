library;
import 'dart:math' as math;

int nextPowerOfTwo(int n) {
  if (n <= 1) return 1;
  int p = 1;
  while (p < n) {
    p <<= 1;
  }
  return p;
}

void fftInPlace(List<double> re, List<double> im) {
  final int n = re.length;
  assert(n == im.length, 'Real / imag length mismatch');
  assert(n > 0 && (n & (n - 1)) == 0, 'Length must be a power of 2 (got $n)');

  int j = 0;
  for (int i = 0; i < n - 1; i++) {
    if (i < j) {
      double t = re[i];
      re[i] = re[j];
      re[j] = t;
      t = im[i];
      im[i] = im[j];
      im[j] = t;
    }
    int m = n >> 1;
    while (m >= 1 && j >= m) {
      j -= m;
      m >>= 1;
    }
    j += m;
  }

  for (int size = 2; size <= n; size <<= 1) {
    final int half = size >> 1;
    final double theta = -2.0 * math.pi / size;
    final double wR = math.cos(theta);
    final double wI = math.sin(theta);

    for (int i = 0; i < n; i += size) {
      double uR = 1.0, uI = 0.0;
      for (int k = 0; k < half; k++) {
        final int a = i + k;
        final int b = a + half;
        final double tR = uR * re[b] - uI * im[b];
        final double tI = uR * im[b] + uI * re[b];
        re[b] = re[a] - tR;
        im[b] = im[a] - tI;
        re[a] += tR;
        im[a] += tI;
        final double nu = uR * wR - uI * wI;
        uI = uR * wI + uI * wR;
        uR = nu;
      }
    }
  }
}

List<double> hannWindow(int n) {
  if (n <= 1) return List.filled(n, 1.0);
  return List<double>.generate(
    n,
    (i) => 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (n - 1))),
  );
}

class CubicSpline {
  final List<double> _x;
  final List<double> _a; 
  late final List<double> _b, _c, _d;

  CubicSpline(this._x, List<double> y)
      : _a = List<double>.from(y) {
    assert(_x.length == _a.length && _x.length >= 2,
        'Need ≥ 2 knots for a spline');
    _build();
  }

  void _build() {
    final int n = _x.length - 1; 
    _b = List<double>.filled(n, 0.0);
    _c = List<double>.filled(n + 1, 0.0);
    _d = List<double>.filled(n, 0.0);

    if (n == 1) {
      _b[0] = (_a[1] - _a[0]) / (_x[1] - _x[0]);
      return;
    }

    final h = List<double>.generate(n, (i) => _x[i + 1] - _x[i]);
    final alpha = List<double>.filled(n, 0.0);
    for (int i = 1; i < n; i++) {
      alpha[i] = 3.0 / h[i] * (_a[i + 1] - _a[i]) -
          3.0 / h[i - 1] * (_a[i] - _a[i - 1]);
    }

    final l = List<double>.filled(n + 1, 1.0);
    final mu = List<double>.filled(n + 1, 0.0);
    final z = List<double>.filled(n + 1, 0.0);

    for (int i = 1; i < n; i++) {
      l[i] = 2.0 * (_x[i + 1] - _x[i - 1]) - h[i - 1] * mu[i - 1];
      mu[i] = h[i] / l[i];
      z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
    }

    for (int j = n - 1; j >= 0; j--) {
      _c[j] = z[j] - mu[j] * _c[j + 1];
      _b[j] = (_a[j + 1] - _a[j]) / h[j] -
          h[j] * (_c[j + 1] + 2.0 * _c[j]) / 3.0;
      _d[j] = (_c[j + 1] - _c[j]) / (3.0 * h[j]);
    }
  }

  double evaluate(double x) {
    final int i = _interval(x);
    final double dx = x - _x[i];
    return _a[i] + _b[i] * dx + _c[i] * dx * dx + _d[i] * dx * dx * dx;
  }

  List<double> evaluateList(List<double> xs) => xs.map(evaluate).toList();

  int _interval(double x) {
    if (x <= _x.first) return 0;
    if (x >= _x.last) return _x.length - 2;
    int lo = 0, hi = _x.length - 2;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (_x[mid + 1] <= x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

(List<double>, List<double>) cubicInterpolate(
  List<double> times,
  List<double> values,
  double fs,
) {
  assert(times.length == values.length && times.length >= 2);
  final double dt = 1.0 / fs;
  final int nOut = ((times.last - times.first) / dt).floor() + 1;
  final newT = List<double>.generate(nOut, (i) => times.first + i * dt);
  final spline = CubicSpline(times, values);
  return (newT, spline.evaluateList(newT));
}

(List<double>, List<double>) linearInterpolate(
  List<double> times,
  List<double> values,
  double fs,
) {
  assert(times.length == values.length && times.length >= 2);
  final double dt = 1.0 / fs;
  final int nOut = ((times.last - times.first) / dt).floor() + 1;
  final newT = List<double>.generate(nOut, (i) => times.first + i * dt);
  final newV = List<double>.filled(nOut, 0.0);

  int j = 0;
  for (int i = 0; i < nOut; i++) {
    final double t = newT[i];
    while (j < times.length - 2 && times[j + 1] < t) {
      j++;
    }
    if (j >= times.length - 1) {
      newV[i] = values.last;
    } else {
      final double frac = (times[j + 1] != times[j])
          ? (t - times[j]) / (times[j + 1] - times[j])
          : 0.0;
      newV[i] = values[j] + frac * (values[j + 1] - values[j]);
    }
  }
  return (newT, newV);
}

(List<double>, List<double>) welchPSD(
  List<double> signal,
  double fs, {
  int? nperseg,
  int? noverlap,
}) {
  final int n = signal.length;
  if (n < 4) return (<double>[0.0], <double>[0.0]);

  nperseg = (nperseg ?? n).clamp(4, n);
  noverlap ??= nperseg ~/ 2;

  final int step = math.max(1, nperseg - noverlap);
  final int nfft = nextPowerOfTwo(nperseg);
  final win = hannWindow(nperseg);

  double s2 = 0.0;
  for (int i = 0; i < nperseg; i++) {
    s2 += win[i] * win[i];
  }

  final int nFreqs = nfft ~/ 2 + 1;
  final psd = List<double>.filled(nFreqs, 0.0);

  int nSeg = 0;
  for (int start = 0; start + nperseg <= n; start += step) {
    nSeg++;
    final re = List<double>.filled(nfft, 0.0);
    final im = List<double>.filled(nfft, 0.0);
    for (int i = 0; i < nperseg; i++) {
      re[i] = signal[start + i] * win[i];
    }
    fftInPlace(re, im);
    for (int k = 0; k < nFreqs; k++) {
      double mag2 = re[k] * re[k] + im[k] * im[k];
      if (k > 0 && k < nfft ~/ 2) mag2 *= 2.0; 
      psd[k] += mag2;
    }
  }
  if (nSeg == 0) nSeg = 1;

  final double scale = fs * s2 * nSeg;
  for (int k = 0; k < nFreqs; k++) {
    psd[k] /= scale;
  }

  final freqs = List<double>.generate(nFreqs, (k) => k * fs / nfft);
  return (freqs, psd);
}

List<double> lombScarglePSD(
  List<double> times,
  List<double> values,
  List<double> frequencies,
) {
  final int n = times.length;
  final int nf = frequencies.length;
  if (n < 2) return List<double>.filled(nf, 0.0);

  final double mean = values.reduce((a, b) => a + b) / n;
  final c = values.map((v) => v - mean).toList();
  final double variance = c.fold<double>(0.0, (s, v) => s + v * v) / n;
  if (variance < 1e-30) return List<double>.filled(nf, 0.0);

  final psd = List<double>.filled(nf, 0.0);

  for (int fi = 0; fi < nf; fi++) {
    final double f = frequencies[fi];
    if (f <= 0) continue;
    final double w = 2.0 * math.pi * f;

    double s2 = 0.0, c2 = 0.0;
    for (int i = 0; i < n; i++) {
      s2 += math.sin(2.0 * w * times[i]);
      c2 += math.cos(2.0 * w * times[i]);
    }
    final double tau = math.atan2(s2, c2) / (2.0 * w);

    double ccNum = 0, ssNum = 0, ccDen = 0, ssDen = 0;
    for (int i = 0; i < n; i++) {
      final double ph = w * (times[i] - tau);
      final double cp = math.cos(ph), sp = math.sin(ph);
      ccNum += c[i] * cp;
      ssNum += c[i] * sp;
      ccDen += cp * cp;
      ssDen += sp * sp;
    }
    psd[fi] = 0.5 *
        ((ccNum * ccNum) / ccDen.clamp(1e-30, double.infinity) +
            (ssNum * ssNum) / ssDen.clamp(1e-30, double.infinity));
  }

  final double df = nf > 1 ? frequencies[1] - frequencies[0] : 1.0;
  final double psdSum = psd.fold<double>(0.0, (s, v) => s + v);
  if (psdSum > 0) {
    final double sf = variance / (psdSum * df);
    for (int i = 0; i < nf; i++) {
      psd[i] *= sf;
    }
  }
  return psd;
}

double trapz(List<double> x, List<double> y) {
  assert(x.length == y.length);
  if (x.length < 2) return 0.0;
  double s = 0.0;
  for (int i = 0; i < x.length - 1; i++) {
    s += (x[i + 1] - x[i]) * (y[i] + y[i + 1]);
  }
  return s * 0.5;
}