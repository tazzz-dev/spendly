import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/app_preferences.dart';
import '../../l10n/app_localizations.dart';

/// Menyediakan [AppLocalizations] untuk subtree Pengaturan. SPEC G-7, ST-5.
///
/// `lib/app/app.dart` tidak boleh diubah, padahal `MaterialApp` — tempat
/// `localizationsDelegates` seharusnya dipasang — ada di sana. Karena itu
/// delegasi bahasa tidak bisa dipasang sekali di akar aplikasi. Sebagai
/// gantinya subtree Pengaturan membungkus dirinya dengan `Localizations`
/// sendiri, memakai kunci bahasa dari setelan yang sedang aktif. Delegasi
/// Material, Cupertino, dan Widgets ikut dipasang (dari
/// [AppLocalizations.localizationsDelegates]) supaya widget bawaan di dalam
/// subtree ini tetap menemukan lokalisasinya.
///
/// Dialog dibangun di atas `Navigator` akar, di luar subtree ini, jadi teksnya
/// diambil lebih dulu dari `AppLocalizations` pemanggil sebelum dialog dibuka.
class SettingsLocalizations extends ConsumerWidget {
  const SettingsLocalizations({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language =
        ref.watch(
          settingsProvider.select((settings) => settings.value?.language),
        ) ??
        AppLanguage.indonesia;

    return Localizations(
      locale: Locale(language.storageValue),
      delegates: AppLocalizations.localizationsDelegates,
      child: child,
    );
  }
}
