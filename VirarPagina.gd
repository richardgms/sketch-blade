extends Control
## Virada de página no estilo caderno (aprovada em 31/10, versão A3 "pelo
## canto"): uma folha pautada do capítulo entra pela direita com "Capítulo N ·
## nome", "Página N" escrito à caneta, traço e a trilha das páginas; depois o
## canto de baixo dobra e a folha descola na diagonal, mostrando o verso (com a
## pauta espelhada e apagada) até sair pelo alto. A folha nunca encolhe: a
## letra não deforma. Dura ~1,4 s (a página espera 1,2 s antes de soltar o
## primeiro monstro, que ainda leva o intervalo da onda). Libera-se no fim.

signal virando # a folha começa a dobrar (som de folhear)

const FONTE := preload("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
const NUM := preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")
const AZUL := Color("0047ab")
const AZUL_ESCURO := Color("002867")
const SOMBRA := Color(0.15, 0.17, 0.25)

var _alt := 1920.0

## d: cap, nome, numero, total.
func iniciar(d: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alt = get_viewport_rect().size.y
	size = Vector2(1080, _alt)
	_folha_pelo_canto(d)

func _folha_pelo_canto(d: Dictionary) -> void:
	var w := 1080.0
	var h := _alt
	var canto := Vector2(w, h)
	var rect := PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
	var papel_ref: ColorRect = preload("res://Paper.gd").new()
	papel_ref.configurar_para_capitulo(int(d["cap"]))
	var cor_verso: Color = papel_ref.color.lightened(0.25)
	var cor_linha: Color = papel_ref.cor_da_linha
	var esp: float = papel_ref.espacamento_linhas
	var grade: bool = papel_ref.tipo_pauta != "pautado"
	papel_ref.free()
	# Linha da dobra: começa mais deitada e endireita para a diagonal (o dedo
	# puxa o canto para cima e depois para a esquerda)
	var dobra := {"s": 0.0, "u": Vector2(-0.35, -1.0).normalized()}
	var sombra := Control.new()
	sombra.size = Vector2(w, h)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)
	# Máscara: só a parte ainda não dobrada da folha aparece
	var mascara := Control.new()
	mascara.size = Vector2(w, h)
	mascara.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mascara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mascara)
	var f := _nova_folha(mascara, d)
	var folha: Control = f["folha"]
	var aba := Control.new()
	aba.size = Vector2(w, h)
	aba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aba)
	var lados := func() -> Array:
		var u: Vector2 = dobra["u"]
		var p0: Vector2 = canto + u * float(dobra["s"])
		var resto := _cortar(rect, p0, u)
		var dobrado := _cortar(rect, p0, -u)
		var refl := PackedVector2Array()
		for x in dobrado:
			refl.append(_refletir(x, p0, u))
		return [resto, dobrado, refl, p0, u]
	mascara.draw.connect(func():
		var g: Array = lados.call()
		if g[0].size() >= 3:
			mascara.draw_colored_polygon(g[0], Color.WHITE))
	aba.draw.connect(func():
		if dobra["s"] <= 0.0:
			return
		var g: Array = lados.call()
		var resto: PackedVector2Array = g[0]
		var dobrado: PackedVector2Array = g[1]
		var poli: PackedVector2Array = g[2]
		var p0: Vector2 = g[3]
		var u: Vector2 = g[4]
		if poli.size() < 3:
			return
		# Sombra que a aba projeta na folha, junto da dobra
		if resto.size() >= 3:
			for i in range(8):
				var faixa := _cortar(_cortar(resto, p0 + u * (i * 7.0), u), p0 + u * ((i + 1) * 7.0), -u)
				if faixa.size() >= 3:
					aba.draw_colored_polygon(faixa, Color(SOMBRA, 0.16 * (1.0 - i / 8.0)))
		# Sombra da aba na página de baixo (deslocada para longe da dobra)
		var sh := PackedVector2Array()
		for x in poli:
			sh.append(x - u * 16.0)
		aba.draw_colored_polygon(sh, Color(SOMBRA, 0.14))
		# Verso do papel com a pauta espelhada, bem apagada (vista por trás)
		aba.draw_colored_polygon(poli, cor_verso)
		var linhas: Array = []
		var y := esp
		while y < h:
			linhas.append([Vector2(0, y), Vector2(w, y)])
			y += esp
		if grade:
			var x := esp
			while x < w:
				linhas.append([Vector2(x, 0), Vector2(x, h)])
				x += esp
		for ln in linhas:
			for seg in Geometry2D.clip_polyline_with_polygon(PackedVector2Array(ln), dobrado):
				if seg.size() >= 2:
					aba.draw_line(_refletir(seg[0], p0, u), _refletir(seg[seg.size() - 1], p0, u),
						Color(cor_linha, cor_linha.a * 0.45), 2.0)
		# Papel curvando: claro logo na dobra, depois uma faixa mais escura
		for i in range(12):
			var faixa := _cortar(_cortar(poli, p0 - u * (i * 8.0), -u), p0 - u * ((i + 1) * 8.0), u)
			if faixa.size() < 3:
				continue
			var k := float(i) / 12.0
			var cor := Color(1, 1, 1, 0.35 * (1.0 - k / 0.3)) if k < 0.3 else Color(SOMBRA, 0.10 * sin((k - 0.3) / 0.7 * PI))
			aba.draw_colored_polygon(faixa, cor)
		aba.draw_polyline(poli + PackedVector2Array([poli[0]]), Color(SOMBRA, 0.3), 2.0, true))
	# Sombra da folha na página de baixo ao entrar (borda esquerda)
	sombra.draw.connect(func():
		if folha.position.x > 0.0:
			for i in range(12):
				sombra.draw_rect(Rect2(folha.position.x - (i + 1) * 6.0, 0, 6, h),
					Color(SOMBRA, 0.16 * (1.0 - i / 12.0))))
	folha.position.x = 1080.0
	var t := create_tween()
	t.tween_method(func(v: float):
		folha.position.x = 1080.0 * (1.0 - v)
		sombra.queue_redraw(), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): _escrever(f["bloco"]))
	t.tween_interval(0.65)
	t.tween_callback(func(): virando.emit())
	# Descola: devagar no começo (o canto levanta), rápido no fim
	t.tween_method(func(v: float):
		var u: Vector2 = Vector2(-0.35, -1.0).normalized().slerp(Vector2(-w, -h).normalized(), v)
		dobra["u"] = u
		var fim: float = (Vector2.ZERO - canto).dot(u) + 60.0
		dobra["s"] = fim * v
		mascara.queue_redraw()
		aba.queue_redraw(), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)

static func _refletir(x: Vector2, p0: Vector2, u: Vector2) -> Vector2:
	return x - 2.0 * (x - p0).dot(u) * u

## Parte do polígono convexo do lado em que (x - p0)·n >= 0.
static func _cortar(poli: PackedVector2Array, p0: Vector2, n: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var k := poli.size()
	for i in range(k):
		var a: Vector2 = poli[i]
		var b: Vector2 = poli[(i + 1) % k]
		var da: float = (a - p0).dot(n)
		var db: float = (b - p0).dot(n)
		if da >= 0.0:
			out.append(a)
		if (da >= 0.0) != (db >= 0.0):
			out.append(a + (b - a) * (da / (da - db)))
	# Sem pontos repetidos (a triangulação falha com eles)
	var limpo := PackedVector2Array()
	for x in out:
		if limpo.is_empty() or limpo[limpo.size() - 1].distance_to(x) > 0.5:
			limpo.append(x)
	if limpo.size() > 1 and limpo[0].distance_to(limpo[limpo.size() - 1]) <= 0.5:
		limpo.remove_at(limpo.size() - 1)
	if limpo.size() >= 3 and absf(_area(limpo)) < 4.0:
		return PackedVector2Array()
	return limpo

static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in range(p.size()):
		a += p[i].cross(p[(i + 1) % p.size()])
	return a / 2.0

## Folha pautada do capítulo com o cabeçalho, dentro de um Control que anda.
func _nova_folha(pai: Control, d: Dictionary) -> Dictionary:
	var folha := Control.new()
	folha.size = Vector2(1080, _alt)
	folha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(folha)
	var papel := ColorRect.new()
	papel.set_script(preload("res://Paper.gd"))
	papel.desenhar_margem = false # a linha-limite da caneta é da página, não da folha
	papel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folha.add_child(papel)
	papel.configurar_para_capitulo(int(d["cap"]))
	var bloco := _cabecalho(folha, d, _alt / 2.0 - 230.0)
	return {"folha": folha, "bloco": bloco}

# ------------------------------------------------------------
# Peças
# ------------------------------------------------------------
## "Capítulo N · nome", "Página N" (escrito da esquerda para a direita),
## traço e trilha com a página atual. Devolve as partes para animar.
func _cabecalho(pai: Control, d: Dictionary, y: float) -> Dictionary:
	var raiz := Control.new()
	raiz.size = Vector2(1080, 460)
	raiz.position = Vector2(0, y)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(raiz)
	var sub := _lbl(raiz, "Capítulo %d · %s" % [d["cap"], d["nome"]], FONTE, 44, AZUL, 0, 60)
	# Recorte que cresce = caneta escrevendo
	var clip := Control.new()
	clip.clip_contents = true
	clip.position = Vector2(0, 60)
	clip.size = Vector2(0, 170)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(clip)
	var titulo := _lbl(clip, "Página %d" % d["numero"], NUM, 140, AZUL_ESCURO, 0, 170)
	var w: float = NUM.get_string_size(titulo.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 140).x
	var traco := {"v": 0.0}
	var risco := Control.new()
	risco.size = Vector2(1080, 460)
	risco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	risco.draw.connect(func():
		if traco["v"] <= 0.0:
			return
		var x0 := 540.0 - w / 2.0 - 30.0
		var x1: float = lerp(x0, 540.0 + w / 2.0 + 30.0, traco["v"])
		var pts: PackedVector2Array = []
		for i in range(21):
			var xx: float = lerp(x0, x1, float(i) / 20.0)
			pts.append(Vector2(xx, 240 + sin(i * 1.9) * 1.2))
		risco.draw_polyline(pts, Color(AZUL_ESCURO, 0.85), 5.0, true))
	raiz.add_child(risco)
	var trilha: Control = preload("res://TrilhaPaginas.gd").new()
	trilha.total = int(d["total"])
	trilha.cheias = int(d["numero"]) - 1
	trilha.atual = int(d["numero"]) - 1
	trilha.anel = 0.0
	trilha.position = Vector2(0, 290)
	raiz.add_child(trilha)
	return {"raiz": raiz, "sub": sub, "clip": clip, "w": w, "traco": traco, "risco": risco, "trilha": trilha}

func _escrever(b: Dictionary) -> void:
	var w: float = b["w"]
	var clip: Control = b["clip"]
	clip.size.x = 540.0 - w / 2.0
	var t := create_tween()
	t.tween_property(clip, "size:x", 540.0 + w / 2.0 + 10.0, 0.22)
	t.tween_method(func(v: float):
		b["traco"]["v"] = v
		b["risco"].queue_redraw(), 0.0, 1.0, 0.1)
	t.tween_method(func(v: float):
		b["trilha"].anel = v
		b["trilha"].queue_redraw(), 0.0, 1.0, 0.14)

func _lbl(pai: Control, t: String, f: Font, tam: int, cor: Color, y0: float, y1: float) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y0)
	l.size = Vector2(1080, y1 - y0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(l)
	return l
