// Breakin offline shell. The whole game is one HTML file that needs no network to play,
// so caching six files is all "works on a plane / in a lift" takes.
// ponytail: network-first, always. Offline gets the last good copy; online can never be
// served a stale build, so a launch-day hotfix still lands on the next reload.
// The catch that made that half true: Pages serves the page with Cache-Control max-age=600,
// and our own fetch reads through the browser's HTTP cache like any other - so for ten minutes
// after a deploy the "network" copy could itself be the old build. Every request for the page
// is made with cache:'reload' to skip that one cache. Only the page: the icons and manifest
// never change, and re-downloading them on every load would cost real bytes for nothing.
const C = 'breakin-v2';
const ASSETS = ['./', 'index.html', 'manifest.json', 'icon-192.png', 'icon-512.png', 'og.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(C)
    .then(c => c.addAll(ASSETS.map(u => new Request(u, {cache: 'reload'}))))   // a fresh copy at install, not whatever the HTTP cache is holding
    .then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  // ponytail: only ever touch our own caches. github.io serves courtconnect from the
  // same origin, and caches are per-origin - an unfiltered sweep here wipes that app's
  // offline shell (and its sweep wipes ours; that side needs the same guard in its repo).
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k.startsWith('breakin-') && k !== C).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  // the leaderboard / feedback calls go to Supabase - never cache or shadow those
  if (url.origin !== self.location.origin) return;
  // ponytail: key the cache on the path alone. Reads already ignored the search string, so
  // every ?join=CODE invite and every ?v= cache-buster was writing ANOTHER full copy of
  // index.html that nothing could ever match back - 59 dead copies on one test device.
  // Unbounded growth, and an over-budget origin gets its whole storage evicted on iOS,
  // which takes the offline shell with it.
  const key = url.origin + url.pathname;
  // Belt and braces: a synchronous throw here would reject respondWith and leave the player
  // with a dead page, so an engine that dislikes the option just gets the ordinary fetch.
  // A rejected promise is already safe - the race below falls through to the cached copy.
  const ask = r => { try { return fetch(r, {cache: 'reload'}); } catch (_) { return fetch(r); } };
  const net = (e.request.mode === 'navigate' ? ask(e.request) : fetch(e.request)).then(res => {
    // a 404 served during a deploy must never become the offline copy of the game
    if (res.ok) { const copy = res.clone(); caches.open(C).then(c => c.put(key, copy)).catch(() => {}); }
    return res;
  });
  const cached = () => caches.match(key).then(r => r || caches.match('index.html'));
  e.respondWith(
    // ponytail: fetch does not reject on a stalled mobile connection, it hangs - so plain
    // network-first left the player staring at a blank page for good, in exactly the
    // weak-signal case this offline shell exists for. Give the network 8s to win, so a slow
    // but working load still gets the newest build, then show the cached game. The fetch
    // runs on and still refreshes the cache, so a launch-day hotfix lands on the next open.
    Promise.race([net.catch(() => null), new Promise(r => setTimeout(r, 8000))])
      .then(res => res || cached().then(r => r || net))
  );
});
