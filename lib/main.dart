import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/readings_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/constants.dart';
import 'services/exchange_rate_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firestore_readings_repository.dart';
import 'services/readings_repository.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Optional file; resolver falls back to [kDefaultExchangeRateApiUrl].
  }

  final prefs = await SharedPreferences.getInstance();

  final settingsService = SettingsService(prefs);
  Get.put<SettingsService>(settingsService);

  Get.put<ExchangeRateService>(
    ExchangeRateService(() {
      final fromEnv = dotenv.env['EXCHANGE_RATE_API_URL']?.trim();
      if (fromEnv != null && fromEnv.isNotEmpty) {
        return fromEnv;
      }
      return kDefaultExchangeRateApiUrl;
    }),
  );
  Get.put<SettingsController>(
    SettingsController(settingsService, Get.find<ExchangeRateService>()),
  );

  final firebaseUp = await tryInitFirebase();

  final ReadingsRepository readingsRepo = firebaseUp
      ? FirestoreReadingsRepository()
      : LocalReadingsRepository(prefs);
  Get.put<ReadingsRepository>(readingsRepo);
  Get.put<ReadingsController>(
    ReadingsController(readingsRepo, isCloud: firebaseUp),
  );

  Get.put<DashboardController>(
    DashboardController(
      readingsController: Get.find<ReadingsController>(),
      settingsController: Get.find<SettingsController>(),
    ),
  );

  runApp(const MyBillApp());
}
