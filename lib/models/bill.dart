class BillBreakdown {
  final double elecUsageKwh;
  final double waterUsageM3;
  final double elecRateKhr;
  final double waterRateKhr;
  final double khrPerUsd;

  const BillBreakdown({
    required this.elecUsageKwh,
    required this.waterUsageM3,
    required this.elecRateKhr,
    required this.waterRateKhr,
    required this.khrPerUsd,
  });

  double get elecAmountKhr => elecUsageKwh * elecRateKhr;
  double get waterAmountKhr => waterUsageM3 * waterRateKhr;
  double get totalKhr => elecAmountKhr + waterAmountKhr;
  double get totalUsd => khrPerUsd == 0 ? 0 : totalKhr / khrPerUsd;
}
