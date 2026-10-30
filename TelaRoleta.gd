extends "res://TelaFim.gd"
## Roleta de melhorias (páginas 2, 4 e 6) no estilo caderno.
## 3 cartas com miolo branco e contorno de caneta sobre o papel da fase.
## As cartas só aceitam toque depois da animação de entrada (ícones girando)
## + 0,35 s: o dedo ainda pode estar na tela quando a página termina.
## O Main monta os dados (mostrar) e aplica a escolha (sinal escolhido).

signal escolhido(indice: int)
signal icone_parou

## "A" = tocar na carta escolhe; "B" = tocar marca e o botão ESCOLHER confirma.
var versao := "A"

const CINZA_TEXTO := Color("3d3d4a")
const AZUL_CLARINHO := Color("e3edfc")
const VAO_TEXTOS := 28.0 # espaço igual entre nome, nível, descrição e efeito
const CARD_IMAGEM := "res://assets/ui/card_roleta.png" # caneta + papel (ChatGPT)
const CARD_MARGENS := Vector4(40, 40, 55, 55) # cantos preservados ao esticar
const ALT_LINHA_RODAPE := 110.0
const ICONES_1A_LINHA := 3
const LARG_CARTA := 960.0
const LADO_ICONE := 200.0
const COL_ICONE := 250.0 # largura da coluna do ícone (ícone + nível embaixo)

var _titulo: Label
var _sub: Label
var _cartas: Array = [] # {botao, icone, nome, desc, efeito, nivel}
var _rodape: VBoxContainer
var _lbl_pagina: Label
var _btn_escolher: Button
var _cab: Control
var _selecionada := -1
var _liberado := false
var _icones_giro: Array = []
var _estilo_card: StyleBoxTexture = null

## Usa uma imagem de card (nine-patch) no lugar do contorno desenhado em código.
## margens = cantos preservados ao esticar (em pixels da imagem).
func usar_card_imagem(tex: Texture2D, margens: Vector4) -> void:
	_estilo_card = StyleBoxTexture.new()
	_estilo_card.texture = tex
	_estilo_card.texture_margin_left = margens.x
	_estilo_card.texture_margin_top = margens.y
	_estilo_card.texture_margin_right = margens.z
	_estilo_card.texture_margin_bottom = margens.w
	for c in _cartas:
		c["botao"].queue_redraw()

func _montar_fixo() -> void:
	# Cabeçalho num bloco só, que desce/sobe para centrar a tela
	_cab = Control.new()
	_cab.size = Vector2(1080, 300)
	_cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_cab)
	_lbl_pagina = _txt(_cab, "", 48, AZUL_ESCURO, 0, 60, NUM)
	_titulo = _txt(_cab, "ESCOLHA UMA MELHORIA", 68, AZUL_ESCURO, 70, 170)
	_traco(_cab, 150, 930, 178, Color(AZUL_ESCURO, 0.85), 5.0)
	_sub = _txt(_cab, "", 44, AZUL, 200, 260)
	for i in range(3):
		_cartas.append(_criar_carta(i))
	# Card desenhado (contorno de caneta + papel); sem a imagem, cai no contorno em código
	if ResourceLoader.exists(CARD_IMAGEM):
		usar_card_imagem(load(CARD_IMAGEM), CARD_MARGENS)
	# "Nesta partida:" + ícones das melhorias que já tem
	# 1ª linha: "Nesta partida:" + até 3 ícones; do 4º em diante, 2ª linha centrada
	_rodape = VBoxContainer.new()
	_rodape.add_theme_constant_override("separation", 6)
	_rodape.size = Vector2(1080, ALT_LINHA_RODAPE)
	_rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_rodape)
	_btn_escolher = _botao_cheio("ESCOLHER", BOTAO_VOLTAR)
	_btn_escolher.pressed.connect(func():
		if _liberado and _selecionada >= 0:
			_confirmar(_selecionada))

func _criar_carta(i: int) -> Dictionary:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.size = Vector2(LARG_CARTA, 330)
	b.pivot_offset = b.size / 2.0
	for e in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	_conteudo.add_child(b)
	b.draw.connect(func(): _desenhar_carta(b, i))
	b.pressed.connect(func(): _tocou_carta(i))

	var ic := TextureRect.new()
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size = Vector2(LADO_ICONE, LADO_ICONE)
	ic.pivot_offset = ic.size / 2.0
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)

	var x0 := COL_ICONE + 26.0
	var larg: float = LARG_CARTA - x0 - 36.0
	var nome := _txt(b, "", 52, AZUL_ESCURO, 0, 0, FONTE, x0, x0 + larg, HORIZONTAL_ALIGNMENT_LEFT)
	var desc := _txt(b, "", 42, CINZA_TEXTO, 0, 0, FONTE, x0, x0 + larg, HORIZONTAL_ALIGNMENT_LEFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.add_theme_constant_override("line_spacing", -6)
	var efeito := _txt(b, "", 54, AZUL, 0, 0, NUM, x0, x0 + larg, HORIZONTAL_ALIGNMENT_LEFT)
	# Nível ("Nv. 1 → 2") ou "NOVO" em marca-texto, embaixo do ícone
	var nivel := Control.new()
	nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nivel)
	return {"botao": b, "icone": ic, "nome": nome, "desc": desc, "efeito": efeito, "nivel": nivel, "x0": x0, "larg": larg}

## Card em imagem (assets/ui/card_roleta.png) ou, sem ela, miolo branco +
## contorno de caneta em código. Tocada: azul clarinho + ✓ no canto.
func _desenhar_carta(b: Button, i: int) -> void:
	var w := b.size.x
	var h := b.size.y
	var sel := (i == _selecionada)
	if _estilo_card:
		# Card desenhado (imagem do ChatGPT) esticado sem deformar os cantos;
		# a tocada recebe um tom azul clarinho por cima
		b.draw_style_box(_estilo_card, Rect2(Vector2.ZERO, b.size))
		if sel:
			# Véu azul clarinho por cima do papel (mantém a textura, sem acinzentar)
			var veu := StyleBoxFlat.new()
			veu.bg_color = Color(AZUL_CLARINHO, 0.7)
			veu.set_corner_radius_all(30)
			b.draw_style_box(veu, Rect2(10, 10, w - 20, h - 20))
			var c := Vector2(w - 8, 8)
			b.draw_circle(c, 34, AZUL)
			b.draw_polyline(PackedVector2Array([c + Vector2(-15, 1), c + Vector2(-4, 12), c + Vector2(16, -11)]),
				Color.WHITE, 7.0, true)
		return
	# Selecionada: miolo azul bem clarinho (destaca no papel); as outras, branco
	var miolo: Color = AZUL_CLARINHO if sel else Color.WHITE
	b.draw_rect(Rect2(6, 6, w - 12, h - 12), miolo)
	var pts := _contorno_torto(w, h, 26.0, i)
	b.draw_polyline(pts, AZUL if sel else Color(AZUL_ESCURO, 0.9), 7.0 if sel else 4.0, true)
	if sel:
		var c := Vector2(w - 8, 8)
		b.draw_circle(c, 34, AZUL)
		b.draw_polyline(PackedVector2Array([c + Vector2(-15, 1), c + Vector2(-4, 12), c + Vector2(16, -11)]),
			Color.WHITE, 7.0, true)

func _contorno_torto(w: float, h: float, r: float, semente: int) -> PackedVector2Array:
	var m := 2.0
	var cantos := [[Vector2(w - m - r, m + r), -PI / 2.0], [Vector2(w - m - r, h - m - r), 0.0],
		[Vector2(m + r, h - m - r), PI / 2.0], [Vector2(m + r, m + r), PI]]
	var pts: PackedVector2Array = []
	var idx := semente * 13
	for c in cantos:
		for k in range(9):
			var a: float = c[1] + float(k) / 8.0 * PI / 2.0
			pts.append(c[0] + Vector2(cos(a), sin(a)) * r + Vector2(sin(idx * 7.31), cos(idx * 5.17)) * 1.6)
			idx += 1
	pts.append(pts[0] + Vector2(-18, -2.0))
	return pts

## d: cap, pagina, total_paginas, opcoes (3x {nome, descricao, efeito, icone,
## nivel_atual, consumivel}), ja_tem ([{icone, nivel}]), icones_giro ([caminhos]).
func mostrar(d: Dictionary) -> void:
	_dados = d
	_papel.configurar_para_capitulo(int(d["cap"]))
	_icones_giro = d.get("icones_giro", [])
	_lbl_pagina.text = "Página %d  de %d" % [int(d["pagina"]), int(d["total_paginas"])]
	_selecionada = -1
	_liberado = false
	var b_layout := versao == "B"
	_sub.text = "Toque em uma e confirme." if b_layout else "Toque em uma carta para escolher."
	var alt := 340.0 if b_layout else 360.0
	var vao := 22.0 if b_layout else 44.0
	var gap_rodape := 14.0 if b_layout else 40.0
	# B: botão ESCOLHER fixo no polegar (BOTAO_VOLTAR); A: bloco centrado
	var linhas_rodape: int = 1 if d.get("ja_tem", []).size() <= ICONES_1A_LINHA else 2
	var alt_rodape: float = linhas_rodape * ALT_LINHA_RODAPE + (linhas_rodape - 1) * 6.0
	var bloco: float = 320.0 + 3 * alt + 2 * vao + gap_rodape + alt_rodape
	# B: o bloco termina antes do botão ESCOLHER (y 1580)
	var topo: float = max(20.0, min(50.0, 1570.0 - bloco)) if b_layout else (1920.0 - bloco) / 2.0
	_cab.position = Vector2(0, topo)
	var y0 := topo + 320.0
	for i in range(3):
		var c: Dictionary = _cartas[i]
		var op: Dictionary = d["opcoes"][i]
		var b: Button = c["botao"]
		b.size = Vector2(LARG_CARTA, alt)
		b.pivot_offset = b.size / 2.0
		b.position = Vector2((1080.0 - LARG_CARTA) / 2.0, y0 + i * (alt + vao))
		b.set_meta("pos", b.position)
		b.modulate = Color.WHITE
		b.scale = Vector2.ONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic: TextureRect = c["icone"]
		b.set_meta("cons", op.get("consumivel", false))
		ic.position = _pos_icone(alt, op.get("consumivel", false))
		ic.texture = load(op["icone"])
		_preencher_textos(c, op, alt)
		b.queue_redraw()
	_montar_rodape(d.get("ja_tem", []))
	_rodape.position = Vector2(0, y0 + 3 * alt + 2 * vao + gap_rodape)
	_btn_escolher.visible = b_layout
	_btn_escolher.modulate.a = 0.0
	_btn_escolher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animar_entrada()

## Ícone na coluna da esquerda, centrado na altura da carta.
func _pos_icone(alt: float, _consumivel := false) -> Vector2:
	var y: float = (alt - LADO_ICONE) / 2.0
	return Vector2(14 + (COL_ICONE - LADO_ICONE) / 2.0, y)

func _preencher_textos(c: Dictionary, op: Dictionary, alt: float) -> void:
	var larg: float = c["larg"]
	var nome: Label = c["nome"]
	nome.text = String(op["nome"]).replace("\n", " ")
	var tam := 52
	while tam > 42 and FONTE.get_string_size(nome.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > larg:
		tam -= 2
	nome.add_theme_font_size_override("font_size", tam)
	# Ordem: nome → nível (se tiver) → descrição → efeito
	var com_nivel: bool = not op.get("consumivel", false)
	var desc: Label = c["desc"]
	desc.text = String(op["descricao"]).replace("\n", " ")
	var duas_linhas: bool = FONTE.get_string_size(desc.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x > larg
	var efeito: Label = c["efeito"]
	efeito.text = String(op["efeito"]).replace("\n", " ")
	var nv: Control = c["nivel"]
	for f in nv.get_children():
		f.queue_free()
	nv.visible = com_nivel
	# Cada elemento entra com a faixa de tinta dele (topo das letras → linha de
	# base, medidas nas fontes do jogo) e o MESMO vão entre um e outro; o bloco
	# fica centrado na carta (margens de cima e de baixo maiores, como antes).
	var k: float = tam / 52.0
	var itens: Array = [[nome, 16.0 * k, 52.0 * k, 73.0 * k]]
	if com_nivel:
		var atual := int(op["nivel_atual"])
		if atual <= 0:
			var t := "NOVO"
			var w: float = FONTE.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x + 30.0
			var faixa := ColorRect.new()
			faixa.color = Color(1.0, 0.92, 0.35, 0.8)
			faixa.position = Vector2(-10, 0)
			faixa.size = Vector2(w, 52)
			faixa.rotation_degrees = -2.0
			faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nv.add_child(faixa)
			_txt(nv, t, 42, AZUL_ESCURO, 0, 59, FONTE, -10, w - 10)
			itens.append([nv, 0.0, 52.0, 59.0])
		else:
			_txt(nv, "Nv. %d → %d" % [atual, atual + 1], 50, AZUL_ESCURO, 0, 69, NUM, 0, larg,
				HORIZONTAL_ALIGNMENT_LEFT)
			itens.append([nv, 18.0, 48.0, 69.0])
	var linhas_desc: int = 2 if duas_linhas else 1
	itens.append([desc, 13.0, 42.0 + (linhas_desc - 1) * 53.0, 59.0 + (linhas_desc - 1) * 53.0])
	itens.append([efeito, 13.0, 52.0, 69.0])
	var total: float = VAO_TEXTOS * (itens.size() - 1)
	for it in itens:
		total += it[2] - it[1]
	var y_tinta: float = (alt - total) / 2.0
	for it in itens:
		var n: Control = it[0]
		n.position = Vector2(c["x0"], y_tinta - it[1])
		n.size = Vector2(larg, it[3])
		y_tinta += it[2] - it[1] + VAO_TEXTOS

func _linha_rodape() -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 34)
	linha.custom_minimum_size = Vector2(1080, ALT_LINHA_RODAPE)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rodape.add_child(linha)
	return linha

func _montar_rodape(ja_tem: Array) -> void:
	for f in _rodape.get_children():
		_rodape.remove_child(f)
		f.queue_free()
	var linha := _linha_rodape()
	if ja_tem.is_empty():
		linha.add_child(_lbl_rodape("Primeira melhoria da partida", FONTE, 50, AZUL_ESCURO))
		return
	linha.add_child(_lbl_rodape("Nesta partida:", FONTE, 50, AZUL_ESCURO))
	for n in range(ja_tem.size()):
		var item: Dictionary = ja_tem[n]
		if n == ICONES_1A_LINHA:
			linha = _linha_rodape()
		var grupo := HBoxContainer.new()
		grupo.add_theme_constant_override("separation", 4)
		grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_child(grupo)
		var ic := TextureRect.new()
		ic.texture = load(item["icone"])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(100, 100)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grupo.add_child(ic)
		grupo.add_child(_lbl_rodape(str(int(item["nivel"])), NUM, 62, AZUL))

func _lbl_rodape(t: String, f: Font, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# ------------------------------------------------------------
# Animação: cartas entram uma a uma e os ícones giram até parar
# ------------------------------------------------------------
func _animar_entrada() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_animando = true
	_pular.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	for i in range(3):
		var c: Dictionary = _cartas[i]
		var b: Button = c["botao"]
		var pos: Vector2 = b.get_meta("pos")
		b.modulate.a = 0.0
		b.position = pos + Vector2(0, 40)
		_tween.tween_property(b, "modulate:a", 1.0, 0.18).set_delay(i * 0.08)
		_tween.tween_property(b, "position", pos, 0.25).set_delay(i * 0.08) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var final: Texture2D = c["icone"].texture
		var dur := 0.5 + i * 0.15
		var voltas := 7 + i * 2
		_tween.tween_method(func(v: float): _girar_icone(c, v, voltas, final), 0.0, 1.0, dur) \
			.set_delay(i * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_callback(func(): _parou(c)).set_delay(i * 0.08 + dur)
	_tween.chain().tween_callback(_finalizar_animacao)

func _girar_icone(c: Dictionary, v: float, voltas: int, final: Texture2D) -> void:
	var ic: TextureRect = c["icone"]
	if v >= 1.0 or _icones_giro.is_empty():
		ic.texture = final
		ic.position.y = _pos_icone(c["botao"].size.y, c["botao"].get_meta("cons", false)).y
		return
	var passo := int(v * voltas)
	ic.texture = load(_icones_giro[(passo * 7 + c["botao"].get_index()) % _icones_giro.size()])
	# cada troca "cai" um pouco, como a fita de uma roleta
	ic.position.y = _pos_icone(c["botao"].size.y, c["botao"].get_meta("cons", false)).y - 30.0 * (1.0 - fmod(v * voltas, 1.0))

func _parou(c: Dictionary) -> void:
	icone_parou.emit()
	var ic: TextureRect = c["icone"]
	ic.position.y = _pos_icone(c["botao"].size.y, c["botao"].get_meta("cons", false)).y
	ic.scale = Vector2(1.12, 1.12)
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(ic, "scale", Vector2.ONE, 0.15)

func _finalizar_animacao() -> void:
	if not _animando:
		return
	_animando = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_pular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in _cartas:
		var b: Button = c["botao"]
		b.modulate.a = 1.0
		b.position = b.get_meta("pos")
		_girar_icone(c, 1.0, 1, _texturas_finais()[_cartas.find(c)])
		c["icone"].scale = Vector2.ONE
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if versao == "B":
		t.tween_property(_btn_escolher, "modulate:a", 0.45, 0.15)
	t.tween_interval(0.35)
	t.tween_callback(func():
		_liberado = true
		for c in _cartas:
			c["botao"].mouse_filter = Control.MOUSE_FILTER_STOP)

func _texturas_finais() -> Array:
	var out: Array = []
	for op in _dados.get("opcoes", []):
		out.append(load(op["icone"]))
	return out

func voltar_do_sistema() -> bool:
	if _animando:
		_finalizar_animacao()
	return true # a roleta não fecha pelo voltar: a escolha é obrigatória

# ------------------------------------------------------------
# Escolha
# ------------------------------------------------------------
func _tocou_carta(i: int) -> void:
	if not _liberado:
		return
	if versao == "B":
		_selecionada = i
		for c in _cartas:
			c["botao"].queue_redraw()
		_btn_escolher.modulate.a = 1.0
		_btn_escolher.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	_selecionada = i
	_cartas[i]["botao"].queue_redraw()
	_confirmar(i)

func _confirmar(i: int) -> void:
	_liberado = false
	_btn_escolher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in _cartas:
		c["botao"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	var b: Button = _cartas[i]["botao"]
	t.tween_property(b, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(b, "scale", Vector2.ONE, 0.12)
	for k in range(3):
		if k != i:
			t.parallel().tween_property(_cartas[k]["botao"], "modulate:a", 0.0, 0.3)
	t.chain().tween_interval(0.15)
	t.chain().tween_callback(func(): escolhido.emit(i))

## Para prints e testes: marca uma carta sem confirmar (versão B).
func marcar_para_print(i: int) -> void:
	_selecionada = i
	for c in _cartas:
		c["botao"].queue_redraw()
	_btn_escolher.modulate.a = 1.0

## Monta os dados de mostrar() a partir das 3 opções sorteadas e do jogador
## (usado pelo Main e pelos prints).
static func montar_dados(opcoes: Array, player: Node, cap: int, pagina: int, total: int) -> Dictionary:
	var gd: Node = player.get_node("/root/GameData")
	var ops: Array = []
	for up in opcoes:
		var atual: int = player.nivel_upgrade(up["id"])
		var idx: int = clamp(atual, 0, up["stats"].size() - 1)
		ops.append({"nome": up["nome"], "descricao": up["descricao"], "efeito": up["stats"][idx],
			"icone": up["icone"], "nivel_atual": atual, "consumivel": up.get("consumivel", false)})
	var ja_tem: Array = []
	for id in player.upgrades.keys():
		var u: Dictionary = gd.get_upgrade(id)
		if not u.is_empty() and int(player.upgrades[id]) > 0:
			ja_tem.append({"icone": u["icone"], "nivel": player.upgrades[id]})
	var giro: Array = []
	for u in gd.UPGRADES:
		giro.append(u["icone"])
	return {"cap": cap, "pagina": pagina, "total_paginas": total, "opcoes": ops, "ja_tem": ja_tem, "icones_giro": giro}
