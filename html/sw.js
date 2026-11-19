// PDF Araçları service worker — cc014b8523 (tools/build.py)
const CACHE = 'pdf-araclari-cc014b8523';
const ASSETS = [
  "/",
  "/index.html",
  "/manifest.webmanifest",
  "/favicon.ico",
  "/libs/docx.umd.js",
  "/libs/html2pdf.bundle.min.js",
  "/libs/jspdf.umd.min.js",
  "/libs/jszip.min.js",
  "/libs/mammoth.browser.min.js",
  "/libs/pdf-lib.min.js",
  "/libs/pdf.min.js",
  "/libs/pdf.worker.min.js",
  "/libs/pptxgen.bundle.js",
  "/libs/xlsx.full.min.js",
  "/fonts/fonts.css",
  "/icons/apple-touch-icon.png",
  "/icons/favicon-32.png",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/icons/icon-maskable-512.png"
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k.startsWith('pdf-araclari-') && k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  if (req.mode === 'navigate') {
    // sayfa: önce ağ, çevrimdışıysa önbellek / page: network first, cache when offline
    e.respondWith(fetch(req).then(r => {
      if (r.ok) { const copy = r.clone(); caches.open(CACHE).then(c => c.put('/index.html', copy)); }
      return r;
    }).catch(() => caches.match('/index.html')));
    return;
  }
  // kütüphane, yazı tipi, simge: önce önbellek / assets: cache first
  e.respondWith(caches.match(req, { ignoreSearch: true }).then(hit => hit || fetch(req)));
});
