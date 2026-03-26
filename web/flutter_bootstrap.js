{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    document.getElementById('loading').style.display = 'none';
    const appRunner = await engineInitializer.initializeEngine({
      renderer: 'html',
    });
    await appRunner.runApp();
  }
});
