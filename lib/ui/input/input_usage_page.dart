import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/readings_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/electric_meter_truncation.dart';
import '../../core/formatters.dart';
import '../../core/meter_chain.dart';
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
  /// After a failed save, re-run [FormState.validate] on meter edits so errors
  /// clear immediately and paired prev/current fields stay in sync.
  bool _meterLiveValidation = false;

  void _onMeterControllersChanged() {
    setState(() {});
    if (_meterLiveValidation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _formKey.currentState?.validate();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final settings = Get.find<SettingsController>();
    final readings = Get.find<ReadingsController>();
    final e = widget.editing;
    if (e != null) {
      _roomId = e.roomId;
      _month = DateTime(e.month.year, e.month.month);
      _prevElec.text = formatMeterInputText(e.prevElec);
      _currElec.text = formatMeterInputText(e.currElec);
      _prevWater.text = formatMeterInputText(e.prevWater);
      _currWater.text = formatMeterInputText(e.currWater);
    } else {
      _roomId = settings.settings.rooms.first.id;
      final now = DateTime.now();
      _month = DateTime(now.year, now.month);
      _prefillAdjacentFromHistory(readings, _roomId, _month);
    }
    for (final c in [_prevElec, _currElec, _prevWater, _currWater]) {
      c.addListener(_onMeterControllersChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [_prevElec, _currElec, _prevWater, _currWater]) {
      c.removeListener(_onMeterControllersChanged);
    }
    _prevElec.dispose();
    _currElec.dispose();
    _prevWater.dispose();
    _currWater.dispose();
    super.dispose();
  }

  double _read(TextEditingController c) => tryParseMeterReading(c.text) ?? 0;

  ResolvedElectricInputs _resolvedElectricInputs(ReadingsController readings) {
    final omitEditing =
        widget.editing == null ? <String>{} : {widget.editing!.id};
    final pred =
        predecessorReading(readings.readings, _roomId, _month, omitEditing);
    final succ =
        successorReading(readings.readings, _roomId, _month, omitEditing);
    return resolveTruncatedElectricInputs(
      prevInput: _read(_prevElec),
      currInput: _read(_currElec),
      predecessorClosing: pred?.currElec,
      successorOpening: succ?.prevElec,
    );
  }

  String _electricTruncationBanner(AppLocalizations t, ResolvedElectricInputs r) {
    switch (r.explanation) {
      case ElectricTruncationExplanation.none:
        return '';
      case ElectricTruncationExplanation.canonicalKnownTruncatedPair:
        return t.electricTruncationAdjustedCanonical;
      case ElectricTruncationExplanation.inferredFromNeighborClosing:
        return t.electricTruncationAdjustedNeighbor;
    }
  }

  /// Stable doc id so saving the same room+month twice updates rather than
  /// creates duplicates. Editing uses the same scheme; if the user changes
  /// the room or month in edit mode, the old doc is deleted before the
  /// new one is written.
  String _docId(String roomId, DateTime month) =>
      '${roomId}_${formatYearMonthKey(month)}';

  /// Pre-fill meter fields using the nearest readings before / after [month].
  /// When backfilling (e.g. April after May exists), prefills closing meters
  /// from the next month's opening readings (current = successor's previous).
  void _prefillAdjacentFromHistory(
    ReadingsController readings,
    String roomId,
    DateTime month,
  ) {
    final omitEditing = widget.editing == null ? <String>{} : {widget.editing!.id};
    final pred =
        predecessorReading(readings.readings, roomId, month, omitEditing);
    if (pred == null) {
      _prevElec.text = '';
      _prevWater.text = '';
    } else {
      _prevElec.text = formatMeterInputText(pred.currElec);
      _prevWater.text = formatMeterInputText(pred.currWater);
    }

    final succ =
        successorReading(readings.readings, roomId, month, omitEditing);
    if (succ != null) {
      if (_currElec.text.trim().isEmpty) {
        _currElec.text = formatMeterInputText(succ.prevElec);
      }
      if (_currWater.text.trim().isEmpty) {
        _currWater.text = formatMeterInputText(succ.prevWater);
      }
    }
  }

  Future<void> _onSave() async {
    if (_saving) return;
    final t = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      _meterLiveValidation = true;
      AppSnack.error(context, t.formInvalid);
      return;
    }
    FocusScope.of(context).unfocus();

    final readings = Get.find<ReadingsController>();
    final navigator = Navigator.of(context);
    final newId = _docId(_roomId, _month);
    final editing = widget.editing;
    final resolvedElec = _resolvedElectricInputs(readings);

    final readingDraft = Reading(
      id: newId,
      roomId: _roomId,
      month: _month,
      prevElec: resolvedElec.prev,
      currElec: resolvedElec.curr,
      prevWater: _read(_prevWater),
      currWater: _read(_currWater),
      createdAt: editing?.createdAt ?? DateTime.now(),
    );

    final excludeNeighbors = <String>{
      newId,
      if (editing != null) editing.id,
    };
    final chainIssues = mismatchesWithNeighbors(
      readings.readings,
      readingDraft,
      excludeNeighbors,
    );
    if (chainIssues.isNotEmpty) {
      final settings = Get.find<SettingsController>();
      final proceed = await _confirmMeterChainMismatches(
        t,
        settings.settings.localeCode,
        chainIssues,
      );
      if (!proceed || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      if (editing != null && editing.id != newId) {
        await readings.delete(editing.id);
      }
      await readings.upsert(readingDraft);
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

  Future<bool> _confirmMeterChainMismatches(
    AppLocalizations t,
    String locale,
    List<MeterNeighborMismatch> issues,
  ) async {
    final details = issues.map((m) => _meterChainLine(t, locale, m)).join('\n');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.meterChainWarningTitle),
        content: SingleChildScrollView(
          child: Text('${t.meterChainWarningIntro}\n\n$details'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.meterChainSaveAnyway),
          ),
        ],
      ),
    );
    return result == true;
  }

  String _meterChainLine(
    AppLocalizations t,
    String locale,
    MeterNeighborMismatch m,
  ) {
    final neighborMonth = formatYearMonthHuman(m.neighborMonth, locale);
    final expected = formatMeterInputText(m.expected);
    final got = formatMeterInputText(m.got);
    if (m.isPredecessor) {
      return m.isElectricity
          ? t.meterChainPredElectricity(neighborMonth, expected, got)
          : t.meterChainPredWater(neighborMonth, expected, got);
    }
    return m.isElectricity
        ? t.meterChainSuccElectricity(neighborMonth, expected, got)
        : t.meterChainSuccWater(neighborMonth, expected, got);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = Get.find<SettingsController>();
    final readings = Get.find<ReadingsController>();
    final resolvedElec = _resolvedElectricInputs(readings);
    final billColors = Theme.of(context).extension<BillColors>()!;
    final s = settings.settings;
    final locale = s.localeCode;

    final bill = computeBillFromValues(
      prevElec: resolvedElec.prev,
      currElec: resolvedElec.curr,
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
                            _currElec.clear();
                            _currWater.clear();
                            _prefillAdjacentFromHistory(readings, r.id, _month);
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
                        _currElec.clear();
                        _currWater.clear();
                        _prefillAdjacentFromHistory(readings, _roomId, _month);
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
            if (resolvedElec.wasAdjusted) ...[
              const SizedBox(height: AppSpacing.md),
              _InfoBanner(
                text: _electricTruncationBanner(t, resolvedElec),
                color: billColors.elec,
                surfaceColor: billColors.elec.withValues(alpha: 0.12),
                icon: Icons.auto_fix_high_rounded,
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
              helperText: t.electricMeterInputHint,
              usageLabel:
                  '${formatKwh(bill.elecUsageKwh)} • ${formatKhr(bill.elecAmountKhr)}',
              validatePrev: _validateMeterPrev,
              validateCurr: _validateMeterCurrElectric,
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
              validatePrev: _validateMeterPrev,
              validateCurr: _validateMeterCurr,
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

  String? _validateMeterPrev(String? value) {
    final t = AppLocalizations.of(context);
    final s = value?.trim() ?? '';
    if (s.isEmpty) return t.meterReadingEmpty;
    final n = tryParseMeterReading(s);
    if (n == null) return t.invalidNumber;
    return null;
  }

  String? _validateMeterCurr(String? value, String prevText) {
    final t = AppLocalizations.of(context);
    final s = value?.trim() ?? '';
    if (s.isEmpty) return t.meterReadingEmpty;
    final curr = tryParseMeterReading(s);
    if (curr == null) return t.invalidNumber;
    final ps = prevText.trim();
    if (ps.isEmpty) return null;
    final prev = tryParseMeterReading(ps);
    if (prev == null) return null;
    if (curr < prev) return t.errorCurrLessThanPrev;
    return null;
  }

  String? _validateMeterCurrElectric(String? value, String prevText) {
    final t = AppLocalizations.of(context);
    final s = value?.trim() ?? '';
    if (s.isEmpty) return t.meterReadingEmpty;
    final curr = tryParseMeterReading(s);
    if (curr == null) return t.invalidNumber;
    final ps = prevText.trim();
    if (ps.isEmpty) return null;
    if (tryParseMeterReading(ps) == null) return null;
    final readings = Get.find<ReadingsController>();
    final resolved = _resolvedElectricInputs(readings);
    if (resolved.curr < resolved.prev) return t.errorCurrLessThanPrev;
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
    this.helperText,
    required this.usageLabel,
    required this.validatePrev,
    required this.validateCurr,
  });

  final String title;
  final IconData icon;
  final Color color;
  final TextEditingController prev;
  final TextEditingController curr;
  final String prevLabel;
  final String currLabel;
  final String? helperText;
  final String usageLabel;
  final String? Function(String? value) validatePrev;
  final String? Function(String? value, String prevText) validateCurr;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: prev,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9., \u00a0\u202f]'),
                      ),
                    ],
                    validator: validatePrev,
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
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9., \u00a0\u202f]'),
                      ),
                    ],
                    validator: (v) => validateCurr(v, prev.text),
                    decoration: InputDecoration(labelText: currLabel),
                  ),
                ),
              ],
            ),
            if (helperText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                helperText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
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
