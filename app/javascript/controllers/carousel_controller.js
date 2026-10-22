import { Controller } from "@hotwired/stimulus"

// Avança uma faixa rolável (overflow-x + scroll-snap) automaticamente, um item por vez,
// voltando ao início no fim. Pausa enquanto o usuário interage (mouse em cima, toque,
// foco) ou a aba está oculta, e não roda sozinho com prefers-reduced-motion.
// Usage: data-controller="carousel" data-carousel-interval-value="5000"
export default class extends Controller {
  static values = { interval: { type: Number, default: 5000 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.pause = this.stop.bind(this)
    this.resume = this.start.bind(this)
    this.onVisibility = () => (document.hidden ? this.stop() : this.start())

    this.pauseEvents = ["pointerenter", "pointerdown", "touchstart", "focusin"]
    this.resumeEvents = ["pointerleave", "pointerup", "touchend", "focusout"]
    this.pauseEvents.forEach((e) => this.element.addEventListener(e, this.pause, { passive: true }))
    this.resumeEvents.forEach((e) => this.element.addEventListener(e, this.resume, { passive: true }))
    document.addEventListener("visibilitychange", this.onVisibility)

    this.start()
  }

  disconnect() {
    this.stop()
    if (!this.pauseEvents) return
    this.pauseEvents.forEach((e) => this.element.removeEventListener(e, this.pause))
    this.resumeEvents.forEach((e) => this.element.removeEventListener(e, this.resume))
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  start() {
    this.stop()
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  stop() {
    if (this.timer) clearInterval(this.timer)
    this.timer = null
  }

  next() {
    const el = this.element
    const first = el.firstElementChild
    if (!first) return

    const gap = parseFloat(getComputedStyle(el).columnGap) || 0
    const step = first.getBoundingClientRect().width + gap
    const max = el.scrollWidth - el.clientWidth

    if (el.scrollLeft >= max - 2) {
      el.scrollTo({ left: 0, behavior: "smooth" })
    } else {
      el.scrollBy({ left: step, behavior: "smooth" })
    }
  }
}
