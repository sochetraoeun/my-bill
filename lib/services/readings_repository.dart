import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/reading.dart';

abstract class ReadingsRepository {
  Stream<List<Reading>> watchAll();
  Future<List<Reading>> getAll();
  Future<void> upsert(Reading reading);
  Future<void> delete(String id);
  Future<void> deleteByRoom(String roomId);
  Future<void> clear();
}

class LocalReadingsRepository implements ReadingsRepository {
  LocalReadingsRepository(this._prefs);

  final SharedPreferences _prefs;
  final _controller = StreamController<List<Reading>>.broadcast();
  List<Reading> _cache = const [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = _prefs.getString(StorageKeys.localReadings);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => Reading.fromJson(e as Map<String, dynamic>))
          .toList();
      _cache = list;
    }
    _loaded = true;
    _controller.add(List.unmodifiable(_cache));
  }

  Future<void> _persist() async {
    await _prefs.setString(
      StorageKeys.localReadings,
      jsonEncode(_cache.map((r) => r.toJson()).toList()),
    );
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Stream<List<Reading>> watchAll() async* {
    await _ensureLoaded();
    yield List.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Future<List<Reading>> getAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  @override
  Future<void> upsert(Reading reading) async {
    await _ensureLoaded();
    final idx = _cache.indexWhere((r) => r.id == reading.id);
    final next = [..._cache];
    if (idx == -1) {
      next.add(reading);
    } else {
      next[idx] = reading;
    }
    _cache = next;
    await _persist();
  }

  @override
  Future<void> delete(String id) async {
    await _ensureLoaded();
    _cache = _cache.where((r) => r.id != id).toList();
    await _persist();
  }

  @override
  Future<void> deleteByRoom(String roomId) async {
    await _ensureLoaded();
    final next = _cache.where((r) => r.roomId != roomId).toList();
    if (next.length == _cache.length) return;
    _cache = next;
    await _persist();
  }

  @override
  Future<void> clear() async {
    await _ensureLoaded();
    _cache = const [];
    await _persist();
  }
}
