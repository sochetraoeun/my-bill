import 'package:get/get.dart';

import '../core/formatters.dart';
import '../models/bill.dart';
import '../models/reading.dart';
import '../services/bill_calculator.dart';
import 'readings_controller.dart';
import 'settings_controller.dart';

class MonthlyTotals {
  final String key;
  final DateTime month;
  final double totalKhr;
  final double totalKwh;
  final double totalM3;
  final double elecKhr;
  final double waterKhr;
  final int roomsReported;

  const MonthlyTotals({
    required this.key,
    required this.month,
    required this.totalKhr,
    required this.totalKwh,
    required this.totalM3,
    required this.elecKhr,
    required this.waterKhr,
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
    double khr = 0, kwh = 0, m3 = 0, eKhr = 0, wKhr = 0;
    for (final r in list) {
      final b = computeBill(r, s);
      khr += b.totalKhr;
      kwh += b.elecUsageKwh;
      m3 += b.waterUsageM3;
      eKhr += b.elecAmountKhr;
      wKhr += b.waterAmountKhr;
    }
    return MonthlyTotals(
      key: yearMonth,
      month: parseYearMonthKey(yearMonth),
      totalKhr: khr,
      totalKwh: kwh,
      totalM3: m3,
      elecKhr: eKhr,
      waterKhr: wKhr,
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

  /// Returns the progress status for the current month based on collection
  /// date spans per room. A room is "complete" when both its electricity and
  /// water date spans cover the full billing month.
  MonthProgress monthProgress() {
    final s = settingsController.settings;
    final now = DateTime.now();
    final currentKey = formatYearMonthKey(now);
    final monthReadings = readingsController.forMonthKey(currentKey);
    final totalRooms = s.rooms.length;

    final roomStatuses = <String, RoomCompletionStatus>{};
    final byRoom = <String, Reading>{};
    for (final r in monthReadings) {
      byRoom[r.roomId] = r;
    }

    for (final room in s.rooms) {
      final r = byRoom[room.id];
      if (r == null) {
        roomStatuses[room.id] = RoomCompletionStatus(
          roomId: room.id,
          hasReading: false,
          elecDaysSpan: null,
          waterDaysSpan: null,
          isElecComplete: false,
          isWaterComplete: false,
        );
      } else {
        roomStatuses[room.id] = RoomCompletionStatus(
          roomId: room.id,
          hasReading: true,
          elecDaysSpan: r.elecDaysSpan,
          waterDaysSpan: r.waterDaysSpan,
          isElecComplete: r.isElecMonthComplete,
          isWaterComplete: r.isWaterMonthComplete,
        );
      }
    }

    final completeCount =
        roomStatuses.values.where((s) => s.isFullyComplete).length;

    int? estimatedDaysRemaining;
    if (completeCount < totalRooms) {
      estimatedDaysRemaining = _estimateRemainingDays(roomStatuses.values);
    }

    return MonthProgress(
      yearMonth: currentKey,
      month: DateTime(now.year, now.month),
      totalRooms: totalRooms,
      completeCount: completeCount,
      roomStatuses: roomStatuses,
      estimatedDaysRemaining: estimatedDaysRemaining,
    );
  }

  /// Estimates remaining days based on how far incomplete rooms are from
  /// the full billing month.
  int? _estimateRemainingDays(Iterable<RoomCompletionStatus> statuses) {
    final now = DateTime.now();
    final monthDays = DateTime(now.year, now.month + 1, 0).day;
    final threshold = monthDays - 1;
    int maxNeeded = 0;
    for (final s in statuses) {
      if (s.isFullyComplete) continue;
      if (!s.hasReading) {
        maxNeeded = threshold;
        break;
      }
      final elecRemain = s.isElecComplete ? 0 : threshold - (s.elecDaysSpan ?? 0);
      final waterRemain = s.isWaterComplete ? 0 : threshold - (s.waterDaysSpan ?? 0);
      final roomMax = elecRemain > waterRemain ? elecRemain : waterRemain;
      if (roomMax > maxNeeded) maxNeeded = roomMax;
    }
    return maxNeeded > 0 ? maxNeeded : null;
  }
}

class RoomCompletionStatus {
  final String roomId;
  final bool hasReading;
  final int? elecDaysSpan;
  final int? waterDaysSpan;
  final bool isElecComplete;
  final bool isWaterComplete;

  const RoomCompletionStatus({
    required this.roomId,
    required this.hasReading,
    required this.elecDaysSpan,
    required this.waterDaysSpan,
    required this.isElecComplete,
    required this.isWaterComplete,
  });

  bool get isFullyComplete => hasReading && isElecComplete && isWaterComplete;
}

class MonthProgress {
  final String yearMonth;
  final DateTime month;
  final int totalRooms;
  final int completeCount;
  final Map<String, RoomCompletionStatus> roomStatuses;
  final int? estimatedDaysRemaining;

  const MonthProgress({
    required this.yearMonth,
    required this.month,
    required this.totalRooms,
    required this.completeCount,
    required this.roomStatuses,
    this.estimatedDaysRemaining,
  });

  bool get isAllComplete => completeCount >= totalRooms;
  double get progress => totalRooms == 0 ? 0 : completeCount / totalRooms;
}
