// Configuración del Service Worker para Firebase Cloud Messaging

// Importar los scripts de Firebase
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-messaging-compat.js');

// Configuración de Firebase
const firebaseConfig = {
  apiKey: "AIzaSyBdooWtPdtgytKqGw0FneBMhoNPyFLoS2U",
  authDomain: "running-app-uni.firebaseapp.com",
  projectId: "running-app-uni",
  storageBucket: "running-app-uni.firebasestorage.app",
  messagingSenderId: "28475506464",
  appId: "1:28475506464:web:782c4974a284d18f2c6145",
  measurementId: "G-7GKEG48RPX"
};

// Inicializar Firebase
firebase.initializeApp(firebaseConfig);

// Obtener la instancia de Firebase Messaging
const messaging = firebase.messaging();

// Configurar el manejador de mensajes en segundo plano
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Personalizar la notificación
  const notificationTitle = payload.notification?.title || 'Nueva notificación';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {}
  };

  // Mostrar la notificación
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Manejar la acción de clic en la notificación
self.addEventListener('notificationclick', (event) => {
  console.log('Notification click received.', event);
  
  // Cerrar la notificación
  event.notification.close();
  
  // Abrir o enfocar la aplicación
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      for (const client of clientList) {
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
