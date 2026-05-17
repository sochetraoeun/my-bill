import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/readings_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../dashboard/widgets/room_summary_tile.dart';
import 'room_detail_page.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dash = Get.find<DashboardController>();
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.roomsTitle),
        titleSpacing: AppSpacing.lg,
      ),
      body: Obx(() {
        readings.readings.length;
        settings.rx.value;

        final totals = dash.currentMonthTotals;
        final breakdown = dash.roomBreakdown(totals.key);
        final locale = settings.settings.localeCode;
        final monthLabel = formatYearMonthHuman(totals.month, locale);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            96,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.md,
                left: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            for (final entry in breakdown)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: RoomSummaryTile(
                  roomName: settings.roomById(entry.roomId).name,
                  bill: entry.bill,
                  onTap: () =>
                      Get.to(() => RoomDetailPage(roomId: entry.roomId)),
                ),
              ),
          ],
        );
      }),
    );
  }
}
