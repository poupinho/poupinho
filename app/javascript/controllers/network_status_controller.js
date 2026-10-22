import { Controller } from "@hotwired/stimulus"

// Exibe uma faixa "Você está offline" quando o navegador perde a conexão.
export default class extends Controller {
  connect() {
    this._update = () => this.element.classList.toggle("show", !navigator.onLine)
    window.addEventListener("online", this._update)
    window.addEventListener("offline", this._update)
    this._update()
  }

  disconnect() {
    window.removeEventListener("online", this._update)
    window.removeEventListener("offline", this._update)
  }
}
