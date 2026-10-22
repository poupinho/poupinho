import { Controller } from "@hotwired/stimulus"

// Cents-first BRL mask: any keystroke shifts digits from the right.
// On submit, replaces the visible "1.500,50" with the raw decimal "1500.50".
export default class extends Controller {
  connect() {
    this.element.setAttribute("inputmode", "numeric")

    this._inputHandler = () => this.format()
    this.element.addEventListener("input", this._inputHandler)

    const form = this.element.closest("form")
    if (form) {
      this._submitHandler = () => this.unformat()
      form.addEventListener("submit", this._submitHandler)
    }
  }

  disconnect() {
    this.element.removeEventListener("input", this._inputHandler)
    const form = this.element.closest("form")
    if (form && this._submitHandler) {
      form.removeEventListener("submit", this._submitHandler)
    }
  }

  format() {
    const digits = this.element.value.replace(/\D/g, "")
    if (digits === "") {
      this.element.value = ""
      return
    }
    const cents = parseInt(digits, 10)
    const reais = Math.floor(cents / 100)
    const centsR = (cents % 100).toString().padStart(2, "0")
    const reaisStr = reais.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    this.element.value = `${reaisStr},${centsR}`
  }

  unformat() {
    const v = this.element.value
    if (v === "") return
    const digits = v.replace(/\D/g, "")
    if (digits === "") {
      this.element.value = ""
      return
    }
    const cents = parseInt(digits, 10)
    const reais = Math.floor(cents / 100)
    const centsR = (cents % 100).toString().padStart(2, "0")
    this.element.value = `${reais}.${centsR}`
  }
}
