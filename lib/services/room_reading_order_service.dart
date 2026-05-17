import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Persists custom display order of readings per room (list of reading ids).
class RoomReadingOrderService {
  RoomReadingOrderService(this._prefs);

  final SharedPreferences _prefs;

  Map<String, List<String>> load() {
    final raw = _prefs.getString(StorageKeys.roomReadingOrder);
    if (raw == null || raw.isEmpty) return {};
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return j.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, List<String>> orderByRoom) async {
    await _prefs.setString(
      StorageKeys.roomReadingOrder,
      jsonEncode(orderByRoom),
    );
  }
}
