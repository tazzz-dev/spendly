import 'package:flutter/material.dart';

import 'settings_screen.dart';

/// Ikon gerigi di pojok kiri atas setiap tab utama.
///
/// Sejak tab Pengaturan diganti tab **Scan AI**, pengaturan tidak punya tab
/// sendiri. Ikon ini adalah satu-satunya jalan masuk, dan sengaja diletakkan di
/// kiri atas supaya sama di semua tab.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('open_settings'),
      tooltip: 'Pengaturan',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => openSettings(context),
    );
  }
}

Future<void> openSettings(BuildContext context) {
  return Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => const SettingsScreen()));
}
