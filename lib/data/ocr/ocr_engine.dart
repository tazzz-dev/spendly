import 'dart:typed_data';

/// Pembaca teks dari gambar.
///
/// Antarmuka sengaja sempit supaya mesin OCR bisa diganti (ML Kit lokal hari
/// ini, layanan vision lain nanti) tanpa menyentuh layar. Mesin hanya
/// dipanggil ketika pengguna benar-benar memindai, bukan saat aplikasi dibuka:
/// memuat model OCR di awal menambah berat cold start.
abstract class OcrEngine {
  /// Membaca seluruh teks pada berkas gambar di [path].
  Future<String> recognizeFile(String path);

  /// Varian untuk platform yang memberi byte langsung (mis. web).
  Future<String> recognizeBytes(Uint8List bytes);

  Future<void> dispose();
}

/// Mesin yang tidak tersedia di platform ini.
class UnsupportedOcrEngine implements OcrEngine {
  const UnsupportedOcrEngine();

  Never _unavailable() =>
      throw UnsupportedError('Scan AI hanya tersedia di Android dan iOS.');

  @override
  Future<String> recognizeFile(String path) async => _unavailable();

  @override
  Future<String> recognizeBytes(Uint8List bytes) async => _unavailable();

  @override
  Future<void> dispose() async {}
}
