import { Controller } from "@hotwired/stimulus"

// Toggles between light and dark Bootstrap themes.
// Persists choice in localStorage and respects prefers-color-scheme on first visit.
export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    this.apply(this.currentTheme())
    this.beforeRender = this.beforeRender.bind(this)
    document.addEventListener("turbo:before-render", this.beforeRender)
  }

  disconnect() {
    document.removeEventListener("turbo:before-render", this.beforeRender)
  }

  beforeRender(event) {
    // Turbo copies the incoming <html> attributes on render; stamp the theme
    // on the new document so the attribute survives navigation without a flash.
    const incoming = event.detail.newBody && event.detail.newBody.parentElement
    if (incoming) incoming.setAttribute("data-bs-theme", this.currentTheme())
  }

  toggle() {
    const next = this.currentTheme() === "dark" ? "light" : "dark"
    localStorage.setItem("economiza-theme", next)
    this.apply(next)
  }

  currentTheme() {
    const stored = localStorage.getItem("economiza-theme")
    if (stored === "light" || stored === "dark") return stored
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  apply(theme) {
    document.documentElement.setAttribute("data-bs-theme", theme)
    if (this.hasLightIconTarget && this.hasDarkIconTarget) {
      if (theme === "dark") {
        this.lightIconTarget.classList.add("d-none")
        this.darkIconTarget.classList.remove("d-none")
      } else {
        this.lightIconTarget.classList.remove("d-none")
        this.darkIconTarget.classList.add("d-none")
      }
    }
  }
}
