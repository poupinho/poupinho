import { Controller } from "@hotwired/stimulus"
import { launchConfetti } from "confetti"

// Demo interativa do "Como funciona" na landing: o visitante salva uma economia
// na mini-tela 1 e vê o valor "voar" para o painel (2), os números subirem e a
// meta/sequência comemorarem com confete (3). Tudo fake e local, sem requisições.
export default class extends Controller {
  static targets = [
    "step", "amount", "save", "chipOrigin",
    "today", "month", "bar", "list", "itemTemplate", "itemLabel",
    "progress", "progressLabel", "streak", "badge", "reset"
  ]
  static values = {
    monthBase: { type: Number, default: 412.9 },
    goal: { type: Number, default: 500 },
    streakBase: { type: Number, default: 11 }
  }

  connect() {
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.reset()
  }

  disconnect() {
    this.clearTimers()
    this.cancelConfetti?.()
  }

  // --- Ações -------------------------------------------------------------

  save(event) {
    event?.preventDefault()
    if (this.running) return

    const amount = this.parseAmount(this.amountTarget.value)
    if (!(amount > 0)) {
      this.shake(this.amountTarget)
      return
    }

    this.running = true
    this.saveTarget.disabled = true
    this.amountTarget.disabled = true
    this.setState(0, "done")
    this.flyChip(amount)

    this.after(this.reduced ? 0 : 550, () => this.track(amount))
    this.after(this.reduced ? 0 : 1700, () => this.celebrate(amount))
  }

  reset(event) {
    event?.preventDefault()
    this.clearTimers()
    this.running = false

    this.stepTargets.forEach((step) => step.classList.remove("is-done", "is-active", "is-celebrating"))
    this.saveTarget.disabled = false
    this.amountTarget.disabled = false
    this.resetTarget.hidden = true

    this.todayTarget.textContent = this.brl(0)
    this.monthTarget.textContent = this.brl(this.monthBaseValue)
    this.barTarget.style.setProperty("--h", "38%")
    this.listTarget.querySelectorAll("[data-demo-new]").forEach((li) => li.remove())

    this.setProgress(this.monthBaseValue)
    this.streakTarget.textContent = this.streakBaseValue
    this.badgeTarget.hidden = true
  }

  // --- Etapas ------------------------------------------------------------

  track(amount) {
    this.setState(1, "active")
    this.scrollTo(1)

    this.countUp(this.todayTarget, 0, amount)
    this.countUp(this.monthTarget, this.monthBaseValue, this.monthBaseValue + amount)
    this.barTarget.style.setProperty("--h", "78%")

    const li = this.itemTemplateTarget.content.firstElementChild.cloneNode(true)
    li.querySelector("[data-demo-amount]").textContent = this.brl(amount)
    li.setAttribute("data-demo-new", "")
    this.listTarget.prepend(li)
    if (!this.reduced) {
      li.animate(
        [{ opacity: 0, transform: "translateY(-10px)" }, { opacity: 1, transform: "translateY(0)" }],
        { duration: 400, easing: "cubic-bezier(0.2, 0.9, 0.3, 1)" }
      )
    }
  }

  celebrate(amount) {
    this.setState(2, "active")
    this.stepTargets[2].classList.add("is-celebrating")
    this.scrollTo(2)

    const total = this.monthBaseValue + amount
    this.setProgress(total)
    this.streakTarget.textContent = this.streakBaseValue + 1
    if (!this.reduced) {
      this.streakTarget.animate(
        [{ transform: "scale(1)" }, { transform: "scale(1.35)" }, { transform: "scale(1)" }],
        { duration: 450, easing: "ease-out" }
      )
    }

    this.badgeTarget.hidden = false
    this.badgeTarget.dataset.kind = total >= this.goalValue ? "goal" : "streak"
    this.resetTarget.hidden = false
    this.running = false

    if (!this.reduced) this.confetti(this.stepTargets[2])
  }

  setProgress(total) {
    const pct = Math.min(100, Math.round((total / this.goalValue) * 100))
    this.progressTarget.style.width = `${pct}%`
    this.progressLabelTarget.textContent = `${pct}%`
  }

  setState(index, state) {
    this.stepTargets.forEach((step, i) => {
      if (i === index) step.classList.add(`is-${state}`)
      else if (i < index) { step.classList.remove("is-active"); step.classList.add("is-done") }
    })
  }

  // --- Efeitos -----------------------------------------------------------

  // Um chip "+R$ 12,00" sai do botão de salvar e pousa no KPI "Hoje" do painel.
  flyChip(amount) {
    if (this.reduced) return
    const from = this.chipOriginTarget.getBoundingClientRect()
    const to = this.todayTarget.getBoundingClientRect()

    const chip = document.createElement("span")
    chip.className = "ec-demo-fly"
    chip.textContent = `+${this.brl(amount)}`
    document.body.appendChild(chip)

    const rect = chip.getBoundingClientRect()
    const startX = from.left + from.width / 2 - rect.width / 2
    const startY = from.top + from.height / 2 - rect.height / 2
    const endX = to.left + to.width / 2 - rect.width / 2
    const endY = to.top + to.height / 2 - rect.height / 2
    chip.style.left = `${startX}px`
    chip.style.top = `${startY}px`

    const dx = endX - startX
    const dy = endY - startY
    chip.animate(
      [
        { transform: "translate(0, 0) scale(0.6)", opacity: 0 },
        { transform: "translate(0, -12px) scale(1.1)", opacity: 1, offset: 0.15 },
        { transform: `translate(${dx * 0.5}px, ${dy * 0.5 - 40}px) scale(1)`, opacity: 1, offset: 0.55 },
        { transform: `translate(${dx}px, ${dy}px) scale(0.5)`, opacity: 0 }
      ],
      { duration: 900, easing: "cubic-bezier(0.4, 0, 0.2, 1)" }
    ).onfinish = () => chip.remove()
  }

  countUp(el, from, to) {
    if (this.reduced) { el.textContent = this.brl(to); return }
    const duration = 800
    const start = performance.now()
    const tick = (now) => {
      const t = Math.min(1, (now - start) / duration)
      const eased = 1 - Math.pow(1 - t, 3)
      el.textContent = this.brl(from + (to - from) * eased)
      if (t < 1) requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  }

  shake(el) {
    el.animate(
      [{ transform: "translateX(0)" }, { transform: "translateX(-6px)" }, { transform: "translateX(6px)" }, { transform: "translateX(0)" }],
      { duration: 300 }
    )
    el.focus()
  }

  confetti(origin) {
    this.cancelConfetti?.()
    this.cancelConfetti = launchConfetti(origin)
  }

  // --- Utilidades --------------------------------------------------------

  scrollTo(index) {
    if (window.innerWidth >= 992) return
    this.stepTargets[index].scrollIntoView({ behavior: this.reduced ? "auto" : "smooth", block: "center" })
  }

  after(ms, fn) {
    this.timers ||= []
    this.timers.push(setTimeout(fn, ms))
  }

  clearTimers() {
    this.timers?.forEach((t) => clearTimeout(t))
    this.timers = []
  }

  parseAmount(text) {
    return Number(String(text).replace(/\./g, "").replace(",", "."))
  }

  brl(value) {
    return value.toLocaleString("pt-BR", { style: "currency", currency: "BRL", minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
