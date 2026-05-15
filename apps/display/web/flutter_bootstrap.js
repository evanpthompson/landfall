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

  // fontFallbackBaseUrl: redirect FontFallbackManager fetches to a same-origin
  // path so any unresolved codepoint produces a same-origin 404 instead of a
  // request to fonts.gstatic.com that the strict CSP blocks. Common codepoints
  // are covered by the Noto fonts declared in pubspec flutter.fonts (pass 1).
  var _engineConfig = { fontFallbackBaseUrl: 'assets/fonts/' };

  _flutter.loader.load({
    config: _engineConfig,
    onEntrypointLoaded: async function (engineInitializer) {
      setProgress(45, 'Initializing engine...');
      const appRunner = await engineInitializer.initializeEngine(_engineConfig);
      setProgress(85, 'Starting app...');
      await appRunner.runApp();
      hideLoading();
    }
  });
})();
