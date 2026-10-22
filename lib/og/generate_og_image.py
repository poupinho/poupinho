"""Gera public/og-image.png (1200x630) para Open Graph / WhatsApp usando só o Pillow.

Uso (no host, precisa de python3 + Pillow): python3 lib/og/generate_og_image.py
"""
import os, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
W, H = 1200, 630
OUT = os.path.join(ROOT, "public/og-image.png")


def font(name, size):
    candidates = {
        "bold": ["/usr/share/fonts/truetype/ubuntu/Ubuntu-B.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
        "medium": ["/usr/share/fonts/truetype/ubuntu/Ubuntu-M.ttf", "/usr/share/fonts/truetype/ubuntu/Ubuntu-R.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
        "regular": ["/usr/share/fonts/truetype/ubuntu/Ubuntu-R.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
    }[name]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


# Fundo: gradiente diagonal verde (mesmas cores do ícone) + orbs suaves.
img = Image.new("RGB", (W, H))
px = img.load()
c1, c2 = (4, 120, 87), (16, 185, 129)
for y in range(H):
    for x in range(W):
        t = (x / W * 0.6 + y / H * 0.4)
        px[x, y] = lerp(c1, c2, t)

orbs = Image.new("RGBA", (W, H), (0, 0, 0, 0))
od = ImageDraw.Draw(orbs)
od.ellipse((820, -220, 1420, 380), fill=(110, 231, 183, 110))
od.ellipse((-260, 330, 340, 930), fill=(4, 90, 60, 120))
orbs = orbs.filter(ImageFilter.GaussianBlur(90))
img = Image.alpha_composite(img.convert("RGBA"), orbs)

# Padrão sutil de moedas (círculos) no canto inferior direito.
pat = Image.new("RGBA", (W, H), (0, 0, 0, 0))
pd = ImageDraw.Draw(pat)
for i in range(7):
    for j in range(4):
        cx, cy = 760 + i * 74 + (j % 2) * 37, 400 + j * 64
        pd.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), outline=(255, 255, 255, 38), width=3)
img = Image.alpha_composite(img, pat)

# Card branco com o ícone do app (público/icon.png já tem o porquinho no gradiente).
icon = Image.open(os.path.join(ROOT, "public/icon.png")).convert("RGBA").resize((236, 236), Image.LANCZOS)
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
sd.rounded_rectangle((88, 190, 88 + 236, 190 + 236), radius=56, fill=(0, 40, 25, 130))
shadow = shadow.filter(ImageFilter.GaussianBlur(28))
img = Image.alpha_composite(img, shadow)
img.alpha_composite(icon, (88, 176))

d = ImageDraw.Draw(img)

# Textos
x0 = 372
d.text((x0, 168), "Poupinho", font=font("bold", 118), fill=(255, 255, 255))
d.text((x0 + 4, 300), "Registre o que você deixou de gastar.", font=font("medium", 46), fill=(236, 253, 245))
d.text((x0 + 4, 362), "Pequenas economias, grandes conquistas.", font=font("regular", 34), fill=(209, 250, 229))

# Pills com os recursos (numa camada própria para o alpha compor de verdade).
pills = ["Registro em segundos", "Metas com nome", "Relatórios", "Grátis"]
pf = font("medium", 25)
layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ld = ImageDraw.Draw(layer)
x, y = x0 + 4, 446
for label in pills:
    tw = d.textlength(label, font=pf)
    ld.rounded_rectangle((x, y, x + tw + 34, y + 46), radius=23, fill=(255, 255, 255, 46), outline=(255, 255, 255, 110), width=2)
    ld.text((x + 17, y + 9), label, font=pf, fill=(255, 255, 255, 255))
    x += tw + 34 + 12
img = Image.alpha_composite(img, layer)
d = ImageDraw.Draw(img)

# Rodapé com o domínio
df = font("medium", 28)
d.text((x0 + 4, 548), "poupinho.com.br", font=df, fill=(255, 255, 255))

img.convert("RGB").save(OUT, "PNG", optimize=True)
print(OUT, os.path.getsize(OUT) // 1024, "KB")
