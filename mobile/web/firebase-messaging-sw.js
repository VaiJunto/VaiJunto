importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBC0JnvlPxcSmLZ4_Ynl4JokRvQJ_tcFC0',
  authDomain: 'vaijunto-8e5b9.firebaseapp.com',
  projectId: 'vaijunto-8e5b9',
  storageBucket: 'vaijunto-8e5b9.firebasestorage.app',
  messagingSenderId: '23025980605',
  appId: '1:23025980605:web:b407f1b82bcfe6dce253d4'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const data = message.data || {};
  return self.registration.showNotification(data.title || 'VaiJunto', {
    body: data.body || 'Voce recebeu uma nova notificacao.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
