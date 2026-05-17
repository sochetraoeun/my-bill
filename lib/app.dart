import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'controllers/settings_controller.dart';
import 'core/theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/shell/app_shell.dart';

class MyBillApp extends StatelessWidget {
  const MyBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    return Obx(() {
      final settings = settingsController.rx.value;
      return GetMaterialApp(
        title: 'My Bill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode,
        locale: Locale(settings.localeCode),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AppShell(),
      );
    });
  }
}
