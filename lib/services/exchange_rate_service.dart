import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the official FX endpoint cannot produce a usable KHR/USD rate.
class ExchangeRateFetchException implements Exception {
  ExchangeRateFetchException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Fetches the Cambodia MEF realtime USD/KHR reference (KHR per 1 USD).
class ExchangeRateService {
  ExchangeRateService(this._resolveUrl);

  final String Function() _resolveUrl;

  static const Duration _timeout = Duration(seconds: 25);

  /// Returns official KHR per 1 USD (same unit as [AppSettings.khrPerUsd]).
  Future<double> fetchOfficialKhrPerUsd() async {
    final uri = Uri.parse(_resolveUrl());
    final response = await http
        .get(uri, headers: const {'accept': 'application/json'})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw ExchangeRateFetchException('HTTP ${response.statusCode}');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ExchangeRateFetchException('Invalid JSON.');
    }

    final row = _findUsdRow(decoded);
    if (row == null) {
      throw ExchangeRateFetchException('USD rate not found in response.');
    }

    final raw = row['average'] ?? row['bid'] ?? row['ask'];
    if (raw == null) {
      throw ExchangeRateFetchException('Missing rate fields.');
    }

    final rate = switch (raw) {
      num v => v.toDouble(),
      String s when s.trim().isNotEmpty => double.tryParse(s.trim()),
      _ => null,
    };

    if (rate == null || rate <= 0 || rate.isNaN || rate.isInfinite) {
      throw ExchangeRateFetchException('Could not parse rate value.');
    }

    // Sanity bounds for KHR/USD reference (narrows malformed data).
    if (rate < 1000 || rate > 20000) {
      throw ExchangeRateFetchException('Rate out of expected range.');
    }

    return rate;
  }

  Map<String, dynamic>? _findUsdRow(dynamic decoded) {
    Iterable<Map<String, dynamic>>? maps;

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        maps = data.whereType<Map<String, dynamic>>();
      } else if (decoded['currency_id'] == 'USD') {
        return decoded;
      }
    } else if (decoded is List) {
      maps = decoded.whereType<Map<String, dynamic>>();
    }

    if (maps == null) return null;

    for (final m in maps) {
      if (m['currency_id'] == 'USD') {
        return m;
      }
    }
    return null;
  }
}
