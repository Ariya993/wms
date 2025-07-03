// Import Firebase App & Messaging
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');

// Inisialisasi Firebase App
firebase.initializeApp({
  apiKey: "AIzaSyAVJvBN-W6v8_G0LLuF1JYfPbjyEmnDvXI",
  authDomain: "wms-apps-92931.firebaseapp.com",
  projectId: "wms-apps-92931",
  storageBucket: "wms-apps-92931.firebasestorage.app",
  messagingSenderId: "192738229033",
  appId: "1:192738229033:web:929faed584bfbaa1be9538"
});

const messaging = firebase.messaging();

// Tangani push message dari FCM
self.addEventListener('push', function(event) {
  let data = {};
  if (event.data) {
    try {
      const raw = event.data.json();
      console.log("📦 Raw push data:", raw);
      data = raw.data || raw; // Support wrapping dari FCM
    } catch (e) {
      console.error('❌ Gagal parse push data:', e);
    }
  }

  const title = data.title || 'WMS Apps';
  const options = {
    body: data.body || 'Ada notifikasi baru',
    icon: 'assets/logo.png',
    badge: 'assets/logo.png',
    data: {
      url: data.target || '/' // Simpan target URL untuk dibuka saat diklik
    }
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Tangani klik pada notifikasi
self.addEventListener('notificationclick', function(event) {
  const rawPath = event.notification.data?.url || '/';
  event.notification.close();

  const targetUrl = new URL(rawPath, self.location.origin).href;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (const client of clientList) {
        if (client.url === targetUrl && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(targetUrl);
    })
  );
});

