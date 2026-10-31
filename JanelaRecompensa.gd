extends "res://JanelaMissoes.gd"
## Recompensa diária no estilo caderno (aprovada em 31/10/2026, versão A):
## a semana de 7 dias em caixinhas, o prêmio de hoje e os botões COLETAR e
## "Dobrar" (anúncio).
## Só o visual: o Hub calcula o dia, paga e mostra o anúncio pelos sinais
## receber e dobrar; estado "carregando"/"falhou" volta pelo mostrar().

signal receber
signal dobrar

const PRESENTE := "res://assets/gift-box.svg"

var _caixa_hoje: Vector2
var _btn_coletar: Button
var _btn_dobro: Button

## d: dia (1..7), recompensas (GameData.RECOMPENSAS_DIARIAS),
## anuncio: "oferta" | "carregando" | "falhou"; nova: trava os botões 0,4 s.
func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	for b in [_btn_coletar, _btn_dobro]:
		if b:
			b.queue_free()
	_btns.clear()
	_janela_semana(d)
	var estado: String = d.get("anuncio", "oferta")
	_conteudo_dobro(estado, d)
	_btn_coletar.pressed.connect(func(): receber.emit())
	_btn_dobro.pressed.connect(func(): dobrar.emit())
	if estado == "carregando":
		for b in [_btn_coletar, _btn_dobro]:
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.modulate.a = 0.6
	if d.get("nova", false):
		for b in [_btn_coletar, _btn_dobro]:
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t := create_tween()
		t.tween_interval(0.4)
		t.tween_callback(func():
			for b in [_btn_coletar, _btn_dobro]:
				if is_instance_valid(b):
					b.mouse_filter = Control.MOUSE_FILTER_STOP)

# ------------------------------------------------------------
# Janela: folha arrancada (irmã das Missões) com a semana em caixinhas
# ------------------------------------------------------------
func _janela_semana(d: Dictionary) -> void:
	var card := Rect2(50, 330, 980, 1288)
	var c := _folha(card)
	var dia: int = d["dia"]
	# Presente na mesma linha do título (sozinho em cima ficava solto)
	var titulo := HBoxContainer.new()
	titulo.alignment = BoxContainer.ALIGNMENT_CENTER
	titulo.add_theme_constant_override("separation", 18)
	titulo.position = Vector2(0, 86)
	titulo.size = Vector2(card.size.x, 90)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(titulo)
	var pres := _icone(PRESENTE, 76)
	pres.modulate = AZUL_ESCURO
	titulo.add_child(pres)
	titulo.add_child(_lbl("RECOMPENSA DIÁRIA", FONTE, 66, AZUL_ESCURO))
	_traco(c, 150, 830, 188, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(c, "Volte todo dia para ganhar mais.", 42, AZUL, 206, 266, FONTE, 0, card.size.x)
	# Semana: 7 colunas com o dia, a caixinha e o prêmio
	var x0 := 70.0
	var larg := 120.0
	for i in range(7):
		var col := Rect2(x0 + i * larg, 300, larg, 290)
		var feito: bool = i + 1 < dia
		var hoje: bool = i + 1 == dia
		var alfa: float = 0.45 if feito else 1.0
		_txt(c, str(i + 1), 52, Color(AZUL_ESCURO, alfa), col.position.y, col.position.y + 60, NUM,
			col.position.x, col.end.x)
		_caixinha(c, Vector2(col.position.x + 26, col.position.y + 74), {"completa": feito, "coletada": false}, 60.0)
		_premio_pequeno(c, d["recompensas"][i], Rect2(col.position.x, col.position.y + 160, larg, 120), alfa)
		if hoje:
			_caixa_hoje = card.position + Vector2(col.position.x + 26, col.position.y + 74)
			_oval(c, Rect2(col.position.x - 10, col.position.y - 6, larg + 20, col.size.y - 2))
	# Prêmio de hoje bem grande
	_premio_grande(c, d["recompensas"][dia - 1], 640, card.size.x)
	_botoes(card, card.position.y + 880, 700)

# ------------------------------------------------------------
# Peças
# ------------------------------------------------------------
func _folha(card: Rect2) -> Control:
	var c := Control.new()
	c.position = card.position
	c.size = card.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	_bloco.add_child(c)
	var folha := TextureRect.new()
	folha.texture = load(FOLHA)
	folha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	folha.size = card.size
	folha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(folha)
	return c

## Ícone (gota ou clipe) em cima e o valor embaixo, em Caveat.
func _premio_pequeno(pai: Control, rec: Dictionary, r: Rect2, alfa: float) -> void:
	var clipes: bool = rec["clipes"] > 0
	var ic := _icone("res://assets/clip.svg" if clipes else "res://assets/ink.svg", 46)
	ic.position = Vector2(r.position.x + r.size.x / 2.0 - 23, r.position.y)
	ic.size = Vector2(46, 46)
	ic.modulate.a = alfa
	pai.add_child(ic)
	_txt(pai, "+%d" % (rec["clipes"] if clipes else rec["tinta"]), 48, Color(AZUL, alfa),
		r.position.y + 48, r.position.y + 104, NUM, r.position.x, r.end.x)

func _premio_grande(pai: Control, rec: Dictionary, y: float, larg: float) -> void:
	var clipes: bool = rec["clipes"] > 0
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 18)
	linha.position = Vector2(0, y)
	linha.size = Vector2(larg, 170)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(linha)
	linha.add_child(_lbl("+" + _milhar(rec["clipes"] if clipes else rec["tinta"]), NUM, 140, AZUL))
	linha.add_child(_icone("res://assets/clip.svg" if clipes else "res://assets/ink.svg", 120))

## COLETAR em giz azul e, embaixo, o anúncio na pílula de caneta.
func _botoes(card: Rect2, y: float, larg: float) -> void:
	var x: float = card.position.x + (card.size.x - larg) / 2.0
	_btn_coletar = _botao_peca(_conteudo, BTN_COLETAR, 36, 36, Rect2(x, y, larg, 140))
	_btn_coletar.text = "COLETAR"
	_btn_coletar.add_theme_font_override("font", _negrito)
	_btn_coletar.add_theme_font_size_override("font_size", 58)
	for e in ["font_color", "font_hover_color", "font_pressed_color"]:
		_btn_coletar.add_theme_color_override(e, Color.WHITE)
	_btn_coletar.add_theme_color_override("font_outline_color", Color(AZUL_ESCURO, 0.85))
	_btn_coletar.add_theme_constant_override("outline_size", 8)
	_btn_dobro = _botao_fechar("", Rect2(x, y + 170, larg, 110))

func _conteudo_dobro(estado: String, d: Dictionary) -> void:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 12)
	linha.set_anchors_preset(Control.PRESET_FULL_RECT)
	linha.offset_top = 4.0
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_dobro.add_child(linha)
	match estado:
		"carregando":
			linha.add_child(_lbl("Carregando...", FONTE, 44, AZUL))
		"falhou":
			linha.add_child(_lbl("Sem anúncio agora", FONTE, 44, Color(AZUL_ESCURO, 0.6)))
		_:
			var rec: Dictionary = d["recompensas"][int(d["dia"]) - 1]
			var clipes: bool = rec["clipes"] > 0
			var ad := _icone("res://assets/ads.svg", 54)
			ad.modulate = AZUL
			linha.add_child(ad)
			linha.add_child(_lbl("Dobrar", FONTE, 46, AZUL))
			linha.add_child(_icone("res://assets/clip.svg" if clipes else "res://assets/ink.svg", 50))
			linha.add_child(_lbl("+" + _milhar((rec["clipes"] if clipes else rec["tinta"]) * 2), NUM, 56, AZUL))

## Contorno de caneta em volta do dia de hoje.
func _oval(pai: Control, r: Rect2) -> void:
	var t := Control.new()
	t.size = pai.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.draw.connect(func():
		var pts: PackedVector2Array = []
		var centro := r.get_center()
		for i in range(43):
			var a: float = -PI / 2.0 + float(i) / 40.0 * TAU
			var raio := Vector2(r.size.x / 2.0, r.size.y / 2.0) * (1.0 + sin(i * 0.9) * 0.015)
			# Superelipse: cantos mais cheios que a oval, não corta o prêmio
			var cx: float = sign(cos(a)) * pow(abs(cos(a)), 0.5)
			var cy: float = sign(sin(a)) * pow(abs(sin(a)), 0.5)
			pts.append(centro + Vector2(cx * raio.x, cy * raio.y))
		t.draw_polyline(pts, AZUL, 5.0, true))
	pai.add_child(t)

## Depois de pago: marca a caixinha de hoje, trava os botões e some.
func marcar_e_fechar() -> void:
	for b in [_btn_coletar, _btn_dobro]:
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lado := 60.0
	var tam: float = lado * 1.35
	var cx := TextureRect.new()
	cx.texture = load(CAIXA_MARCADA)
	cx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cx.position = Vector2(_caixa_hoje.x, _caixa_hoje.y + lado - tam)
	cx.size = Vector2(tam, tam)
	cx.pivot_offset = cx.size / 2.0
	cx.scale = Vector2(1.4, 1.4)
	cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloco.add_child(cx)
	var t := create_tween()
	t.tween_property(cx, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.45)
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)
