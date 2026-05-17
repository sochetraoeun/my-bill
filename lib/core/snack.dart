import 'package:flutter/material.dart';

import 'theme.dart';

/// App-wide snackbar helper.
///
/// All actions in the app should surface their result through one of these
/// helpers so the user always gets feedback (success / error / info).
/// Background colors follow the app theme: success → green, error → red,
/// info → default themed snackbar.
class AppSnack {
  AppSnack._();

  static void success(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    final billColors = Theme.of(context).extension<BillColors>();
    _show(
      context,
      message: message,
      icon: icon,
      background: billColors?.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    IconData icon = Icons.error_outline_rounded,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      background: Theme.of(context).colorScheme.error,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    _show(context, message: message, icon: icon, duration: duration);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Duration duration,
    Color? background,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: background,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
