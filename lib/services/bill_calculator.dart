import '../models/bill.dart';
import '../models/reading.dart';
import '../models/settings.dart';

BillBreakdown computeBill(Reading r, AppSettings s) => BillBreakdown(
  elecUsageKwh: r.elecUsage,
  waterUsageM3: r.waterUsage,
  elecRateKhr: s.elecRateKhrPerKwh,
  waterRateKhr: s.waterRateKhrPerM3,
  khrPerUsd: s.khrPerUsd,
);

BillBreakdown computeBillFromValues({
  required double prevElec,
  required double currElec,
  required double prevWater,
  required double currWater,
  required AppSettings s,
}) => BillBreakdown(
  elecUsageKwh: (currElec - prevElec).clamp(0, double.infinity),
  waterUsageM3: (currWater - prevWater).clamp(0, double.infinity),
  elecRateKhr: s.elecRateKhrPerKwh,
  waterRateKhr: s.waterRateKhrPerM3,
  khrPerUsd: s.khrPerUsd,
);
