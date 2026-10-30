extends "res://TelaFim.gd"
## Estojo no estilo caderno (protótipo de 30/10/2026): gastar tinta em dano,
## corações e cadência, com o card da roleta (caneta + papel), nível em
## bolinhas e o resultado da compra ("23 → 28 de dano").
## Fica dentro do Hub (aba Estojo): o papel, o cabeçalho e a barra de abas são
## do Hub, então esta tela não cobre nada e não bloqueia toques fora dos botões.
## O Hub chama mostrar(montar_dados(save)) e compra no sinal upar(chave);
## depois chama mostrar() de novo com "comprado" = chave para animar.
## versao: "A" (fichas largas empilhadas) ou "B" (3 cartas em pé).

signal upar(chave: String)

const CARD_IMAGEM := "res://assets/ui/card_roleta.png"
const CARD_MARGENS := Vector4(40, 40, 55, 55)
const ITENS := [
	{"chave": "nivel_dano", "nome": "Dano da Caneta", "nome_b": "Dano da\nCaneta",
		"icone": "res://assets/upgrade1.svg", "unidade": "de dano"},
	{"chave": "nivel_hp", "nome": "Corações", "nome_b": "Corações",
		"icone": "res://assets/upgrade2.svg", "unidade": "corações"},
	{"chave": "nivel_cadencia", "nome": "Cadência de Tiro", "nome_b": "Cadência\nde Tiro",
		"icone": "res://assets/upgrade3.svg", "unidade": ""},
]

var versao := "A"
var _bloco: Control
var _estilo_card: StyleBoxTexture
var _btns: Array = []

func _montar_fixo() -> void:
	# O Hub já tem papel, cabeçalho e abas: esta tela só desenha o miolo
	_papel.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_estilo_card = StyleBoxTexture.new()
	_estilo_card.texture = load(CARD_IMAGEM)
	_estilo_card.texture_margin_left = CARD_MARGENS.x
	_estilo_card.texture_margin_top = CARD_MARGENS.y
	_estilo_card.texture_margin_right = CARD_MARGENS.z
	_estilo_card.texture_margin_bottom = CARD_MARGENS.w
	_bloco = Control.new()
	_bloco.size = Vector2(1080, 1920)
	_bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_bloco)

## Monta os 3 itens a partir do save (níveis, custos e curvas do GameData).
static func montar_dados(save: Dictionary) -> Dictionary:
	var itens: Array = []
	var tinta := int(save["tinta"])
	for it in ITENS:
		var nivel := int(save[it["chave"]])
		var curva: Array = _curva(it["chave"])
		var maximo: bool = nivel >= GameData.NIVEL_MAX_ESTOJO
		var custo: int = 0 if maximo else int(GameData.CUSTOS_ESTOJO[nivel - 1])
		var d: Dictionary = it.duplicate()
		d["nivel"] = nivel
		d["maximo"] = maximo
		d["custo"] = custo
		d["falta"] = max(0, custo - tinta)
		d["atual"] = _valor(it["chave"], curva[nivel])
		d["proximo"] = "" if maximo else _valor(it["chave"], curva[nivel + 1])
		itens.append(d)
	return {"tinta": tinta, "itens": itens}

static func _curva(chave: String) -> Array:
	match chave:
		"nivel_dano":
			return GameData.DANO_POR_NIVEL
		"nivel_hp":
			return GameData.HP_POR_NIVEL
	return GameData.CADENCIA_POR_NIVEL

## Cadência em segundos com vírgula ("0,56 s"); o resto inteiro.
static func _valor(chave: String, v) -> String:
	if chave == "nivel_cadencia":
		return ("%.2f s" % v).replace(".", ",")
	return str(v)

## d: tinta, itens (de montar_dados); "comprado": chave que acabou de subir.
func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	_btns.clear()
	_txt(_bloco, "MEU ESTOJO", 74, AZUL_ESCURO, 318, 418)
	_traco(_bloco, 300, 780, 432, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(_bloco, "Melhorias para todas as partidas.", 44, AZUL, 455, 515)
	var cartas: Array = _cartas_em_pe(d["itens"]) if versao == "B" else _fichas(d["itens"])
	var comprado: String = d.get("comprado", "")
	if comprado != "":
		_animar_compra(cartas[_indice(comprado)])

func _indice(chave: String) -> int:
	for k in range(ITENS.size()):
		if ITENS[k]["chave"] == chave:
			return k
	return 0

# ------------------------------------------------------------
# Versão A: fichas largas, uma por linha
# ------------------------------------------------------------
func _fichas(itens: Array) -> Array:
	var cartas: Array = []
	var alt := 320.0
	var y := 560.0
	for it in itens:
		var c := _carta(Rect2(70, y, 940, alt))
		cartas.append(c)
		var dx := 0.0
		if versao == "A2":
			_etiqueta(c)
			dx = 22.0
		_icone_em(c, it["icone"], Rect2(84, 70, 170, 170) if versao == "A2" else Rect2(40, 62, 190, 190))
		# Nome e "Nv. 4" na mesma linha
		var linha := _linha(c, Vector2(255 + dx, 28), 560, 76, BoxContainer.ALIGNMENT_BEGIN)
		linha.add_child(_lbl(it["nome"], FONTE, 52, AZUL_ESCURO))
		linha.add_child(_lbl("  Nv. %d" % int(it["nivel"]), NUM, 52, AZUL))
		if versao == "A2":
			_tracinhos(c, Vector2(265 + dx, 140), int(it["nivel"]), it["chave"] == _dados.get("comprado", ""))
		else:
			_bolinhas(c, Vector2(275, 140), int(it["nivel"]), 34.0, 12.0, 10)
		# Resultado da compra
		var ef := _linha(c, Vector2(255 + dx, 178), 420, 76, BoxContainer.ALIGNMENT_BEGIN)
		_efeito(ef, it, 58)
		_zona_compra(c, it, Rect2(680, 112, 225, 140))
		y += alt + 34.0
	return cartas

# ------------------------------------------------------------
# Versão B: 3 cartas em pé lado a lado (como o descanso)
# ------------------------------------------------------------
func _cartas_em_pe(itens: Array) -> Array:
	var cartas: Array = []
	var larg := 318.0
	var alt := 960.0
	var vao := 22.0
	var x0: float = (1080.0 - (3 * larg + 2 * vao)) / 2.0
	for k in range(itens.size()):
		var it: Dictionary = itens[k]
		var c := _carta(Rect2(x0 + k * (larg + vao), 560, larg, alt))
		cartas.append(c)
		_icone_em(c, it["icone"], Rect2((larg - 210) / 2.0 - 8, 40, 210, 210))
		# Nome com espaço para 2 linhas; o de 1 linha fica no meio dessa altura
		var nome := _txt(c, it["nome_b"], 46, AZUL_ESCURO, 262, 372, FONTE, 14, larg - 30)
		nome.add_theme_constant_override("line_spacing", -8)
		_txt(c, "Nv. %d" % int(it["nivel"]), 54, AZUL, 380, 440, NUM, 0, larg - 16)
		# 10 níveis em 2 linhas de 5 bolinhas
		var cx: float = (larg - 16) / 2.0 - 2 * 40.0
		_bolinhas(c, Vector2(cx, 470), int(it["nivel"]), 40.0, 14.0, 5)
		_bolinhas(c, Vector2(cx, 512), int(it["nivel"]) - 5, 40.0, 14.0, 5)
		# Resultado: número grande e a unidade embaixo
		var ef := _txt(c, _texto_efeito(it), 60, AZUL, 550, 630, NUM, 10, larg - 26)
		ef.autowrap_mode = TextServer.AUTOWRAP_WORD
		var un: String = it["unidade"] if it["unidade"] != "" else "entre tiros"
		_txt(c, un, 42, AZUL_ESCURO, 630, 690, FONTE, 10, larg - 26)
		_zona_compra(c, it, Rect2(22, 740, larg - 60, 150))
	return cartas

# ------------------------------------------------------------
# Peças
# ------------------------------------------------------------
func _carta(r: Rect2) -> Control:
	var c := Control.new()
	c.position = r.position
	c.size = r.size
	c.pivot_offset = r.size / 2.0
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func(): c.draw_style_box(_estilo_card, Rect2(Vector2.ZERO, c.size)))
	_bloco.add_child(c)
	return c

func _texto_efeito(it: Dictionary) -> String:
	if it["maximo"]:
		return it["atual"]
	return "%s → %s" % [it["atual"], it["proximo"]]

## "23 → 28 de dano" (número em Caveat azul, unidade em letra de texto).
func _efeito(linha: HBoxContainer, it: Dictionary, tam: int) -> void:
	linha.add_child(_lbl(_texto_efeito(it), NUM, tam, AZUL))
	if it["unidade"] != "":
		# Letra de texto mais baixa que o número: desce para a mesma linha de base
		var un := _lbl(" " + it["unidade"], FONTE, 42, AZUL_ESCURO)
		un.size_flags_vertical = Control.SIZE_SHRINK_END
		un.custom_minimum_size.y = 62
		linha.add_child(un)

## Botão de compra: cheio (SUBIR + gota + custo) quando dá para pagar;
## contorno com o custo apagado e "faltam N" quando não dá; no nível 10,
## "MÁXIMO ✓" em verde, sem botão.
func _zona_compra(c: Control, it: Dictionary, r: Rect2) -> void:
	if it["maximo"]:
		var mx := _txt(c, "NÍVEL\nMÁXIMO ✓", 44, VERDE, r.position.y, r.end.y, FONTE, r.position.x, r.end.x)
		mx.add_theme_constant_override("line_spacing", -12)
		return
	var pode: bool = int(it["falta"]) == 0
	var b: Button
	if pode:
		b = _botao_cheio("", r)
	else:
		b = _botao_contorno(r)
		_linha_anuncio.queue_free()
	b.reparent(c, false)
	b.position = r.position
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", -8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 4.0
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)
	var cor: Color = Color.WHITE if pode else Color(AZUL_ESCURO, 0.5)
	if pode:
		var l := _lbl("SUBIR", FONTE, 42, Color.WHITE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
	var preco := HBoxContainer.new()
	preco.alignment = BoxContainer.ALIGNMENT_CENTER
	preco.add_theme_constant_override("separation", 8)
	preco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# No azul, a gota desenhada em branco (tools/gerar_gota_branca.gd)
	var gota := _icone("res://assets/ui/gota_branca.png" if pode else "res://assets/ink.svg", 50 if pode else 46)
	if not pode:
		gota.modulate = Color(1, 1, 1, 0.5)
	preco.add_child(gota)
	preco.add_child(_lbl(_milhar(int(it["custo"])), NUM, 56, cor))
	col.add_child(preco)
	if not pode:
		var f := _lbl("faltam %s" % _milhar(int(it["falta"])), NUM, 44, AZUL_ESCURO)
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(f)
	var chave: String = it["chave"]
	b.pressed.connect(func(): upar.emit(chave))
	_btns.append(b)

## n bolinhas de nível (cheias até "nivel"), com contorno de caneta.
func _bolinhas(pai: Control, inicio: Vector2, nivel: int, passo: float, raio: float, n: int) -> void:
	var d := Control.new()
	d.size = pai.size
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.draw.connect(func():
		for q in range(n):
			var c := inicio + Vector2(q * passo, 0) + Vector2(sin(q * 2.3) * 0.8, cos(q * 1.7) * 0.8)
			if q < nivel:
				d.draw_circle(c, raio, AZUL)
			d.draw_arc(c, raio, 0, TAU, 32, AZUL_ESCURO, 3.0, true))
	pai.add_child(d)

## Cara de etiqueta: margem vermelha vertical (como a do caderno) e um furo
## à esquerda, mostrando o papel por baixo.
func _etiqueta(c: Control) -> void:
	var e := Control.new()
	e.size = c.size
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	e.draw.connect(func():
		var x := 66.0
		var pts: PackedVector2Array = []
		for i in range(13):
			var y: float = lerp(16.0, c.size.y - 30.0, float(i) / 12.0)
			pts.append(Vector2(x + sin(i * 1.7) * 1.2, y))
		e.draw_polyline(pts, Color(VERMELHO, 0.7), 3.5, true)
		var f := Vector2(38, c.size.y / 2.0 - 6)
		e.draw_circle(f, 13, Color("f3efe6"))
		e.draw_arc(f, 13, 0, TAU, 32, Color(AZUL_ESCURO, 0.85), 3.0, true)
		# Sombra de dentro do furo (borda de cima), para parecer vazado
		e.draw_arc(f, 9, PI * 1.1, PI * 1.9, 12, Color(AZUL_ESCURO, 0.3), 3.0, true))
	c.add_child(e)

## Tracinhos de contagem escolar: grupos de 5 (4 riscos + corte na diagonal),
## os níveis que faltam bem apagados. Na compra, o traço novo é "escrito"
## em ~0,25 s.
func _tracinhos(pai: Control, inicio: Vector2, nivel: int, animar: bool) -> void:
	var d := Control.new()
	d.size = pai.size
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.set_meta("p", 0.0 if animar else 1.0)
	var alt := 44.0
	var passo := 22.0
	d.draw.connect(func():
		var p: float = d.get_meta("p")
		for i in range(GameData.NIVEL_MAX_ESTOJO):
			var g := i / 5
			var k := i % 5
			var bx: float = inicio.x + g * (4 * passo + 44.0)
			var a: Vector2
			var b: Vector2
			if k < 4:
				var x: float = bx + k * passo
				var tilt: float = 2.5 if i % 2 == 0 else -2.0
				a = Vector2(x + tilt, inicio.y - alt / 2.0)
				b = Vector2(x - tilt, inicio.y + alt / 2.0)
			else:
				a = Vector2(bx - 10, inicio.y + alt / 2.0 - 6)
				b = Vector2(bx + 3 * passo + 10, inicio.y - alt / 2.0 + 6)
			var novo: bool = animar and i == nivel - 1
			if i >= nivel or (novo and p < 1.0):
				d.draw_line(a, b, Color(AZUL_ESCURO, 0.16), 4.5, true)
			if i < nivel:
				d.draw_line(a, a.lerp(b, p) if novo else b, AZUL, 4.5, true))
	pai.add_child(d)
	if animar:
		var t := d.create_tween()
		t.tween_method(func(v: float):
			d.set_meta("p", v)
			d.queue_redraw(), 0.0, 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _linha(pai: Control, pos: Vector2, larg: float, alt: float, alinh: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = alinh
	h.add_theme_constant_override("separation", 0)
	h.position = pos
	h.size = Vector2(larg, alt)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(h)
	return h

func _lbl(t: String, f: Font, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _icone(caminho: String, lado: float) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = load(caminho)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(lado, lado)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic

func _icone_em(pai: Control, caminho: String, r: Rect2) -> void:
	var ic := _icone(caminho, r.size.x)
	ic.position = r.position
	ic.size = r.size
	pai.add_child(ic)

## Compra feita: a carta pulsa e os botões só voltam a aceitar toque depois.
func _animar_compra(carta: Control) -> void:
	for b in _btns:
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween()
	t.tween_property(carta, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(carta, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_interval(0.1)
	t.tween_callback(func():
		for b in _btns:
			if is_instance_valid(b):
				b.mouse_filter = Control.MOUSE_FILTER_STOP)
