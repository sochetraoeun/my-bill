/// App-wide compile-time constants and defaults.
library;

import 'package:flutter/material.dart';

const int kRoomCount = 6;

/// Stable IDs for rooms so that data survives renames.
List<String> get kRoomIds => List.generate(kRoomCount, (i) => 'room_${i + 1}');

/// Cambodia MEF official realtime USD/KHR API (KHR per USD).
const String kDefaultExchangeRateApiUrl =
    'https://data.mef.gov.kh/api/v1/realtime-api/exchange-rate';

class Defaults {
  static const double elecRateKhrPerKwh = 800;
  static const double waterRateKhrPerM3 = 2000;
  static const double khrPerUsd = 4100;
  static const String localeCode = 'en';
  static const ThemeMode themeMode = ThemeMode.system;
}

class StorageKeys {
  static const String settings = 'mybill.settings.v1';
  static const String localReadings = 'mybill.readings.v1';
}
