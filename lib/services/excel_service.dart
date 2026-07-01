import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/formatters.dart';
import '../models/reading.dart';
import '../models/room.dart';
import '../models/settings.dart';
import 'bill_calculator.dart';

class _ExcelLabels {
  final String month;
  final String room;
  final String fromDate;
  final String toDate;
  final String daysSpan;
  final String status;
  final String prevKwh;
  final String currKwh;
  final String usageKwh;
  final String prevM3;
  final String currM3;
  final String usageM3;
  final String elecKhr;
  final String waterKhr;
  final String roomPriceKhr;
  final String totalKhr;
  final String totalUsd;
  final String rateElec;
  final String rateWater;
  final String complete;
  final String incomplete;

  const _ExcelLabels({
    required this.month,
    required this.room,
    required this.fromDate,
    required this.toDate,
    required this.daysSpan,
    required this.status,
    required this.prevKwh,
    required this.currKwh,
    required this.usageKwh,
    required this.prevM3,
    required this.currM3,
    required this.usageM3,
    required this.elecKhr,
    required this.waterKhr,
    required this.roomPriceKhr,
    required this.totalKhr,
    required this.totalUsd,
    required this.rateElec,
    required this.rateWater,
    required this.complete,
    required this.incomplete,
  });

  factory _ExcelLabels.forLocale(String locale) {
    if (locale == 'km') {
      return const _ExcelLabels(
        month: 'ខែ',
        room: 'បន្ទប់',
        fromDate: 'កាលបរិច្ឆេទចាប់ផ្តើម',
        toDate: 'កាលបរិច្ឆេទបញ្ចប់',
        daysSpan: 'ចំនួនថ្ងៃ',
        status: 'ស្ថានភាព',
        prevKwh: 'ម៉ែត្រអគ្គិសនីមុន',
        currKwh: 'ម៉ែត្រអគ្គិសនីថ្មី',
        usageKwh: 'ប្រើអគ្គិសនី (kWh)',
        prevM3: 'ម៉ែត្រទឹកមុន',
        currM3: 'ម៉ែត្រទឹកថ្មី',
        usageM3: 'ប្រើទឹក (m³)',
        elecKhr: 'ថ្លៃអគ្គិសនី (៛)',
        waterKhr: 'ថ្លៃទឹក (៛)',
        roomPriceKhr: 'តម្លៃបន្ទប់ (៛)',
        totalKhr: 'សរុប (៛)',
        totalUsd: 'សរុប (\$)',
        rateElec: 'តម្លៃអគ្គិសនី (៛/kWh)',
        rateWater: 'តម្លៃទឹក (៛/m³)',
        complete: 'គ្រប់មួយខែ',
        incomplete: 'មិនទាន់គ្រប់មួយខែ',
      );
    }
    return const _ExcelLabels(
      month: 'Month',
      room: 'Room',
      fromDate: 'From Date',
      toDate: 'To Date',
      daysSpan: 'Days',
      status: 'Status',
      prevKwh: 'Prev kWh',
      currKwh: 'Curr kWh',
      usageKwh: 'Usage kWh',
      prevM3: 'Prev m³',
      currM3: 'Curr m³',
      usageM3: 'Usage m³',
      elecKhr: 'Electricity KHR',
      waterKhr: 'Water KHR',
      roomPriceKhr: 'Room Price KHR',
      totalKhr: 'Total KHR',
      totalUsd: 'Total USD',
      rateElec: 'Elec Rate (KHR/kWh)',
      rateWater: 'Water Rate (KHR/m³)',
      complete: 'Complete',
      incomplete: 'Incomplete',
    );
  }
}

class ExcelService {
  ExcelService._();
  static final ExcelService instance = ExcelService._();

  Excel build({
    required List<Reading> readings,
    required List<Room> rooms,
    required AppSettings settings,
    required String localeCode,
  }) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Summary');
    final labels = _ExcelLabels.forLocale(localeCode);

    _writeSummary(excel['Summary'], readings, rooms, settings, localeCode, labels);

    for (final room in rooms) {
      final list = readings.where((r) => r.roomId == room.id).toList()
        ..sort((a, b) => a.month.compareTo(b.month));
      _writeRoomSheet(
        excel[_safeSheetName(room.name, room.id)],
        list,
        room.priceUsd,
        settings,
        localeCode,
        labels,
      );
    }
    return excel;
  }

  String _safeSheetName(String name, String fallback) {
    var n = name.replaceAll(RegExp(r'[\[\]\*\?\/\\:]'), ' ').trim();
    if (n.isEmpty) n = fallback;
    if (n.length > 31) n = n.substring(0, 31);
    return n;
  }

  String _formatDate(DateTime? dt, String locale) {
    if (dt == null) return '';
    return DateFormat.yMd(locale).format(dt);
  }

  void _writeSummary(
    Sheet sheet,
    List<Reading> readings,
    List<Room> rooms,
    AppSettings s,
    String localeCode,
    _ExcelLabels labels,
  ) {
    sheet.appendRow([
      TextCellValue(labels.month),
      TextCellValue(labels.room),
      TextCellValue(labels.fromDate),
      TextCellValue(labels.toDate),
      TextCellValue(labels.daysSpan),
      TextCellValue(labels.status),
      TextCellValue(labels.prevKwh),
      TextCellValue(labels.currKwh),
      TextCellValue(labels.usageKwh),
      TextCellValue(labels.elecKhr),
      TextCellValue(labels.prevM3),
      TextCellValue(labels.currM3),
      TextCellValue(labels.usageM3),
      TextCellValue(labels.waterKhr),
      TextCellValue(labels.roomPriceKhr),
      TextCellValue(labels.totalKhr),
      TextCellValue(labels.totalUsd),
      TextCellValue(labels.rateElec),
      TextCellValue(labels.rateWater),
    ]);

    final byId = {for (final r in rooms) r.id: r};
    final sorted = [...readings]..sort((a, b) {
      final m = a.month.compareTo(b.month);
      if (m != 0) return m;
      return a.roomId.compareTo(b.roomId);
    });

    for (final r in sorted) {
      final b = computeBill(r, s);
      final roomPriceKhr = (byId[r.roomId]?.priceUsd ?? 0) * s.khrPerUsd;
      final grandTotalKhr = b.totalKhr + roomPriceKhr;
      final grandTotalUsd = s.khrPerUsd > 0 ? grandTotalKhr / s.khrPerUsd : 0.0;
      final daysSpan = (r.prevElecDate != null && r.currElecDate != null)
          ? r.currElecDate!.difference(r.prevElecDate!).inDays
          : null;
      sheet.appendRow([
        TextCellValue(formatYearMonthHuman(r.month, localeCode)),
        TextCellValue(byId[r.roomId]?.name ?? r.roomId),
        TextCellValue(_formatDate(r.prevElecDate, localeCode)),
        TextCellValue(_formatDate(r.currElecDate, localeCode)),
        daysSpan != null ? IntCellValue(daysSpan) : TextCellValue(''),
        TextCellValue(r.isMonthComplete ? labels.complete : labels.incomplete),
        DoubleCellValue(r.prevElec),
        DoubleCellValue(r.currElec),
        DoubleCellValue(b.elecUsageKwh),
        DoubleCellValue(b.elecAmountKhr),
        DoubleCellValue(r.prevWater),
        DoubleCellValue(r.currWater),
        DoubleCellValue(b.waterUsageM3),
        DoubleCellValue(b.waterAmountKhr),
        DoubleCellValue(roomPriceKhr),
        DoubleCellValue(grandTotalKhr),
        DoubleCellValue(grandTotalUsd),
        DoubleCellValue(s.elecRateKhrPerKwh),
        DoubleCellValue(s.waterRateKhrPerM3),
      ]);
    }
  }

  void _writeRoomSheet(
    Sheet sheet,
    List<Reading> readings,
    double roomPriceUsd,
    AppSettings s,
    String localeCode,
    _ExcelLabels labels,
  ) {
    sheet.appendRow([
      TextCellValue(labels.month),
      TextCellValue(labels.fromDate),
      TextCellValue(labels.toDate),
      TextCellValue(labels.daysSpan),
      TextCellValue(labels.status),
      TextCellValue(labels.prevKwh),
      TextCellValue(labels.currKwh),
      TextCellValue(labels.usageKwh),
      TextCellValue(labels.elecKhr),
      TextCellValue(labels.prevM3),
      TextCellValue(labels.currM3),
      TextCellValue(labels.usageM3),
      TextCellValue(labels.waterKhr),
      TextCellValue(labels.roomPriceKhr),
      TextCellValue(labels.totalKhr),
      TextCellValue(labels.totalUsd),
    ]);
    final roomPriceKhr = roomPriceUsd * s.khrPerUsd;
    for (final r in readings) {
      final b = computeBill(r, s);
      final grandTotalKhr = b.totalKhr + roomPriceKhr;
      final grandTotalUsd = s.khrPerUsd > 0 ? grandTotalKhr / s.khrPerUsd : 0.0;
      final daysSpan = (r.prevElecDate != null && r.currElecDate != null)
          ? r.currElecDate!.difference(r.prevElecDate!).inDays
          : null;
      sheet.appendRow([
        TextCellValue(formatYearMonthHuman(r.month, localeCode)),
        TextCellValue(_formatDate(r.prevElecDate, localeCode)),
        TextCellValue(_formatDate(r.currElecDate, localeCode)),
        daysSpan != null ? IntCellValue(daysSpan) : TextCellValue(''),
        TextCellValue(r.isMonthComplete ? labels.complete : labels.incomplete),
        DoubleCellValue(r.prevElec),
        DoubleCellValue(r.currElec),
        DoubleCellValue(b.elecUsageKwh),
        DoubleCellValue(b.elecAmountKhr),
        DoubleCellValue(r.prevWater),
        DoubleCellValue(r.currWater),
        DoubleCellValue(b.waterUsageM3),
        DoubleCellValue(b.waterAmountKhr),
        DoubleCellValue(roomPriceKhr),
        DoubleCellValue(grandTotalKhr),
        DoubleCellValue(grandTotalUsd),
      ]);
    }
  }

  Future<void> shareWorkbook(Excel excel, {required String fileName}) async {
    final bytes = excel.save(fileName: fileName);
    if (bytes == null) return;
    final data = Uint8List.fromList(bytes);
    if (kIsWeb) {
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(data, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], fileNameOverrides: [fileName]),
    );
  }
}
