// Confete em canvas próprio (sem lib): explode a partir de um elemento e cai com gravidade.
// Compartilhado pela demo da landing (demo_controller) e pelas celebrações do app (celebrate_controller).
// Retorna uma função que cancela a animação e remove o canvas.
const COLORS = ["#10b981", "#34d399", "#f59e0b", "#3b82f6", "#ec4899", "#a78bfa"]

export function launchConfetti(origin, { count = 160, duration = 2700 } = {}) {
  const canvas = document.createElement("canvas")
  canvas.className = "ec-confetti"
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight
  document.body.appendChild(canvas)

  const ctx = canvas.getContext("2d")
  const rect = origin.getBoundingClientRect()
  const cx = rect.left + rect.width / 2
  const cy = rect.top + rect.height * 0.4
  const particles = Array.from({ length: count }, () => {
    const angle = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 1.1
    const speed = 7 + Math.random() * 9
    return {
      x: cx, y: cy,
      vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed,
      w: 6 + Math.random() * 6, h: 4 + Math.random() * 6,
      rot: Math.random() * Math.PI, vr: (Math.random() - 0.5) * 0.3,
      color: COLORS[Math.floor(Math.random() * COLORS.length)],
      life: 1
    }
  })

  let raf = null
  const start = performance.now()
  const frame = (now) => {
    const elapsed = now - start
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    particles.forEach((p) => {
      p.vy += 0.28
      p.vx *= 0.99
      p.x += p.vx
      p.y += p.vy
      p.rot += p.vr
      p.life = Math.max(0, 1 - Math.max(0, elapsed - (duration - 1100)) / 1000)
      ctx.save()
      ctx.globalAlpha = p.life
      ctx.translate(p.x, p.y)
      ctx.rotate(p.rot)
      ctx.fillStyle = p.color
      ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h)
      ctx.restore()
    })
    if (elapsed < duration) raf = requestAnimationFrame(frame)
    else canvas.remove()
  }
  raf = requestAnimationFrame(frame)

  return () => {
    if (raf) cancelAnimationFrame(raf)
    canvas.remove()
  }
}
