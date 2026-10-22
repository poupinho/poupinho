import { Controller } from "@hotwired/stimulus"

// Expande/recolhe um bloco: alterna a classe is-open no elemento e mantém
// aria-expanded no botão. Usage: data-controller="expand" no container,
// data-action="expand#toggle" e data-expand-target="button" no botão.
export default class extends Controller {
  static targets = ["button"]

  toggle() {
    const open = this.element.classList.toggle("is-open")
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", open)
  }
}
