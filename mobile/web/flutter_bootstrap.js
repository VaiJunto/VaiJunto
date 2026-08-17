{{flutter_js}}
{{flutter_build_config}}

// O painel administrativo precisa refletir a publicacao atual imediatamente.
// Nele, remove o service worker legado que podia manter um bundle antigo. As
// demais rotas preservam o comportamento PWA padrao do Flutter.
(async () => {
  const isAdminRoute =
      window.location.pathname === '/admin' ||
      window.location.pathname.startsWith('/admin/');

  if (isAdminRoute && 'serviceWorker' in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(
          registrations.map((registration) => registration.unregister()));

      if (registrations.length > 0 &&
          !sessionStorage.getItem('vj-sw-removed')) {
        sessionStorage.setItem('vj-sw-removed', '1');
        window.location.reload();
        return;
      }
    } catch (error) {
      console.warn('Nao foi possivel limpar o cache legado do admin.', error);
    }

    _flutter.loader.load();
    return;
  }

  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    },
  });
})();
