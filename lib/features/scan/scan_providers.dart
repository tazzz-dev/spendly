import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ocr/ocr_engine.dart';
import '../../data/ocr/ocr_engine_factory.dart';
import '../../domain/mutation_text_parser.dart';

/// `true` bila platform ini punya mesin OCR lokal.
///
/// ML Kit hanya ada di Android dan iOS. Web tetap bisa dibuka (untuk
/// sinkronisasi), tetapi tab Scan AI menjelaskan bahwa pemindaian gambar
/// dilakukan di ponsel.
bool get isScanSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Mesin OCR dibuat saat pertama kali dibutuhkan, bukan saat aplikasi dibuka.
///
/// Inilah bagian dari optimasi cold start: memuat model ML Kit bisa memakan
/// ratusan milidetik dan puluhan MB, dan tidak ada gunanya bagi pengguna yang
/// hanya ingin mencatat transaksi manual.
final ocrEngineProvider = Provider<OcrEngine>((ref) {
  if (!isScanSupported) return const UnsupportedOcrEngine();
  final engine = createOcrEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Pengurai teks murni; tidak menyimpan state.
const MutationTextParser mutationParser = MutationTextParser();
