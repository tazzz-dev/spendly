import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_engine.dart';
import 'ocr_text_layout.dart';

/// Membuat mesin OCR lokal berbasis Google ML Kit.
///
/// Dipanggil dari [ocr_engine_factory.dart] hanya pada platform yang punya
/// implementasi native. Model dibaca dari perangkat, tidak ada gambar yang
/// dikirim ke server.
OcrEngine createOcrEngine() => MlKitOcrEngine();

class MlKitOcrEngine implements OcrEngine {
  TextRecognizer? _recognizer;

  TextRecognizer get _engine =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final result = await _engine.processImage(input);
    final lines = <OcrTextLine>[
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrTextLine(
            text: line.text,
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            right: line.boundingBox.right,
            bottom: line.boundingBox.bottom,
          ),
    ];
    final composed = composeOcrText(lines);
    return composed.isEmpty ? result.text : composed;
  }

  @override
  Future<String> recognizeBytes(Uint8List bytes) async {
    // Jalur berkas selalu tersedia di Android/iOS lewat image_picker. Jalur
    // byte sengaja tidak dipakai supaya tidak perlu menebak metadata gambar.
    throw UnsupportedError('Gunakan recognizeFile pada Android/iOS.');
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
