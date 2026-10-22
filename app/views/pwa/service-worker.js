// Service worker do Poupinho.
//
// Estratégia:
//  - Assets digeridos (/assets/...): cache-first — são imutáveis (o nome muda a cada build).
//  - Navegações (HTML): network-first; se a rede falhar, usa a última cópia em cache
//    da mesma URL e, por último, a página /offline.html.
//  - Demais requisições (POST, JSON etc.): só rede.
//
// Aumente CACHE_VERSION para invalidar todos os caches em um novo deploy relevante.

const CACHE_VERSION = "v3"
const PRECACHE = `economiza-precache-${CACHE_VERSION}`
const ASSETS = `economiza-assets-${CACHE_VERSION}`
const PAGES = `economiza-pages-${CACHE_VERSION}`
const OFFLINE_URL = "/offline.html"
const PRECACHE_URLS = [OFFLINE_URL, "/icon.svg", "/icon-192.png", "/icon.png", "/badge-96.png"]
const MAX_PAGES = 30

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(PRECACHE).then((cache) => cache.addAll(PRECACHE_URLS)).then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((k) => k.startsWith("economiza-") && ![PRECACHE, ASSETS, PAGES].includes(k))
          .map((k) => caches.delete(k))
      )
    ).then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", (event) => {
  const { request } = event
  if (request.method !== "GET") return

  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return

  if (url.pathname.startsWith("/assets/")) {
    event.respondWith(cacheFirst(request, ASSETS))
    return
  }

  if (request.mode === "navigate") {
    event.respondWith(networkFirstPage(request))
    return
  }

  if (PRECACHE_URLS.includes(url.pathname)) {
    event.respondWith(cacheFirst(request, PRECACHE))
  }
})

// --- Notificações push (lembretes) ---
self.addEventListener("push", (event) => {
  let data = {}
  try { data = event.data ? event.data.json() : {} } catch (_e) { data = { body: event.data && event.data.text() } }
  const title = data.title || "Poupinho"
  const options = {
    body: data.body || "",
    icon: data.icon || "/icon-192.png",
    badge: data.badge || "/badge-96.png", // monocromático: o Android desenha o badge pela silhueta (alfa)
    tag: data.tag || undefined,
    data: { url: data.url || "/dashboard" }
  }
  event.waitUntil(self.registration.showNotification(title, options))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = (event.notification.data && event.notification.data.url) || "/dashboard"
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clients) => {
      const open = clients.find((c) => new URL(c.url).origin === self.location.origin)
      if (open) return open.navigate(url).then((c) => c && c.focus())
      return self.clients.openWindow(url)
    })
  )
})

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName)
  const cached = await cache.match(request)
  if (cached) return cached

  const response = await fetch(request)
  if (response.ok) cache.put(request, response.clone())
  return response
}

async function networkFirstPage(request) {
  const cache = await caches.open(PAGES)
  try {
    const response = await fetch(request)
    if (response.ok && response.type === "basic") {
      cache.put(request, response.clone())
      trimCache(cache, MAX_PAGES)
    }
    return response
  } catch (_error) {
    const cached = await cache.match(request)
    if (cached) return cached
    return caches.match(OFFLINE_URL, { cacheName: PRECACHE })
  }
}

async function trimCache(cache, max) {
  const keys = await cache.keys()
  if (keys.length <= max) return
  await Promise.all(keys.slice(0, keys.length - max).map((key) => cache.delete(key)))
}
