import { Controller } from "@hotwired/stimulus"

// Mostra um banner "Instalar app" quando o navegador dispara beforeinstallprompt.
// Esconde se o app já roda instalado (standalone) ou se o usuário dispensou nos últimos 14 dias.
// Os dois banners ocupam o mesmo lugar: enquanto o aviso de cookies estiver na tela, este
// espera, e aparece depois da escolha (eventos do controller cookie-consent).
const DISMISS_KEY = "economiza-install-dismissed-at"
const DISMISS_DAYS = 14

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    this.prompt = null
    this._onPrompt = (event) => {
      event.preventDefault()
      this.prompt = event
      this.maybeShow()
    }
    this._onInstalled = () => this.hide()
    this._onCookieShown = () => this.hide()
    this._onCookieDecided = () => this.maybeShow()
    window.addEventListener("beforeinstallprompt", this._onPrompt)
    window.addEventListener("appinstalled", this._onInstalled)
    window.addEventListener("cookie-consent:shown", this._onCookieShown)
    window.addEventListener("cookie-consent:decided", this._onCookieDecided)
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this._onPrompt)
    window.removeEventListener("appinstalled", this._onInstalled)
    window.removeEventListener("cookie-consent:shown", this._onCookieShown)
    window.removeEventListener("cookie-consent:decided", this._onCookieDecided)
  }

  maybeShow() {
    if (!this.prompt || this.dismissedRecently() || this.standalone() || this.cookiePending()) return
    this.show()
  }

  cookiePending() {
    return document.querySelector(".ec-cookie-banner:not([hidden])") !== null
  }

  async install() {
    if (!this.prompt) return
    this.prompt.prompt()
    const { outcome } = await this.prompt.userChoice
    this.prompt = null
    if (outcome === "accepted") this.hide()
  }

  dismiss() {
    try { localStorage.setItem(DISMISS_KEY, String(Date.now())) } catch (_e) {}
    this.hide()
  }

  show() { this.bannerTarget.classList.add("show") }
  hide() { this.bannerTarget.classList.remove("show") }

  standalone() {
    return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
  }

  dismissedRecently() {
    try {
      const at = Number(localStorage.getItem(DISMISS_KEY))
      return at && Date.now() - at < DISMISS_DAYS * 24 * 60 * 60 * 1000
    } catch (_e) {
      return false
    }
  }
}
