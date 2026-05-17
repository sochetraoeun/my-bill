import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Hero card showing the headline metric for the current month.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalKhr,
    required this.totalUsd,
    required this.roomsReported,
    required this.roomsTotal,
    required this.roomsLabel,
  });

  final String title;
  final String subtitle;
  final String totalKhr;
  final String totalUsd;
  final int roomsReported;
  final int roomsTotal;
  final String roomsLabel;

  @override
  Widget build(BuildContext context) {
    final billColors = Theme.of(context).extension<BillColors>()!;
    final progress = roomsTotal == 0 ? 0.0 : roomsReported / roomsTotal;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: billColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: billColors.heroGradient.first.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: _Blob(
              color: Colors.white.withValues(alpha: 0.12),
              size: 160,
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: _Blob(
              color: Colors.white.withValues(alpha: 0.08),
              size: 110,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  totalKhr,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalUsd,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      roomsLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      '$roomsReported / $roomsTotal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
