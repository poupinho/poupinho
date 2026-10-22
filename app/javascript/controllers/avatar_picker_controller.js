import { Controller } from "@hotwired/stimulus"

// Prévia da foto de perfil escolhida no formulário, antes de salvar.
// Ao escolher um arquivo, o círculo passa a mostrar a imagem; ao marcar "remover", volta às iniciais.
export default class extends Controller {
  static targets = ["input", "preview", "remove"]

  disconnect() {
    this.revoke()
  }

  preview() {
    const file = this.inputTarget.files && this.inputTarget.files[0]
    if (!file || !file.type.startsWith("image/")) return
    this.revoke()
    this.objectUrl = URL.createObjectURL(file)
    if (!this.original) this.original = this.previewTarget.innerHTML
    this.previewTarget.innerHTML = ""
    const img = document.createElement("img")
    img.src = this.objectUrl
    img.alt = ""
    this.previewTarget.appendChild(img)
    if (this.hasRemoveTarget) this.removeTarget.checked = false
  }

  toggleRemove() {
    if (this.removeTarget.checked) {
      this.inputTarget.value = ""
      this.revoke()
      if (!this.original) this.original = this.previewTarget.innerHTML
      this.previewTarget.textContent = this.previewTarget.dataset.initials || "?"
    } else if (this.original) {
      this.previewTarget.innerHTML = this.original
    }
  }

  revoke() {
    if (this.objectUrl) URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = null
  }
}
