import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../features/debts/debt_list_screen.dart';
import '../features/notifications/notification_inbox_button.dart';
import '../features/reports/report_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/settings/settings_button.dart';
import '../features/transactions/transaction_list_screen.dart';
import '../features/wallets/wallet_list_screen.dart';
import 'theme.dart';

/// Kerangka aplikasi: lima tab.
///
/// Tab **Pengaturan** sudah diganti tab **Scan AI**. Pengaturan tetap ada,
/// tetapi dibuka lewat ikon gerigi di kiri atas setiap tab — jadi ruang bilah
/// bawah dipakai untuk fitur yang lebih sering dibuka.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  static const List<String> tabTitles = [
    'Transaksi',
    'Rekening',
    'Rekap',
    'Hutang',
    'Scan AI',
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _index = 0; // Mulai dari Transaksi, tab pertama Sepran.

  /// Tab yang pernah dibuka. Hanya tab ini yang dibangun, sehingga aplikasi
  /// tidak menjalankan empat query basis data sekaligus saat cold start.
  final Set<int> _visited = {0};

  static const List<Widget> _pages = [
    TransactionListScreen(),
    WalletListScreen(),
    ReportScreen(),
    DebtListScreen(),
    ScanScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sedot antrean notifikasi yang mungkin tertinggal saat mesin latar tidak
    // sempat berjalan. Ini juga menjadi jaring pengaman bagi pengguna yang
    // baru memberikan izin akses notifikasi.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncNotifications());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotifications();
    }
  }

  Future<void> _syncNotifications() async {
    await ref.read(notificationInboxSyncProvider).sync();
    if (!mounted) return;
    // Mesin latar bisa saja sudah menulis draft sebelum aplikasi dilanjutkan.
    // Paksa badge membaca ulang; daftar draft mengikuti angka tersebut.
    ref.invalidate(pendingNotificationCountProvider);
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transaksi, Rekap, dan Scan AI membawa bilah judulnya sendiri (ikon
    // ekspor/riwayat, ikon konfigurasi rekap, tombol pengaturan). Kerangka
    // tidak menggambar bilah kedua di atasnya.
    final ownsAppBar = _index == 0 || _index == 2 || _index == 4;

    return Scaffold(
      appBar: ownsAppBar
          ? null
          : AppBar(
              leading: const SettingsButton(),
              title: Text(AppShell.tabTitles[_index]),
              actions: const [NotificationInboxButton()],
            ),
      body: IndexedStack(
        index: _index,
        children: [
          for (var index = 0; index < _pages.length; index++)
            if (_visited.contains(index))
              _pages[index]
            else
              // Placeholder konstanta: tidak membangun layar, tidak membuka
              // stream, dan tidak memakan memori sampai tab disentuh.
              const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Rekening',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Rekap',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Hutang',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan AI',
          ),
        ],
      ),
    );
  }
}

class SpendlyApp extends ConsumerWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(ref.watch(themeProvider)),
      home: const AppShell(),
    );
  }
}
