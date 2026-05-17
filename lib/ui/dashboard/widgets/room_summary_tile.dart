import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../models/bill.dart';
import 'usage_bar.dart';

class RoomSummaryTile extends StatelessWidget {
  const RoomSummaryTile({
    super.key,
    required this.roomName,
    required this.bill,
    this.onTap,
  });

  final String roomName;
  final BillBreakdown bill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final billColors = Theme.of(context).extension<BillColors>()!;
    final hasData = bill.elecUsageKwh > 0 || bill.waterUsageM3 > 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.18),
                          scheme.primary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: scheme.primary,
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
                        if (hasData)
                          Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: billColors.elec,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                formatKwh(bill.elecUsageKwh),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.water_drop_rounded,
                                size: 14,
                                color: billColors.water,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                formatM3(bill.waterUsageM3),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '—',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasData ? formatKhr(bill.totalKhr) : '—',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                      ),
                      if (hasData)
                        Text(
                          formatUsd(bill.totalUsd),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ),
              if (hasData) ...[
                const SizedBox(height: AppSpacing.md),
                UsageBar(
                  elecAmount: bill.elecAmountKhr,
                  waterAmount: bill.waterAmountKhr,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
