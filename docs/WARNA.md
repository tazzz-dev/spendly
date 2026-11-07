# Bahasa Warna

Catatan ini menjelaskan warna aplikasi: dari mana angkanya, di mana dipakai, dan
ke berkas mana harus melihat kalau ingin mengubahnya.

Seluruh warna ada di **`lib/app/palette.dart`**. Tidak ada lagi nilai heksadesimal
warna di layar mana pun; layar memanggil nama peran (`AppPalette.positive`,
`TxColors.moneyOut`, dan seterusnya).

## Yang diukur dari Sepran

Angka di bawah bukan perkiraan. Tangkapan layar Sepran v5.2.2 diambil dari
perangkat, lalu warna dominan tiap bidang dihitung piksel demi piksel.

| Peran | Nilai | Terlihat di |
|---|---|---|
| Bilah atas / aksen | `#2196F3` | bilah atas penuh, tombol tambah, tab terpilih, pilihan berganda |
| Nominal positif (Pemasukan, Menerima) | `#4BA894` | kepala halaman Hutang, kartu ringkasan harian |
| Teks utama | `#666666` | judul baris daftar |
| Teks kedua | `#AAAAAA` | keterangan rekening di bawah judul |
| Latar | putih | seluruh halaman |
| Garis pemisah | `#ECECEC` | antarbaris daftar |

Dua hal yang mudah salah dibaca, dan sudah diikuti apa adanya:

1. **Nominal negatif tidak dimerahi.** Di daftar Sepran, pengeluaran dan "Memberi"
   berwarna teks biasa; tanda minusnya yang berbicara. Merah hanya muncul pada
   tombol arah dan ikon jenis.
2. **Pemasukan punya dua warna.** Ikon jenisnya oranye (`#FB8C00`), tetapi
   angkanya hijau (`#4BA894`). Ini bukan kelalaian: Sepran memang begitu, dan
   SPEC T-12 (hijau) serta T-16 (oranye) sama-sama benar karena keduanya
   membicarakan hal yang berbeda.

## Peran warna

| Nama di kode | Warna | Dipakai untuk |
|---|---|---|
| `AppPalette.moneyIn` | `#FB8C00` oranye | ikon dan lingkaran Pemasukan / Menerima (SPEC T-16, H-2) |
| `AppPalette.moneyOut` | `#E53935` merah | ikon dan lingkaran Pengeluaran / Memberi (SPEC T-16, H-2) |
| `AppPalette.neutral` | `#757575` abu | pindah saldo dan koreksi saldo (SPEC T-16) |
| `AppPalette.positive` | `#4BA894` hijau | nominal positif: Pemasukan, Menerima, sisa saldo (SPEC T-12, H-1, H-3) |
| `AppPalette.remaining` | `#EC407A` merah muda | sel ketiga ringkasan detail hutang (SPEC H-14) |
| `AppPalette.chart` | 10 warna | bagian grafik rincian (SPEC L-2, L-11) |

## Tema

Empat tema tetap seperti Sepran (SPEC G-6, ST-4): **Biru Terang**, **Mode Pink**,
**Mode Ungu**, **Mode Gelap**. Tema hanya mengubah warna aksen — bilah atas,
tombol tambah, tab terpilih, pilihan berganda. Warna uang tidak ikut berubah,
supaya arti oranye/merah/hijau tetap sama di tema mana pun.

| Tema | Aksen | Latar |
|---|---|---|
| Biru Terang | `#2196F3` | putih |
| Mode Pink | `#E91E63` | putih |
| Mode Ungu | `#7B1FA2` | putih |
| Mode Gelap | `#1E88E5` | `#121212` |

Di mode gelap, kartu dinaikkan satu nada di atas latar supaya batasnya tetap
terbaca — bayangan tidak terlihat di latar gelap.

Menambah warna baru berarti menambah satu baris di `AppPalette`, bukan menulis
`Color(0x…)` di layar. Itulah satu-satunya aturan yang perlu diingat.
