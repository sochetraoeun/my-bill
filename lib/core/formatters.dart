import 'package:intl/intl.dart';

final _khr = NumberFormat.decimalPattern('en_US');
final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
final _whole = NumberFormat.decimalPattern('en_US');
final _decimal = NumberFormat('#,##0.0', 'en_US');
final _meterInputDisplay = NumberFormat('#,##0.###', 'en_US');

String formatKhr(num value) => '${_khr.format(value.round())} ៛';

String formatUsd(num value) => _usd.format(value);

String formatKwh(num value) => '${_decimal.format(value)} kWh';

String formatM3(num value) => '${_decimal.format(value)} m³';

String formatInt(num value) => _whole.format(value);

/// `2025-05` style year-month key.
String formatYearMonthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

String formatYearMonthHuman(DateTime d, String locale) =>
    DateFormat.yMMMM(locale).format(DateTime(d.year, d.month));

DateTime parseYearMonthKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

/// Removes grouping separators users may type when copying meter readings.
String normalizeMeterReadingInput(String raw) {
  var s = raw.trim();
  s = s.replaceAll(',', '');
  s = s.replaceAll(' ', '');
  s = s.replaceAll('\u00a0', '');
  s = s.replaceAll('\u202f', '');
  return s;
}

/// Parses a meter value after [normalizeMeterReadingInput].
double? tryParseMeterReading(String raw) =>
    double.tryParse(normalizeMeterReadingInput(raw));

/// Display form for readings / meter inputs (grouped thousands for clarity).
String formatMeterInputText(double v) => _meterInputDisplay.format(v);

/// Whether two meters from storage are the same reading (rounding noise).
bool metersRoughlyEqual(double a, double b) => (a - b).abs() < 1e-9;
