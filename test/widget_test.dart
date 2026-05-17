import 'package:flutter_test/flutter_test.dart';

import 'package:my_bill/models/reading.dart';
import 'package:my_bill/models/settings.dart';
import 'package:my_bill/services/bill_calculator.dart';

void main() {
  test('computeBill multiplies usage by rates', () {
    final r = Reading(
      id: 'r1',
      roomId: 'room_1',
      month: DateTime(2026, 5),
      prevElec: 100,
      currElec: 200,
      prevWater: 10,
      currWater: 15,
      createdAt: DateTime(2026, 5, 28),
    );
    final s = AppSettings.defaults();
    final b = computeBill(r, s);

    expect(b.elecUsageKwh, 100);
    expect(b.waterUsageM3, 5);
    expect(b.elecAmountKhr, 100 * s.elecRateKhrPerKwh);
    expect(b.waterAmountKhr, 5 * s.waterRateKhrPerM3);
    expect(b.totalKhr, b.elecAmountKhr + b.waterAmountKhr);
    expect(b.totalUsd, b.totalKhr / s.khrPerUsd);
  });

  test('computeBill clamps negative usage to zero', () {
    final r = Reading(
      id: 'r2',
      roomId: 'room_1',
      month: DateTime(2026, 5),
      prevElec: 200,
      currElec: 100,
      prevWater: 5,
      currWater: 5,
      createdAt: DateTime(2026, 5, 28),
    );
    final b = computeBill(r, AppSettings.defaults());
    expect(b.elecUsageKwh, 0);
    expect(b.waterUsageM3, 0);
  });
}
