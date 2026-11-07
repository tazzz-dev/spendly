// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get settingsRestorePurchase => 'กู้คืนการซื้อก่อนหน้า';

  @override
  String get settingsRemoveAds => 'ลบโฆษณา';

  @override
  String get settingsUnavailable => 'ฟีเจอร์นี้ยังไม่มีในเวอร์ชันนี้';

  @override
  String get settingsShowDecimals => 'แสดงทศนิยม';

  @override
  String settingsShowDecimalsExample(String amount) {
    return 'ตัวอย่าง: $amount';
  }

  @override
  String get settingsBackupRestore => 'สำรองและกู้คืนข้อมูล';

  @override
  String get settingsDeleteAll => 'ลบข้อมูลทั้งหมด';

  @override
  String get settingsDeleteAllBody =>
      'ธุรกรรม บัญชี หนี้ ข้อเสนอแนะ และงบประมาณทั้งหมดจะถูกล้าง การตั้งค่าจะไม่ถูกลบ การกระทำนี้ไม่สามารถย้อนกลับได้';

  @override
  String get settingsDeleteAllDone => 'ข้อมูลทั้งหมดถูกลบแล้ว';

  @override
  String get settingsReminder => 'การแจ้งเตือน';

  @override
  String get settingsReminderSubtitle => 'แจ้งเตือนบันทึกรายวัน';

  @override
  String get settingsReminderWhen => 'เมื่อไหร่';

  @override
  String get settingsReminderPermissionDenied =>
      'การอนุญาตแจ้งเตือนถูกปฏิเสธ การแจ้งเตือนจะไม่ปรากฏ';

  @override
  String get settingsTheme => 'สีธีม';

  @override
  String get settingsLanguage => 'ภาษา';

  @override
  String get settingsCancel => 'ยกเลิก';

  @override
  String get settingsDelete => 'ลบ';

  @override
  String settingsLoadFailed(String error) {
    return 'อ่านการตั้งค่าไม่สำเร็จ: $error';
  }

  @override
  String get themeBlue => 'ฟ้าสว่าง';

  @override
  String get themePink => 'โหมดชมพู';

  @override
  String get themePurple => 'โหมดม่วง';

  @override
  String get themeDark => 'โหมดมืด';
}
