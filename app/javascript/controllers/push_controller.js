import { Controller } from "@hotwired/stimulus"

// Ativa/desativa os lembretes por notificação push neste navegador.
// Fluxo: permissão -> pushManager.subscribe (chave VAPID) -> POST /push_subscription.
// No iPhone só funciona com o app instalado na tela inicial (mostra a dica).
// Modo "banner" (dashboard): convite automático que só aparece quando dá para ativar
// e some quando já está ativo, sem suporte ou dispensado nos últimos 7 dias.
const DISMISS_KEY = "economiza-push-dismissed-at"
const DISMISS_DAYS = 7

export default class extends Controller {
  static targets = ["status", "enable", "disable", "unsupported", "ios"]
  static values = { publicKey: String, url: String, mode: { type: String, default: "settings" } }

  async connect() {
    if (this.banner && (this.dismissedRecently() || Notification?.permission === "denied")) return
    if (!this.supported()) {
      if (this.banner && !this.iosNotInstalled()) return
      this.show(this.iosNotInstalled() ? "ios" : "unsupported")
      this.reveal()
      return
    }
    const subscription = await this.currentSubscription()
    if (this.banner && subscription) return
    this.render(!!subscription)
    this.reveal()
  }

  get banner() {
    return this.modeValue === "banner"
  }

  reveal() {
    this.element.hidden = false
  }

  dismiss() {
    try { localStorage.setItem(DISMISS_KEY, String(Date.now())) } catch (_e) {}
    this.element.hidden = true
  }

  dismissedRecently() {
    try {
      const at = Number(localStorage.getItem(DISMISS_KEY))
      return at && Date.now() - at < DISMISS_DAYS * 24 * 60 * 60 * 1000
    } catch (_e) { return false }
  }

  async enable() {
    this.enableTarget.disabled = true
    try {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") { this.render(false, "denied"); return }

      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.applicationServerKey()
      })
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: this.headers(),
        body: JSON.stringify({ subscription: subscription.toJSON() })
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      this.render(true)
      if (this.banner) setTimeout(() => { this.element.hidden = true }, 2500)
    } catch (error) {
      console.warn("Não foi possível ativar os lembretes:", error)
      this.render(false, "error")
    } finally {
      this.enableTarget.disabled = false
    }
  }

  async disable() {
    this.disableTarget.disabled = true
    try {
      const subscription = await this.currentSubscription()
      if (subscription) {
        await fetch(`${this.urlValue}?endpoint=${encodeURIComponent(subscription.endpoint)}`, { method: "DELETE", headers: this.headers() })
        await subscription.unsubscribe()
      }
      this.render(false)
    } finally {
      this.disableTarget.disabled = false
    }
  }

  // --- helpers ---

  supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  iosNotInstalled() {
    const ios = /iPhone|iPad|iPod/.test(navigator.userAgent)
    const standalone = window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
    return ios && !standalone
  }

  async currentSubscription() {
    const registration = await navigator.serviceWorker.ready
    return registration.pushManager.getSubscription()
  }

  render(active, reason = null) {
    this.show(active ? "on" : "off")
    this.statusTarget.dataset.state = active ? "on" : reason || "off"
  }

  show(state) {
    this.element.dataset.pushState = state
  }

  headers() {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
    }
  }

  applicationServerKey() {
    const base64 = (this.publicKeyValue + "=".repeat((4 - (this.publicKeyValue.length % 4)) % 4)).replace(/-/g, "+").replace(/_/g, "/")
    const raw = atob(base64)
    return Uint8Array.from(raw, (c) => c.charCodeAt(0))
  }
}
