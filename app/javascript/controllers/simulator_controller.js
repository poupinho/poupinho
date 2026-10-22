import { Controller } from "@hotwired/stimulus"

// Simulador da landing: recalcula, a cada movimento do slider, quanto uma
// economia diária vira em cada horizonte (guardado e investido com juros compostos).
// Mesma fórmula de Simulations::Projection (aportes mensais = diário × 365/12).
const DAYS_PER_MONTH = 365 / 12

export default class extends Controller {
  static targets = ["range", "daily", "title", "monthly", "saved", "invested"]
  static values = { rate: { type: Number, default: 0.008 }, titleTemplate: String }

  connect() {
    this.update()
  }

  preset(event) {
    this.rangeTarget.value = event.currentTarget.dataset.amount
    this.update()
  }

  update() {
    const daily = Number(this.rangeTarget.value)
    const monthly = daily * DAYS_PER_MONTH

    this.dailyTarget.textContent = this.brl(daily)
    if (this.hasTitleTarget && this.titleTemplateValue) {
      this.titleTarget.textContent = this.titleTemplateValue.replace("%{amount}", this.brl(daily))
    }
    if (this.hasMonthlyTarget) this.monthlyTarget.textContent = this.brl(monthly)

    this.savedTargets.forEach((el) => {
      const months = Number(el.dataset.months)
      el.textContent = this.brl(monthly * months)
    })
    this.investedTargets.forEach((el) => {
      const months = Number(el.dataset.months)
      el.textContent = this.brl(this.futureValue(monthly, months))
    })

    this.element.querySelectorAll("[data-amount]").forEach((btn) => {
      btn.classList.toggle("active", Number(btn.dataset.amount) === daily)
    })
  }

  futureValue(monthly, months) {
    const i = this.rateValue
    if (i === 0) return monthly * months
    return monthly * ((Math.pow(1 + i, months) - 1) / i)
  }

  brl(value) {
    return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 })
  }
}
