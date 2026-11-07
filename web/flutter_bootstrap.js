{{flutter_js}}
{{flutter_build_config}}

// Bootstrap kustom: kerangka "Spendly" di index.html dilepas setelah frame
// pertama tampil, sehingga pengguna tidak melihat layar biru kosong.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('spendly-loading')?.remove();
  },
});
