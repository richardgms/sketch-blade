extends SceneTree
## Protótipos da nova tela de derrota ("Página arruinada", 29/10/2026),
## montados por cima da derrota real do jogo, sem mexer no Main.gd.
## Uso: Godot --path . -s tools/prototipo_derrota.gd -- <pasta>
## (faça backup do save do PC antes, como no capturar_telas)

const FONTE := preload("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
const NUM := preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")
const AZUL := Color("0047ab")
const AZUL_ESCURO := Color("002867")
const VERMELHO := Color("c62828")
const BOTAO_RISCADO := "res://assets/ui/botao_riscado.png"
const CAP := 5
const TOTAL := 8

var _sv: SubViewport
var _saida := ""
var _conteudo: Control

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/derrota-nova/v1"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	# A: com arte. Morreu na página 6, recorde 7.
	await _caso("A-pagina6", "A", 6, 7)
	# A: morreu no chefe, recorde novo (antes 6).
	await _caso("A-chefe-recorde", "A", 8, 6)
	# B: enxuta, trilha como herói.
	await _caso("B-pagina6", "B", 6, 7)
	quit()

func _caso(nome: String, versao: String, pagina: int, recorde_antes: int) -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = 640; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = CAP; d["capitulo_selecionado"] = CAP
	d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}
	d["stats"]["melhor_pagina"] = {str(CAP): recorde_antes}
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var m: Node = load("res://main.tscn").instantiate(); _sv.add_child(m)
	await create_timer(1.0).timeout
	m.player.invencivel = true
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.capitulo_atual = CAP
	m.wave_manager.pagina_atual = pagina
	m.tinta_partida = 180; m.monstros_derrotados_partida = 23
	m._processar_fim_de_jogo(false); m.menu_game_over.visible = true
	await create_timer(0.3).timeout
	var tf: int = int(m.tinta_final_ultima_run)
	var dados := {
		"pagina": pagina, "recorde_antes": recorde_antes,
		"tinta_partida": 180, "bonus_cap": tf - 180, "tinta_final": tf,
		"xp_ganho": 23, "nivel": int(d["nivel_conta"]), "xp": int(d["xp_conta"]),
		"xp_req": int(m.get_xp_necessario_para_nivel(int(d["nivel_conta"]))),
	}
	_montar(m, versao, dados)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[prototipo_derrota] ", nome)
	paused = false
	_sv.queue_free(); await process_frame; await process_frame

# ------------------------------------------------------------
func _montar(m: Node, versao: String, d: Dictionary) -> void:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	m.menu_game_over.add_child(c)
	var papel := ColorRect.new()
	papel.set_script(preload("res://Paper.gd"))
	papel.desenhar_margem = false
	c.add_child(papel)
	papel.configurar_para_capitulo(CAP)
	_conteudo = Control.new()
	_conteudo.size = Vector2(1080, 1920)
	c.add_child(_conteudo)

	var pagina: int = d["pagina"]
	var no_chefe: bool = pagina >= TOTAL
	var recorde_novo: bool = pagina > int(d["recorde_antes"])
	var recorde: int = max(pagina, int(d["recorde_antes"]))

	_txt(_conteudo, "PÁGINA ARRUINADA!", 74, VERMELHO, 70, 170)
	_traco(_conteudo, 170, 910, 180, Color(VERMELHO, 0.85), 5.0)

	var y: float
	if versao == "A":
		# Arte: o chefe (colorido, ele venceu) se morreu nele; senão o desenho do capítulo
		var arte := TextureRect.new()
		arte.texture = load(preload("res://Boss.gd").FICHAS[CAP]["arte"] if no_chefe else "res://assets/images/stage%d.png" % CAP)
		arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		arte.position = Vector2(240, 225)
		arte.size = Vector2(600, 470)
		_conteudo.add_child(arte)
		y = 712.0
	else:
		y = 470.0

	var nome_chefe: String = preload("res://Boss.gd").FICHAS[CAP]["nome"]
	var frase := (nome_chefe.capitalize().substr(0, 1) + nome_chefe.substr(1) + " venceu desta vez!") if no_chefe else "Você chegou à página %d  de %d" % [pagina, TOTAL]
	_txt(_conteudo, frase, 46 if versao == "A" else 54, AZUL_ESCURO, y, y + 64)
	# Trilha: casas vencidas cheias, casa da derrota com X vermelho, recorde em azul claro
	var alt_trilha: float = 100.0 if versao == "A" else 150.0
	var trilha := Control.new()
	trilha.position = Vector2(100, y + 80)
	trilha.size = Vector2(880, alt_trilha)
	trilha.draw.connect(func(): _desenhar_trilha(trilha, pagina, recorde, versao == "B"))
	_conteudo.add_child(trilha)
	y += 80.0 + alt_trilha + 14.0
	if recorde_novo:
		_marca_texto(_conteudo, "Novo recorde!", y)
	else:
		_txt(_conteudo, "Melhor tentativa: página %d  de %d" % [recorde, TOTAL], 42, AZUL, y, y + 70)
	if versao == "B":
		_txt(_conteudo, "Nova tentativa começa na página 1.", 40, AZUL, y + 90, y + 150)

	# Tinta guardada (herói) + linhas + XP
	var yt: float = 1075.0 if versao == "A" else 1130.0
	_txt(_conteudo, "Tinta guardada", 46, AZUL_ESCURO, yt - 60, yt)
	var texto_total := "+%s tinta" % _milhar(int(d["tinta_final"]))
	var tw: float = NUM.get_string_size(texto_total, HORIZONTAL_ALIGNMENT_LEFT, -1, 120).x
	var x0: float = 540.0 - (tw + 104.0) / 2.0
	var gota := TextureRect.new()
	gota.texture = load("res://assets/ink.svg")
	gota.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gota.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gota.size = Vector2(90, 90)
	gota.position = Vector2(x0, yt + 18)
	_conteudo.add_child(gota)
	_txt(_conteudo, texto_total, 120, AZUL, yt - 10, yt + 130, NUM, x0 + 104, x0 + 104 + tw + 40, HORIZONTAL_ALIGNMENT_LEFT)
	var linhas: Array = [["Tinta coletada", int(d["tinta_partida"])]]
	if int(d["bonus_cap"]) > 0:
		linhas.append(["Bônus do capítulo", int(d["bonus_cap"])])
	var yl: float = yt + 140.0
	for i in linhas.size():
		var yy := yl + i * 58.0
		_txt(_conteudo, linhas[i][0], 42, AZUL_ESCURO, yy, yy + 56, FONTE, 220, 700, HORIZONTAL_ALIGNMENT_LEFT)
		_txt(_conteudo, "+" + _milhar(linhas[i][1]), 46, AZUL_ESCURO, yy, yy + 56, NUM, 700, 860, HORIZONTAL_ALIGNMENT_RIGHT)
	var y_xp: float = yl + linhas.size() * 58.0 + 30.0
	_traco(_conteudo, 200, 880, y_xp - 12.0, Color(AZUL_ESCURO, 0.45), 2.5)
	var frac: float = clamp(float(d["xp"]) / max(1.0, float(d["xp_req"])), 0.0, 1.0)
	var barra := Control.new()
	barra.position = Vector2(200, y_xp)
	barra.size = Vector2(680, 60)
	barra.draw.connect(func():
		var r := Rect2(100, 14, 400, 30)
		barra.draw_rect(r, Color.WHITE)
		barra.draw_rect(Rect2(r.position, Vector2(r.size.x * frac, r.size.y)), AZUL)
		barra.draw_rect(r, AZUL_ESCURO, false, 3.0)
		barra.draw_string(NUM, Vector2(0, 43), "Nv. %d" % int(d["nivel"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 42, AZUL_ESCURO)
		barra.draw_string(NUM, Vector2(518, 43), "+%d XP" % int(d["xp_ganho"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, AZUL_ESCURO))
	_conteudo.add_child(barra)

	if versao == "A":
		_txt(_conteudo, "Nova tentativa começa na página 1.", 40, AZUL, 1478, 1538)
	_botao_cheio("VOLTAR AO CADERNO", Rect2(130, 1580, 820, 125))
	_botao_anuncio(Rect2(150, 1740, 780, 100), int(d["tinta_final"]))

# ------------------------------------------------------------
func _desenhar_trilha(c: Control, pagina: int, recorde: int, grande: bool) -> void:
	var y: float = c.size.y / 2.0
	var r_pag: float = 30.0 if grande else 22.0
	var r_chefe: float = 54.0 if grande else 42.0
	var x0: float = r_pag + 4.0
	var x_chefe: float = c.size.x - r_chefe - 6.0
	var passo: float = (x_chefe - r_chefe - r_pag - 34.0 - x0) / float(TOTAL - 2)
	var xs: Array = []
	for i in range(TOTAL - 1):
		xs.append(x0 + passo * i)
	xs.append(x_chefe)
	for i in range(TOTAL - 1):
		var rb: float = r_chefe if i == TOTAL - 2 else r_pag
		c.draw_line(Vector2(xs[i] + r_pag, y), Vector2(xs[i + 1] - rb, y), AZUL_ESCURO, 3.0, true)
	for i in range(TOTAL):
		var casa: int = i + 1
		var centro := Vector2(xs[i], y)
		var r: float = r_chefe if casa == TOTAL else r_pag
		var cor_fundo := Color(1, 1, 1, 0.95)
		if casa < pagina:
			cor_fundo = AZUL
		elif casa > pagina and casa <= recorde:
			cor_fundo = Color("b9cdee") # recorde ainda à frente
		_disco(c, centro, r, cor_fundo)
		_circulo_caneta(c, centro, r, AZUL_ESCURO, 4.0 if casa == TOTAL else 3.0, i)
		if casa == TOTAL and casa != pagina:
			var tam: int = 66 if grande else 56
			var w: float = FONTE.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
			c.draw_string(FONTE, centro + Vector2(-w / 2.0, tam * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, AZUL_ESCURO)
		if grande and casa < TOTAL:
			var n := str(casa)
			var wn: float = NUM.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
			c.draw_string(NUM, centro + Vector2(-wn / 2.0, r + 44), n, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, AZUL_ESCURO)
		if casa == pagina:
			# X de caneta vermelha por cima da casa onde caiu
			var k: float = r * 1.05
			c.draw_line(centro + Vector2(-k, -k), centro + Vector2(k, k * 0.9), VERMELHO, 7.0, true)
			c.draw_line(centro + Vector2(k * 0.95, -k), centro + Vector2(-k, k), VERMELHO, 7.0, true)

func _disco(c: Control, centro: Vector2, raio: float, cor: Color) -> void:
	var pts: PackedVector2Array = []
	for i in range(48):
		var t: float = float(i) / 48.0 * TAU
		pts.append(centro + Vector2(cos(t), sin(t)) * raio)
	c.draw_colored_polygon(pts, cor)

func _circulo_caneta(c: Control, centro: Vector2, raio: float, cor: Color, esp: float, semente: int) -> void:
	var pts: PackedVector2Array = []
	for i in range(49):
		var t: float = float(i) / 48.0 * TAU * 1.06 + semente
		pts.append(centro + Vector2(cos(t), sin(t)) * (raio + sin(i * 2.1 + semente) * 0.8))
	c.draw_polyline(pts, cor, esp, true)

func _txt(pai: Control, t: String, tam: int, cor: Color, y0: float, y1: float, fonte: Font = FONTE,
		x0: float = 0.0, x1: float = 1080.0, alinh := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.horizontal_alignment = alinh
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(x0, y0)
	l.size = Vector2(x1 - x0, y1 - y0)
	pai.add_child(l)
	return l

func _traco(pai: Control, x0: float, x1: float, y: float, cor: Color, esp: float) -> void:
	var c := Control.new()
	c.size = Vector2(1080, 1920)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var pts: PackedVector2Array = []
		for i in range(21):
			pts.append(Vector2(lerp(x0, x1, float(i) / 20.0), y + sin(i * 1.9 + y) * 1.2))
		c.draw_polyline(pts, cor, esp, true))
	pai.add_child(c)

func _marca_texto(pai: Control, t: String, y: float) -> void:
	var w: float = FONTE.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 50).x + 60.0
	var faixa := ColorRect.new()
	faixa.color = Color(1.0, 0.92, 0.35, 0.75)
	faixa.position = Vector2(540 - w / 2.0, y + 6)
	faixa.size = Vector2(w, 66)
	faixa.rotation_degrees = -1.0
	pai.add_child(faixa)
	_txt(pai, t, 50, AZUL_ESCURO, y, y + 78)

func _botao_cheio(t: String, rect: Rect2) -> void:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", FONTE)
	b.add_theme_font_size_override("font_size", 60)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(AZUL_ESCURO, 0.6))
	b.add_theme_constant_override("outline_size", 6)
	var st := StyleBoxTexture.new()
	st.texture = load(BOTAO_RISCADO)
	st.texture_margin_left = 48.0
	st.texture_margin_right = 48.0
	st.texture_margin_top = 36.0
	st.texture_margin_bottom = 36.0
	for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_content_margin(lado, 6.0)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.position = rect.position
	b.size = rect.size
	_conteudo.add_child(b)

func _botao_anuncio(rect: Rect2, valor: int) -> void:
	var b := Button.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(14)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.position = rect.position
	b.size = rect.size
	b.draw.connect(func():
		var r := 22.0
		var m := -6.0
		var w := b.size.x
		var h := b.size.y
		var cantos := [[Vector2(w - m - r, m + r), -PI / 2.0], [Vector2(w - m - r, h - m - r), 0.0],
			[Vector2(m + r, h - m - r), PI / 2.0], [Vector2(m + r, m + r), PI]]
		var pts: PackedVector2Array = []
		var idx := 0
		for c in cantos:
			for i in range(9):
				var a: float = c[1] + float(i) / 8.0 * PI / 2.0
				pts.append(c[0] + Vector2(cos(a), sin(a)) * r + Vector2(3, 3)
					+ Vector2(sin(idx * 7.31), cos(idx * 5.17)) * 1.2)
				idx += 1
		pts.append(pts[0] + Vector2(-14, -1.5))
		b.draw_polyline(pts, Color(AZUL_ESCURO, 0.9), 3.5, true))
	_conteudo.add_child(b)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 14)
	linha.set_anchors_preset(Control.PRESET_FULL_RECT)
	linha.offset_top = 6.0
	b.add_child(linha)
	for p in [["res://assets/ads.svg", ""], ["", "Ver anúncio ·"], ["res://assets/ink.svg", ""], ["", "+" + _milhar(valor)]]:
		if p[0] != "":
			var ic := TextureRect.new()
			ic.texture = load(p[0])
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(58, 58)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if p[0].ends_with("ads.svg"):
				ic.modulate = AZUL
			linha.add_child(ic)
		else:
			var numero: bool = p[1].begins_with("+")
			var l := Label.new()
			l.text = p[1]
			l.add_theme_font_override("font", NUM if numero else FONTE)
			l.add_theme_font_size_override("font_size", 58 if numero else 46)
			l.add_theme_color_override("font_color", AZUL)
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			linha.add_child(l)

static func _milhar(n: int) -> String:
	var s := str(abs(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
