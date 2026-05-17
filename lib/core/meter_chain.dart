import '../models/reading.dart';
import 'formatters.dart' show metersRoughlyEqual;

/// Reading strictly before [month], same room, excluding docs in [omitIds].
Reading? predecessorReading(
  Iterable<Reading> readings,
  String roomId,
  DateTime month,
  Set<String> omitIds,
) {
  Reading? best;
  for (final r in readings) {
    if (omitIds.contains(r.id) || r.roomId != roomId) continue;
    if (!r.month.isBefore(month)) continue;
    if (best == null || r.month.isAfter(best.month)) best = r;
  }
  return best;
}

/// Earliest reading strictly after [month], same room.
Reading? successorReading(
  Iterable<Reading> readings,
  String roomId,
  DateTime month,
  Set<String> omitIds,
) {
  Reading? best;
  for (final r in readings) {
    if (omitIds.contains(r.id) || r.roomId != roomId) continue;
    if (!r.month.isAfter(month)) continue;
    if (best == null || r.month.isBefore(best.month)) best = r;
  }
  return best;
}

List<MeterNeighborMismatch> mismatchesWithNeighbors(
  Iterable<Reading> readings,
  Reading draft,
  Set<String> omitNeighborIds,
) {
  final out = <MeterNeighborMismatch>[];
  final pred = predecessorReading(readings, draft.roomId, draft.month, omitNeighborIds);
  if (pred != null) {
    if (!metersRoughlyEqual(pred.currElec, draft.prevElec)) {
      out.add(
        MeterNeighborMismatch(
          isPredecessor: true,
          isElectricity: true,
          neighborMonth: pred.month,
          expected: pred.currElec,
          got: draft.prevElec,
        ),
      );
    }
    if (!metersRoughlyEqual(pred.currWater, draft.prevWater)) {
      out.add(
        MeterNeighborMismatch(
          isPredecessor: true,
          isElectricity: false,
          neighborMonth: pred.month,
          expected: pred.currWater,
          got: draft.prevWater,
        ),
      );
    }
  }
  final succ = successorReading(readings, draft.roomId, draft.month, omitNeighborIds);
  if (succ != null) {
    if (!metersRoughlyEqual(succ.prevElec, draft.currElec)) {
      out.add(
        MeterNeighborMismatch(
          isPredecessor: false,
          isElectricity: true,
          neighborMonth: succ.month,
          expected: succ.prevElec,
          got: draft.currElec,
        ),
      );
    }
    if (!metersRoughlyEqual(succ.prevWater, draft.currWater)) {
      out.add(
        MeterNeighborMismatch(
          isPredecessor: false,
          isElectricity: false,
          neighborMonth: succ.month,
          expected: succ.prevWater,
          got: draft.currWater,
        ),
      );
    }
  }
  return out;
}

class MeterNeighborMismatch {
  const MeterNeighborMismatch({
    required this.isPredecessor,
    required this.isElectricity,
    required this.neighborMonth,
    required this.expected,
    required this.got,
  });

  final bool isPredecessor;
  final bool isElectricity;
  final DateTime neighborMonth;
  final double expected;
  final double got;
}
