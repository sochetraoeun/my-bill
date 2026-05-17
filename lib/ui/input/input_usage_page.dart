import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/readings_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/formatters.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/bill.dart';
import '../../models/reading.dart';
import '../../models/settings.dart';
import '../../services/bill_calculator.dart';

class InputUsagePage extends StatefulWidget {
  const InputUsagePage({super.key, this.editing});

  /// If supplied, the form opens pre-filled to edit that reading.
  final Reading? editing;

  @override
  State<InputUsagePage> createState() => _InputUsagePageState();
}

class _InputUsagePageState extends State<InputUsagePage> {
  final _formKey = GlobalKey<FormState>();

  late String _roomId;
  late DateTime _month;
  final _prevElec = TextEditingController();
  final _currElec = TextEditingController();
  final _prevWater = TextEditingController();
  final _currWater = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<SettingsController>();
    final readings = Get.find<ReadingsController>();
    final e = widget.editing;
    if (e != null) {
      _roomId = e.roomId;
      _month = DateTime(e.month.year, e.month.month);
      _prevElec.text = _trim(e.prevElec);
      _currElec.text = _trim(e.currElec);
      _prevWater.text = _trim(e.prevWater);
      _currWater.text = _trim(e.currWater);
    } else {
      _roomId = settings.settings.rooms.first.id;
      final now = DateTime.now();
      _month = DateTime(now.year, now.month);
      _prefillPrevFromHistory(readings, _roomId, _month);
    }
    for (final c in [_prevElec, _currElec, _prevWater, _currWater]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _prevElec.dispose();
    _currElec.dispose();
    _prevWater.dispose();
    _currWater.dispose();
    super.dispose();
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double _read(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;

  /// Stable doc id so saving the same room+month twice updates rather than
  /// creates duplicates. Editing uses the same scheme; if the user changes
  /// the room or month in edit mode, the old doc is deleted before the
  /// new one is written.
  String _docId(String roomId, DateTime month) =>
      '${roomId}_${formatYearMonthKey(month)}';

  /// Pre-fill the "previous" meters from the most recent prior reading for
  /// the chosen room.
  void _prefillPrevFromHistory(
    ReadingsController readings,
    String roomId,
    DateTime month,
  ) {
    final candidates = readings.readings
        .where((r) => r.roomId == roomId && r.month.isBefore(month))
        .toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    if (candidates.isEmpty) {
      _prevElec.text = '';
      _prevWater.text = '';
      return;
    }
    final prev = candidates.first;
    _prevElec.text = _trim(prev.currElec);
    _prevWater.text = _trim(prev.currWater);
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final t = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnack.error(context, t.formInvalid);
      return;
    }
    FocusScope.of(context).unfocus();

    final readings = Get.find<ReadingsController>();
    final navigator = Navigator.of(context);
    final newId = _docId(_roomId, _month);

    setState(() => _saving = true);
    try {
      final editing = widget.editing;
      if (editing != null && editing.id != newId) {
        await readings.delete(editing.id);
      }
      final reading = Reading(
        id: newId,
        roomId: _roomId,
        month: _month,
        prevElec: _read(_prevElec),
        currElec: _read(_currElec),
        prevWater: _read(_prevWater),
        currWater: _read(_currWater),
        createdAt: editing?.createdAt ?? DateTime.now(),
      );
      await readings.upsert(reading);
      navigator.pop();
      final rootContext = Get.context;
      if (rootContext != null) {
        // Get.context is the persistent MaterialApp context, safe after pop.
        AppSnack.success(
          // ignore: use_build_context_synchronously
          rootContext,
          readings.isCloud ? t.savedCloud : t.savedLocal,
          icon: readings.isCloud
              ? Icons.cloud_done_outlined
              : Icons.save_outlined,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnack.error(context, t.saveFailed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = Get.find<SettingsController>();
    final readings = Get.find<ReadingsController>();
    final billColors = Theme.of(context).extension<BillColors>()!;
    final s = settings.settings;
    final locale = s.localeCode;

    final bill = computeBillFromValues(
      prevElec: _read(_prevElec),
      currElec: _read(_currElec),
      prevWater: _read(_prevWater),
      currWater: _read(_currWater),
      s: s,
    );

    final existing = readings.find(
      roomId: _roomId,
      yearMonth: formatYearMonthKey(_month),
    );
    final willUpdate = existing != null && existing.id != widget.editing?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.inputUsageTitle),
        actions: [
          _SyncBadge(isCloud: readings.isCloud),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            120,
          ),
          children: [
            _Section(
              title: t.fieldRoom,
              icon: Icons.meeting_room_outlined,
              color: Theme.of(context).colorScheme.primary,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final r in s.rooms)
                    ChoiceChip(
                      label: Text(r.name),
                      selected: _roomId == r.id,
                      onSelected: (sel) {
                        if (!sel) return;
                        setState(() {
                          _roomId = r.id;
                          if (widget.editing == null) {
                            _prefillPrevFromHistory(readings, r.id, _month);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: t.fieldMonth,
              icon: Icons.calendar_month_outlined,
              color: Theme.of(context).colorScheme.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _month,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(DateTime.now().year + 2, 12, 31),
                    helpText: t.fieldMonth,
                  );
                  if (picked != null) {
                    setState(() {
                      _month = DateTime(picked.year, picked.month);
                      if (widget.editing == null) {
                        _prefillPrevFromHistory(readings, _roomId, _month);
                      }
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatYearMonthHuman(_month, locale),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (willUpdate) ...[
              const SizedBox(height: AppSpacing.md),
              _InfoBanner(
                text: t.updateExisting,
                color: billColors.warning,
                surfaceColor: billColors.warningSurface,
                icon: Icons.info_outline_rounded,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _MeterSection(
              title: t.sectionElectricity,
              icon: Icons.bolt_rounded,
              color: billColors.elec,
              prev: _prevElec,
              curr: _currElec,
              prevLabel: t.fieldPrevMeter,
              currLabel: t.fieldCurrMeter,
              usageLabel:
                  '${formatKwh(bill.elecUsageKwh)} • ${formatKhr(bill.elecAmountKhr)}',
              validate: _validateMeter,
            ),
            const SizedBox(height: AppSpacing.md),
            _MeterSection(
              title: t.sectionWater,
              icon: Icons.water_drop_rounded,
              color: billColors.water,
              prev: _prevWater,
              curr: _currWater,
              prevLabel: t.fieldPrevMeter,
              currLabel: t.fieldCurrMeter,
              usageLabel:
                  '${formatM3(bill.waterUsageM3)} • ${formatKhr(bill.waterAmountKhr)}',
              validate: _validateMeter,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PreviewCard(bill: bill, t: t, s: s),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: FilledButton.icon(
            onPressed: _saving ? null : _onSave,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? t.saving : t.save),
          ),
        ),
      ),
    );
  }

  String? _validateMeter(String? value, String? other) {
    if (value == null || value.isEmpty || other == null || other.isEmpty) {
      return null;
    }
    final v = double.tryParse(value.replaceAll(',', '')) ?? 0;
    final o = double.tryParse(other.replaceAll(',', '')) ?? 0;
    if (v < o) {
      return AppLocalizations.of(context).errorCurrLessThanPrev;
    }
    return null;
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.isCloud});
  final bool isCloud;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final billColors = Theme.of(context).extension<BillColors>()!;
    final color = isCloud ? billColors.success : billColors.warning;
    final bg = isCloud ? billColors.successSurface : billColors.warningSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCloud ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              isCloud ? t.badgeCloud : t.badgeLocal,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _MeterSection extends StatelessWidget {
  const _MeterSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.prev,
    required this.curr,
    required this.prevLabel,
    required this.currLabel,
    required this.usageLabel,
    required this.validate,
  });

  final String title;
  final IconData icon;
  final Color color;
  final TextEditingController prev;
  final TextEditingController curr;
  final String prevLabel;
  final String currLabel;
  final String usageLabel;
  final String? Function(String? value, String? other) validate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.20),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  usageLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: prev,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(labelText: prevLabel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: curr,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) => validate(v, prev.text),
                    decoration: InputDecoration(labelText: currLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.bill, required this.t, required this.s});

  final BillBreakdown bill;
  final AppLocalizations t;
  final AppSettings s;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final billColors = Theme.of(context).extension<BillColors>()!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.10),
            scheme.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t.previewBill,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _row(
              context,
              label: t.sectionElectricity,
              icon: Icons.bolt_rounded,
              iconColor: billColors.elec,
              usage: formatKwh(bill.elecUsageKwh),
              rate: '${formatInt(s.elecRateKhrPerKwh)} ៛/${t.unitKwh}',
              amount: formatKhr(bill.elecAmountKhr),
            ),
            const SizedBox(height: AppSpacing.sm),
            _row(
              context,
              label: t.sectionWater,
              icon: Icons.water_drop_rounded,
              iconColor: billColors.water,
              usage: formatM3(bill.waterUsageM3),
              rate: '${formatInt(s.waterRateKhrPerM3)} ៛/${t.unitM3}',
              amount: formatKhr(bill.waterAmountKhr),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                color: scheme.primary.withValues(alpha: 0.20),
                height: 1,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.labelTotal,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatKhr(bill.totalKhr),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                            letterSpacing: -0.4,
                          ),
                    ),
                    Text(
                      formatUsd(bill.totalUsd),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required String usage,
    required String rate,
    required String amount,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$usage • $rate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    required this.color,
    required this.surfaceColor,
    required this.icon,
  });
  final String text;
  final Color color;
  final Color surfaceColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
