import 'package:get/get.dart';

import '../core/formatters.dart';
import '../models/bill.dart';
import '../services/bill_calculator.dart';
import 'readings_controller.dart';
import 'settings_controller.dart';

class MonthlyTotals {
  final String key;
  final DateTime month;
  final double totalKhr;
  final double totalKwh;
  final double totalM3;
  final int roomsReported;

  const MonthlyTotals({
    required this.key,
    required this.month,
    required this.totalKhr,
    required this.totalKwh,
    required this.totalM3,
    required this.roomsReported,
  });
}

class RoomMonthEntry {
  final String roomId;
  final BillBreakdown bill;
  const RoomMonthEntry({required this.roomId, required this.bill});
}

class DashboardController extends GetxController {
  DashboardController({
    required this.readingsController,
    required this.settingsController,
  });

  final ReadingsController readingsController;
  final SettingsController settingsController;

  /// Returns the totals for the most recent month present in the data,
  /// or for the current calendar month if no data exists.
  MonthlyTotals get currentMonthTotals {
    final keys = readingsController.monthKeys;
    final now = DateTime.now();
    final key = keys.isNotEmpty ? keys.first : formatYearMonthKey(now);
    return totalsFor(key);
  }

  MonthlyTotals totalsFor(String yearMonth) {
    final list = readingsController.forMonthKey(yearMonth);
    final s = settingsController.settings;
    double khr = 0, kwh = 0, m3 = 0;
    for (final r in list) {
      final b = computeBill(r, s);
      khr += b.totalKhr;
      kwh += b.elecUsageKwh;
      m3 += b.waterUsageM3;
    }
    return MonthlyTotals(
      key: yearMonth,
      month: parseYearMonthKey(yearMonth),
      totalKhr: khr,
      totalKwh: kwh,
      totalM3: m3,
      roomsReported: list.length,
    );
  }

  /// Last `count` months ending with the most recent month present (or
  /// the current month). Older months come first.
  List<MonthlyTotals> last(int count) {
    final keys = readingsController.monthKeys;
    final anchor = keys.isNotEmpty
        ? parseYearMonthKey(keys.first)
        : DateTime(DateTime.now().year, DateTime.now().month);
    final out = <MonthlyTotals>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(anchor.year, anchor.month - i, 1);
      out.add(totalsFor(formatYearMonthKey(m)));
    }
    return out;
  }

  /// For the given month, returns one entry per room (even rooms with no
  /// reading get a zero entry) so the dashboard can show every room.
  List<RoomMonthEntry> roomBreakdown(String yearMonth) {
    final list = readingsController.forMonthKey(yearMonth);
    final s = settingsController.settings;
    final byRoom = {for (final r in list) r.roomId: computeBill(r, s)};
    return [
      for (final room in s.rooms)
        RoomMonthEntry(
          roomId: room.id,
          bill:
              byRoom[room.id] ??
              BillBreakdown(
                elecUsageKwh: 0,
                waterUsageM3: 0,
                elecRateKhr: s.elecRateKhrPerKwh,
                waterRateKhr: s.waterRateKhrPerM3,
                khrPerUsd: s.khrPerUsd,
              ),
        ),
    ];
  }
}
