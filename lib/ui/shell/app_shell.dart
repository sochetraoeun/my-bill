import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../dashboard/dashboard_page.dart';
import '../history/history_page.dart';
import '../input/input_usage_page.dart';
import '../rooms/rooms_page.dart';
import '../settings/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    RoomsPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final billColors = Theme.of(context).extension<BillColors>()!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Get.to(() => const InputUsagePage()),
          tooltip: t.fabInputUsage,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _AppBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        labels: [
          t.tabDashboard,
          t.tabRooms,
          t.tabHistory,
          t.tabSettings,
        ],
        cardBorder: billColors.cardBorder,
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.index,
    required this.onChanged,
    required this.labels,
    required this.cardBorder,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cardBorder)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onChanged,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: labels[0],
            ),
            NavigationDestination(
              icon: const Icon(Icons.meeting_room_outlined),
              selectedIcon: const Icon(Icons.meeting_room_rounded),
              label: labels[1],
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history_rounded),
              label: labels[2],
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: labels[3],
            ),
          ],
        ),
      ),
    );
  }
}
