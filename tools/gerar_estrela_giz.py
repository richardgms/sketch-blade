"""Gera assets/ui/estrela_giz.png: estrela à mão, giz de cera amarelo com falhas, contorno de caneta azul."""
import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops
random.seed(7)
S = 512; ESC = 2  # desenha em 2x e reduz (antisserrilhado)
W = S * ESC
def estrela(cx, cy, r_ext, r_int, osc):
    pts = []
    for k in range(10):
        r = (r_ext if k % 2 == 0 else r_int)
        for j in range(12):  # muitos pontos por segmento: tremido
            t = j / 12
            a0 = -math.pi/2 + k*math.pi/5; a1 = -math.pi/2 + (k+1)*math.pi/5
            r0 = r_ext if k % 2 == 0 else r_int; r1 = r_int if k % 2 == 0 else r_ext
            p0 = (cx + math.cos(a0)*r0, cy + math.sin(a0)*r0); p1 = (cx + math.cos(a1)*r1, cy + math.sin(a1)*r1)
            x = p0[0] + (p1[0]-p0[0])*t; y = p0[1] + (p1[1]-p0[1])*t
            ruido = math.sin(k*1.7 + j*0.9) * osc + random.uniform(-osc, osc) * 0.5
            pts.append((x + ruido, y + ruido*0.7))
    return pts
cx = cy = W/2
forma = estrela(cx, cy+W*0.03, W*0.46, W*0.215, W*0.006)
# Máscara arredondada: desenha e "amacia" as pontas com blur + limiar
m = Image.new("L", (W, W), 0); ImageDraw.Draw(m).polygon(forma, fill=255)
m = m.filter(ImageFilter.GaussianBlur(W*0.018)).point(lambda v: 255 if v > 140 else 0)
# Giz de cera: amarelo com veios e algumas falhas brancas
giz = Image.new("RGBA", (W, W), (255, 205, 60, 255))
d = ImageDraw.Draw(giz)
for _ in range(900):  # riscos diagonais de giz em tons próximos
    x = random.uniform(0, W); y = random.uniform(0, W); L = random.uniform(40, 160)
    c = random.choice([(250, 190, 40), (255, 215, 80), (245, 180, 30)])
    d.line([(x, y), (x + L, y - L*0.55)], fill=c + (255,), width=random.randint(4, 10))
falhas = Image.new("L", (W, W), 0); df = ImageDraw.Draw(falhas)
for _ in range(150):  # pontinhos brancos (papel aparecendo)
    x = random.uniform(0, W); y = random.uniform(0, W); r = random.uniform(5, 12)
    df.ellipse([x-r, y-r*0.6, x+r, y+r*0.6], fill=255)
for _ in range(40):
    x = random.uniform(0, W); y = random.uniform(0, W); L = random.uniform(20, 60)
    df.line([(x, y), (x + L, y - L*0.55)], fill=255, width=7)
branco = Image.new("RGBA", (W, W), (255, 253, 245, 255))
giz = Image.composite(branco, giz, falhas)
out = Image.new("RGBA", (W, W), (0, 0, 0, 0)); out.paste(giz, (0, 0), m)
# Contorno de caneta: duas passadas levemente deslocadas
borda = m.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(27))
for dx, dy, a in [(0, 0, 255), (7, -6, 170)]:
    b = ImageChops.offset(borda, dx, dy)
    tinta = Image.new("RGBA", (W, W), (0, 71, 171, a)); out.paste(tinta, (0, 0), b)
out = out.resize((S, S), Image.LANCZOS)
out.save("assets/ui/estrela_giz.png")
print("ok")
