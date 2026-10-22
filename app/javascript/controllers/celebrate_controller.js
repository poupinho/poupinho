import { Controller } from "@hotwired/stimulus"
import { launchConfetti } from "confetti"

// Dispara confete a partir do elemento assim que ele aparece (ex.: toast de
// novo nível). Usage: data-controller="celebrate". Nada com prefers-reduced-motion.
export default class extends Controller {
  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    // Espera a animação de entrada do toast para o confete sair do lugar certo.
    this.timer = setTimeout(() => { this.cancel = launchConfetti(this.element) }, 250)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.cancel?.()
  }
}
