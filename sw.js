/* Japan 2026 — minimal service worker.
   Precaches the app shell so the itinerary opens offline (rural Kyushu / on the
   plane), and uses network-first for same-origin requests so redeploys are
   picked up when online. Supabase (cross-origin) is never intercepted, so the
   notes feature always talks to the live API. */
const CACHE = 'japan-2026-v107';
const SHELL = [
  './', 'index.html', 'manifest.json',
  'favicon.svg', 'apple-touch-icon.png', 'icon-192.png', 'icon-512.png', 'qr.svg',
  'aim-dojo.jpg', 'moon-chorus.jpg'
];

self.addEventListener('install', function(e){
  e.waitUntil(
    caches.open(CACHE).then(function(c){ return c.addAll(SHELL); }).then(function(){ return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function(e){
  e.waitUntil(
    caches.keys().then(function(keys){
      return Promise.all(keys.filter(function(k){ return k !== CACHE; }).map(function(k){ return caches.delete(k); }));
    }).then(function(){ return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function(e){
  var req = e.request;
  if(req.method !== 'GET') return;                       // never cache writes
  var url = new URL(req.url);
  if(url.origin !== self.location.origin) return;        // let Supabase etc. hit the network directly
  e.respondWith(
    fetch(req).then(function(res){
      var copy = res.clone();
      caches.open(CACHE).then(function(c){ c.put(req, copy); }).catch(function(){});
      return res;
    }).catch(function(){
      return caches.match(req).then(function(r){ return r || caches.match('index.html'); });
    })
  );
});
