import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/readings_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/bill_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsTitle),
        titleSpacing: AppSpacing.lg,
      ),
      body: Obx(() {
        final s = settings.rx.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            96,
          ),
          children: [
            _SectionLabel(text: t.settingsAppearance),
            const SizedBox(height: AppSpacing.sm),
            _ThemeSelector(
              value: s.themeMode,
              onChanged: (mode) async {
                if (mode == s.themeMode) return;
                await settings.setThemeMode(mode);
                if (!context.mounted) return;
                AppSnack.success(
                  context,
                  t.themeChanged,
                  icon: Icons.palette_outlined,
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _LanguageSelector(
              value: s.localeCode,
              onChanged: (code) async {
                if (code == s.localeCode) return;
                await settings.setLocale(code);
                if (!context.mounted) return;
                AppSnack.success(
                  context,
                  AppLocalizations.of(context).languageChanged,
                  icon: Icons.translate_rounded,
                );
              },
              labelEn: t.settingsLangEn,
              labelKm: t.settingsLangKm,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(text: t.settingsRates),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _RateField(
                  initialValue: s.elecRateKhrPerKwh,
                  label: t.settingsRateElec,
                  icon: Icons.bolt,
                  iconColor: Theme.of(
                    context,
                  ).extension<BillColors>()!.elec,
                  onChanged: (v) async {
                    if (v == s.elecRateKhrPerKwh) return;
                    await settings.updateRates(elec: v);
                    if (!context.mounted) return;
                    AppSnack.success(context, t.ratesUpdated);
                  },
                ),
                const _ThinDivider(),
                _RateField(
                  initialValue: s.waterRateKhrPerM3,
                  label: t.settingsRateWater,
                  icon: Icons.water_drop,
                  iconColor: Theme.of(
                    context,
                  ).extension<BillColors>()!.water,
                  onChanged: (v) async {
                    if (v == s.waterRateKhrPerM3) return;
                    await settings.updateRates(water: v);
                    if (!context.mounted) return;
                    AppSnack.success(context, t.ratesUpdated);
                  },
                ),
                const _ThinDivider(),
                _RateField(
                  initialValue: s.khrPerUsd,
                  label: t.settingsFx,
                  icon: Icons.currency_exchange,
                  iconColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) async {
                    if (v == s.khrPerUsd) return;
                    await settings.updateRates(khrPerUsd: v);
                    if (!context.mounted) return;
                    AppSnack.success(context, t.ratesUpdated);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(text: t.settingsRoomNames),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                for (int i = 0; i < s.rooms.length; i++) ...[
                  if (i != 0) const _ThinDivider(),
                  _RoomTile(
                    name: s.rooms[i].name,
                    canDelete: s.rooms.length > 1,
                    onTap: () => _renameRoom(
                      context,
                      s.rooms[i].id,
                      s.rooms[i].name,
                    ),
                    onDelete: () => _confirmRemoveRoom(
                      context,
                      s.rooms[i].id,
                      s.rooms[i].name,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addRoom(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(t.addRoom),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(text: t.settingsAbout),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              children: [
                _AboutTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: t.settingsAppVersion,
                  trailing: Text(
                    settings.appVersion.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const _ThinDivider(),
                _AboutTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: Theme.of(context).colorScheme.error,
                  title: t.settingsResetData,
                  titleColor: Theme.of(context).colorScheme.error,
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Future<void> _renameRoom(
    BuildContext context,
    String id,
    String current,
  ) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final result = await showBillDialog<String>(
      context: context,
      builder: (ctx) => BillDialogFrame(
        icon: const BillDialogIconHeader(icon: Icons.meeting_room_outlined),
        styleBody: false,
        title: t.fieldRoom,
        body: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(),
        ),
        actions: [
          TextButton(
            style: billDialogTextActionStyle(ctx),
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: billDialogFilledActionStyle(ctx),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (result == null) {
      if (!context.mounted) return;
      AppSnack.info(context, t.actionCancelled);
      return;
    }
    if (!context.mounted) return;
    if (result.isEmpty) {
      AppSnack.error(context, t.roomNameEmpty);
      return;
    }
    if (result == current.trim() && current == current.trim()) {
      return;
    }
    try {
      await Get.find<SettingsController>().renameRoom(id, result);
      if (!context.mounted) return;
      AppSnack.success(
        context,
        t.roomRenamed(result),
        icon: Icons.meeting_room_outlined,
      );
    } on DuplicateRoomNameException {
      if (!context.mounted) return;
      AppSnack.error(context, t.roomNameDuplicate);
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.error(context, t.saveFailed(e.toString()));
    }
  }

  Future<void> _addRoom(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showBillDialog<String>(
      context: context,
      builder: (ctx) => BillDialogFrame(
        icon: const BillDialogIconHeader(icon: Icons.meeting_room_outlined),
        styleBody: false,
        title: t.addRoom,
        body: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: t.fieldRoom),
        ),
        actions: [
          TextButton(
            style: billDialogTextActionStyle(ctx),
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: billDialogFilledActionStyle(ctx),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (result == null) {
      if (!context.mounted) return;
      AppSnack.info(context, t.actionCancelled);
      return;
    }
    if (!context.mounted) return;
    if (result.isEmpty) {
      AppSnack.error(context, t.roomNameEmpty);
      return;
    }
    try {
      await Get.find<SettingsController>().addRoom(result);
      if (!context.mounted) return;
      AppSnack.success(
        context,
        t.roomAdded,
        icon: Icons.meeting_room_outlined,
      );
    } on DuplicateRoomNameException {
      if (!context.mounted) return;
      AppSnack.error(context, t.roomNameDuplicate);
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.error(context, t.saveFailed(e.toString()));
    }
  }

  Future<void> _confirmRemoveRoom(
    BuildContext context,
    String id,
    String roomName,
  ) async {
    final t = AppLocalizations.of(context);
    final ok = await showBillDialog<bool>(
      context: context,
      builder: (ctx) => BillDialogFrame(
        icon: const BillDialogIconHeader(
          icon: Icons.meeting_room_outlined,
          destructive: true,
        ),
        title: t.deleteRoomTitle(roomName),
        body: Text(t.deleteRoomMessage),
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
      final readings = Get.find<ReadingsController>();
      await readings.deleteByRoom(id);
      await Get.find<SettingsController>().removeRoom(id);
      if (!context.mounted) return;
      AppSnack.success(
        context,
        t.roomRemoved,
        icon: Icons.meeting_room_outlined,
      );
    } on CannotDeleteLastRoomException {
      if (!context.mounted) return;
      AppSnack.error(context, t.cannotDeleteLastRoom);
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.error(context, t.deleteFailed(e.toString()));
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await showBillDialog<bool>(
      context: context,
      builder: (ctx) => BillDialogFrame(
        icon: const BillDialogIconHeader(
          icon: Icons.warning_amber_rounded,
          destructive: true,
        ),
        title: t.settingsResetData,
        body: Text(t.settingsResetConfirm),
        actions: [
          TextButton(
            style: billDialogTextActionStyle(ctx),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: billDialogDestructiveFilledStyle(ctx),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.confirm),
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
      await Get.find<ReadingsController>().clear();
      if (!context.mounted) return;
      AppSnack.success(
        context,
        t.deletedAllData,
        icon: Icons.delete_sweep_outlined,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnack.error(context, t.deleteFailed(e.toString()));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6, top: AppSpacing.sm),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).dividerColor,
      ),
    );
  }
}

Widget _segmentSingleLineLabel(String text) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.center,
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
    ),
  );
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              _LeadingIcon(
                icon: Icons.palette_outlined,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.settingsTheme,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _description(t, value),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                label: _segmentSingleLineLabel(t.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined, size: 18),
                label: _segmentSingleLineLabel(t.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined, size: 18),
                label: _segmentSingleLineLabel(t.themeDark),
              ),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (set) => onChanged(set.first),
          ),
        ),
      ],
    );
  }

  String _description(AppLocalizations t, ThemeMode mode) => switch (mode) {
    ThemeMode.system => t.themeSystemDescription,
    ThemeMode.light => t.themeLightDescription,
    ThemeMode.dark => t.themeDarkDescription,
  };
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.value,
    required this.onChanged,
    required this.labelEn,
    required this.labelKm,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String labelEn;
  final String labelKm;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              _LeadingIcon(
                icon: Icons.translate_rounded,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  t.settingsLanguage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'en', label: _segmentSingleLineLabel(labelEn)),
              ButtonSegment(value: 'km', label: _segmentSingleLineLabel(labelKm)),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (set) => onChanged(set.first),
          ),
        ),
      ],
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _RateField extends StatefulWidget {
  const _RateField({
    required this.initialValue,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });
  final double initialValue;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Future<void> Function(double) onChanged;

  @override
  State<_RateField> createState() => _RateFieldState();
}

class _RateFieldState extends State<_RateField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue == widget.initialValue.roundToDouble()
          ? widget.initialValue.toStringAsFixed(0)
          : widget.initialValue.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _RateField old) {
    super.didUpdateWidget(old);
    if (old.initialValue != widget.initialValue && !_ctrl.text.contains('.')) {
      _ctrl.text = widget.initialValue.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, String raw) {
    final text = raw.trim().replaceAll(',', '');
    if (text.isEmpty) {
      _ctrl.text = widget.initialValue == widget.initialValue.roundToDouble()
          ? widget.initialValue.toStringAsFixed(0)
          : widget.initialValue.toString();
      return;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) {
      AppSnack.error(context, AppLocalizations.of(context).invalidNumber);
      _ctrl.text = widget.initialValue == widget.initialValue.roundToDouble()
          ? widget.initialValue.toStringAsFixed(0)
          : widget.initialValue.toString();
      return;
    }
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: Row(
      children: [
        _LeadingIcon(icon: widget.icon, color: widget.iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.label,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: Theme.of(context).textTheme.titleMedium,
            onSubmitted: (v) => _submit(context, v),
            onTapOutside: (_) {
              _submit(context, _ctrl.text);
              FocusScope.of(context).unfocus();
            },
          ),
        ),
      ],
    ),
  );
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.name,
    required this.onTap,
    required this.canDelete,
    required this.onDelete,
  });

  final String name;
  final VoidCallback onTap;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                    _LeadingIcon(
                      icon: Icons.meeting_room_outlined,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canDelete)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: IconButton(
                tooltip: t.deleteRoom,
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: scheme.error,
                ),
              ),
            ),
        ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            _LeadingIcon(icon: icon, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: titleColor,
                ),
              ),
            ),
            ?trailing,
            if (onTap != null && trailing == null)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
