import { Controller } from "@hotwired/stimulus"

// Máscara de celular brasileiro: "(11) 91234-5678". Aceita colar com ou sem
// formatação; o servidor guarda só os dígitos (User normaliza).
export default class extends Controller {
  connect() {
    this.element.setAttribute("inputmode", "tel")
    this.element.setAttribute("maxlength", "15")
    this.onInput = () => this.format()
    this.element.addEventListener("input", this.onInput)
    this.format()
  }

  disconnect() {
    this.element.removeEventListener("input", this.onInput)
  }

  format() {
    const digits = this.element.value.replace(/\D/g, "").slice(0, 11)
    let out = ""
    if (digits.length > 0) out = `(${digits.slice(0, 2)}`
    if (digits.length >= 2) out += ") "
    if (digits.length > 2) out += digits.slice(2, 7)
    if (digits.length > 7) out += `-${digits.slice(7, 11)}`
    this.element.value = out
  }
}
