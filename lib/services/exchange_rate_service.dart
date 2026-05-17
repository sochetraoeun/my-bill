import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';

/// Thrown when the stored Firestore FX document is missing or unusable.
class ExchangeRateSyncException implements Exception {
  ExchangeRateSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Loads USD/KHR (KHR per 1 USD) from Firestore — same unit as [AppSettings.khrPerUsd].
///
/// The value is maintained by CI (`fetch-rate.js`); the app does not call MEF directly.
class ExchangeRateService {
  DocumentReference<Map<String, dynamic>> get _rateRef =>
      FirebaseFirestore.instance
          .collection(kFirestoreExchangeRateCollection)
          .doc(kFirestoreExchangeRateDocId);

  /// Validates and returns [khrPerUsd] from a Firestore document map.
  double khrPerUsdFromMap(Map<String, dynamic> data) {
    final raw = data['khrPerUsd'];
    final rate = switch (raw) {
      num n => n.toDouble(),
      String s when s.trim().isNotEmpty => double.tryParse(s.trim()),
      _ => null,
    };

    if (rate == null || rate <= 0 || rate.isNaN || rate.isInfinite) {
      throw ExchangeRateSyncException('Invalid khrPerUsd in Firestore.');
    }

    if (rate < 1000 || rate > 20000) {
      throw ExchangeRateSyncException('KHR/USD out of expected range.');
    }

    return rate;
  }

  /// Same validation as [khrPerUsdFromMap] but returns null instead of throwing.
  double? tryKhrPerUsdFromMap(Map<String, dynamic> data) {
    try {
      return khrPerUsdFromMap(data);
    } on ExchangeRateSyncException {
      return null;
    }
  }

  /// One-shot read (e.g. tests or tools). Prefer the Firestore snapshot stream in [SettingsController] for the UI.
  Future<double> fetchKhrPerUsdFromFirestore() async {
    final snap = await _rateRef.get();
    if (!snap.exists || snap.data() == null) {
      throw ExchangeRateSyncException('Exchange rate document missing.');
    }
    return khrPerUsdFromMap(snap.data()!);
  }
}
