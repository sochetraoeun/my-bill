// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Bill';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabRooms => 'Rooms';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSettings => 'Settings';

  @override
  String get fabInputUsage => 'New Usage';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get statTotalBilled => 'Total Billed';

  @override
  String get statThisMonth => 'This Month';

  @override
  String get statTotalKwh => 'Electricity';

  @override
  String get statTotalM3 => 'Water';

  @override
  String get statRoomsReported => 'Rooms Reported';

  @override
  String statRoomsValue(int reported, int total) {
    return '$reported/$total';
  }

  @override
  String get perRoomSummary => 'Per-Room Summary';

  @override
  String get monthlyTrend => '6-Month Trend';

  @override
  String get noData => 'No data yet. Tap + to add a reading.';

  @override
  String get roomsTitle => 'Rooms';

  @override
  String roomLabel(int n) {
    return 'Room $n';
  }

  @override
  String get roomDetailTitle => 'Room Detail';

  @override
  String get roomHistory => 'History';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get reorderReadingsHint => 'Drag to reorder';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get inputUsageTitle => 'Input Usage';

  @override
  String get fieldRoom => 'Room';

  @override
  String get fieldMonth => 'Month';

  @override
  String get sectionElectricity => 'Electricity';

  @override
  String get sectionWater => 'Water';

  @override
  String get fieldPrevMeter => 'Previous meter';

  @override
  String get fieldCurrMeter => 'Current meter';

  @override
  String get previewBill => 'Bill Preview';

  @override
  String get labelUsage => 'Usage';

  @override
  String get labelRate => 'Rate';

  @override
  String get labelAmount => 'Amount';

  @override
  String get labelTotal => 'Total';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get saved => 'Saved.';

  @override
  String get savedCloud => 'Saved to cloud.';

  @override
  String get savedLocal => 'Saved on device.';

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get formInvalid => 'Please fix the highlighted errors.';

  @override
  String get roomNameEmpty => 'Room name cannot be empty.';

  @override
  String get roomNameDuplicate =>
      'Another room already uses that name. Choose a different name.';

  @override
  String get invalidNumber => 'Please enter a valid number.';

  @override
  String get filtersUpdated => 'Filters updated.';

  @override
  String get filtersCleared => 'Filters cleared.';

  @override
  String get actionCancelled => 'Action cancelled.';

  @override
  String get badgeCloud => 'Cloud';

  @override
  String get badgeLocal => 'Local';

  @override
  String get updateExisting =>
      'A reading already exists for this room and month. Saving will update it.';

  @override
  String get errorCurrLessThanPrev =>
      'Current meter must be greater than or equal to previous.';

  @override
  String get historyTitle => 'History';

  @override
  String get filterAllRooms => 'All rooms';

  @override
  String get filterAllMonths => 'All months';

  @override
  String get emptyHistory => 'No readings yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsRates => 'Tariff';

  @override
  String get settingsRateElec => 'Electricity rate (KHR / kWh)';

  @override
  String get settingsRateWater => 'Water rate (KHR / m³)';

  @override
  String get settingsFx => 'Exchange rate (KHR / USD)';

  @override
  String get settingsFxOfficialTooltip => 'Official USD/KHR rate (MEF)';

  @override
  String get fxOfficialRateUpdated =>
      'Exchange rate updated from Ministry of Economy and Finance (reference).';

  @override
  String fxOfficialRateFailed(String error) {
    return 'Could not refresh official rate: $error';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLangEn => 'English';

  @override
  String get settingsLangKm => 'Khmer';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemDescription => 'Match device theme';

  @override
  String get themeLightDescription => 'Always use light theme';

  @override
  String get themeDarkDescription => 'Always use dark theme';

  @override
  String get dashboardGreeting => 'Hello there';

  @override
  String get dashboardSubtitle => 'Here is your monthly overview';

  @override
  String get viewAll => 'View all';

  @override
  String get billPreviewTitle => 'Bill Preview';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get deleteReadingTitle => 'Delete reading?';

  @override
  String get deleteReadingMessage => 'This action cannot be undone.';

  @override
  String get deleteRoomData => 'Delete room data';

  @override
  String deleteRoomDataTitle(String room) {
    return 'Delete all data for $room?';
  }

  @override
  String get deleteRoomDataMessage =>
      'All readings for this room will be removed. This cannot be undone.';

  @override
  String deletedRoomData(String room) {
    return 'Deleted all readings for $room.';
  }

  @override
  String get deleteRoomDataEmpty => 'No readings to delete for this room.';

  @override
  String get deletedReading => 'Reading deleted.';

  @override
  String get deletedAllData => 'All readings deleted.';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get exportedPdf => 'PDF ready to share.';

  @override
  String get exportedExcel => 'Excel ready to share.';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String roomRenamed(String name) {
    return 'Room renamed to $name.';
  }

  @override
  String get ratesUpdated => 'Rates updated.';

  @override
  String get themeChanged => 'Theme updated.';

  @override
  String get languageChanged => 'Language updated.';

  @override
  String get settingsRoomNames => 'Room names';

  @override
  String get addRoom => 'Add room';

  @override
  String get deleteRoom => 'Remove room';

  @override
  String deleteRoomTitle(String room) {
    return 'Remove $room?';
  }

  @override
  String get deleteRoomMessage =>
      'This room will be removed from the list and all readings for it will be deleted. This cannot be undone.';

  @override
  String get cannotDeleteLastRoom => 'You need at least one room.';

  @override
  String get roomAdded => 'Room added.';

  @override
  String get roomRemoved => 'Room removed.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsResetData => 'Reset all data';

  @override
  String get settingsResetConfirm =>
      'Delete every reading? This cannot be undone.';

  @override
  String get confirm => 'Confirm';

  @override
  String get unitKwh => 'kWh';

  @override
  String get unitM3 => 'm³';

  @override
  String get currencyKhr => '៛';

  @override
  String get currencyUsd => '\$';
}
