import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/readings_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/formatters.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/reading.dart';
import '../../services/bill_calculator.dart';
import '../../services/pdf_service.dart';
import '../input/input_usage_page.dart';
import '../widgets/bill_dialog.dart';

class RoomDetailPage extends StatelessWidget {
  const RoomDetailPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(settings.roomById(roomId).name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: t.exportPdf,
            onPressed: () => _exportPdf(context),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: t.deleteRoomData,
            onPressed: () => _confirmDeleteAll(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        final list = readings.orderedForRoom(roomId);
        final locale = settings.settings.localeCode;
        if (list.isEmpty) {
          return _EmptyMessage(message: t.noData);
        }
        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            96,
          ),
          itemCount: list.length,
          onReorder: (oldIndex, newIndex) {
            var ni = newIndex;
            if (ni > oldIndex) ni--;
            final next = List<Reading>.from(list);
            final moved = next.removeAt(oldIndex);
            next.insert(ni, moved);
            unawaited(
              readings.setRoomReadingOrder(
                roomId,
                next.map((e) => e.id).toList(),
              ),
            );
          },
          itemBuilder: (context, i) {
            final r = list[i];
            final b = computeBill(r, settings.settings);
            return Padding(
              key: ValueKey(r.id),
              padding: EdgeInsets.only(
                bottom: i < list.length - 1 ? AppSpacing.md : 0,
              ),
              child: _ReadingTile(
                monthLabel: formatYearMonthHuman(r.month, locale),
                elec: formatKwh(b.elecUsageKwh),
                water: formatM3(b.waterUsageM3),
                totalKhr: formatKhr(b.totalKhr),
                totalUsd: formatUsd(b.totalUsd),
                reorderIndex: i,
                reorderTooltip: t.reorderReadingsHint,
                onTap: () => Get.to(() => InputUsagePage(editing: r)),
                onDelete: () => _confirmDelete(context, r),
                onLongPress: () => _confirmDelete(context, r),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Reading r) async {
    final t = AppLocalizations.of(context);
    final ok = await showBillDialog<bool>(
      context: context,
      builder: (ctx) => BillDialogFrame(
        icon: const BillDialogIconHeader(
          icon: Icons.delete_outline_rounded,
          destructive: true,
        ),
        title: t.deleteReadingTitle,
        body: Text(t.deleteReadingMessage),
        actions: [
          TextButton(
            style: billDialogTextActionStyle(ctx),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: billDialogDestructiveFilledStyle(ctx),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true) {
      if (!context.mounted) return;
      AppSnack.info(context, t.actionCancelled);
      return;
    }
    if (!context.mounted) return;
    try {
      await Get.find<ReadingsController>().delete(r.id);
      if (!context.mounted) return;
      AppSnack.success(
        context,
        t.deletedReading,
        icon: Icons.delete_outline_rounded,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.error(context, t.deleteFailed(e.toString()));
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();
    final navigator = Navigator.of(context);
    final roomName = settings.roomById(roomId).name;

    if (readings.forRoom(roomId).isEmpty) {
      AppSnack.info(context, t.deleteRoomDataEmpty);
      return;
    }

    final ok = await showBillDialog<bool>(
      context: context,
      builder: (ctx) => BillDialogFrame(
        icon: const BillDialogIconHeader(
          icon: Icons.folder_delete_outlined,
          destructive: true,
        ),
        title: t.deleteRoomDataTitle(roomName),
        body: Text(t.deleteRoomDataMessage),
        actions: [
          TextButton(
            style: billDialogTextActionStyle(ctx),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: billDialogDestructiveFilledStyle(ctx),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true) {
      if (!context.mounted) return;
      AppSnack.info(context, t.actionCancelled);
      return;
    }

    try {
      await readings.deleteByRoom(roomId);
      if (navigator.canPop()) navigator.pop();
      final rootContext = Get.context;
      if (rootContext != null) {
        // Get.context is the persistent MaterialApp context, safe after pop.
        AppSnack.success(
          // ignore: use_build_context_synchronously
          rootContext,
          t.deletedRoomData(roomName),
          icon: Icons.delete_sweep_outlined,
        );
      }
    } catch (e) {
      final rootContext = Get.context;
      if (rootContext != null) {
        AppSnack.error(
          // ignore: use_build_context_synchronously
          rootContext,
          t.deleteFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();
    final list = readings.orderedForRoom(roomId);
    if (list.isEmpty) {
      AppSnack.info(context, t.noData);
      return;
    }
    final room = settings.roomById(roomId);
    try {
      final doc = await PdfService.instance.buildInvoiceBatch(
        roomsById: {room.id: room},
        readings: list,
        settings: settings.settings,
        localeCode: settings.settings.localeCode,
      );
      await PdfService.instance.shareDoc(
        doc,
        fileName: 'my_bill_${room.id}.pdf',
      );
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
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({
    required this.monthLabel,
    required this.elec,
    required this.water,
    required this.totalKhr,
    required this.totalUsd,
    this.reorderIndex,
    this.reorderTooltip,
    this.onTap,
    this.onDelete,
    this.onLongPress,
  });

  final String monthLabel;
  final String elec;
  final String water;
  final String totalKhr;
  final String totalUsd;
  final int? reorderIndex;
  final String? reorderTooltip;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final billColors = Theme.of(context).extension<BillColors>()!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (reorderIndex != null) ...[
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: reorderTooltip != null && reorderTooltip!.isNotEmpty
                      ? Tooltip(
                          message: reorderTooltip!,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: scheme.onSurfaceVariant,
                              size: 28,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: scheme.onSurfaceVariant,
                            size: 28,
                          ),
                        ),
                ),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthLabel,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: billColors.elec,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          elec,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.water_drop_rounded,
                          size: 14,
                          color: billColors.water,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          water,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalKhr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    totalUsd,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: AppLocalizations.of(context).delete,
                  style: IconButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.history_rounded,
                size: 32,
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
