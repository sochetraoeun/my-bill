import 'package:get/get.dart';

import '../models/reading.dart';
import '../services/readings_repository.dart';
import '../services/room_reading_order_service.dart';

class ReadingsController extends GetxController {
  ReadingsController(
    this._repo, {
    required this.isCloud,
    required RoomReadingOrderService roomOrderService,
  }) : _roomOrderService = roomOrderService {
    _roomOrder.addAll(_roomOrderService.load());
  }

  final ReadingsRepository _repo;
  final RoomReadingOrderService _roomOrderService;
  final bool isCloud;
  final RxList<Reading> readings = <Reading>[].obs;

  /// Incremented when custom per-room list order changes (for Obx).
  final RxInt roomOrderEpoch = 0.obs;

  final Map<String, List<String>> _roomOrder = {};

  /// True when a reading for this room+month already exists in storage.
  bool exists({required String roomId, required String yearMonth}) =>
      readings.any((r) => r.roomId == roomId && r.yearMonth == yearMonth);

  Reading? find({required String roomId, required String yearMonth}) {
    for (final r in readings) {
      if (r.roomId == roomId && r.yearMonth == yearMonth) return r;
    }
    return null;
  }

  @override
  void onInit() {
    _repo.watchAll().listen((data) {
      final sorted = [...data]
        ..sort((a, b) {
          final m = b.month.compareTo(a.month);
          if (m != 0) return m;
          return a.roomId.compareTo(b.roomId);
        });
      readings.assignAll(sorted);
    });
    super.onInit();
  }

  Future<void> upsert(Reading reading) => _repo.upsert(reading);

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _pruneOrderAfterDelete(id);
    await _persistRoomOrder();
    roomOrderEpoch.value++;
  }

  Future<void> deleteByRoom(String roomId) async {
    await _repo.deleteByRoom(roomId);
    _roomOrder.remove(roomId);
    await _persistRoomOrder();
    roomOrderEpoch.value++;
  }

  Future<void> clear() async {
    await _repo.clear();
    _roomOrder.clear();
    await _persistRoomOrder();
    roomOrderEpoch.value++;
  }

  List<Reading> forRoom(String roomId) =>
      readings.where((r) => r.roomId == roomId).toList();

  /// [forRoom] with optional saved manual order (room detail + PDF export).
  List<Reading> orderedForRoom(String roomId) {
    roomOrderEpoch.value;
    final base = forRoom(roomId);
    return _applyReadingOrder(base, _roomOrder[roomId]);
  }

  Future<void> setRoomReadingOrder(String roomId, List<String> orderedIds) async {
    _roomOrder[roomId] = List<String>.from(orderedIds);
    await _persistRoomOrder();
    roomOrderEpoch.value++;
  }

  void _pruneOrderAfterDelete(String id) {
    for (final e in _roomOrder.entries.toList()) {
      final next = e.value.where((x) => x != id).toList();
      if (next.length != e.value.length) {
        if (next.isEmpty) {
          _roomOrder.remove(e.key);
        } else {
          _roomOrder[e.key] = next;
        }
      }
    }
  }

  Future<void> _persistRoomOrder() =>
      _roomOrderService.save(Map<String, List<String>>.from(_roomOrder));

  List<Reading> _applyReadingOrder(
    List<Reading> items,
    List<String>? preferredIds,
  ) {
    if (preferredIds == null || preferredIds.isEmpty) {
      return List<Reading>.from(items)
        ..sort((a, b) => b.month.compareTo(a.month));
    }
    final byId = {for (final r in items) r.id: r};
    final seen = <String>{};
    final ordered = <Reading>[];
    for (final id in preferredIds) {
      final r = byId[id];
      if (r != null) {
        ordered.add(r);
        seen.add(id);
      }
    }
    final rest = items.where((r) => !seen.contains(r.id)).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    ordered.addAll(rest);
    return ordered;
  }

  List<Reading> forMonthKey(String yearMonth) =>
      readings.where((r) => r.yearMonth == yearMonth).toList();

  Reading? latestForRoom(String roomId) {
    final list = forRoom(roomId);
    if (list.isEmpty) return null;
    return list.first;
  }

  /// Returns the available year-month keys (descending) found in readings.
  List<String> get monthKeys {
    final set = <String>{for (final r in readings) r.yearMonth};
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}
