import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/formatters.dart';
import '../models/reading.dart';
import '../models/room.dart';
import '../models/settings.dart';
import 'bill_calculator.dart';

class ExcelService {
  ExcelService._();
  static final ExcelService instance = ExcelService._();

  /// Build a workbook with a `Summary` sheet plus one sheet per room.
  Excel build({
    required List<Reading> readings,
    required List<Room> rooms,
    required AppSettings settings,
    required String localeCode,
  }) {
    final excel = Excel.createExcel();
    // createExcel() pre-creates `Sheet1`; rename it to Summary.
    excel.rename('Sheet1', 'Summary');

    _writeSummary(excel['Summary'], readings, rooms, settings, localeCode);

    for (final room in rooms) {
      final list = readings.where((r) => r.roomId == room.id).toList()
        ..sort((a, b) => a.month.compareTo(b.month));
      _writeRoomSheet(
        excel[_safeSheetName(room.name, room.id)],
        list,
        settings,
        localeCode,
      );
    }
    return excel;
  }

  /// Sheet names cannot exceed 31 chars and cannot contain []*?/\:
  String _safeSheetName(String name, String fallback) {
    var n = name.replaceAll(RegExp(r'[\[\]\*\?\/\\:]'), ' ').trim();
    if (n.isEmpty) n = fallback;
    if (n.length > 31) n = n.substring(0, 31);
    return n;
  }

  void _writeSummary(
    Sheet sheet,
    List<Reading> readings,
    List<Room> rooms,
    AppSettings s,
    String localeCode,
  ) {
    sheet.appendRow([
      TextCellValue('Month'),
      TextCellValue('Room'),
      TextCellValue('Prev kWh'),
      TextCellValue('Curr kWh'),
      TextCellValue('Usage kWh'),
      TextCellValue('Prev m3'),
      TextCellValue('Curr m3'),
      TextCellValue('Usage m3'),
      TextCellValue('Electricity KHR'),
      TextCellValue('Water KHR'),
      TextCellValue('Total KHR'),
      TextCellValue('Total USD'),
    ]);

    final byId = {for (final r in rooms) r.id: r};
    final sorted = [...readings]..sort((a, b) {
      final m = a.month.compareTo(b.month);
      if (m != 0) return m;
      return a.roomId.compareTo(b.roomId);
    });

    for (final r in sorted) {
      final b = computeBill(r, s);
      sheet.appendRow([
        TextCellValue(formatYearMonthHuman(r.month, localeCode)),
        TextCellValue(byId[r.roomId]?.name ?? r.roomId),
        DoubleCellValue(r.prevElec),
        DoubleCellValue(r.currElec),
        DoubleCellValue(b.elecUsageKwh),
        DoubleCellValue(r.prevWater),
        DoubleCellValue(r.currWater),
        DoubleCellValue(b.waterUsageM3),
        DoubleCellValue(b.elecAmountKhr),
        DoubleCellValue(b.waterAmountKhr),
        DoubleCellValue(b.totalKhr),
        DoubleCellValue(b.totalUsd),
      ]);
    }
  }

  void _writeRoomSheet(
    Sheet sheet,
    List<Reading> readings,
    AppSettings s,
    String localeCode,
  ) {
    sheet.appendRow([
      TextCellValue('Month'),
      TextCellValue('Prev kWh'),
      TextCellValue('Curr kWh'),
      TextCellValue('Usage kWh'),
      TextCellValue('Prev m3'),
      TextCellValue('Curr m3'),
      TextCellValue('Usage m3'),
      TextCellValue('Total KHR'),
      TextCellValue('Total USD'),
    ]);
    for (final r in readings) {
      final b = computeBill(r, s);
      sheet.appendRow([
        TextCellValue(formatYearMonthHuman(r.month, localeCode)),
        DoubleCellValue(r.prevElec),
        DoubleCellValue(r.currElec),
        DoubleCellValue(b.elecUsageKwh),
        DoubleCellValue(r.prevWater),
        DoubleCellValue(r.currWater),
        DoubleCellValue(b.waterUsageM3),
        DoubleCellValue(b.totalKhr),
        DoubleCellValue(b.totalUsd),
      ]);
    }
  }

  /// Save the workbook and surface the OS share sheet.
  Future<void> shareWorkbook(Excel excel, {required String fileName}) async {
    final bytes = excel.save(fileName: fileName);
    if (bytes == null) return;
    final data = Uint8List.fromList(bytes);
    if (kIsWeb) {
      // On the web `excel.save(fileName:)` already triggers a download.
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
