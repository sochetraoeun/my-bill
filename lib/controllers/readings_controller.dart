import 'package:get/get.dart';

import '../models/reading.dart';
import '../services/readings_repository.dart';

class ReadingsController extends GetxController {
  ReadingsController(this._repo, {required this.isCloud});

  final ReadingsRepository _repo;
  final bool isCloud;
  final RxList<Reading> readings = <Reading>[].obs;

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
  Future<void> delete(String id) => _repo.delete(id);
  Future<void> deleteByRoom(String roomId) => _repo.deleteByRoom(roomId);
  Future<void> clear() => _repo.clear();

  List<Reading> forRoom(String roomId) =>
      readings.where((r) => r.roomId == roomId).toList();

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
