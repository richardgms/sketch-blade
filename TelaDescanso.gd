extends "res://TelaFim.gd"
## Página de descanso (página 4) no estilo caderno: escolher entre curar
## corações ou guardar tinta. Mesmo card da roleta (caneta + papel).
## As cartas só aceitam toque depois da animação de entrada (~0,5 s): a página
## abre logo depois do combate, com o dedo ainda na tela.
## O Main chama mostrar() e aplica a escolha no sinal escolhido("curar"/"tinta").

signal escolhido(id: String)


const CINZA_TEXTO := Color("3d3d4a")
const AZUL_CLARINHO := Color("e3edfc")
const CARD_IMAGEM := "res://assets/ui/card_roleta.png"
const CARD_MARGENS := Vector4(40, 40, 55, 55)
const CORACAO := "res://assets/ui/icone_coracao.png"

var _estilo_card: StyleBoxTexture
var _cab: Control
var _lbl_pagina: Label
var _coracoes: HBoxContainer
var _lbl_vida: Label
var _linha_tinta: HBoxContainer
var _cartas: Array = [] # {botao, id}
var _rodape: Label
var _selecionada := -1
var _liberado := false

func _montar_fixo() -> void:
	_estilo_card = StyleBoxTexture.new()
	_estilo_card.texture = load(CARD_IMAGEM)
	_estilo_card.texture_margin_left = CARD_MARGENS.x
	_estilo_card.texture_margin_top = CARD_MARGENS.y
	_estilo_card.texture_margin_right = CARD_MARGENS.z
	_estilo_card.texture_margin_bottom = CARD_MARGENS.w
	_cab = Control.new()
	_cab.size = Vector2(1080, 300)
	_cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_cab)
	_lbl_pagina = _txt(_cab, "", 48, AZUL_ESCURO, 0, 60, NUM)
	_txt(_cab, "PÁGINA DE DESCANSO", 68, AZUL_ESCURO, 70, 170)
	_traco(_cab, 170, 910, 178, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(_cab, "Recupere vida ou guarde tinta.", 44, AZUL, 200, 260)
	_coracoes = HBoxContainer.new()
	_coracoes.alignment = BoxContainer.ALIGNMENT_CENTER
	_coracoes.size = Vector2(1080, 90)
	_coracoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_coracoes)
	_lbl_vida = _txt(_conteudo, "", 50, AZUL_ESCURO, 0, 0, NUM)
	_linha_tinta = HBoxContainer.new()
	_linha_tinta.alignment = BoxContainer.ALIGNMENT_CENTER
	_linha_tinta.add_theme_constant_override("separation", 14)
	_linha_tinta.size = Vector2(1080, 70)
	_linha_tinta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_linha_tinta)
	for id in ["curar", "tinta"]:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		for e in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
		_conteudo.add_child(b)
		var i := _cartas.size()
		b.draw.connect(func(): _desenhar_carta(b, i))
		b.pressed.connect(func(): _tocou(i))
		_cartas.append({"botao": b, "id": id})
	_rodape = _txt(_conteudo, "Depois vem a roleta de melhorias.", 42, AZUL_ESCURO, 0, 0)

func _desenhar_carta(b: Button, i: int) -> void:
	b.draw_style_box(_estilo_card, Rect2(Vector2.ZERO, b.size))
	if i == _selecionada:
		var veu := StyleBoxFlat.new()
		veu.bg_color = Color(AZUL_CLARINHO, 0.7)
		veu.set_corner_radius_all(30)
		b.draw_style_box(veu, Rect2(10, 10, b.size.x - 20, b.size.y - 20))
		var c := Vector2(b.size.x - 8, 8)
		b.draw_circle(c, 34, AZUL)
		b.draw_polyline(PackedVector2Array([c + Vector2(-15, 1), c + Vector2(-4, 12), c + Vector2(16, -11)]),
			Color.WHITE, 7.0, true)

## d: cap, pagina, total_paginas, vidas, vidas_max, cura, tinta_partida, ganho_tinta
func mostrar(d: Dictionary) -> void:
	_dados = d
	_papel.configurar_para_capitulo(int(d["cap"]))
	_lbl_pagina.text = "Página %d  de %d" % [int(d["pagina"]), int(d["total_paginas"])]
	_selecionada = -1
	_liberado = false
	var vidas := int(d["vidas"])
	var vmax := int(d["vidas_max"])
	var depois: int = min(vidas + int(d["cura"]), vmax)
	var tinta := int(d["tinta_partida"])
	var ganho := int(d["ganho_tinta"])

	# Bloco de cima: cabeçalho + corações + vida + tinta
	# Bloco inteiro (cabeçalho, corações, cartas, rodapé) centrado na tela
	var alt_cartas := 700.0
	var topo: float = (1920.0 - (600.0 + alt_cartas + 110.0)) / 2.0
	_cab.position = Vector2(0, topo)
	_montar_coracoes(vidas, vmax)
	_coracoes.position = Vector2(0, topo + 300)
	_lbl_vida.position = Vector2(0, topo + 398)
	_lbl_vida.size = Vector2(1080, 66)
	_lbl_vida.text = "Vida  %d  de  %d" % [vidas, vmax]
	_montar_linha_tinta(tinta)
	_linha_tinta.position = Vector2(0, topo + 472)

	# Cartas
	var y0 := topo + 600
	var opcoes := {
		"curar": {"nome": "CORRETIVO DA SORTE", "desc": "Cura %d corações" % int(d["cura"]),
			"efeito": ("Vida já está cheia" if vidas >= vmax else "%d → %d corações" % [vidas, depois]),
			"icone": "res://assets/corretivo.png"},
		"tinta": {"nome": "POTE DE TINTA", "desc": "+%d gotas de tinta" % ganho,
			"efeito": "%s → %s tinta" % [_milhar(tinta), _milhar(tinta + ganho)],
			"icone": "res://assets/pote_tinta.png"},
	}
	for i in range(2):
		var c: Dictionary = _cartas[i]
		var b: Button = c["botao"]
		for f in b.get_children():
			f.queue_free()
		var op: Dictionary = opcoes[c["id"]]
		b.size = Vector2(470, 700)
		b.position = Vector2(50 + i * 510, y0)
		_carta_em_pe(b, op)
		b.pivot_offset = b.size / 2.0
		b.set_meta("pos", b.position)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.queue_redraw()
	var fim: float = y0 + alt_cartas
	_rodape.position = Vector2(0, fim + 50)
	_rodape.size = Vector2(1080, 60)
	_animar_entrada()

func _montar_coracoes(vidas: int, vmax: int) -> void:
	for f in _coracoes.get_children():
		_coracoes.remove_child(f)
		f.queue_free()
	var vao := 12.0
	var lado: float = min(84.0, (940.0 - vao * (vmax - 1)) / vmax)
	_coracoes.add_theme_constant_override("separation", int(vao))
	for k in range(vmax):
		var ic := TextureRect.new()
		ic.texture = load(CORACAO)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(lado, lado)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.pivot_offset = Vector2(lado, lado) / 2.0
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if k >= vidas:
			ic.modulate = Color(1, 1, 1, 0.2) # coração perdido: só o contorno apagado
		_coracoes.add_child(ic)

func _montar_linha_tinta(tinta: int) -> void:
	for f in _linha_tinta.get_children():
		_linha_tinta.remove_child(f)
		f.queue_free()
	var gota := TextureRect.new()
	gota.texture = load("res://assets/ink.svg")
	gota.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gota.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gota.custom_minimum_size = Vector2(56, 56)
	gota.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gota.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_linha_tinta.add_child(gota)
	for p in [[_milhar(tinta) + " ", NUM, 54, AZUL], ["de tinta na partida", FONTE, 44, AZUL_ESCURO]]:
		var l := Label.new()
		l.text = p[0]
		l.add_theme_font_override("font", p[1])
		l.add_theme_font_size_override("font_size", p[2])
		l.add_theme_color_override("font_color", p[3])
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_linha_tinta.add_child(l)

## Carta em pé: desenho grande em cima e textos centrados embaixo.
func _carta_em_pe(b: Button, op: Dictionary) -> void:
	_icone(b, op["icone"], Vector2((b.size.x - 270) / 2.0, 46), 270)
	# Nome com espaço para 2 linhas; o de 1 linha fica no meio dessa altura.
	# Descrição e efeito ficam na mesma altura nas duas cartas.
	var nome := _txt(b, op["nome"], 50, AZUL_ESCURO, 336, 476, FONTE, 30, b.size.x - 30)
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD
	nome.add_theme_constant_override("line_spacing", -8)
	_txt(b, op["desc"], 42, CINZA_TEXTO, 496, 556, FONTE, 20, b.size.x - 20)
	var ef := _txt(b, op["efeito"], 52, AZUL, 566, 640, NUM, 20, b.size.x - 20)
	ef.autowrap_mode = TextServer.AUTOWRAP_WORD

func _icone(b: Button, caminho: String, pos: Vector2, lado: float) -> void:
	var ic := TextureRect.new()
	ic.texture = load(caminho)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = pos
	ic.size = Vector2(lado, lado)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)

# ------------------------------------------------------------
# Animação: corações aparecem, cartas sobem; toque só depois de ~0,5 s
# ------------------------------------------------------------
func _animar_entrada() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_animando = true
	_pular.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	var k := 0
	for h in _coracoes.get_children():
		h.scale = Vector2.ZERO
		_tween.tween_property(h, "scale", Vector2.ONE, 0.18).set_delay(k * 0.03) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		k += 1
	for i in range(2):
		var b: Button = _cartas[i]["botao"]
		var pos: Vector2 = b.get_meta("pos")
		b.modulate.a = 0.0
		b.position = pos + Vector2(0, 40)
		_tween.tween_property(b, "modulate:a", 1.0, 0.2).set_delay(0.1 + i * 0.1)
		_tween.tween_property(b, "position", pos, 0.28).set_delay(0.1 + i * 0.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(_finalizar_animacao)

func _finalizar_animacao() -> void:
	if not _animando:
		return
	_animando = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_pular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for h in _coracoes.get_children():
		h.scale = Vector2.ONE
	for c in _cartas:
		c["botao"].modulate.a = 1.0
		c["botao"].position = c["botao"].get_meta("pos")
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(0.25)
	t.tween_callback(func():
		_liberado = true
		for c in _cartas:
			c["botao"].mouse_filter = Control.MOUSE_FILTER_STOP)

func voltar_do_sistema() -> bool:
	if _animando:
		_finalizar_animacao()
	return true # a escolha é obrigatória

func _tocou(i: int) -> void:
	if not _liberado:
		return
	_liberado = false
	_selecionada = i
	for c in _cartas:
		c["botao"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		c["botao"].queue_redraw()
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	var b: Button = _cartas[i]["botao"]
	t.tween_property(b, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(b, "scale", Vector2.ONE, 0.12)
	t.parallel().tween_property(_cartas[1 - i]["botao"], "modulate:a", 0.0, 0.3)
	t.chain().tween_interval(0.15)
	t.chain().tween_callback(func(): escolhido.emit(_cartas[i]["id"]))

## Para prints: marca uma carta sem confirmar.
func marcar_para_print(i: int) -> void:
	_selecionada = i
	for c in _cartas:
		c["botao"].queue_redraw()
