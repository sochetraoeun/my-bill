// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'វិក្កយបត្ររបស់ខ្ញុំ';

  @override
  String get tabDashboard => 'ផ្ទាំងព័ត៌មាន';

  @override
  String get tabRooms => 'បន្ទប់';

  @override
  String get tabHistory => 'ប្រវត្តិ';

  @override
  String get tabSettings => 'ការកំណត់';

  @override
  String get fabInputUsage => 'បញ្ចូលថ្មី';

  @override
  String get dashboardTitle => 'ផ្ទាំងព័ត៌មាន';

  @override
  String get statTotalBilled => 'ចំនួនទឹកប្រាក់សរុប';

  @override
  String get statThisMonth => 'ខែនេះ';

  @override
  String get statTotalKwh => 'អគ្គិសនី';

  @override
  String get statTotalM3 => 'ទឹក';

  @override
  String get statRoomsReported => 'បន្ទប់បានរាយការណ៍';

  @override
  String statRoomsValue(int reported, int total) {
    return '$reported/$total';
  }

  @override
  String get perRoomSummary => 'សង្ខេបតាមបន្ទប់';

  @override
  String get monthlyTrend => 'និន្នាការ ៦ ខែ';

  @override
  String get noData => 'មិនទាន់មានទិន្នន័យ។ ចុច + ដើម្បីបន្ថែម។';

  @override
  String get roomsTitle => 'បន្ទប់';

  @override
  String roomLabel(int n) {
    return 'បន្ទប់ $n';
  }

  @override
  String get roomDetailTitle => 'ព័ត៌មានបន្ទប់';

  @override
  String get roomHistory => 'ប្រវត្តិ';

  @override
  String get exportPdf => 'នាំចេញ PDF';

  @override
  String get exportExcel => 'នាំចេញ Excel';

  @override
  String get inputUsageTitle => 'បញ្ចូលការប្រើប្រាស់';

  @override
  String get fieldRoom => 'បន្ទប់';

  @override
  String get fieldMonth => 'ខែ';

  @override
  String get sectionElectricity => 'អគ្គិសនី';

  @override
  String get sectionWater => 'ទឹក';

  @override
  String get fieldPrevMeter => 'ម៉ែត្រលើកមុន';

  @override
  String get fieldCurrMeter => 'ម៉ែត្របច្ចុប្បន្ន';

  @override
  String get previewBill => 'មើលជាមុនវិក្កយបត្រ';

  @override
  String get labelUsage => 'ប្រើប្រាស់';

  @override
  String get labelRate => 'តម្លៃ';

  @override
  String get labelAmount => 'ចំនួនទឹកប្រាក់';

  @override
  String get labelTotal => 'សរុប';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get saved => 'បានរក្សាទុក។';

  @override
  String get savedCloud => 'បានរក្សាទុកលើ Cloud។';

  @override
  String get savedLocal => 'បានរក្សាទុកលើឧបករណ៍។';

  @override
  String saveFailed(String error) {
    return 'រក្សាទុកមិនបាន៖ $error';
  }

  @override
  String get saving => 'កំពុងរក្សាទុក…';

  @override
  String get formInvalid => 'សូមកែបញ្ហាដែលបានសម្គាល់។';

  @override
  String get roomNameEmpty => 'ឈ្មោះបន្ទប់មិនអាចទទេបានទេ។';

  @override
  String get roomNameDuplicate =>
      'បន្ទប់ផ្សេងទៀតបានប្រើឈ្មោះនេះរួចហើយ។ សូមជ្រើសរើសឈ្មោះផ្សេង។';

  @override
  String get invalidNumber => 'សូមបញ្ចូលលេខត្រឹមត្រូវ។';

  @override
  String get filtersUpdated => 'បានធ្វើបច្ចុប្បន្នភាពតម្រង។';

  @override
  String get filtersCleared => 'បានសម្អាតតម្រង។';

  @override
  String get actionCancelled => 'បានបោះបង់សកម្មភាព។';

  @override
  String get badgeCloud => 'Cloud';

  @override
  String get badgeLocal => 'ក្នុងឧបករណ៍';

  @override
  String get updateExisting =>
      'មានទិន្នន័យសម្រាប់បន្ទប់នេះក្នុងខែនេះរួចហើយ។ ការរក្សាទុកនឹងធ្វើបច្ចុប្បន្នភាពវា។';

  @override
  String get errorCurrLessThanPrev =>
      'ម៉ែត្របច្ចុប្បន្នត្រូវធំជាងឬស្មើនឹងម៉ែត្រលើកមុន។';

  @override
  String get historyTitle => 'ប្រវត្តិ';

  @override
  String get filterAllRooms => 'បន្ទប់ទាំងអស់';

  @override
  String get filterAllMonths => 'ខែទាំងអស់';

  @override
  String get emptyHistory => 'មិនទាន់មានទិន្នន័យ។';

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get settingsRates => 'តម្លៃឯកតា';

  @override
  String get settingsRateElec => 'តម្លៃអគ្គិសនី (៛ / kWh)';

  @override
  String get settingsRateWater => 'តម្លៃទឹក (៛ / m³)';

  @override
  String get settingsFx => 'អត្រាប្តូរប្រាក់ (៛ / USD)';

  @override
  String get settingsFxOfficialTooltip =>
      'អត្រា USD ផ្លូវការ (សេនាធិការសេដ្ឋកិច្ជា)';

  @override
  String get fxOfficialRateUpdated =>
      'បានធ្វើបច្ចុប្បន្នភាពអត្រាពីសេនាធិការសេដ្ឋកិច្ជារបស់រដ្ឋ (យោង)។';

  @override
  String fxOfficialRateFailed(String error) {
    return 'មិនអាចធ្វើបច្ចុប្បន្នភាពអត្រាផ្លូវការបាន៖ $error';
  }

  @override
  String get settingsLanguage => 'ភាសា';

  @override
  String get settingsLangEn => 'អង់គ្លេស';

  @override
  String get settingsLangKm => 'ខ្មែរ';

  @override
  String get settingsAppearance => 'រូបរាង';

  @override
  String get settingsTheme => 'ស្បែក';

  @override
  String get themeSystem => 'តាមប្រព័ន្ធ';

  @override
  String get themeLight => 'ភ្លឺ';

  @override
  String get themeDark => 'ងងឹត';

  @override
  String get themeSystemDescription => 'ផ្គូផ្គងតាមឧបករណ៍';

  @override
  String get themeLightDescription => 'ប្រើស្បែកភ្លឺជានិច្ច';

  @override
  String get themeDarkDescription => 'ប្រើស្បែកងងឹតជានិច្ច';

  @override
  String get dashboardGreeting => 'សួស្ដី';

  @override
  String get dashboardSubtitle => 'នេះគឺជាទិដ្ឋភាពរួមប្រចាំខែរបស់អ្នក';

  @override
  String get viewAll => 'មើលទាំងអស់';

  @override
  String get billPreviewTitle => 'មើលជាមុនវិក្កយបត្រ';

  @override
  String get delete => 'លុប';

  @override
  String get edit => 'កែប្រែ';

  @override
  String get settingsAppVersion => 'កំណែកម្មវិធី';

  @override
  String get deleteReadingTitle => 'លុបការអាន?';

  @override
  String get deleteReadingMessage => 'សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get deleteRoomData => 'លុបទិន្នន័យបន្ទប់';

  @override
  String deleteRoomDataTitle(String room) {
    return 'លុបទិន្នន័យទាំងអស់សម្រាប់ $room?';
  }

  @override
  String get deleteRoomDataMessage =>
      'ការអានទាំងអស់សម្រាប់បន្ទប់នេះនឹងត្រូវលុបចេញ។ មិនអាចត្រឡប់វិញបានទេ។';

  @override
  String deletedRoomData(String room) {
    return 'បានលុបការអានទាំងអស់សម្រាប់ $room។';
  }

  @override
  String get deleteRoomDataEmpty => 'មិនមានទិន្នន័យសម្រាប់លុបទេ។';

  @override
  String get deletedReading => 'បានលុបការអាន។';

  @override
  String get deletedAllData => 'បានលុបការអានទាំងអស់។';

  @override
  String deleteFailed(String error) {
    return 'លុបមិនបាន៖ $error';
  }

  @override
  String get exportedPdf => 'PDF រួចរាល់សម្រាប់ចែករំលែក។';

  @override
  String get exportedExcel => 'Excel រួចរាល់សម្រាប់ចែករំលែក។';

  @override
  String exportFailed(String error) {
    return 'នាំចេញមិនបាន៖ $error';
  }

  @override
  String roomRenamed(String name) {
    return 'បានប្តូរឈ្មោះបន្ទប់ទៅ $name។';
  }

  @override
  String get ratesUpdated => 'បានធ្វើបច្ចុប្បន្នភាពតម្លៃ។';

  @override
  String get themeChanged => 'បានធ្វើបច្ចុប្បន្នភាពស្បែក។';

  @override
  String get languageChanged => 'បានធ្វើបច្ចុប្បន្នភាពភាសា។';

  @override
  String get settingsRoomNames => 'ឈ្មោះបន្ទប់';

  @override
  String get addRoom => 'បន្ថែមបន្ទប់';

  @override
  String get deleteRoom => 'យកបន្ទប់ចេញ';

  @override
  String deleteRoomTitle(String room) {
    return 'យក $room ចេញ?';
  }

  @override
  String get deleteRoomMessage =>
      'បន្ទប់នេះនឹងត្រូវដកចេញពីបញ្ជី ហើយការអានទាំងអស់នឹងត្រូវលុប។ មិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get cannotDeleteLastRoom => 'ត្រូវមានយ៉ាងហោចណាស់មួយបន្ទប់។';

  @override
  String get roomAdded => 'បានបន្ថែមបន្ទប់។';

  @override
  String get roomRemoved => 'បានយកបន្ទប់ចេញ។';

  @override
  String get settingsAbout => 'អំពី';

  @override
  String get settingsResetData => 'លុបទិន្នន័យទាំងអស់';

  @override
  String get settingsResetConfirm => 'លុបការអានទាំងអស់? មិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get confirm => 'យល់ព្រម';

  @override
  String get unitKwh => 'kWh';

  @override
  String get unitM3 => 'm³';

  @override
  String get currencyKhr => '៛';

  @override
  String get currencyUsd => '\$';
}
