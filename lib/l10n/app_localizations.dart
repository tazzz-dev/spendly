import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('id'),
    Locale('th'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Setting'**
  String get settingsTitle;

  /// No description provided for @settingsRestorePurchase.
  ///
  /// In id, this message translates to:
  /// **'Pulihkan Pembayaran Sebelumnya'**
  String get settingsRestorePurchase;

  /// No description provided for @settingsRemoveAds.
  ///
  /// In id, this message translates to:
  /// **'Hapus Iklan'**
  String get settingsRemoveAds;

  /// No description provided for @settingsUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Fitur ini belum tersedia di versi ini'**
  String get settingsUnavailable;

  /// No description provided for @settingsShowDecimals.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan Angka Desimal'**
  String get settingsShowDecimals;

  /// No description provided for @settingsShowDecimalsExample.
  ///
  /// In id, this message translates to:
  /// **'Contoh: {amount}'**
  String settingsShowDecimalsExample(String amount);

  /// No description provided for @settingsBackupRestore.
  ///
  /// In id, this message translates to:
  /// **'Backup dan Restore Data'**
  String get settingsBackupRestore;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In id, this message translates to:
  /// **'Hapus Semua Data'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllBody.
  ///
  /// In id, this message translates to:
  /// **'Seluruh transaksi, rekening, hutang, saran, dan anggaran akan dikosongkan. Setelan tidak ikut terhapus. Aksi ini tidak dapat diurungkan.'**
  String get settingsDeleteAllBody;

  /// No description provided for @settingsDeleteAllDone.
  ///
  /// In id, this message translates to:
  /// **'Semua data telah dihapus'**
  String get settingsDeleteAllDone;

  /// No description provided for @settingsReminder.
  ///
  /// In id, this message translates to:
  /// **'Pengingat'**
  String get settingsReminder;

  /// No description provided for @settingsReminderSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pengingat mencatat harian'**
  String get settingsReminderSubtitle;

  /// No description provided for @settingsReminderWhen.
  ///
  /// In id, this message translates to:
  /// **'Kapan'**
  String get settingsReminderWhen;

  /// No description provided for @settingsReminderPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin notifikasi ditolak, pengingat tidak akan muncul'**
  String get settingsReminderPermissionDenied;

  /// No description provided for @settingsTheme.
  ///
  /// In id, this message translates to:
  /// **'Warna Tema'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguage;

  /// No description provided for @settingsCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get settingsCancel;

  /// No description provided for @settingsDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get settingsDelete;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal membaca setelan: {error}'**
  String settingsLoadFailed(String error);

  /// No description provided for @themeBlue.
  ///
  /// In id, this message translates to:
  /// **'Biru Terang'**
  String get themeBlue;

  /// No description provided for @themePink.
  ///
  /// In id, this message translates to:
  /// **'Mode Pink'**
  String get themePink;

  /// No description provided for @themePurple.
  ///
  /// In id, this message translates to:
  /// **'Mode Ungu'**
  String get themePurple;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Mode Gelap'**
  String get themeDark;
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
      <String>['en', 'id', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
