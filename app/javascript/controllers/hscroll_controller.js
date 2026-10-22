import { Controller } from "@hotwired/stimulus"

// Rolagem horizontal amigável ao mouse (no toque o navegador já resolve):
//  - roda do mouse (vertical) rola a faixa para o lado;
//  - clicar e arrastar também rola, sem disparar o clique do item ao soltar.
// Usage: data-controller="hscroll" em um container com overflow-x: auto.
export default class extends Controller {
  static DRAG_THRESHOLD = 6

  connect() {
    this.onWheel = this.wheel.bind(this)
    this.onPointerDown = this.pointerDown.bind(this)
    this.onPointerMove = this.pointerMove.bind(this)
    this.onPointerUp = this.pointerUp.bind(this)
    this.onClickCapture = this.clickCapture.bind(this)

    this.element.addEventListener("wheel", this.onWheel, { passive: false })
    this.element.addEventListener("pointerdown", this.onPointerDown)
    this.element.addEventListener("click", this.onClickCapture, true)
  }

  disconnect() {
    this.element.removeEventListener("wheel", this.onWheel)
    this.element.removeEventListener("pointerdown", this.onPointerDown)
    this.element.removeEventListener("click", this.onClickCapture, true)
    this.stopDragging()
  }

  get scrollable() {
    return this.element.scrollWidth > this.element.clientWidth
  }

  wheel(event) {
    if (!this.scrollable) return
    if (Math.abs(event.deltaY) <= Math.abs(event.deltaX)) return
    event.preventDefault()
    this.element.scrollLeft += event.deltaY
  }

  pointerDown(event) {
    if (event.pointerType !== "mouse" || event.button !== 0 || !this.scrollable) return
    this.startX = event.clientX
    this.startScroll = this.element.scrollLeft
    this.dragged = false
    window.addEventListener("pointermove", this.onPointerMove)
    window.addEventListener("pointerup", this.onPointerUp)
  }

  pointerMove(event) {
    const delta = event.clientX - this.startX
    if (!this.dragged && Math.abs(delta) < this.constructor.DRAG_THRESHOLD) return
    this.dragged = true
    this.element.classList.add("is-dragging")
    this.element.scrollLeft = this.startScroll - delta
    event.preventDefault()
  }

  pointerUp() {
    this.stopDragging()
    // Mantém `dragged` até o clique que fecha o arrasto ser engolido em clickCapture.
    setTimeout(() => { this.dragged = false }, 0)
  }

  stopDragging() {
    window.removeEventListener("pointermove", this.onPointerMove)
    window.removeEventListener("pointerup", this.onPointerUp)
    this.element.classList.remove("is-dragging")
  }

  clickCapture(event) {
    if (!this.dragged) return
    event.preventDefault()
    event.stopPropagation()
  }
}
