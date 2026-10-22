import { Controller } from "@hotwired/stimulus"

// Mostra um banner "Instalar app" quando o navegador dispara beforeinstallprompt.
// Esconde se o app já roda instalado (standalone) ou se o usuário dispensou nos últimos 14 dias.
const DISMISS_KEY = "economiza-install-dismissed-at"
const DISMISS_DAYS = 14

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    this.prompt = null
    this._onPrompt = (event) => {
      event.preventDefault()
      this.prompt = event
      if (!this.dismissedRecently() && !this.standalone()) this.show()
    }
    this._onInstalled = () => this.hide()
    window.addEventListener("beforeinstallprompt", this._onPrompt)
    window.addEventListener("appinstalled", this._onInstalled)
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this._onPrompt)
    window.removeEventListener("appinstalled", this._onInstalled)
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
