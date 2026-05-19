import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/reading.dart';
import '../../services/bill_calculator.dart';
import '../input/input_usage_page.dart';

/// Full view of one saved reading — meters plus bill breakdown. Edit opens [InputUsagePage].
class ReadingDetailPage extends StatelessWidget {
  const ReadingDetailPage({super.key, required this.reading});

  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = Get.find<SettingsController>();
    final s = settings.settings;
    final locale = s.localeCode;
    final bill = computeBill(reading, s);
    final billColors = Theme.of(context).extension<BillColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final roomName = settings.roomById(reading.roomId).name;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.readingDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: t.edit,
            onPressed: () => Get.to(() => InputUsagePage(editing: reading)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: scheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatYearMonthHuman(reading.month, locale),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: t.sectionElectricity.toUpperCase(),
            icon: Icons.bolt_rounded,
            accent: billColors.elec,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _meterRow(context, label: t.fieldPrevMeter, value: formatMeterInputText(reading.prevElec)),
                const SizedBox(height: AppSpacing.sm),
                _meterRow(context, label: t.fieldCurrMeter, value: formatMeterInputText(reading.currElec)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: t.sectionWater.toUpperCase(),
            icon: Icons.water_drop_rounded,
            accent: billColors.water,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _meterRow(context, label: t.fieldPrevMeter, value: formatMeterInputText(reading.prevWater)),
                const SizedBox(height: AppSpacing.sm),
                _meterRow(context, label: t.fieldCurrMeter, value: formatMeterInputText(reading.currWater)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: scheme.primary, size: 22),
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
                  _billBreakdownRow(
                    context,
                    icon: Icons.bolt_rounded,
                    iconColor: billColors.elec,
                    label: t.sectionElectricity,
                    usageRate:
                        '${formatKwh(bill.elecUsageKwh)} • ${formatInt(s.elecRateKhrPerKwh)} ៛/${t.unitKwh}',
                    amount: formatKhr(bill.elecAmountKhr),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _billBreakdownRow(
                    context,
                    icon: Icons.water_drop_rounded,
                    iconColor: billColors.water,
                    label: t.sectionWater,
                    usageRate:
                        '${formatM3(bill.waterUsageM3)} • ${formatInt(s.waterRateKhrPerM3)} ៛/${t.unitM3}',
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
          ),
        ],
      ),
    );
  }

  Widget _meterRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: variant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _billBreakdownRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String usageRate,
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
                usageRate,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
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
