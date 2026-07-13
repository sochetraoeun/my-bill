import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'room.dart';

class AppSettings {
  /// Electricity tariff in USD per kWh. KHR is derived via [khrPerUsd].
  final double elecRateUsdPerKwh;

  /// Water tariff in USD per m³. KHR is derived via [khrPerUsd].
  final double waterRateUsdPerM3;
  final double khrPerUsd;
  final String localeCode;
  final ThemeMode themeMode;
  final List<Room> rooms;

  const AppSettings({
    required this.elecRateUsdPerKwh,
    required this.waterRateUsdPerM3,
    required this.khrPerUsd,
    required this.localeCode,
    required this.themeMode,
    required this.rooms,
  });

  factory AppSettings.defaults() => AppSettings(
    elecRateUsdPerKwh: Defaults.elecRateUsdPerKwh,
    waterRateUsdPerM3: Defaults.waterRateUsdPerM3,
    khrPerUsd: Defaults.khrPerUsd,
    localeCode: Defaults.localeCode,
    themeMode: Defaults.themeMode,
    rooms: [
      for (int i = 0; i < kRoomCount; i++)
        Room(id: kRoomIds[i], name: 'Room ${i + 1}'),
    ],
  );

  AppSettings copyWith({
    double? elecRateUsdPerKwh,
    double? waterRateUsdPerM3,
    double? khrPerUsd,
    String? localeCode,
    ThemeMode? themeMode,
    List<Room>? rooms,
  }) => AppSettings(
    elecRateUsdPerKwh: elecRateUsdPerKwh ?? this.elecRateUsdPerKwh,
    waterRateUsdPerM3: waterRateUsdPerM3 ?? this.waterRateUsdPerM3,
    khrPerUsd: khrPerUsd ?? this.khrPerUsd,
    localeCode: localeCode ?? this.localeCode,
    themeMode: themeMode ?? this.themeMode,
    rooms: rooms ?? this.rooms,
  );

  Map<String, dynamic> toJson() => {
    'elecRateUsdPerKwh': elecRateUsdPerKwh,
    'waterRateUsdPerM3': waterRateUsdPerM3,
    'khrPerUsd': khrPerUsd,
    'localeCode': localeCode,
    'themeMode': _themeModeToString(themeMode),
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final khrPerUsd = (j['khrPerUsd'] as num?)?.toDouble() ?? Defaults.khrPerUsd;
    return AppSettings(
      elecRateUsdPerKwh: _rateUsd(
        j,
        usdKey: 'elecRateUsdPerKwh',
        legacyKhrKey: 'elecRateKhrPerKwh',
        khrPerUsd: khrPerUsd,
        fallback: Defaults.elecRateUsdPerKwh,
      ),
      waterRateUsdPerM3: _rateUsd(
        j,
        usdKey: 'waterRateUsdPerM3',
        legacyKhrKey: 'waterRateKhrPerM3',
        khrPerUsd: khrPerUsd,
        fallback: Defaults.waterRateUsdPerM3,
      ),
      khrPerUsd: khrPerUsd,
      localeCode: j['localeCode'] as String? ?? Defaults.localeCode,
      themeMode: _themeModeFromString(j['themeMode'] as String?),
      rooms: (j['rooms'] as List)
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Reads a USD tariff, migrating older settings that stored the rate in KHR
  /// by dividing the legacy KHR value by the exchange rate.
  static double _rateUsd(
    Map<String, dynamic> j, {
    required String usdKey,
    required String legacyKhrKey,
    required double khrPerUsd,
    required double fallback,
  }) {
    final usd = j[usdKey];
    if (usd is num) return usd.toDouble();
    final legacyKhr = j[legacyKhrKey];
    if (legacyKhr is num && khrPerUsd > 0) {
      return legacyKhr.toDouble() / khrPerUsd;
    }
    return fallback;
  }
}

String _themeModeToString(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'system',
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
};

ThemeMode _themeModeFromString(String? value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};
