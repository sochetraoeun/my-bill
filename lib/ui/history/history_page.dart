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
import '../../services/excel_service.dart';
import '../widgets/bill_dialog.dart';
import 'reading_detail_page.dart';

/// Room / month filters for [HistoryPage] — outlined dropdowns with icon + label.
class _HistoryFiltersBar extends StatelessWidget {
  const _HistoryFiltersBar({
    required this.roomLabel,
    required this.monthLabel,
    required this.roomFilter,
    required this.monthFilter,
    required this.roomItems,
    required this.monthItems,
    required this.onRoomChanged,
    required this.onMonthChanged,
  });

  final String roomLabel;
  final String monthLabel;
  final String? roomFilter;
  final String? monthFilter;
  final List<DropdownMenuItem<String?>> roomItems;
  final List<DropdownMenuItem<String?>> monthItems;
  final ValueChanged<String?> onRoomChanged;
  final ValueChanged<String?> onMonthChanged;

  static List<Widget> _selectedItemLabels(
    BuildContext context,
    List<DropdownMenuItem<String?>> items,
  ) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    return items.map((item) {
      final textWidget = item.child is Text ? item.child as Text : null;
      final label = textWidget?.data ?? '';
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String?>(
              initialValue: roomFilter,
              isExpanded: true,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              icon: Icon(
                Icons.expand_more_rounded,
                color: iconColor,
              ),
              decoration: InputDecoration(
                labelText: roomLabel,
                prefixIcon: Icon(
                  Icons.meeting_room_outlined,
                  size: 20,
                  color: iconColor,
                ),
              ),
              items: roomItems,
              selectedItemBuilder: (ctx) =>
                  _selectedItemLabels(ctx, roomItems),
              onChanged: onRoomChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String?>(
              initialValue: monthFilter,
              isExpanded: true,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              icon: Icon(
                Icons.expand_more_rounded,
                color: iconColor,
              ),
              decoration: InputDecoration(
                labelText: monthLabel,
                prefixIcon: Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: iconColor,
                ),
              ),
              items: monthItems,
              selectedItemBuilder: (ctx) =>
                  _selectedItemLabels(ctx, monthItems),
              onChanged: onMonthChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _roomFilter;
  String? _monthFilter;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.historyTitle),
        titleSpacing: AppSpacing.lg,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on_outlined),
            tooltip: t.exportExcel,
            onPressed: () => _exportExcel(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Obx(() {
        final months = readings.monthKeys;
        final rooms = settings.settings.rooms;
        final list = readings.readings.where((r) {
          if (_roomFilter != null && r.roomId != _roomFilter) return false;
          if (_monthFilter != null && r.yearMonth != _monthFilter) return false;
          return true;
        }).toList();
        final locale = settings.settings.localeCode;

        final roomMenuItems = <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: Text(t.filterAllRooms),
          ),
          for (final room in rooms)
            DropdownMenuItem<String?>(
              value: room.id,
              child: Text(room.name),
            ),
        ];
        final monthMenuItems = <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: Text(t.filterAllMonths),
          ),
          for (final k in months)
            DropdownMenuItem<String?>(
              value: k,
              child: Text(
                formatYearMonthHuman(parseYearMonthKey(k), locale),
              ),
            ),
        ];

        return Column(
          children: [
            _HistoryFiltersBar(
              roomLabel: t.fieldRoom,
              monthLabel: t.fieldMonth,
              roomFilter: _roomFilter,
              monthFilter: _monthFilter,
              roomItems: roomMenuItems,
              monthItems: monthMenuItems,
              onRoomChanged: (v) {
                if (v == _roomFilter) return;
                setState(() => _roomFilter = v);
                _notifyFilterChange();
              },
              onMonthChanged: (v) {
                if (v == _monthFilter) return;
                setState(() => _monthFilter = v);
                _notifyFilterChange();
              },
            ),
            Expanded(
              child: list.isEmpty
                  ? _EmptyHistory(message: t.emptyHistory)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) {
                        final r = list[i];
                        final b = computeBill(r, settings.settings);
                        final roomName = settings.roomById(r.roomId).name;
                        return _HistoryTile(
                          roomName: roomName,
                          monthLabel: formatYearMonthHuman(r.month, locale),
                          elec: formatKwh(b.elecUsageKwh),
                          water: formatM3(b.waterUsageM3),
                          totalKhr: formatKhr(b.totalKhr),
                          totalUsd: formatUsd(b.totalUsd),
                          onTap: () =>
                              Get.to(() => ReadingDetailPage(reading: r)),
                          onLongPress: () => _confirmDelete(context, r),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  void _notifyFilterChange() {
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final allCleared = _roomFilter == null && _monthFilter == null;
    AppSnack.info(
      context,
      allCleared ? t.filtersCleared : t.filtersUpdated,
      icon: Icons.filter_alt_outlined,
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

  Future<void> _exportExcel(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final readings = Get.find<ReadingsController>();
    final settings = Get.find<SettingsController>();
    final list = readings.readings.where((r) {
      if (_roomFilter != null && r.roomId != _roomFilter) return false;
      if (_monthFilter != null && r.yearMonth != _monthFilter) return false;
      return true;
    }).toList();
    if (list.isEmpty) {
      AppSnack.info(context, t.emptyHistory);
      return;
    }
    try {
      final workbook = ExcelService.instance.build(
        readings: list,
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.roomName,
    required this.monthLabel,
    required this.elec,
    required this.water,
    required this.totalKhr,
    required this.totalUsd,
    this.onTap,
    this.onLongPress,
  });

  final String roomName;
  final String monthLabel;
  final String elec;
  final String water;
  final String totalKhr;
  final String totalUsd;
  final VoidCallback? onTap;
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.meeting_room_rounded,
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
                      roomName,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});
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
