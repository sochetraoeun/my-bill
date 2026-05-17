import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens shared across light and dark themes.
class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// App-specific semantic colors that aren't part of the [ColorScheme].
/// Exposed as a [ThemeExtension] so `Theme.of(context).extension<BillColors>()`
/// works in any widget.
@immutable
class BillColors extends ThemeExtension<BillColors> {
  const BillColors({
    required this.elec,
    required this.elecSurface,
    required this.water,
    required this.waterSurface,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.cardBorder,
    required this.subtleSurface,
    required this.heroGradient,
  });

  final Color elec;
  final Color elecSurface;
  final Color water;
  final Color waterSurface;
  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color cardBorder;
  final Color subtleSurface;
  final List<Color> heroGradient;

  @override
  BillColors copyWith({
    Color? elec,
    Color? elecSurface,
    Color? water,
    Color? waterSurface,
    Color? success,
    Color? successSurface,
    Color? warning,
    Color? warningSurface,
    Color? cardBorder,
    Color? subtleSurface,
    List<Color>? heroGradient,
  }) {
    return BillColors(
      elec: elec ?? this.elec,
      elecSurface: elecSurface ?? this.elecSurface,
      water: water ?? this.water,
      waterSurface: waterSurface ?? this.waterSurface,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      subtleSurface: subtleSurface ?? this.subtleSurface,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  BillColors lerp(ThemeExtension<BillColors>? other, double t) {
    if (other is! BillColors) return this;
    return BillColors(
      elec: Color.lerp(elec, other.elec, t)!,
      elecSurface: Color.lerp(elecSurface, other.elecSurface, t)!,
      water: Color.lerp(water, other.water, t)!,
      waterSurface: Color.lerp(waterSurface, other.waterSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtleSurface: Color.lerp(subtleSurface, other.subtleSurface, t)!,
      heroGradient: [
        for (int i = 0; i < heroGradient.length; i++)
          Color.lerp(
            heroGradient[i],
            other.heroGradient[i.clamp(0, other.heroGradient.length - 1)],
            t,
          )!,
      ],
    );
  }

  static const _light = BillColors(
    elec: Color(0xFFD97706),
    elecSurface: Color(0xFFFEF3C7),
    water: Color(0xFF2563EB),
    waterSurface: Color(0xFFDBEAFE),
    success: Color(0xFF059669),
    successSurface: Color(0xFFD1FAE5),
    warning: Color(0xFFD97706),
    warningSurface: Color(0xFFFEF3C7),
    cardBorder: Color(0x1A0F172A),
    subtleSurface: Color(0xFFF1F5F9),
    heroGradient: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  static const _dark = BillColors(
    elec: Color(0xFFFBBF24),
    elecSurface: Color(0x33F59E0B),
    water: Color(0xFF60A5FA),
    waterSurface: Color(0x333B82F6),
    success: Color(0xFF34D399),
    successSurface: Color(0x3310B981),
    warning: Color(0xFFFBBF24),
    warningSurface: Color(0x33F59E0B),
    cardBorder: Color(0x33FFFFFF),
    subtleSurface: Color(0xFF111827),
    heroGradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
}

class AppTheme {
  static const Color _seed = Color(0xFF4F46E5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final billColors = isDark ? BillColors._dark : BillColors._light;

    final scaffoldBg = isDark
        ? const Color(0xFF0B1020)
        : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'NotoSansKhmer',
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      dividerColor: dividerColor,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: 'NotoSansKhmer',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        )
        .copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      extensions: [billColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: billColors.cardBorder, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: billColors.cardBorder, width: 1),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFF0F172A),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: scheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        elevation: 4,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: billColors.cardBorder),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.primary.withValues(alpha: 0.15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(textTheme.labelLarge),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
        ),
      ),
    );
  }
}
