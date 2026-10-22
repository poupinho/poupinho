import { Controller } from "@hotwired/stimulus"

const DEFAULT_DURATION = 5000

export default class extends Controller {
  static targets = ["toast"]

  connect() {
    this.toastTargets.forEach((toast) => this.schedule(toast))
  }

  schedule(toast) {
    // Small timeout so the enter animation plays
    requestAnimationFrame(() => toast.classList.add("show"))
    const duration = Number(toast.dataset.duration) || DEFAULT_DURATION
    const timer = setTimeout(() => this.hide(toast), duration)
    toast.dataset.timerId = timer
  }

  dismiss(event) {
    const toast = event.currentTarget.closest(".ec-toast")
    if (toast.dataset.timerId) clearTimeout(Number(toast.dataset.timerId))
    this.hide(toast)
  }

  hide(toast) {
    toast.classList.remove("show")
    toast.classList.add("hide")
    toast.addEventListener("transitionend", () => toast.remove(), { once: true })
  }
}
