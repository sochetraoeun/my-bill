import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Tiny stacked horizontal bar showing electricity vs water amount.
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.elecAmount,
    required this.waterAmount,
  });

  final double elecAmount;
  final double waterAmount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final billColors = Theme.of(context).extension<BillColors>()!;
    final total = elecAmount + waterAmount;
    final elecPct = total <= 0 ? 0.0 : elecAmount / total;
    final waterPct = total <= 0 ? 0.0 : waterAmount / total;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(width: w * elecPct, color: billColors.elec),
              Container(width: w * waterPct, color: billColors.water),
            ],
          ),
        );
      },
    );
  }
}
