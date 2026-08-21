// Remove o service worker PWA antigo. Ele mantinha bundles desatualizados e
// podia interceptar chamadas do login no Chrome. As notificacoes continuam no
// firebase-messaging-sw.js, que usa um escopo separado.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const cacheNames = await caches.keys();
    await Promise.all(
      cacheNames
          .filter((name) => name.startsWith('flutter-'))
          .map((name) => caches.delete(name)),
    );
    await self.registration.unregister();
    const clients = await self.clients.matchAll({ type: 'window' });
    await Promise.all(clients.map((client) => client.navigate(client.url)));
  })());
});
