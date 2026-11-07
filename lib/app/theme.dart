import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../domain/theme_choice.dart';
import 'palette.dart';

/// Satu-satunya sumber kebenaran wujud tema aplikasi. SPEC G-6 dan ST-4.
///
/// Identitas tema ([AppTheme]) tinggal di `lib/domain/theme_choice.dart`,
/// sedangkan wujudnya — warna benih dan terang/gelap — tinggal di sini.
/// Sebelumnya keduanya bertumpuk: `lib/app/theme.dart` mengekspor ulang
/// berkas domain sekaligus memakai spec di dalamnya, sehingga [AppTheme],
/// spec, dan pembangun tema bisa dibaca dari dua tempat. Kini satu simbol
/// hanya punya satu definisi.
///
/// Nama tema yang dibaca pengguna ("Biru Terang" dan seterusnya) tidak lagi
/// di sini, melainkan di berkas ARB `lib/l10n/`, supaya ikut berubah saat
/// bahasa berganti. SPEC G-7.
class AppThemeSpec {
  const AppThemeSpec(this.seed, this.primary, this.brightness);

  /// Warna benih `ColorScheme.fromSeed`.
  final Color seed;

  /// Warna aksen yang dipakai apa adanya: bilah atas, tombol tambah, tab
  /// terpilih. Sengaja terpisah dari `seed` karena Material menurunkan `primary`
  /// menjadi nada 40 yang lebih kusam, sedangkan Sepran memakai warna penuh.
  final Color primary;

  /// Menerangkan skema warnanya terang atau gelap.
  final Brightness brightness;
}

const Map<AppTheme, AppThemeSpec> appThemeSpecs = {
  AppTheme.blue: AppThemeSpec(
    Color(0xFF2196F3),
    Color(0xFF2196F3),
    Brightness.light,
  ),
  AppTheme.pink: AppThemeSpec(
    Color(0xFFE91E63),
    Color(0xFFE91E63),
    Brightness.light,
  ),
  AppTheme.purple: AppThemeSpec(
    Color(0xFF7B1FA2),
    Color(0xFF7B1FA2),
    Brightness.light,
  ),
  AppTheme.dark: AppThemeSpec(
    Color(0xFF1565C0),
    Color(0xFF1E88E5),
    Brightness.dark,
  ),
};

/// Tema aplikasi: satu sumber warna untuk seluruh layar. SPEC G-6 dan ST-4.
///
/// Bentuknya mengikuti Sepran, yang dipastikan dari tangkapan layarnya:
///
/// - bilah atas **berwarna pekat** dengan teks putih dan judul di tengah,
///   bukan bilah tipis bertinta seperti bawaan Material 3;
/// - tombol tambah berwarna aksen yang sama;
/// - tab yang sedang dipilih berwarna aksen, sisanya abu-abu;
/// - teks utama `#666666`, teks kedua `#AAAAAA`, garis pemisah `#ECECEC`;
/// - pilihan berganda (Realtime/Bulanan/Custom) memakai aksen penuh.
///
/// Warna uang tidak ikut berubah saat tema diganti; itu urusan [AppPalette].
ThemeData buildAppTheme(AppTheme theme) {
  final spec = appThemeSpecs[theme]!;
  final isDark = spec.brightness == Brightness.dark;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: spec.seed,
        brightness: spec.brightness,
      ).copyWith(
        primary: spec.primary,
        onPrimary: const Color(0xFFFFFFFF),
        surface: isDark ? AppPalette.surfaceDark : AppPalette.surfaceLight,
        onSurface: isDark
            ? AppPalette.textPrimaryDark
            : AppPalette.textPrimaryLight,
        onSurfaceVariant: isDark
            ? AppPalette.textSecondaryDark
            : AppPalette.textSecondaryLight,
        outlineVariant: isDark
            ? AppPalette.hairlineDark
            : AppPalette.hairlineLight,
        surfaceTint: const Color(0x00000000),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: const Color(0xFFFFFFFF),
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      actionsIconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      titleTextStyle: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: const Color(0xFFFFFFFF),
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 2,
      highlightElevation: 4,
      shape: const CircleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: const Color(0x00000000),
      indicatorColor: scheme.primary.withValues(alpha: 0.12),
      elevation: 3,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
    ),
    cardTheme: CardThemeData(
      // Di mode terang kartu putih dibedakan oleh bayangan; di mode gelap
      // bayangan tidak terlihat, jadi kartunya dinaikkan satu nada.
      color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
      surfaceTintColor: const Color(0x00000000),
      shadowColor: const Color(0x33000000),
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    // SPEC L-14 dan layar Rekap: pilihan Realtime/Bulanan/Custom memakai aksen
    // penuh untuk yang terpilih, seperti Sepran.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.primary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surface,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.primary)),
      ),
    ),
  );
}

/// Tema yang sedang aktif, dibaca dari setelan tersimpan. SPEC ST-4.
///
/// Sebelum setelan selesai dimuat, memakai bawaan Biru Terang; begitu
/// `app_settings` termuat, seluruh aplikasi ikut berubah.
///
/// Memakai `Notifier`, bukan `StateProvider`: Riverpod 3 menghapus
/// `StateProvider`.
class ThemeController extends Notifier<AppTheme> {
  @override
  AppTheme build() {
    final theme = ref.watch(
      settingsProvider.select((settings) => settings.value?.theme),
    );
    return theme ?? AppTheme.blue;
  }

  /// Memilih tema dan menyimpannya ke setelan. SPEC ST-4.
  void select(AppTheme theme) {
    state = theme; // seketika, tanpa menunggu penulisan basis data.
    ref.read(settingsProvider.notifier).setTheme(theme);
  }
}

final themeProvider = NotifierProvider<ThemeController, AppTheme>(
  ThemeController.new,
);
