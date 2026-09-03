// Breakin offline shell. The whole game is one HTML file that needs no network to play,
// so caching six files is all "works on a plane / in a lift" takes.
// ponytail: network-first, always. Offline gets the last good copy; online can never be
// served a stale build, so a launch-day hotfix still lands on the next reload.
const C = 'breakin-v1';
const ASSETS = ['./', 'index.html', 'manifest.json', 'icon-192.png', 'icon-512.png', 'og.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(C).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== C).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  // the leaderboard / feedback calls go to Supabase - never cache or shadow those
  if (new URL(e.request.url).origin !== self.location.origin) return;
  e.respondWith(
    fetch(e.request).then(res => {
      const copy = res.clone();
      caches.open(C).then(c => c.put(e.request, copy)).catch(() => {});
      return res;
    }).catch(() =>
      // ignoreSearch so ?v=123 cache-busters and ?join=CODE invites still match
      caches.match(e.request, { ignoreSearch: true }).then(r => r || caches.match('index.html'))
    )
  );
});
