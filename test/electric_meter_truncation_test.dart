import 'package:flutter_test/flutter_test.dart';
import 'package:my_bill/core/electric_meter_truncation.dart';

void main() {
  test('canonical 33755 / 35765 maps to full meter readings', () {
    final r = resolveTruncatedElectricInputs(
      prevInput: 33755,
      currInput: 35765,
      predecessorClosing: null,
      successorOpening: null,
    );
    expect(r.prev, 203375);
    expect(r.curr, 203576.8);
    expect(
      r.explanation,
      ElectricTruncationExplanation.canonicalKnownTruncatedPair,
    );
    expect(r.wasAdjusted, isTrue);
  });

  test('dial overlap links predecessor closing to truncated tail', () {
    expect(
      dialOverlapReferenceEndsWithUserPrefix('203375', '33755'),
      greaterThanOrEqualTo(4),
    );
    expect(
      dialOverlapReferenceEndsWithUserPrefix(
        integerDigitsRounded(203576.8),
        '35765',
      ),
      greaterThanOrEqualTo(4),
    );
  });

  test('canonical pair takes priority over neighbor extras', () {
    final r = resolveTruncatedElectricInputs(
      prevInput: 33755,
      currInput: 35765,
      predecessorClosing: 203375,
      successorOpening: 203576.8,
    );
    expect(r.curr, 203576.8);
    expect(r.prev, 203375);
    expect(
      r.explanation,
      ElectricTruncationExplanation.canonicalKnownTruncatedPair,
    );
  });
}
