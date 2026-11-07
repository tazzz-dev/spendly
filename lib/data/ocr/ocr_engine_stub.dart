import 'ocr_engine.dart';

/// Platform tanpa ML Kit (web, desktop). Fitur Scan AI menampilkan penjelasan
/// dan tidak pernah memuat model OCR.
OcrEngine createOcrEngine() => const UnsupportedOcrEngine();
