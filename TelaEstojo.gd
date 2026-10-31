extends "res://TelaFim.gd"
## Estojo no estilo caderno (aprovado em 30/10/2026): gastar tinta em dano,
## corações e cadência. Fichas com o card da roleta (caneta + papel), margem
## vermelha e furo de etiqueta, nível em tracinhos de contagem e o resultado
## da compra ("23 → 28 de dano").
## Fica dentro do Hub (aba Estojo): o papel, o cabeçalho e a barra de abas são
## do Hub, então esta tela não cobre nada e não bloqueia toques fora dos botões.
## O Hub chama mostrar(montar_dados(save)) e compra no sinal upar(chave);
## depois chama mostrar() de novo com "comprado" = chave para animar.

signal upar(chave: String)

const CARD_IMAGEM := "res://assets/ui/card_roleta.png"
const CARD_MARGENS := Vector4(40, 40, 55, 55)
const BOTAO_FALTA := "res://assets/ui/botao_falta.png"
const BOTAO_MAXIMO := "res://assets/ui/botao_maximo.png"
const ITENS := [
	{"chave": "nivel_dano", "nome": "Dano da Caneta",
		"icone": "res://assets/upgrade1.svg", "unidade": "de dano"},
	{"chave": "nivel_hp", "nome": "Corações",
		"icone": "res://assets/upgrade2.svg", "unidade": "corações"},
	{"chave": "nivel_cadencia", "nome": "Cadência de Tiro",
		"icone": "res://assets/upgrade3.svg", "unidade": ""},
]

var _bloco: Control
var _estilo_card: StyleBoxTexture
var _btns: Array = []
var _fichas_atuais: Array = []

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
	var cartas: Array = _fichas(d["itens"])
	_fichas_atuais = cartas
	var comprado: String = d.get("comprado", "")
	if comprado != "":
		_animar_compra(cartas[_indice(comprado)])

func _indice(chave: String) -> int:
	for k in range(ITENS.size()):
		if ITENS[k]["chave"] == chave:
			return k
	return 0

## Uma ficha larga por melhoria: desenho | nome, tracinhos e resultado | botão.
func _fichas(itens: Array) -> Array:
	var cartas: Array = []
	var alt := 320.0
	var y := 560.0
	for it in itens:
		var c := _carta(Rect2(50, y, 980, alt))
		cartas.append(c)
		_etiqueta(c)
		var dx := 22.0
		_icone_em(c, it["icone"], Rect2(84, 70, 170, 170))
		# Nome e "Nv. 4" na mesma linha
		var linha := _linha(c, Vector2(255 + dx, 36), 560, 76, BoxContainer.ALIGNMENT_BEGIN)
		linha.add_child(_lbl(it["nome"], FONTE, 52, AZUL_ESCURO))
		linha.add_child(_lbl("  Nv. %d" % int(it["nivel"]), NUM, 52, AZUL))
		_tracinhos(c, Vector2(265 + dx, 148), int(it["nivel"]), it["chave"] == _dados.get("comprado", ""))
		# Resultado da compra
		var ef := _linha(c, Vector2(255 + dx, 186), 420, 76, BoxContainer.ALIGNMENT_BEGIN)
		_efeito(ef, it, 58)
		# Botão no meio da ficha, na altura do desenho e dos textos (~150,
		# medido nos prints); se o nome + nível chega até a coluna do botão,
		# ele desce para o meio dos tracinhos e do resultado.
		var fim_nome: float = 255 + dx + FONTE.get_string_size(it["nome"], HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x \
			+ NUM.get_string_size("  Nv. %d" % int(it["nivel"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x
		_zona_compra(c, it, Rect2(688, 80 if fim_nome < 680.0 else 112, 252, 140))
		y += alt + 34.0
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

## Botão de compra: azul riscado (SUBIR + gota + custo) quando dá para pagar;
## riscado clarinho com o custo apagado e "faltam N" quando não dá; no nível
## 10, selo verde riscado "NÍVEL MÁXIMO ✓" (sem toque). Texturas do ChatGPT,
## originais em Documentos\Sketch Blade - design\estojo-novo\gerados\.
func _zona_compra(c: Control, it: Dictionary, r: Rect2) -> void:
	if it["maximo"]:
		var selo := Panel.new()
		selo.add_theme_stylebox_override("panel", _estilo_riscado(BOTAO_MAXIMO))
		selo.position = r.position
		selo.size = r.size
		selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(selo)
		var mx := _txt(selo, "NÍVEL\nMÁXIMO ✓", 40, Color.WHITE, 4, r.size.y, FONTE, 0, r.size.x)
		mx.add_theme_constant_override("line_spacing", -12)
		mx.add_theme_color_override("font_outline_color", Color(VERDE, 0.6))
		mx.add_theme_constant_override("outline_size", 6)
		return
	var pode: bool = int(it["falta"]) == 0
	var b := _botao_cheio("", r)
	if not pode:
		var st := _estilo_riscado(BOTAO_FALTA)
		var st_p: StyleBoxTexture = st.duplicate()
		st_p.modulate_color = Color(0.85, 0.85, 0.9)
		for e in ["normal", "hover"]:
			b.add_theme_stylebox_override(e, st)
		b.add_theme_stylebox_override("pressed", st_p)
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
	preco.add_child(_lbl(_milhar(int(it["custo"])), NUM, 52, cor))
	col.add_child(preco)
	if not pode:
		var f := _lbl("faltam %s" % _milhar(int(it["falta"])), NUM, 42, AZUL_ESCURO)
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(f)
	var chave: String = it["chave"]
	b.pressed.connect(func(): upar.emit(chave))
	_btns.append(b)

## Fundo riscado (mesmas margens do botão azul).
func _estilo_riscado(caminho: String) -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = load(caminho)
	st.texture_margin_left = 48.0
	st.texture_margin_right = 48.0
	st.texture_margin_top = 36.0
	st.texture_margin_bottom = 36.0
	# Sem isso a margem da textura vira margem do texto e o botão alarga
	for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_content_margin(lado, 6.0)
	return st

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

## Sem tinta: a ficha treme (o Hub oferece o pacote em seguida).
func negar(chave: String) -> void:
	var k := _indice(chave)
	if k >= _fichas_atuais.size() or not is_instance_valid(_fichas_atuais[k]):
		return
	var c: Control = _fichas_atuais[k]
	var x0: float = c.position.x
	var t := create_tween()
	t.tween_property(c, "position:x", x0 - 15, 0.05)
	t.tween_property(c, "position:x", x0 + 15, 0.05)
	t.tween_property(c, "position:x", x0, 0.05)
