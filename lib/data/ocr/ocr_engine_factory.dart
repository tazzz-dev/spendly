// Memilih implementasi OCR saat kompilasi.
//
// Web dan desktop memakai stub supaya `flutter build web` tetap bisa
// dikompilasi tanpa pustaka native ML Kit. Android dan iOS memakai ML Kit.
export 'ocr_engine_stub.dart' if (dart.library.io) 'ocr_engine_mlkit.dart';
