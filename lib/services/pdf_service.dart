import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/formatters.dart';
import '../models/bill.dart';
import '../models/reading.dart';
import '../models/room.dart';
import '../models/settings.dart';
import 'bill_calculator.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  pw.Font? _khmerFont;

  Future<pw.Font> _loadKhmerFont() async {
    if (_khmerFont != null) return _khmerFont!;
    final bytes = await rootBundle.load(
      'assets/fonts/NotoSansKhmer-Regular.ttf',
    );
    _khmerFont = pw.Font.ttf(bytes);
    return _khmerFont!;
  }

  Future<pw.ThemeData> _theme() async {
    final font = await _loadKhmerFont();
    return pw.ThemeData.withFont(base: font, bold: font);
  }

  /// Build a one-page invoice for a single reading.
  Future<pw.Document> buildInvoice({
    required Room room,
    required Reading reading,
    required AppSettings settings,
    required String localeCode,
  }) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    final b = computeBill(reading, settings);
    doc.addPage(_buildInvoicePage(room, reading, settings, b, localeCode));
    return doc;
  }

  /// Build a multi-page document with one invoice per reading.
  Future<pw.Document> buildInvoiceBatch({
    required Map<String, Room> roomsById,
    required List<Reading> readings,
    required AppSettings settings,
    required String localeCode,
  }) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    for (final r in readings) {
      final room = roomsById[r.roomId] ?? Room(id: r.roomId, name: r.roomId);
      final b = computeBill(r, settings);
      doc.addPage(_buildInvoicePage(room, r, settings, b, localeCode));
    }
    return doc;
  }

  pw.Page _buildInvoicePage(
    Room room,
    Reading r,
    AppSettings s,
    BillBreakdown b,
    String localeCode,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    formatYearMonthHuman(r.month, localeCode),
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    room.name,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    room.id,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _meterTable(r, b, s),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      formatKhr(b.totalKhr),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formatUsd(b.totalUsd),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Center(
            child: pw.Text(
              'Generated by My Bill',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _meterTable(Reading r, BillBreakdown b, AppSettings s) {
    pw.TableRow header() => pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _cell('Item', bold: true),
        _cell('Prev', bold: true, align: pw.TextAlign.right),
        _cell('Curr', bold: true, align: pw.TextAlign.right),
        _cell('Usage', bold: true, align: pw.TextAlign.right),
        _cell('Rate', bold: true, align: pw.TextAlign.right),
        _cell('Amount', bold: true, align: pw.TextAlign.right),
      ],
    );
    pw.TableRow row({
      required String label,
      required double prev,
      required double curr,
      required double usage,
      required String usageUnit,
      required double rate,
      required double amount,
    }) => pw.TableRow(
      children: [
        _cell(label),
        _cell(_num(prev), align: pw.TextAlign.right),
        _cell(_num(curr), align: pw.TextAlign.right),
        _cell('${_num(usage)} $usageUnit', align: pw.TextAlign.right),
        _cell(formatInt(rate), align: pw.TextAlign.right),
        _cell(formatKhr(amount), align: pw.TextAlign.right),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(2),
      },
      children: [
        header(),
        row(
          label: 'Electricity',
          prev: r.prevElec,
          curr: r.currElec,
          usage: b.elecUsageKwh,
          usageUnit: 'kWh',
          rate: s.elecRateKhrPerKwh,
          amount: b.elecAmountKhr,
        ),
        row(
          label: 'Water',
          prev: r.prevWater,
          curr: r.currWater,
          usage: b.waterUsageM3,
          usageUnit: 'm3',
          rate: s.waterRateKhrPerM3,
          amount: b.waterAmountKhr,
        ),
      ],
    );
  }

  String _num(double v) => v == v.roundToDouble()
      ? formatInt(v)
      : v.toStringAsFixed(1);

  pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  /// Open the platform print/preview UI. Works on mobile, desktop, and web.
  Future<void> printDoc(pw.Document doc, {String? name}) async {
    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: name ?? 'invoice',
    );
  }

  /// Share/save the PDF via the OS share sheet.
  Future<void> shareDoc(pw.Document doc, {required String fileName}) async {
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
