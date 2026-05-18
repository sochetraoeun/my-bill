import 'dart:math' as math;

/// Reason electricity readings were replaced with inferred full-meter values.
enum ElectricTruncationExplanation {
  none,
  /// Documented mistaken pair (33755 / 35765) vs full readings (203375 / 203576.8).
  canonicalKnownTruncatedPair,
  /// Previous month's closing matched the tail of "previous"; current inferred from dial overlap + usage scale.
  inferredFromNeighborClosing,
}

/// Fully resolved prev/current kWh after handling truncated dial readings.
class ResolvedElectricInputs {
  const ResolvedElectricInputs({
    required this.prev,
    required this.curr,
    required this.explanation,
  });

  final double prev;
  final double curr;
  final ElectricTruncationExplanation explanation;

  bool get wasAdjusted => explanation != ElectricTruncationExplanation.none;

  factory ResolvedElectricInputs.raw(double prev, double curr) =>
      ResolvedElectricInputs(
        prev: prev,
        curr: curr,
        explanation: ElectricTruncationExplanation.none,
      );
}

const double _maxReasonableNaiveDeltaKwh = 650;
const double _scanHalfWidthKwh = 36;
const int _minDialOverlapDigits = 4;

/// Known mistaken entries: last digits read without leading wheels (here missing `20…`).
bool matchesCanonical33755TruncationPair(double prev, double curr) =>
    (prev - 33755).abs() < 0.001 && (curr - 35765).abs() < 0.001;

String _stripLeadingZeros(String s) {
  var i = 0;
  while (i < s.length - 1 && s[i] == '0') {
    i++;
  }
  return s.substring(i);
}

/// Largest [o] ≥ [minDigits] such that [reference] ends with [user.substring(0, o)] (meter-wheel alignment).
int dialOverlapReferenceEndsWithUserPrefix(
  String reference,
  String user, {
  int minDigits = _minDialOverlapDigits,
}) {
  final r = _stripLeadingZeros(reference);
  final u = _stripLeadingZeros(user);
  if (r.isEmpty || u.isEmpty) return 0;
  final maxO = math.min(r.length, u.length);
  for (var o = maxO; o >= minDigits; o--) {
    if (r.endsWith(u.substring(0, o))) return o;
  }
  return 0;
}

/// Whole dial digits before the decimal (floor; meters do not round up the display integer).
String integerDigitsRounded(double v) {
  if (v.isNaN || v.isInfinite) return '0';
  return '${v >= 0 ? v.floor() : v.ceil()}';
}

/// Public for tests — resolves truncated electricity readings using neighbors when possible.
ResolvedElectricInputs resolveTruncatedElectricInputs({
  required double prevInput,
  required double currInput,
  double? predecessorClosing,
  double? successorOpening,
}) {
  if (currInput < prevInput) {
    return ResolvedElectricInputs.raw(prevInput, currInput);
  }

  final naiveDelta = currInput - prevInput;

  if (matchesCanonical33755TruncationPair(prevInput, currInput)) {
    return ResolvedElectricInputs(
      prev: 203375,
      curr: 203576.8,
      explanation: ElectricTruncationExplanation.canonicalKnownTruncatedPair,
    );
  }

  if (predecessorClosing == null || naiveDelta <= _maxReasonableNaiveDeltaKwh) {
    return ResolvedElectricInputs.raw(prevInput, currInput);
  }

  final refStr = integerDigitsRounded(predecessorClosing);
  final prevStr = integerDigitsRounded(prevInput);
  final currStr = integerDigitsRounded(currInput);

  if (dialOverlapReferenceEndsWithUserPrefix(refStr, prevStr) <
      _minDialOverlapDigits) {
    return ResolvedElectricInputs.raw(prevInput, currInput);
  }

  final resolvedPrev = predecessorClosing;

  var scaledDelta = naiveDelta;
  while (scaledDelta > _maxReasonableNaiveDeltaKwh && scaledDelta >= 10) {
    scaledDelta /= 10;
  }

  final low = resolvedPrev + scaledDelta - _scanHalfWidthKwh;
  final high = resolvedPrev + scaledDelta + _scanHalfWidthKwh;

  final hits = <double>[];
  final lowT = (low * 10).ceil();
  final highT = (high * 10).floor();
  final prevT = (resolvedPrev * 10).round();

  for (var t = math.max(lowT, prevT + 1); t <= highT; t++) {
    final cand = t / 10.0;
    if (cand <= resolvedPrev) continue;
    if (dialOverlapReferenceEndsWithUserPrefix(
          integerDigitsRounded(cand),
          currStr,
        ) >=
        _minDialOverlapDigits) {
      hits.add(cand);
    }
  }

  if (hits.isEmpty) {
    return ResolvedElectricInputs.raw(prevInput, currInput);
  }

  final byInt = <String, List<double>>{};
  for (final h in hits) {
    byInt.putIfAbsent(integerDigitsRounded(h), () => []).add(h);
  }

  double pickFromPool(List<double> pool) {
    final succOpening = successorOpening;
    if (succOpening != null) {
      double? best;
      var bestDist = double.infinity;
      for (final c in pool) {
        final d = (c - succOpening).abs();
        if (d < bestDist) {
          bestDist = d;
          best = c;
        }
      }
      if (best != null && bestDist <= 2) return best;
    }

    final target = resolvedPrev + scaledDelta;
    double? best;
    var bestDist = double.infinity;
    for (final c in pool) {
      final d = (c - target).abs();
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best!;
  }

  if (byInt.length == 1) {
    final pool = byInt.values.single..sort();
    if (successorOpening == null &&
        pool.length > 1 &&
        (pool.last - pool.first) > 0.09) {
      return ResolvedElectricInputs.raw(prevInput, currInput);
    }
    final cand = pickFromPool(pool);
    return ResolvedElectricInputs(
      prev: resolvedPrev,
      curr: cand,
      explanation: ElectricTruncationExplanation.inferredFromNeighborClosing,
    );
  }

  var bestPool = byInt.values.first;
  var bestScore = double.infinity;
  for (final pool in byInt.values) {
    final cand = pickFromPool(pool);
    final succOpening = successorOpening;
    final score = succOpening != null
        ? (cand - succOpening).abs()
        : (cand - resolvedPrev - scaledDelta).abs();
    if (score < bestScore) {
      bestScore = score;
      bestPool = pool;
    }
  }

  final cand = pickFromPool(bestPool);
  return ResolvedElectricInputs(
    prev: resolvedPrev,
    curr: cand,
    explanation: ElectricTruncationExplanation.inferredFromNeighborClosing,
  );
}
