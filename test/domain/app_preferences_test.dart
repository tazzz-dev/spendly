import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/app_preferences.dart';
import 'package:pencatatan_keuangan/domain/theme_choice.dart';

void main() {
  group('AppPreferences.fromMap', () {
    test('tanpa kunci sama sekali memakai nilai bawaan', () {
      final prefs = AppPreferences.fromMap(null);

      expect(prefs.theme, AppTheme.blue);
      expect(prefs.showDecimals, isTrue); // SPEC ST-3: aktif secara bawaan.
      expect(prefs.language, AppLanguage.indonesia);
      expect(prefs.reminderEnabled, isFalse); // SPEC ST-6.
      expect(prefs.reminderTime, '20:00');
    });

    test('nilai yang tersimpan ditafsirkan benar', () {
      final prefs = AppPreferences.fromMap(const {
        SettingKey.theme: 'dark',
        SettingKey.showDecimals: '0',
        SettingKey.language: 'th',
        SettingKey.reminderEnabled: '1',
        SettingKey.reminderTime: '14:30',
      });

      expect(prefs.theme, AppTheme.dark);
      expect(prefs.showDecimals, isFalse);
      expect(prefs.language, AppLanguage.thailand);
      expect(prefs.reminderEnabled, isTrue);
      expect(prefs.reminderTime, '14:30');
    });

    test('nilai rusak jatuh ke bawaan, tidak melempar', () {
      final prefs = AppPreferences.fromMap(const {
        SettingKey.theme: 'merah',
        SettingKey.showDecimals: 'bukan angka',
        SettingKey.language: 'klingon',
        SettingKey.reminderTime: '25;61',
      });

      expect(prefs.theme, AppTheme.blue);
      expect(prefs.showDecimals, isFalse); // apa pun selain '1' berarti mati.
      expect(prefs.language, AppLanguage.indonesia);
      expect(prefs.reminderTime, '20:00'); // format salah → bawaan.
    });
  });

  group('diff', () {
    test('hanya kunci yang berubah yang dikembalikan', () {
      final next = const AppPreferences().copyWith(
        theme: AppTheme.dark,
        reminderEnabled: true,
      );

      expect(next.diff(const AppPreferences()), const {
        SettingKey.theme: 'dark',
        SettingKey.reminderEnabled: '1',
      });
    });

    test('setelan yang sama menghasilkan peta kosong', () {
      final prefs = const AppPreferences().copyWith(showDecimals: false);

      expect(prefs.diff(prefs), isEmpty);
    });
  });

  group('ReminderClock', () {
    test('jam yang sah dibaca lengkap dengan dua digit', () {
      final clock = ReminderClock.tryParse('07:05');

      expect(clock, isNotNull);
      expect(clock!.hour, 7);
      expect(clock.minute, 5);
      expect(clock.text, '07:05');
    });

    test('jam di luar rentang atau berformat salah ditolak', () {
      for (final value in ['25:00', '12:60', '7:05', '07:5', 'x', '']) {
        expect(ReminderClock.tryParse(value), isNull, reason: value);
      }
    });

    test('nilai rusak jatuh ke bawaan pukul 20.00, bukan melempar', () {
      expect(ReminderClock.parseOrDefault('25:61'), ReminderClock.fallback);
      expect(ReminderClock.parseOrDefault('00:00'), const ReminderClock(0, 0));
      expect(ReminderClock.parseOrDefault('bukan jam').text, '20:00');
    });

    test('fromMap menolak jam di luar rentang 24 jam', () {
      final prefs = AppPreferences.fromMap(const {
        SettingKey.reminderTime: '25:61',
      });

      expect(prefs.reminderTime, '20:00');
    });
  });
}
