import { Controller } from "@hotwired/stimulus"

// Carrossel do hero: troca, a cada intervalo e em sincronia, a tela do mock
// (slide) e o bloco de texto da esquerda (copy), sem setas. As abas no topo do
// mock indicam a tela atual e podem ser clicadas. Pausa com o mouse sobre os
// elementos "hover" (ou o controller inteiro, se não houver); com
// prefers-reduced-motion não avança sozinho.
// Usage: data-controller="slides" data-slides-interval-value="4500"
export default class extends Controller {
  static targets = ["slide", "tab", "copy", "hover"]
  static values = { interval: { type: Number, default: 4500 } }

  connect() {
    this.index = 0
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.show(0)

    this.pause = this.stop.bind(this)
    this.resume = this.start.bind(this)
    this.hoverAreas = this.hasHoverTarget ? this.hoverTargets : [this.element]
    this.hoverAreas.forEach((el) => {
      el.addEventListener("mouseenter", this.pause)
      el.addEventListener("mouseleave", this.resume)
    })
    this.onVisibility = () => (document.hidden ? this.stop() : this.start())
    document.addEventListener("visibilitychange", this.onVisibility)
    this.start()
  }

  disconnect() {
    this.stop()
    this.hoverAreas?.forEach((el) => {
      el.removeEventListener("mouseenter", this.pause)
      el.removeEventListener("mouseleave", this.resume)
    })
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  start() {
    this.stop()
    if (this.reduced) return
    this.timer = setInterval(() => this.show(this.index + 1), this.intervalValue)
  }

  stop() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }

  go(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.show(index)
    this.start() // reinicia a contagem a partir do clique
  }

  show(index) {
    const count = this.slideTargets.length
    this.index = ((index % count) + count) % count
    this.slideTargets.forEach((slide, i) => slide.classList.toggle("is-active", i === this.index))
    this.copyTargets.forEach((copy, i) => {
      copy.classList.toggle("is-active", i === this.index)
      copy.setAttribute("aria-hidden", i !== this.index)
    })
    this.tabTargets.forEach((tab, i) => {
      tab.classList.toggle("is-active", i === this.index)
      tab.setAttribute("aria-selected", i === this.index)
    })
    this.element.style.setProperty("--slides-interval", `${this.intervalValue}ms`)
  }
}
