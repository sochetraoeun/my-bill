import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/settings.dart';

class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  AppSettings load() {
    final raw = _prefs.getString(StorageKeys.settings);
    if (raw == null) return AppSettings.defaults();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(
      StorageKeys.settings,
      jsonEncode(settings.toJson()),
    );
  }
}
