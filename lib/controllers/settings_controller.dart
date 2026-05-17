import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/room.dart';
import '../models/settings.dart';
import '../services/exchange_rate_service.dart';
import '../services/settings_service.dart';

/// Thrown when [SettingsController.renameRoom] would duplicate another room's name.
class DuplicateRoomNameException implements Exception {
  const DuplicateRoomNameException();
}

/// Thrown when [SettingsController.removeRoom] would leave the app with no rooms.
class CannotDeleteLastRoomException implements Exception {
  const CannotDeleteLastRoomException();
}

class SettingsController extends GetxController {
  SettingsController(this._service, this._exchangeRates);

  RxString appVersion = ''.obs;
  final SettingsService _service;
  final ExchangeRateService _exchangeRates;
  final fetchingOfficialFx = false.obs;
  final Rx<AppSettings> _settings = AppSettings.defaults().obs;

  AppSettings get settings => _settings.value;
  Rx<AppSettings> get rx => _settings;

  ThemeMode get themeMode => _settings.value.themeMode;

  @override
  void onInit() {
    _settings.value = _service.load();
    loadAppVersion();
    super.onInit();
  }

  Future<void> loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion.value = packageInfo.version;
  }

  Future<void> updateRates({
    double? elec,
    double? water,
    double? khrPerUsd,
  }) async {
    _settings.value = _settings.value.copyWith(
      elecRateKhrPerKwh: elec,
      waterRateKhrPerM3: water,
      khrPerUsd: khrPerUsd,
    );
    await _service.save(_settings.value);
  }

  /// Cambodia MEF official USD/KHR (KHR per 1 USD), saved as [AppSettings.khrPerUsd].
  Future<void> refreshOfficialKhrPerUsdRate() async {
    if (fetchingOfficialFx.value) return;
    fetchingOfficialFx.value = true;
    try {
      final rate = await _exchangeRates.fetchOfficialKhrPerUsd();
      await updateRates(khrPerUsd: rate);
    } finally {
      fetchingOfficialFx.value = false;
    }
  }

  Future<void> setLocale(String code) async {
    _settings.value = _settings.value.copyWith(localeCode: code);
    await _service.save(_settings.value);
    // GetMaterialApp uses `Get.locale ?? locale` for MaterialApp. Get.locale is
    // only assigned in GetMaterialApp.initState, so it must be updated here or
    // the UI stays on the old language until restart.
    Get.locale = Locale(code);
    Get.appUpdate();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings.value = _settings.value.copyWith(themeMode: mode);
    await _service.save(_settings.value);
  }

  Future<void> renameRoom(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Room name cannot be empty.');
    }
    final normalized = trimmed.toLowerCase();
    final takenElsewhere = _settings.value.rooms.any(
      (r) => r.id != id && r.name.trim().toLowerCase() == normalized,
    );
    if (takenElsewhere) {
      throw const DuplicateRoomNameException();
    }
    final updated = _settings.value.rooms
        .map((r) => r.id == id ? r.copyWith(name: trimmed) : r)
        .toList();
    _settings.value = _settings.value.copyWith(rooms: updated);
    await _service.save(_settings.value);
  }

  Future<void> addRoom(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Room name cannot be empty.');
    }
    final normalized = trimmed.toLowerCase();
    final duplicate = _settings.value.rooms.any(
      (r) => r.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const DuplicateRoomNameException();
    }
    final id = 'room_${DateTime.now().microsecondsSinceEpoch}';
    final next = [..._settings.value.rooms, Room(id: id, name: trimmed)];
    _settings.value = _settings.value.copyWith(rooms: next);
    await _service.save(_settings.value);
  }

  Future<void> removeRoom(String id) async {
    if (_settings.value.rooms.length <= 1) {
      throw const CannotDeleteLastRoomException();
    }
    final next = _settings.value.rooms
        .where((r) => r.id != id)
        .toList(growable: false);
    if (next.length == _settings.value.rooms.length) {
      return;
    }
    _settings.value = _settings.value.copyWith(rooms: next);
    await _service.save(_settings.value);
  }

  Room roomById(String id) => _settings.value.rooms.firstWhere(
    (r) => r.id == id,
    orElse: () => Room(id: id, name: id),
  );
}
