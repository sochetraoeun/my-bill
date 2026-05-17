import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/readings_controller.dart';
import 'controllers/settings_controller.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firestore_readings_repository.dart';
import 'services/readings_repository.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final settingsService = SettingsService(prefs);
  Get.put<SettingsService>(settingsService);
  Get.put<SettingsController>(SettingsController(settingsService));

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
