import { Controller } from "@hotwired/stimulus"

// Card compartilhável: desenha em canvas (1080x1920, formato de stories) o valor
// economizado no período escolhido, com nível e sequência, e entrega pela share
// sheet do celular (navigator.share com arquivo) ou como download da imagem.
// Usage: no modal (controller + values); os períodos são inputs radio com
// data-amount/data-label; render() roda ao abrir o modal e ao trocar o período.
const WIDTH = 1080
const HEIGHT = 1920
const FONT = '-apple-system, BlinkMacSystemFont, "Segoe UI", Inter, Roboto, "Helvetica Neue", Arial, sans-serif'
const PIGGY_GLYPH = ""   // bi-piggy-bank-fill
const FIRE_GLYPH = ""    // bi-fire
const STARS_GLYPH = ""   // bi-stars

// Rodapé: quadro branco do QR e as três linhas de texto abaixo dele. Em pixels
// do card (1080x1920), de cima para baixo.
const QR_BOX = 320
const QR_PADDING = 22
const QR_TOP = 1345
const HINT_Y = 1715
const URL_Y = 1790
const TAGLINE_Y = 1852

export default class extends Controller {
  static targets = ["period", "preview", "share"]
  static values = {
    site: String, url: String, headline: String, tagline: String,
    level: String, streak: String, text: String, file: String,
    qr: String, qrHint: String
  }

  connect() {
    this.canvas = document.createElement("canvas")
    this.canvas.width = WIDTH
    this.canvas.height = HEIGHT
    if (this.canShareFiles()) this.shareTarget.hidden = false
  }

  async render() {
    await this.loadIconFont()
    this.draw()
    this.previewTarget.src = this.canvas.toDataURL("image/png")
  }

  async share() {
    const blob = await new Promise((resolve) => this.canvas.toBlob(resolve, "image/png"))
    const file = new File([blob], this.fileValue, { type: "image/png" })
    if (!navigator.canShare?.({ files: [file] })) return this.download()
    try {
      await navigator.share({ files: [file], text: this.shareText() })
      this.track("share")
    } catch {
      // Usuário fechou a share sheet: nada a fazer.
    }
  }

  download() {
    const link = document.createElement("a")
    link.href = this.canvas.toDataURL("image/png")
    link.download = this.fileValue
    link.click()
    this.track("download")
  }

  // --- período ---

  get period() {
    return this.periodTargets.find((input) => input.checked) || this.periodTargets[0]
  }

  shareText() {
    return this.textValue
      .replace("%{amount}", this.period.dataset.amount)
      .replace("%{label}", this.period.dataset.label)
  }

  // --- desenho ---

  draw() {
    const ctx = this.canvas.getContext("2d")
    const cx = WIDTH / 2

    // Fundo: mesmo degradê do card do total, com círculos translúcidos.
    const gradient = ctx.createLinearGradient(0, 0, WIDTH, HEIGHT)
    gradient.addColorStop(0, "#1fb26f")
    gradient.addColorStop(1, "#4fd08c")
    ctx.fillStyle = gradient
    ctx.fillRect(0, 0, WIDTH, HEIGHT)
    ctx.fillStyle = "rgba(255, 255, 255, 0.12)"
    this.circle(ctx, WIDTH + 40, 140, 420)
    this.circle(ctx, -120, HEIGHT - 260, 360)
    this.circle(ctx, WIDTH - 200, HEIGHT + 120, 300)

    ctx.fillStyle = "#fff"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"

    // Marca no topo: ícone + nome centralizados como um bloco só.
    ctx.font = `800 84px ${FONT}`
    const nameWidth = ctx.measureText(this.siteValue).width
    const iconSpace = this.iconFontReady ? 96 + 24 : 0
    const brandLeft = cx - (iconSpace + nameWidth) / 2
    this.icon(ctx, PIGGY_GLYPH, brandLeft + 48, 300, 96)
    ctx.textAlign = "left"
    ctx.font = `800 84px ${FONT}`
    ctx.fillText(this.siteValue, brandLeft + iconSpace, 300)
    ctx.textAlign = "center"

    // Valor em destaque.
    ctx.font = `500 62px ${FONT}`
    ctx.globalAlpha = 0.92
    ctx.fillText(this.headlineValue, cx, 720)
    ctx.globalAlpha = 1
    ctx.font = `800 ${this.fitSize(ctx, this.period.dataset.amount, 190, WIDTH - 140)}px ${FONT}`
    ctx.fillText(this.period.dataset.amount, cx, 880)
    ctx.font = `600 68px ${FONT}`
    ctx.fillText(this.period.dataset.label, cx, 1030)

    // Chips: nível e sequência.
    const chips = [[STARS_GLYPH, this.levelValue]]
    if (this.streakValue) chips.push([FIRE_GLYPH, this.streakValue])
    let y = 1150
    for (const [glyph, label] of chips) {
      this.chip(ctx, cx, y, glyph, label)
      y += 118
    }

    // Rodapé: QR code, legenda, site e chamada.
    this.qrCode(ctx, cx, QR_TOP)
    ctx.fillStyle = "#fff"
    ctx.font = `500 38px ${FONT}`
    ctx.globalAlpha = 0.85
    ctx.fillText(this.qrHintValue, cx, HINT_Y)
    ctx.globalAlpha = 1
    ctx.font = `800 58px ${FONT}`
    ctx.fillText(this.urlValue, cx, URL_Y)
    ctx.font = `500 40px ${FONT}`
    ctx.globalAlpha = 0.92
    ctx.fillText(this.taglineValue, cx, TAGLINE_Y)
    ctx.globalAlpha = 1
  }

  // QR code num quadro branco arredondado. A matriz vem pronta do servidor, uma
  // string por linha ("1" = módulo preto), então aqui é só pintar quadradinhos.
  // O módulo é arredondado para pixel inteiro, senão o QR sai borrado e a câmera
  // do celular não lê.
  qrCode(ctx, cx, top) {
    const rows = this.qrValue.split(" ").filter((row) => row.length)
    if (!rows.length) return

    const left = cx - QR_BOX / 2
    ctx.fillStyle = "#fff"
    ctx.beginPath()
    ctx.roundRect(left, top, QR_BOX, QR_BOX, 28)
    ctx.fill()

    const module = Math.floor((QR_BOX - QR_PADDING * 2) / rows.length)
    const offset = (QR_BOX - module * rows.length) / 2
    ctx.fillStyle = "#0f3d2a"
    rows.forEach((row, y) => {
      for (let x = 0; x < row.length; x++) {
        if (row[x] !== "1") continue
        ctx.fillRect(left + offset + x * module, top + offset + y * module, module, module)
      }
    })
  }

  circle(ctx, x, y, radius) {
    ctx.beginPath()
    ctx.arc(x, y, radius, 0, Math.PI * 2)
    ctx.fill()
  }

  chip(ctx, cx, y, glyph, label) {
    ctx.font = `600 52px ${FONT}`
    const textWidth = ctx.measureText(label).width
    const iconWidth = this.iconFontReady ? 72 : 0
    const width = textWidth + iconWidth + 96
    const height = 104
    const x = cx - width / 2
    ctx.fillStyle = "rgba(255, 255, 255, 0.2)"
    ctx.beginPath()
    ctx.roundRect(x, y - height / 2, width, height, height / 2)
    ctx.fill()
    ctx.fillStyle = "#fff"
    this.icon(ctx, glyph, x + 48 + 26, y, 54)
    ctx.textAlign = "left"
    ctx.font = `600 52px ${FONT}`
    ctx.fillText(label, x + 48 + iconWidth, y)
    ctx.textAlign = "center"
  }

  // Glifo da fonte bootstrap-icons (só se a fonte carregou; senão fica sem ícone).
  icon(ctx, glyph, x, y, size) {
    if (!this.iconFontReady) return
    const align = ctx.textAlign
    ctx.textAlign = "center"
    ctx.font = `${size}px bootstrap-icons`
    ctx.fillText(glyph, x, y + size * 0.06)
    ctx.textAlign = align
  }

  // Maior tamanho de fonte (até `max`) em que o texto cabe em `width`.
  fitSize(ctx, text, max, width) {
    let size = max
    do {
      ctx.font = `800 ${size}px ${FONT}`
      if (ctx.measureText(text).width <= width) return size
      size -= 10
    } while (size > 80)
    return size
  }

  async loadIconFont() {
    if (this.iconFontReady !== undefined) return
    try {
      await document.fonts.load("64px bootstrap-icons", PIGGY_GLYPH)
      this.iconFontReady = document.fonts.check("64px bootstrap-icons", PIGGY_GLYPH)
    } catch {
      this.iconFontReady = false
    }
  }

  canShareFiles() {
    if (!navigator.canShare) return false
    try {
      return navigator.canShare({ files: [new File([""], "poupinho.png", { type: "image/png" })] })
    } catch {
      return false
    }
  }

  // Evento no analytics (Google Analytics 4), quando configurado.
  track(action) {
    window.gtag?.("event", "share_card", { method: action, period: this.period.value })
  }
}
