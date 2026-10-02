// ChronoMed Service Worker - Offline-First PWA (v1.1.0)
const CACHE_NAME = 'chronomed-sw-v1.1.0';

const PRECACHE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './js/chile_meds.js',
  './assets/favicon.png',
  './assets/images/app_icon.png',
  './assets/images/dashboard_banner.jpg',
  './assets/images/banner.jpg'
];

const EXTERNAL_RESOURCES = [
  'https://cdn.tailwindcss.com',
  'https://unpkg.com/lucide@latest'
];

// Install: Pre-cache local assets and external CDNs gracefully
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      // 1. Cache core local assets
      for (const asset of PRECACHE_ASSETS) {
        try {
          await cache.add(asset);
        } catch (err) {
          console.warn('[SW] Could not precache local asset:', asset, err);
        }
      }

      // 2. Cache external CDNs
      for (const url of EXTERNAL_RESOURCES) {
        try {
          const res = await fetch(url, { mode: 'cors' });
          if (res && (res.ok || res.type === 'opaque')) {
            await cache.put(url, res);
          }
        } catch (err) {
          console.warn('[SW] Could not precache external resource:', url, err);
        }
      }
    }).then(() => self.skipWaiting())
  );
});

// Activate: Clean up old cache versions
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[SW] Purging outdated cache:', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch: Stale-While-Revalidate with full offline fallback
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  // Exclude external QR generation dynamic APIs from blocking offline mode
  if (url.hostname.includes('api.qrserver.com')) {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(event.request))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      // Background revalidation
      const fetchPromise = fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && (networkResponse.status === 200 || networkResponse.type === 'opaque')) {
            const clone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, clone);
            });
          }
          return networkResponse;
        })
        .catch(() => {
          // If offline and navigate mode, fallback to cached index.html
          if (event.request.mode === 'navigate') {
            return caches.match('./index.html');
          }
        });

      return cachedResponse || fetchPromise;
    })
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
