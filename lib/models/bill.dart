class BillBreakdown {
  final double elecUsageKwh;
  final double waterUsageM3;

  /// Electricity tariff in USD per kWh.
  final double elecRateUsd;

  /// Water tariff in USD per m³.
  final double waterRateUsd;
  final double khrPerUsd;

  const BillBreakdown({
    required this.elecUsageKwh,
    required this.waterUsageM3,
    required this.elecRateUsd,
    required this.waterRateUsd,
    required this.khrPerUsd,
  });

  // USD is the primary currency; amounts are computed in USD first.
  double get elecAmountUsd => elecUsageKwh * elecRateUsd;
  double get waterAmountUsd => waterUsageM3 * waterRateUsd;
  double get totalUsd => elecAmountUsd + waterAmountUsd;

  // KHR is derived from USD using the exchange rate.
  double get elecAmountKhr => elecAmountUsd * khrPerUsd;
  double get waterAmountKhr => waterAmountUsd * khrPerUsd;
  double get totalKhr => totalUsd * khrPerUsd;
}
