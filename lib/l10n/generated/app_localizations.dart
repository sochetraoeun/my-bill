import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Bill'**
  String get appTitle;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get tabRooms;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @fabInputUsage.
  ///
  /// In en, this message translates to:
  /// **'New Usage'**
  String get fabInputUsage;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @statTotalBilled.
  ///
  /// In en, this message translates to:
  /// **'Total Billed'**
  String get statTotalBilled;

  /// No description provided for @statThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get statThisMonth;

  /// No description provided for @statTotalKwh.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get statTotalKwh;

  /// No description provided for @statTotalM3.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get statTotalM3;

  /// No description provided for @statRoomsReported.
  ///
  /// In en, this message translates to:
  /// **'Rooms Reported'**
  String get statRoomsReported;

  /// No description provided for @statRoomsValue.
  ///
  /// In en, this message translates to:
  /// **'{reported}/{total}'**
  String statRoomsValue(int reported, int total);

  /// No description provided for @perRoomSummary.
  ///
  /// In en, this message translates to:
  /// **'Per-Room Summary'**
  String get perRoomSummary;

  /// No description provided for @monthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'6-Month Trend'**
  String get monthlyTrend;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet. Tap + to add a reading.'**
  String get noData;

  /// No description provided for @roomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsTitle;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room {n}'**
  String roomLabel(int n);

  /// No description provided for @roomDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Detail'**
  String get roomDetailTitle;

  /// No description provided for @roomHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get roomHistory;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @reorderReadingsHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get reorderReadingsHint;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @inputUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Input Usage'**
  String get inputUsageTitle;

  /// No description provided for @fieldRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get fieldRoom;

  /// No description provided for @fieldMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get fieldMonth;

  /// No description provided for @sectionElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get sectionElectricity;

  /// No description provided for @sectionWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get sectionWater;

  /// No description provided for @fieldPrevMeter.
  ///
  /// In en, this message translates to:
  /// **'Previous meter'**
  String get fieldPrevMeter;

  /// No description provided for @fieldCurrMeter.
  ///
  /// In en, this message translates to:
  /// **'Current meter'**
  String get fieldCurrMeter;

  /// No description provided for @previewBill.
  ///
  /// In en, this message translates to:
  /// **'Bill Preview'**
  String get previewBill;

  /// No description provided for @labelUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get labelUsage;

  /// No description provided for @labelRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get labelRate;

  /// No description provided for @labelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get labelAmount;

  /// No description provided for @labelTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get labelTotal;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get saved;

  /// No description provided for @savedCloud.
  ///
  /// In en, this message translates to:
  /// **'Saved to cloud.'**
  String get savedCloud;

  /// No description provided for @savedLocal.
  ///
  /// In en, this message translates to:
  /// **'Saved on device.'**
  String get savedLocal;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @formInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted errors.'**
  String get formInvalid;

  /// No description provided for @roomNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Room name cannot be empty.'**
  String get roomNameEmpty;

  /// No description provided for @roomNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another room already uses that name. Choose a different name.'**
  String get roomNameDuplicate;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number.'**
  String get invalidNumber;

  /// No description provided for @meterReadingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Meter reading cannot be empty.'**
  String get meterReadingEmpty;

  /// No description provided for @filtersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Filters updated.'**
  String get filtersUpdated;

  /// No description provided for @filtersCleared.
  ///
  /// In en, this message translates to:
  /// **'Filters cleared.'**
  String get filtersCleared;

  /// No description provided for @actionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Action cancelled.'**
  String get actionCancelled;

  /// No description provided for @badgeCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get badgeCloud;

  /// No description provided for @badgeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get badgeLocal;

  /// No description provided for @updateExisting.
  ///
  /// In en, this message translates to:
  /// **'A reading already exists for this room and month. Saving will update it.'**
  String get updateExisting;

  /// No description provided for @errorCurrLessThanPrev.
  ///
  /// In en, this message translates to:
  /// **'Current meter must be greater than or equal to previous.'**
  String get errorCurrLessThanPrev;

  /// No description provided for @meterChainWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Meters don\'t match nearby months'**
  String get meterChainWarningTitle;

  /// No description provided for @meterChainWarningIntro.
  ///
  /// In en, this message translates to:
  /// **'Neighboring readings use different values:'**
  String get meterChainWarningIntro;

  /// No description provided for @meterChainSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get meterChainSaveAnyway;

  /// No description provided for @meterChainPredElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity — ‘Previous’ is {got}, but {neighborMonth} ends at {expected}.'**
  String meterChainPredElectricity(
    String neighborMonth,
    String expected,
    String got,
  );

  /// No description provided for @meterChainPredWater.
  ///
  /// In en, this message translates to:
  /// **'Water — ‘Previous’ is {got}, but {neighborMonth} ends at {expected}.'**
  String meterChainPredWater(String neighborMonth, String expected, String got);

  /// No description provided for @meterChainSuccElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity — ‘Current’ is {got}, but {neighborMonth} opens at {expected}.'**
  String meterChainSuccElectricity(
    String neighborMonth,
    String expected,
    String got,
  );

  /// No description provided for @meterChainSuccWater.
  ///
  /// In en, this message translates to:
  /// **'Water — ‘Current’ is {got}, but {neighborMonth} opens at {expected}.'**
  String meterChainSuccWater(String neighborMonth, String expected, String got);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @filterAllRooms.
  ///
  /// In en, this message translates to:
  /// **'All rooms'**
  String get filterAllRooms;

  /// No description provided for @filterAllMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get filterAllMonths;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No readings yet.'**
  String get emptyHistory;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsRates.
  ///
  /// In en, this message translates to:
  /// **'Tariff'**
  String get settingsRates;

  /// No description provided for @settingsRateElec.
  ///
  /// In en, this message translates to:
  /// **'Electricity rate (KHR / kWh)'**
  String get settingsRateElec;

  /// No description provided for @settingsRateWater.
  ///
  /// In en, this message translates to:
  /// **'Water rate (KHR / m³)'**
  String get settingsRateWater;

  /// No description provided for @settingsFx.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate (KHR / USD)'**
  String get settingsFx;

  /// No description provided for @settingsFxCloudHint.
  ///
  /// In en, this message translates to:
  /// **'Synced from the server when online (updated daily). You can still type an override.'**
  String get settingsFxCloudHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLangEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLangEn;

  /// No description provided for @settingsLangKm.
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get settingsLangKm;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Match device theme'**
  String get themeSystemDescription;

  /// No description provided for @themeLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeLightDescription;

  /// No description provided for @themeDarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeDarkDescription;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello there'**
  String get dashboardGreeting;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here is your monthly overview'**
  String get dashboardSubtitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @billPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill Preview'**
  String get billPreviewTitle;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// No description provided for @deleteReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reading?'**
  String get deleteReadingTitle;

  /// No description provided for @deleteReadingMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteReadingMessage;

  /// No description provided for @deleteRoomData.
  ///
  /// In en, this message translates to:
  /// **'Delete room data'**
  String get deleteRoomData;

  /// No description provided for @deleteRoomDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data for {room}?'**
  String deleteRoomDataTitle(String room);

  /// No description provided for @deleteRoomDataMessage.
  ///
  /// In en, this message translates to:
  /// **'All readings for this room will be removed. This cannot be undone.'**
  String get deleteRoomDataMessage;

  /// No description provided for @deletedRoomData.
  ///
  /// In en, this message translates to:
  /// **'Deleted all readings for {room}.'**
  String deletedRoomData(String room);

  /// No description provided for @deleteRoomDataEmpty.
  ///
  /// In en, this message translates to:
  /// **'No readings to delete for this room.'**
  String get deleteRoomDataEmpty;

  /// No description provided for @deletedReading.
  ///
  /// In en, this message translates to:
  /// **'Reading deleted.'**
  String get deletedReading;

  /// No description provided for @deletedAllData.
  ///
  /// In en, this message translates to:
  /// **'All readings deleted.'**
  String get deletedAllData;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @exportedPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF ready to share.'**
  String get exportedPdf;

  /// No description provided for @exportedExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel ready to share.'**
  String get exportedExcel;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @roomRenamed.
  ///
  /// In en, this message translates to:
  /// **'Room renamed to {name}.'**
  String roomRenamed(String name);

  /// No description provided for @ratesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rates updated.'**
  String get ratesUpdated;

  /// No description provided for @themeChanged.
  ///
  /// In en, this message translates to:
  /// **'Theme updated.'**
  String get themeChanged;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language updated.'**
  String get languageChanged;

  /// No description provided for @settingsRoomNames.
  ///
  /// In en, this message translates to:
  /// **'Room names'**
  String get settingsRoomNames;

  /// No description provided for @addRoom.
  ///
  /// In en, this message translates to:
  /// **'Add room'**
  String get addRoom;

  /// No description provided for @deleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Remove room'**
  String get deleteRoom;

  /// No description provided for @deleteRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {room}?'**
  String deleteRoomTitle(String room);

  /// No description provided for @deleteRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'This room will be removed from the list and all readings for it will be deleted. This cannot be undone.'**
  String get deleteRoomMessage;

  /// No description provided for @cannotDeleteLastRoom.
  ///
  /// In en, this message translates to:
  /// **'You need at least one room.'**
  String get cannotDeleteLastRoom;

  /// No description provided for @roomAdded.
  ///
  /// In en, this message translates to:
  /// **'Room added.'**
  String get roomAdded;

  /// No description provided for @roomRemoved.
  ///
  /// In en, this message translates to:
  /// **'Room removed.'**
  String get roomRemoved;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsResetData.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get settingsResetData;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete every reading? This cannot be undone.'**
  String get settingsResetConfirm;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unitKwh.
  ///
  /// In en, this message translates to:
  /// **'kWh'**
  String get unitKwh;

  /// No description provided for @unitM3.
  ///
  /// In en, this message translates to:
  /// **'m³'**
  String get unitM3;

  /// No description provided for @currencyKhr.
  ///
  /// In en, this message translates to:
  /// **'៛'**
  String get currencyKhr;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currencyUsd;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
