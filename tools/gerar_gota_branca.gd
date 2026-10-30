extends SceneTree
## Gera assets/ui/gota_branca.png a partir de assets/ink.svg, para usar em
## cima do azul (botão SUBIR do Estojo): contorno grosso em branco (perto da
## grossura dos números em Caveat Bold do botão), miolo vazado mostrando o azul
## do botão e só o brilho claro do desenho por dentro.
## Uso: Godot --headless --path . -s tools/gerar_gota_branca.gd

## Grossura do contorno (px na imagem de 256; no botão a gota tem ~50 px).
const ANEL := 20.0

func _initialize() -> void:
	var svg := FileAccess.get_file_as_string("res://assets/ink.svg")
	var img := Image.new()
	img.load_svg_from_string(svg, 256.0 / 72.0)
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var dist := _distancia_ate_fora(img)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var d: float = dist[y * w + x]
			# Anel do contorno, com a borda de dentro suavizada
			var a: float = clamp(ANEL + 1.0 - d, 0.0, 1.0)
			# Brilho do desenho (pixels bem claros) continua por dentro
			var lum: float = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			a = max(a, smoothstep(0.78, 0.9, lum))
			out.set_pixel(x, y, Color(1, 1, 1, c.a * a))
	out.save_png("res://assets/ui/gota_branca.png")
	print("[gota_branca] ", out.get_size())
	quit()

## Distância (chanfro 3-4, em px) de cada pixel do desenho até o lado de fora.
func _distancia_ate_fora(img: Image) -> PackedFloat32Array:
	var w := img.get_width()
	var h := img.get_height()
	var d := PackedFloat32Array()
	d.resize(w * h)
	for y in h:
		for x in w:
			d[y * w + x] = 1e6 if img.get_pixel(x, y).a > 0.5 else 0.0
	for y in h:
		for x in w:
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var m: float = d[i]
			if x > 0: m = min(m, d[i - 1] + 3.0)
			if y > 0:
				m = min(m, d[i - w] + 3.0)
				if x > 0: m = min(m, d[i - w - 1] + 4.0)
				if x < w - 1: m = min(m, d[i - w + 1] + 4.0)
			if x == 0 or y == 0: m = min(m, 3.0)
			d[i] = m
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var m: float = d[i]
			if x < w - 1: m = min(m, d[i + 1] + 3.0)
			if y < h - 1:
				m = min(m, d[i + w] + 3.0)
				if x < w - 1: m = min(m, d[i + w + 1] + 4.0)
				if x > 0: m = min(m, d[i + w - 1] + 4.0)
			if x == w - 1 or y == h - 1: m = min(m, 3.0)
			d[i] = m
	for i in d.size():
		d[i] /= 3.0
	return d
