import { Controller } from "@hotwired/stimulus"

// Banner de cookies do Google Analytics (Consent Mode). Mostra o aviso enquanto não há
// escolha guardada em localStorage ("economiza-cookies": granted | denied); ao aceitar,
// libera analytics_storage no gtag. O padrão negado é definido em layouts/_analytics.
// Avisa na window ("cookie-consent:shown" / "cookie-consent:decided") para o banner de
// instalar (pwa-install) não aparecer por cima deste.
const KEY = "economiza-cookies"

export default class extends Controller {
  connect() {
    if (this.stored()) return
    this.element.hidden = false
    requestAnimationFrame(() => this.element.classList.add("show"))
    this.dispatch("shown", { target: window })
  }

  accept() {
    this.remember("granted")
    window.gtag?.("consent", "update", { analytics_storage: "granted" })
    this.hide()
  }

  decline() {
    this.remember("denied")
    this.hide()
  }

  hide() {
    this.element.classList.remove("show")
    this.element.hidden = true
    this.dispatch("decided", { target: window })
  }

  remember(choice) {
    try {
      localStorage.setItem(KEY, choice)
    } catch (error) {
      // Modo privado ou storage bloqueado: some só nesta visita.
    }
  }

  stored() {
    try {
      return localStorage.getItem(KEY)
    } catch (error) {
      return null
    }
  }
}
