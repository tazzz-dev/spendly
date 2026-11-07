// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsRestorePurchase => 'Restore Previous Purchase';

  @override
  String get settingsRemoveAds => 'Remove Ads';

  @override
  String get settingsUnavailable =>
      'This feature is not available in this version';

  @override
  String get settingsShowDecimals => 'Show Decimal Numbers';

  @override
  String settingsShowDecimalsExample(String amount) {
    return 'Example: $amount';
  }

  @override
  String get settingsBackupRestore => 'Backup and Restore Data';

  @override
  String get settingsDeleteAll => 'Delete All Data';

  @override
  String get settingsDeleteAllBody =>
      'All transactions, accounts, debts, suggestions, and budgets will be cleared. Settings are kept. This action cannot be undone.';

  @override
  String get settingsDeleteAllDone => 'All data has been deleted';

  @override
  String get settingsReminder => 'Reminder';

  @override
  String get settingsReminderSubtitle => 'Daily record reminder';

  @override
  String get settingsReminderWhen => 'When';

  @override
  String get settingsReminderPermissionDenied =>
      'Notification permission was denied, the reminder will not appear';

  @override
  String get settingsTheme => 'Theme Color';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsDelete => 'Delete';

  @override
  String settingsLoadFailed(String error) {
    return 'Failed to read settings: $error';
  }

  @override
  String get themeBlue => 'Light Blue';

  @override
  String get themePink => 'Pink Mode';

  @override
  String get themePurple => 'Purple Mode';

  @override
  String get themeDark => 'Dark Mode';
}
