import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/readings_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/formatters.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/excel_service.dart';
import '../../services/pdf_service.dart';
import '../rooms/room_detail_page.dart';
import 'widgets/hero_card.dart';
import 'widgets/room_summary_tile.dart';
import 'widgets/stat_card.dart';
import 'widgets/trend_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dash = Get.find<DashboardController>();
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.dashboardGreeting,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              t.dashboardTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: t.exportPdf,
            onSelected: (v) =>
                v == 'pdf' ? _exportAllPdf(context) : _exportAllExcel(context),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Text(t.exportPdf),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    const Icon(Icons.grid_on_outlined, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Text(t.exportExcel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        readings.readings.length;
        settings.rx.value;

        final totals = dash.currentMonthTotals;
        final breakdown = dash.roomBreakdown(totals.key);
        final months = dash.last(6);
        final locale = settings.settings.localeCode;
        final monthLabel = formatYearMonthHuman(totals.month, locale);
        final billColors = Theme.of(context).extension<BillColors>()!;

        if (readings.readings.isEmpty) {
          return _EmptyState(message: t.noData);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            96,
          ),
          children: [
            HeroCard(
              title: t.dashboardSubtitle,
              subtitle: monthLabel,
              totalKhr: formatKhr(totals.totalKhr),
              totalUsd: formatUsd(
                settings.settings.khrPerUsd == 0
                    ? 0
                    : totals.totalKhr / settings.settings.khrPerUsd,
              ),
              roomsReported: totals.roomsReported,
              roomsTotal: settings.settings.rooms.length,
              roomsLabel: t.statRoomsReported,
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              // Wide ratio makes cells too short for [StatCard] (icon + labels + value + sub).
              childAspectRatio: 1.02,
              children: [
                StatCard(
                  label: t.statTotalKwh,
                  value: formatKwh(totals.totalKwh),
                  sub: t.statThisMonth,
                  icon: Icons.bolt_rounded,
                  color: billColors.elec,
                ),
                StatCard(
                  label: t.statTotalM3,
                  value: formatM3(totals.totalM3),
                  sub: t.statThisMonth,
                  icon: Icons.water_drop_rounded,
                  color: billColors.water,
                ),
                StatCard(
                  label: t.statTotalBilled,
                  value: formatKhr(totals.totalKhr),
                  sub: formatUsd(
                    settings.settings.khrPerUsd == 0
                        ? 0
                        : totals.totalKhr / settings.settings.khrPerUsd,
                  ),
                  icon: Icons.receipt_long_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatCard(
                  label: t.statRoomsReported,
                  value: t.statRoomsValue(
                    totals.roomsReported,
                    settings.settings.rooms.length,
                  ),
                  sub: t.statThisMonth,
                  icon: Icons.meeting_room_rounded,
                  color: billColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(title: t.monthlyTrend),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: TrendChart(months: months, locale: locale),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(title: t.perRoomSummary),
            const SizedBox(height: AppSpacing.sm),
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

  Future<void> _exportAllPdf(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();
    final dash = Get.find<DashboardController>();
    final key = dash.currentMonthTotals.key;
    final list = readings.forMonthKey(key);
    if (list.isEmpty) {
      AppSnack.info(context, t.noData);
      return;
    }
    final roomsById = {for (final r in settings.settings.rooms) r.id: r};
    try {
      final doc = await PdfService.instance.buildInvoiceBatch(
        roomsById: roomsById,
        readings: list,
        settings: settings.settings,
        localeCode: settings.settings.localeCode,
      );
      await PdfService.instance.shareDoc(doc, fileName: 'my_bill_$key.pdf');
      if (!context.mounted) return;
      AppSnack.success(
        context,
        t.exportedPdf,
        icon: Icons.picture_as_pdf_outlined,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.error(context, t.exportFailed(e.toString()));
    }
  }

  Future<void> _exportAllExcel(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();
    if (readings.readings.isEmpty) {
      AppSnack.info(context, t.emptyHistory);
      return;
    }
    try {
      final workbook = ExcelService.instance.build(
        readings: readings.readings,
        rooms: settings.settings.rooms,
        settings: settings.settings,
        localeCode: settings.settings.localeCode,
      );
      await ExcelService.instance.shareWorkbook(
        workbook,
        fileName: 'my_bill_history.xlsx',
      );
      if (!context.mounted) return;
      AppSnack.success(
        context,
        t.exportedExcel,
        icon: Icons.grid_on_outlined,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.error(context, t.exportFailed(e.toString()));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.insights_rounded,
                size: 40,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
