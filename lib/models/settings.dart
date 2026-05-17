import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'room.dart';

class AppSettings {
  final double elecRateKhrPerKwh;
  final double waterRateKhrPerM3;
  final double khrPerUsd;
  final String localeCode;
  final ThemeMode themeMode;
  final List<Room> rooms;

  const AppSettings({
    required this.elecRateKhrPerKwh,
    required this.waterRateKhrPerM3,
    required this.khrPerUsd,
    required this.localeCode,
    required this.themeMode,
    required this.rooms,
  });

  factory AppSettings.defaults() => AppSettings(
    elecRateKhrPerKwh: Defaults.elecRateKhrPerKwh,
    waterRateKhrPerM3: Defaults.waterRateKhrPerM3,
    khrPerUsd: Defaults.khrPerUsd,
    localeCode: Defaults.localeCode,
    themeMode: Defaults.themeMode,
    rooms: [
      for (int i = 0; i < kRoomCount; i++)
        Room(id: kRoomIds[i], name: 'Room ${i + 1}'),
    ],
  );

  AppSettings copyWith({
    double? elecRateKhrPerKwh,
    double? waterRateKhrPerM3,
    double? khrPerUsd,
    String? localeCode,
    ThemeMode? themeMode,
    List<Room>? rooms,
  }) => AppSettings(
    elecRateKhrPerKwh: elecRateKhrPerKwh ?? this.elecRateKhrPerKwh,
    waterRateKhrPerM3: waterRateKhrPerM3 ?? this.waterRateKhrPerM3,
    khrPerUsd: khrPerUsd ?? this.khrPerUsd,
    localeCode: localeCode ?? this.localeCode,
    themeMode: themeMode ?? this.themeMode,
    rooms: rooms ?? this.rooms,
  );

  Map<String, dynamic> toJson() => {
    'elecRateKhrPerKwh': elecRateKhrPerKwh,
    'waterRateKhrPerM3': waterRateKhrPerM3,
    'khrPerUsd': khrPerUsd,
    'localeCode': localeCode,
    'themeMode': _themeModeToString(themeMode),
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    elecRateKhrPerKwh: (j['elecRateKhrPerKwh'] as num).toDouble(),
    waterRateKhrPerM3: (j['waterRateKhrPerM3'] as num).toDouble(),
    khrPerUsd: (j['khrPerUsd'] as num).toDouble(),
    localeCode: j['localeCode'] as String,
    themeMode: _themeModeFromString(j['themeMode'] as String?),
    rooms: (j['rooms'] as List)
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
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
