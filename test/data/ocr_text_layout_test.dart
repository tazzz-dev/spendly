import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/ocr/ocr_text_layout.dart';

void main() {
  test('menggabungkan merchant, nominal, dan tanggal pada baris visual', () {
    final text = composeOcrText(const [
      OcrTextLine(text: 'Activity', left: 60, top: 80, right: 180, bottom: 110),
      OcrTextLine(
        text: 'This Month',
        left: 30,
        top: 330,
        right: 200,
        bottom: 360,
      ),
      OcrTextLine(
        text: 'Statement >',
        left: 600,
        top: 330,
        right: 830,
        bottom: 360,
      ),
      OcrTextLine(text: 'RIS', left: 55, top: 440, right: 115, bottom: 505),
      OcrTextLine(
        text: 'SPBU 34-13805',
        left: 170,
        top: 445,
        right: 470,
        bottom: 480,
      ),
      OcrTextLine(
        text: '-Rp56.860',
        left: 700,
        top: 445,
        right: 860,
        bottom: 480,
      ),
      OcrTextLine(
        text: '27 Oct 2026 • 19:10',
        left: 170,
        top: 505,
        right: 470,
        bottom: 540,
      ),
      OcrTextLine(text: 'RIS', left: 55, top: 650, right: 115, bottom: 715),
      OcrTextLine(
        text: 'Telor Gulung Sudirman',
        left: 170,
        top: 655,
        right: 640,
        bottom: 690,
      ),
      OcrTextLine(
        text: '-Rp10.000',
        left: 720,
        top: 655,
        right: 860,
        bottom: 690,
      ),
      OcrTextLine(
        text: '27 Oct 2026 • 17:45',
        left: 170,
        top: 715,
        right: 470,
        bottom: 750,
      ),
    ]);

    final lines = text.split('\n');
    expect(
      lines,
      contains('RIS SPBU 34-13805 -Rp56.860 27 Oct 2026 • 19:10'),
    );
    expect(
      lines,
      contains('RIS Telor Gulung Sudirman -Rp10.000 27 Oct 2026 • 17:45'),
    );
  });

  test('melewati baris logo di antara nominal dan tanggal', () {
    final text = composeOcrText(const [
      OcrTextLine(
        text: 'SPBU 34-13805',
        left: 170,
        top: 445,
        right: 470,
        bottom: 480,
      ),
      OcrTextLine(
        text: '-Rp56.860',
        left: 700,
        top: 445,
        right: 860,
        bottom: 480,
      ),
      OcrTextLine(text: 'RS', left: 55, top: 500, right: 110, bottom: 530),
      OcrTextLine(
        text: '27 Oct 2026 • 19:10',
        left: 170,
        top: 540,
        right: 470,
        bottom: 575,
      ),
    ]);

    expect(text.split('\n'), [
      'SPBU 34-13805 -Rp56.860 27 Oct 2026 • 19:10',
    ]);
  });

  test('daftar kosong tetap kosong', () {
    expect(composeOcrText(const []), '');
    expect(
      composeOcrText(const [
        OcrTextLine(text: '   ', left: 0, top: 0, right: 1, bottom: 1),
      ]),
      '',
    );
  });
}
