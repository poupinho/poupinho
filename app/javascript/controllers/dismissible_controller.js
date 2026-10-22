import { Controller } from "@hotwired/stimulus"

// Hides an element (a tip, a banner) and remembers the choice per browser.
// Usage: data-controller="dismissible" data-dismissible-key-value="goals-tip"
export default class extends Controller {
  static values = { key: String }

  connect() {
    if (this.stored() === "1") this.element.hidden = true
  }

  dismiss() {
    this.element.hidden = true
    try {
      localStorage.setItem(this.storageKey(), "1")
    } catch (error) {
      // Modo privado ou storage bloqueado: some só nesta visita.
    }
  }

  stored() {
    try {
      return localStorage.getItem(this.storageKey())
    } catch (error) {
      return null
    }
  }

  storageKey() {
    return `economiza-dismissed-${this.keyValue}`
  }
}
