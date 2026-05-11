{{flutter_js}}
{{flutter_build_config}}

(function () {
  var bar = document.getElementById('loading-bar');
  var status = document.getElementById('loading-status');

  function setProgress(pct, label) {
    if (bar) {
      bar.style.animation = 'none';
      bar.style.width = pct + '%';
    }
    if (status) status.textContent = label;
  }

  function hideLoading() {
    var el = document.getElementById('loading');
    if (el) el.style.display = 'none';
  }

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      setProgress(45, 'Initializing engine...');
      const appRunner = await engineInitializer.initializeEngine();
      setProgress(85, 'Starting app...');
      await appRunner.runApp();
      hideLoading();
    }
  });
})();
