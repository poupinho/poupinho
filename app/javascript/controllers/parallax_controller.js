import { Controller } from "@hotwired/stimulus"

// Movimento da landing page:
//  - layer: elementos que deslocam no scroll em velocidades diferentes (data-parallax-speed).
//    Velocidade positiva = acompanha o scroll (parece mais próximo); negativa = vai contra.
//  - tilt: inclinação 3D suave seguindo o mouse (só em dispositivos com ponteiro fino).
//  - reveal: aparece com fade + subida quando entra na viewport (uma vez só).
// Tudo é desligado quando o usuário prefere menos movimento (prefers-reduced-motion).
export default class extends Controller {
  static targets = ["layer", "tilt", "reveal"]

  connect() {
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.setupReveal()
    if (this.reduced) return

    this.ticking = false
    this.measure()
    this._onScroll = () => this.requestTick()
    this._onResize = () => { this.measure(); this.requestTick() }
    window.addEventListener("scroll", this._onScroll, { passive: true })
    window.addEventListener("resize", this._onResize)
    this.setupTilt()
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll)
    window.removeEventListener("resize", this._onResize)
    this.observer?.disconnect()
    this.teardownTilt()
  }

  // --- Scroll layers -------------------------------------------------------

  measure() {
    const scrollY = window.scrollY
    this.layers = this.layerTargets.map((el) => {
      const section = el.closest("[data-parallax-section]") || el.parentElement
      const rect = section.getBoundingClientRect()
      return {
        el,
        speed: Number(el.dataset.parallaxSpeed || 0.2),
        top: rect.top + scrollY,
        height: rect.height
      }
    })
  }

  requestTick() {
    if (this.ticking) return
    this.ticking = true
    requestAnimationFrame(() => { this.update(); this.ticking = false })
  }

  update() {
    const scrollY = window.scrollY
    const viewport = window.innerHeight
    for (const layer of this.layers) {
      // Distância entre o centro da seção e o centro da viewport: 0 quando a seção está centralizada.
      const sectionCenter = layer.top + layer.height / 2
      const viewportCenter = scrollY + viewport / 2
      if (Math.abs(sectionCenter - viewportCenter) > viewport + layer.height) continue
      const offset = (viewportCenter - sectionCenter) * layer.speed
      layer.el.style.transform = `translate3d(0, ${offset.toFixed(1)}px, 0)`
    }
  }

  // --- Mouse tilt ----------------------------------------------------------

  setupTilt() {
    if (!this.hasTiltTarget || !window.matchMedia("(pointer: fine)").matches) return
    this.tiltArea = this.tiltTarget.closest("[data-parallax-section]") || this.tiltTarget.parentElement
    this._onMove = (event) => {
      const rect = this.tiltArea.getBoundingClientRect()
      const x = (event.clientX - rect.left) / rect.width - 0.5
      const y = (event.clientY - rect.top) / rect.height - 0.5
      this.tiltTarget.style.setProperty("--tilt-x", `${(-y * 8).toFixed(2)}deg`)
      this.tiltTarget.style.setProperty("--tilt-y", `${(x * 10).toFixed(2)}deg`)
    }
    this._onLeave = () => {
      this.tiltTarget.style.setProperty("--tilt-x", "0deg")
      this.tiltTarget.style.setProperty("--tilt-y", "0deg")
    }
    this.tiltArea.addEventListener("mousemove", this._onMove)
    this.tiltArea.addEventListener("mouseleave", this._onLeave)
  }

  teardownTilt() {
    if (!this.tiltArea) return
    this.tiltArea.removeEventListener("mousemove", this._onMove)
    this.tiltArea.removeEventListener("mouseleave", this._onLeave)
  }

  // --- Reveal on scroll ----------------------------------------------------

  setupReveal() {
    if (this.reduced || !("IntersectionObserver" in window)) {
      this.revealTargets.forEach((el) => el.classList.add("is-visible"))
      return
    }
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        entry.target.classList.add("is-visible")
        this.observer.unobserve(entry.target)
      })
    }, { threshold: 0.15, rootMargin: "0px 0px -40px 0px" })
    this.revealTargets.forEach((el) => this.observer.observe(el))
  }
}
