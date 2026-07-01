import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_bill/models/reading.dart';
import 'package:my_bill/models/room.dart';
import 'package:my_bill/models/settings.dart';
import 'package:my_bill/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('km');
  });

  test('invoice pdf embeds the payment QR on a single page', () async {
    final settings = AppSettings.defaults().copyWith(
      rooms: [const Room(id: 'room_1', name: 'Room 1', priceUsd: 90)],
    );
    final reading = Reading(
      id: 'room_1_2026-06',
      roomId: 'room_1',
      month: DateTime(2026, 6),
      prevElec: 203703,
      currElec: 203941,
      prevWater: 272,
      currWater: 291,
      createdAt: DateTime(2026, 6, 30),
      prevElecDate: DateTime(2026, 5, 31),
      currElecDate: DateTime(2026, 6, 30),
      prevWaterDate: DateTime(2026, 5, 31),
      currWaterDate: DateTime(2026, 6, 30),
    );

    final doc = await PdfService.instance.buildInvoice(
      room: settings.rooms.first,
      reading: reading,
      settings: settings,
      localeCode: 'en',
    );
    final bytes = await doc.save();
    final raw = String.fromCharCodes(bytes);

    final images = '/Subtype /Image'.allMatches(raw).length +
        '/Subtype/Image'.allMatches(raw).length;
    final pages = '/MediaBox'.allMatches(raw).length;

    expect(images, greaterThan(0), reason: 'payment QR must be embedded');
    expect(pages, 1, reason: 'invoice must stay on a single page');
  });
}
