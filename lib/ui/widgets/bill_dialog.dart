import 'package:flutter/material.dart';

import '../../core/theme.dart';

Color _barrierColor(BuildContext context) {
  return Theme.of(context).colorScheme.scrim.withValues(alpha: 0.48);
}

/// [showDialog] with a softer scrim consistent across the app.
Future<T?> showBillDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext dialogContext) builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: _barrierColor(context),
    builder: builder,
  );
}

ButtonStyle billDialogTextActionStyle(BuildContext context) {
  return TextButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

ButtonStyle billDialogFilledActionStyle(BuildContext context) {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

ButtonStyle billDialogDestructiveFilledStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return billDialogFilledActionStyle(context).copyWith(
    backgroundColor: WidgetStatePropertyAll(scheme.error),
    foregroundColor: WidgetStatePropertyAll(scheme.onError),
  );
}

/// Circular icon header for dialog titles (Material 3–style).
class BillDialogIconHeader extends StatelessWidget {
  const BillDialogIconHeader({
    super.key,
    required this.icon,
    this.destructive = false,
  });

  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = destructive ? scheme.errorContainer : scheme.primaryContainer;
    final fg = destructive ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: fg, size: 28),
    );
  }
}

/// Shared dialog chrome: card border, typography, optional icon, action area.
class BillDialogFrame extends StatelessWidget {
  const BillDialogFrame({
    super.key,
    this.icon,
    this.styleBody = true,
    required this.title,
    required this.body,
    required this.actions,
  });

  final Widget? icon;
  /// When true, [body] is wrapped with secondary on-surface text style (e.g. confirm copy).
  final bool styleBody;
  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billColors = theme.extension<BillColors>()!;
    final hasIcon = icon != null;

    final content = styleBody
        ? DefaultTextStyle.merge(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
            child: body,
          )
        : body;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      backgroundColor: theme.dialogTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: theme.dialogTheme.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: billColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasIcon) ...[
                Center(child: icon!),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                title,
                textAlign: hasIcon ? TextAlign.center : TextAlign.start,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              content,
              SizedBox(height: hasIcon ? AppSpacing.xl : AppSpacing.lg),
              Divider(height: 1, color: theme.dividerColor),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
