import 'theme_choice.dart';

/// Kunci penyimpanan pada tabel `app_settings`. SPEC §5.12.
///
/// Tabelnya kunci-nilai teks biasa (DATA-MODEL), jadi nilai boolean ditulis
/// sebagai `1`/`0` dan tema serta bahasa sebagai kode teksnya.
class SettingKey {
  const SettingKey._();

  static const theme = 'theme';

  /// SPEC ST-3: sakelar "Tampilkan Angka Desimal".
  static const showDecimals = 'show_decimals';

  /// SPEC ST-5: bahasa Indonesia, Inggris, atau Thailand.
  static const language = 'language';

  /// SPEC ST-6: pengingat pencatatan harian, aktif atau tidak.
  static const reminderEnabled = 'reminder_enabled';

  /// SPEC ST-6: "Kapan", jam pengingat. Format `HH:MM`.
  static const reminderTime = 'reminder_time';
}

/// Jam pengingat ("Kapan") sebagai jam dan menit. SPEC ST-6.
///
/// Dipisah dari [AppPreferences] supaya penjadwalan notifikasi dan penyimpanan
/// setelan memakai aturan pembacaan yang sama, dan bisa diuji tanpa Flutter.
class ReminderClock {
  const ReminderClock(this.hour, this.minute);

  final int hour;
  final int minute;

  /// Jam bawaan bila setelan belum ada atau rusak: pukul 20.00.
  static const ReminderClock fallback = ReminderClock(20, 0);

  static final RegExp _pattern = RegExp(r'^(\d{2}):(\d{2})$');

  /// Membaca `HH:MM`. Mengembalikan null bila format maupun nilainya tidak sah.
  static ReminderClock? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;

    return ReminderClock(hour, minute);
  }

  /// Seperti [tryParse], tetapi jatuh ke [fallback] alih-alih null.
  static ReminderClock parseOrDefault(String value) =>
      tryParse(value) ?? fallback;

  /// Bentuk dua digit `HH:MM`, sama seperti yang disimpan.
  String get text =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ReminderClock && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Bahasa pilihan. SPEC ST-5 dan G-7.
enum AppLanguage {
  indonesia('id', 'Indonesia'),
  english('en', 'English'),
  thailand('th', 'ไทย');

  const AppLanguage(this.storageValue, this.label);

  /// Sebagaimana tersimpan di tabel `app_settings`.
  final String storageValue;

  /// Nama yang tampil di menu Bahasa. Ditulis dalam bahasanya sendiri,
  /// kecuali Indonesia yang menjadi bawaan.
  final String label;

  static AppLanguage fromStorage(String value) => AppLanguage.values.firstWhere(
    (language) => language.storageValue == value,
    orElse: () => AppLanguage.indonesia,
  );
}

/// Seluruh setelan aplikasi, dalam bentuk bertipe.
///
/// Kelas ini yang menafsirkan kunci-nilai mentah `app_settings` menjadi nilai
/// nyata, lengkap dengan nilai bawaannya: desimal menyala (ST-3), tema Biru
/// Terang (ST-4), bahasa Indonesia (ST-5), dan pengingat mati (ST-6).
class AppPreferences {
  const AppPreferences({
    this.theme = AppTheme.blue,
    this.showDecimals = true,
    this.language = AppLanguage.indonesia,
    this.reminderEnabled = false,
    this.reminderTime = '20:00',
  });

  final AppTheme theme;

  /// SPEC ST-3: aktif secara bawaan; hanya memengaruhi tampilan, bukan cara
  /// penyimpanan. Lihat SPEC R-9.
  final bool showDecimals;

  final AppLanguage language;
  final bool reminderEnabled;

  /// Jam pengingat "Kapan". Bawaan pukul 20.00.
  final String reminderTime;

  /// Menafsirkan isi tabel `app_settings`. Kunci yang belum pernah ditulis
  /// memakai nilai bawaan.
  factory AppPreferences.fromMap(Map<String, String>? map) {
    map ??= const {};

    final themeText = map[SettingKey.theme];
    final decimalsText = map[SettingKey.showDecimals];
    final languageText = map[SettingKey.language];
    final reminderText = map[SettingKey.reminderEnabled];
    final timeText = map[SettingKey.reminderTime];

    return AppPreferences(
      theme: themeText == null
          ? AppTheme.blue
          : AppTheme.fromStorage(themeText),
      showDecimals: decimalsText == null ? true : decimalsText == '1',
      language: languageText == null
          ? AppLanguage.indonesia
          : AppLanguage.fromStorage(languageText),
      reminderEnabled: reminderText == '1',
      reminderTime: ReminderClock.parseOrDefault(timeText ?? '').text,
    );
  }

  /// Bagian yang berbeda daripada [other], siap ditulis ke basis data.
  ///
  /// Hanya kunci yang berubah yang dikembalikan, supaya penulisan tetap
  /// kecil meski setelannya bertambah kelak.
  Map<String, String> diff(AppPreferences other) {
    final values = <String, String>{};

    if (theme != other.theme) {
      values[SettingKey.theme] = theme.storageValue;
    }
    if (showDecimals != other.showDecimals) {
      values[SettingKey.showDecimals] = showDecimals ? '1' : '0';
    }
    if (language != other.language) {
      values[SettingKey.language] = language.storageValue;
    }
    if (reminderEnabled != other.reminderEnabled) {
      values[SettingKey.reminderEnabled] = reminderEnabled ? '1' : '0';
    }
    if (reminderTime != other.reminderTime) {
      values[SettingKey.reminderTime] = reminderTime;
    }

    return values;
  }

  AppPreferences copyWith({
    AppTheme? theme,
    bool? showDecimals,
    AppLanguage? language,
    bool? reminderEnabled,
    String? reminderTime,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      showDecimals: showDecimals ?? this.showDecimals,
      language: language ?? this.language,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.theme == theme &&
      other.showDecimals == showDecimals &&
      other.language == language &&
      other.reminderEnabled == reminderEnabled &&
      other.reminderTime == reminderTime;

  @override
  int get hashCode =>
      Object.hash(theme, showDecimals, language, reminderEnabled, reminderTime);
}
