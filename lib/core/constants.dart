/// App-wide compile-time constants and defaults.
library;

import 'package:flutter/material.dart';

const int kRoomCount = 6;

/// Stable IDs for rooms so that data survives renames.
List<String> get kRoomIds => List.generate(kRoomCount, (i) => 'room_${i + 1}');

/// Firestore doc written by `fetch-rate.js` / `.github/workflows/exchnage-rate.yml`.
/// Path format: `{collection}/{documentId}`.
const String kFirestoreExchangeRateCollection = 'settings';
const String kFirestoreExchangeRateDocId = 'exchange_rate';

class Defaults {
  /// Tariffs are entered and stored in USD; KHR is derived via [khrPerUsd].
  static const double elecRateUsdPerKwh = 0.20;
  static const double waterRateUsdPerM3 = 0.50;
  static const double khrPerUsd = 4100;
  static const String localeCode = 'en';
  static const ThemeMode themeMode = ThemeMode.system;
}

class StorageKeys {
  static const String settings = 'mybill.settings.v1';
  static const String localReadings = 'mybill.readings.v1';
  /// JSON map: roomId → ordered list of reading ids (custom list order in room detail).
  static const String roomReadingOrder = 'mybill.room_reading_order.v1';
}
