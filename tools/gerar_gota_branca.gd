extends SceneTree
## Gera assets/ui/gota_branca.png a partir de assets/ink.svg, para usar em
## cima do azul (botão SUBIR do Estojo): contorno escuro e brilho viram branco,
## o miolo azul fica vazado e mostra o azul do botão.
## Uso: Godot --headless --path . -s tools/gerar_gota_branca.gd

func _initialize() -> void:
	var svg := FileAccess.get_file_as_string("res://assets/ink.svg")
	var img := Image.new()
	img.load_svg_from_string(svg, 256.0 / 72.0)
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var mx: float = max(c.r, max(c.g, c.b))
			var mn: float = min(c.r, min(c.g, c.b))
			var sat: float = mx - mn
			var lum: float = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			# Traço neutro (preto/cinza) ou brilho claro = branco; azul = vazado
			var a: float = 1.0 - smoothstep(0.12, 0.35, sat)
			a = max(a, smoothstep(0.62, 0.8, lum))
			img.set_pixel(x, y, Color(1, 1, 1, c.a * a))
	img.save_png("res://assets/ui/gota_branca.png")
	print("[gota_branca] ", img.get_size())
	quit()
