import { Controller } from "@hotwired/stimulus"

// Toggles visibility of a password input and swaps the eye/eye-slash icons.
export default class extends Controller {
  static targets = ["input", "eye", "eyeSlash"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"
    this.inputTarget.type = isPassword ? "text" : "password"
    this.eyeTarget.classList.toggle("d-none", isPassword)
    this.eyeSlashTarget.classList.toggle("d-none", !isPassword)
  }
}
