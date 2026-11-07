<#
.SYNOPSIS
    Menebak framework/stack sebuah file APK. Tanpa JDK, tanpa REA.

.DESCRIPTION
    Membuka APK sebagai arsip ZIP, mencocokkan penanda khas setiap framework
    (Flutter, React Native/Hermes, Unity, Xamarin/.NET MAUI, Cordova, native
    Java/Kotlin), lalu melaporkan implikasinya bagi upaya reverse engineering.

    Skrip ini hanya membaca isi arsip. Ia tidak menjalankan kode aplikasi dan
    tidak mengubah file APK.

.PARAMETER Apk
    Path ke file APK yang mau diperiksa.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\inspect-apk.ps1 -Apk _apk\sepran.apk

.EXAMPLE
    .\tools\inspect-apk.ps1 _apk\sepran.apk
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Apk
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path -LiteralPath $Apk -PathType Leaf)) {
    Write-Error "File APK tidak ditemukan: $Apk"
    exit 1
}

$resolved = (Resolve-Path -LiteralPath $Apk).Path
$fileSize = [Math]::Round((Get-Item -LiteralPath $resolved).Length / 1MB, 2)

# ---------------------------------------------------------------------------
# 1. Baca daftar isi arsip
# ---------------------------------------------------------------------------
$names = New-Object System.Collections.Generic.List[string]
$bundleHeader = $null

$zip = [System.IO.Compression.ZipFile]::OpenRead($resolved)
try {
    foreach ($entry in $zip.Entries) { $names.Add(($entry.FullName -replace '\\', '/')) }

    $bundle = $zip.Entries |
        Where-Object { ($_.FullName -replace '\\', '/') -eq 'assets/index.android.bundle' } |
        Select-Object -First 1

    if ($bundle) {
        $stream = $bundle.Open()
        try {
            $buffer = New-Object byte[] 16
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -gt 0) {
                $bytes = @()
                for ($i = 0; $i -lt $read; $i++) { $bytes += $buffer[$i].ToString('x2') }
                $bundleHeader = ($bytes -join ' ')
            }
        }
        finally { $stream.Dispose() }
    }
}
finally { $zip.Dispose() }

function Test-Marker {
    param([string]$Pattern)
    foreach ($n in $names) { if ($n -match $Pattern) { return $true } }
    return $false
}

function Get-Marker {
    param([string]$Pattern)
    return @($names | Where-Object { $_ -match $Pattern })
}

# ---------------------------------------------------------------------------
# 2. Cari penanda framework
# ---------------------------------------------------------------------------
$m = [ordered]@{
    'classes.dex (kode Java/Kotlin)' = @(Get-Marker '^classes\d*\.dex$')
    'libflutter.so (runtime Flutter)' = @(Get-Marker '^lib/[^/]+/libflutter\.so$')
    'libapp.so (snapshot Dart AOT)' = @(Get-Marker '^lib/[^/]+/libapp\.so$')
    'libhermes.so (React Native)' = @(Get-Marker '^lib/[^/]+/libhermes(_executor)?\.so$')
    'libreactnativejni.so' = @(Get-Marker '^lib/[^/]+/libreactnativejni\.so$')
    'libjsc.so (React Native/JSC)' = @(Get-Marker '^lib/[^/]+/libjsc\.so$')
    'libunity.so / libil2cpp.so' = @(Get-Marker '^lib/[^/]+/lib(unity|il2cpp)\.so$')
    'libmonodroid.so (.NET MAUI/Xamarin)' = @(Get-Marker '^lib/[^/]+/libmonodroid\.so$')
    'assemblies/ (.NET kelas terkelola)' = @(Get-Marker '^assemblies/')
    'libgojni.so (Gomobile)' = @(Get-Marker '^lib/[^/]+/libgojni\.so$')
    'assets/www/ (Cordova/Ionic)' = @(Get-Marker '^assets/www/')
    'assets/public/ (Capacitor)' = @(Get-Marker '^assets/public/')
    'AndroidManifest.xml' = @(Get-Marker '^AndroidManifest\.xml$')
    'assets/index.android.bundle' = @(Get-Marker '^assets/index\.android\.bundle$')
}

$flutter   = $m['libflutter.so (runtime Flutter)'].Count -gt 0
$dartAot   = $m['libapp.so (snapshot Dart AOT)'].Count -gt 0
$hermes    = $m['libhermes.so (React Native)'].Count -gt 0
$rnJni     = $m['libreactnativejni.so'].Count -gt 0
$jsc       = $m['libjsc.so (React Native/JSC)'].Count -gt 0
$bundle    = $m['assets/index.android.bundle'].Count -gt 0
$unity     = $m['libunity.so / libil2cpp.so'].Count -gt 0
$xamarin   = $m['libmonodroid.so (.NET MAUI/Xamarin)'].Count -gt 0 -or
             $m['assemblies/ (.NET kelas terkelola)'].Count -gt 0
$golang    = $m['libgojni.so (Gomobile)'].Count -gt 0
$cordova   = $m['assets/www/ (Cordova/Ionic)'].Count -gt 0
$capacitor = $m['assets/public/ (Capacitor)'].Count -gt 0
$dex       = $m['classes.dex (kode Java/Kotlin)'].Count -gt 0
$isApk     = $m['AndroidManifest.xml'].Count -gt 0

# ---------------------------------------------------------------------------
# 3. Tentukan kesimpulan
# ---------------------------------------------------------------------------
$verdict  = 'Tidak dapat ditentukan'
$reason   = @()

if ($flutter) {
    $verdict = 'Flutter'
    $reason += 'Ditemukan libflutter.so - mesin render Flutter tertanam di APK.'
    if ($dartAot) { $reason += 'libapp.so ada: kode Dart sudah dikompilasi AOT, bukan teks.' }
    else { $reason += 'libapp.so tidak ditemukan: mungkin build debug/mode add-to-app.' }
}
elseif ($hermes -or $rnJni -or $jsc -or $bundle) {
    $verdict = 'React Native'
    if ($hermes) { $reason += 'Ditemukan libhermes.so - JavaScript dikompilasi ke bytecode Hermes.' }
    if ($jsc)    { $reason += 'Ditemukan libjsc.so - JavaScriptCore.' }
    if ($rnJni)  { $reason += 'Ditemukan libreactnativejni.so - jembatan JNI React Native.' }
    if ($bundle) { $reason += "Berkas assets/index.android.bundle ada (byte awal: $bundleHeader)." }
}
elseif ($unity)     { $verdict = 'Unity'; $reason += 'Ditemukan libunity.so/libil2cpp.so.' }
elseif ($xamarin)   { $verdict = 'Xamarin / .NET MAUI'; $reason += 'Ditemukan runtime Mono atau folder assemblies/.' }
elseif ($cordova)   { $verdict = 'Cordova / Ionic (WebView)'; $reason += 'Ditemukan assets/www/.' }
elseif ($capacitor) { $verdict = 'Capacitor (WebView)'; $reason += 'Ditemukan assets/public/.' }
elseif ($dex)       { $verdict = 'Native Android (Java/Kotlin)'; $reason += 'Hanya ditemukan kode DEX tanpa penanda framework lintas platform.' }
else                { $reason += 'Tidak ada penanda yang cocok. Pastikan file ini benar-benar APK.' }

if ($golang) { $reason += 'Catatan: libgojni.so menandakan ada kode Go (gomobile).' }

# ---------------------------------------------------------------------------
# 4. Implikasi untuk rencana reverse engineering
# ---------------------------------------------------------------------------
$impacts = @{
    'Flutter' = @'
Logika bisnis TIDAK dapat dibaca.
Kode Dart sudah menjadi bahasa mesin di dalam libapp.so.
- REA (analisis APK) hanya memberi hash snapshot dan daftar library. Tidak berguna untuk aturan bisnis.
- Alat pembedah Dart AOT (mis. blutter) masih eksperimental dan rumit; hasilnya bukan kode sumber asli.
- Jalur yang disarankan: verifikasi docs\SPEC.md Bagian 12 dengan mengamati aplikasi secara langsung,
  lalu bandingkan angkanya di aplikasi kamu sendiri.
'@
    'React Native' = @'
Sebagian dapat dibaca, dengan usaha ekstra.
- Screenshot/UI mudah ditebak; bagian Java/Kotlin-nya bisa dibaca dengan REA + JADX.
- Logika JavaScript ada sebagai bytecode Hermes, bukan teks. Perlu tooling khusus dan tetap sulit.
- Jalur yang disarankan: pakai REA untuk lapisan Java/Kotlin dan struktur data, andalkan pengamatan
  untuk logika yang ada di sisi JavaScript.
'@
    'Native Android (Java/Kotlin)' = @'
PALING MENGUNTUNGKAN. REA sangat berguna di sini.
- REA + JADX dapat menampilkan nama kelas, method, dan isi method hasil decompile.
- Logika saldo, aturan transfer, dan perhitungan laporan biasanya dapat dipahami dari kode.
- Prasyarat: JDK 17+ (full JDK) dan JAR jadx-headless-mcp, lalu daftarkan REA ke OpenCode.
'@
    'Xamarin / .NET MAUI' = @'
Cukup terbaca. REA punya jalur analisis rakitan .NET.
- REA dapat membaca metadata dan instruksi CIL dari assemblies/.
- Kombinasikan dengan docs\SPEC.md untuk memverifikasi aturan bisnis.
'@
    'Cordova / Ionic (WebView)' = @'
Sangat mudah.
- Isi assets/www/ biasanya JavaScript yang masih terbaca sebagai teks.
- Tidak perlu REA; cukup ekstrak dan baca.
'@
    'Capacitor (WebView)' = @'
Sangat mudah.
- Isi assets/public/ biasanya JavaScript yang masih terbaca sebagai teks.
- Tidak perlu REA; cukup ekstrak dan baca.
'@
    'Unity' = @'
Tidak relevan untuk aplikasi pencatatan keuangan.
- Kemungkinan besar Anda salah mengenali aplikasi, atau aplikasi ini memakai Unity untuk hal lain.
'@
    'default' = @'
Periksa kembali file APK-nya, atau cek stack-nya lewat Play Store (sering tertera di deskripsi)
atau melalui nama paket.
'@
}

if ($impacts.ContainsKey($verdict)) { $impact = $impacts[$verdict] }
else { $impact = $impacts['default'] }

# ---------------------------------------------------------------------------
# 5. Cetak laporan
# ---------------------------------------------------------------------------
$abis = @(Get-Marker '^lib/[^/]+/') |
    ForEach-Object { ($_ -split '/')[1] } |
    Sort-Object -Unique

Write-Host ''
Write-Host '=== Laporan Inspeksi APK ===' -ForegroundColor Cyan
Write-Host ("File   : {0}" -f $resolved)
Write-Host ("Ukuran : {0} MB" -f $fileSize)
Write-Host ("Entri  : {0}" -f $names.Count)
Write-Host ("APK    : {0}" -f $(if ($isApk) { 'ya (AndroidManifest.xml ada)' } else { 'TIDAK - ini bukan APK Android' }))
Write-Host ("ABI    : {0}" -f $(if ($abis.Count) { $abis -join ', ' } else { 'tidak ada library native' }))

Write-Host ''
Write-Host '--- Penanda yang ditemukan ---' -ForegroundColor Cyan
foreach ($key in $m.Keys) {
    $count = @($m[$key]).Count
    if ($count -gt 0) {
        Write-Host ("  [x] {0} - {1} berkas" -f $key, $count) -ForegroundColor Green
    }
    else {
        Write-Host ("  [ ] {0}" -f $key) -ForegroundColor DarkGray
    }
}

Write-Host ''
Write-Host '--- Kesimpulan ---' -ForegroundColor Cyan
Write-Host ("Stack : {0}" -f $verdict) -ForegroundColor Yellow
foreach ($line in $reason) { Write-Host ("        {0}" -f $line) }

Write-Host ''
Write-Host '--- Dampak untuk rencana RE ---' -ForegroundColor Cyan
Write-Host $impact

Write-Host ''
