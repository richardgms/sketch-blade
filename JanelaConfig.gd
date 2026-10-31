extends "res://JanelaMissoes.gd"
## Configurações no estilo caderno: a mesma folha arrancada das Missões,
## mais baixa, com som e vibração, "Stats de teste" (só no MODO_TESTE) e
## Fechar. Só o visual: o Hub grava o save pelos sinais.

signal alterar(chave: String, ligado: bool)
signal abrir_stats

var _estado := {}

## d: som, vibracao (bool), teste (mostra Stats de teste), nova.
func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	if _btn_fechar:
		_btn_fechar.queue_free()
	_btns.clear()
	_estado = {"som_ativo": bool(d.get("som", true)), "vibracao_ativa": bool(d.get("vibracao", true))}
	_janela_config(d)
	_btn_fechar.pressed.connect(func(): fechar.emit())
	if d.get("nova", false):
		var todos: Array = _btns + [_btn_fechar]
		for b in todos:
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t := create_tween()
		t.tween_interval(0.4)
		t.tween_callback(func():
			for b in todos:
				if is_instance_valid(b):
					b.mouse_filter = Control.MOUSE_FILTER_STOP)

func _janela_config(d: Dictionary) -> void:
	var teste: bool = d.get("teste", false)
	var meio := 360.0
	var alt: float = 260.0 + meio + (130.0 if teste else 0.0) + 120.0 + 150.0
	var card := Rect2(50, round((1920.0 - alt) / 2.0), 980, alt)
	var c := _folha_curta(card)
	var titulo := HBoxContainer.new()
	titulo.alignment = BoxContainer.ALIGNMENT_CENTER
	titulo.add_theme_constant_override("separation", 34)
	titulo.position = Vector2(0, 86)
	titulo.size = Vector2(card.size.x, 90)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(titulo)
	var eng := _icone("res://assets/config2.svg", 76)
	_pintar(eng, AZUL_ESCURO)
	titulo.add_child(eng)
	titulo.add_child(_lbl("CONFIGURAÇÕES", FONTE, 66, AZUL_ESCURO))
	_traco(c, 150, 830, 188, Color(AZUL_ESCURO, 0.85), 5.0)
	var y := 230.0
	_linha_ajuste(c, Rect2(70, y, 840, 170), "res://assets/volume.svg", "Som", "som_ativo")
	_tracejado(c, 70, 910, y + 175)
	_linha_ajuste(c, Rect2(70, y + 180, 840, 170), "res://assets/vibrate.svg", "Vibração", "vibracao_ativa")
	y += meio + 30.0
	if teste:
		var st := _botao_fechar("Stats de teste", Rect2(card.position.x + 190, card.position.y + y, 600, 100))
		st.pressed.connect(func(): abrir_stats.emit())
		_btns.append(st)
		y += 130.0
	_btn_fechar = _botao_fechar("Fechar", Rect2(card.position.x + 190, card.position.y + y, 600, 100))

## A folha das Missões em 9 partes: picotes em cima e pingo/ponta dobrada
## embaixo ficam inteiros; só o papel liso do meio encolhe.
func _folha_curta(card: Rect2) -> Control:
	var c := Control.new()
	c.position = card.position
	c.size = card.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	_bloco.add_child(c)
	var folha := NinePatchRect.new()
	folha.texture = load(FOLHA)
	folha.patch_margin_top = 90
	folha.patch_margin_bottom = 240
	folha.patch_margin_left = 60
	folha.patch_margin_right = 60
	folha.size = card.size
	folha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(folha)
	return c

## Linha inteira tocável com ícone, nome, "ligado/desligado" e a caixinha
## das Missões à direita. Desligado: ícone apagado e riscado com "/" em
## vermelho suave, desenhado à caneta ao desligar.
func _linha_ajuste(pai: Control, r: Rect2, icone: String, nome: String, chave: String) -> void:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for e in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	b.position = r.position
	b.size = r.size
	pai.add_child(b)
	var ic := _icone(icone, 84)
	ic.position = Vector2(20, r.size.y / 2.0 - 42)
	ic.size = Vector2(84, 84)
	b.add_child(ic)
	var risco := {"p": 0.0 if _estado[chave] else 1.0}
	var traco := Control.new()
	traco.size = r.size
	traco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	traco.draw.connect(func():
		if risco["p"] <= 0.0:
			return
		var a: Vector2 = ic.position + Vector2(6, 90)
		var z: Vector2 = ic.position + Vector2(84, -6)
		var pts: PackedVector2Array = []
		for k in range(9):
			var f: float = risco["p"] * k / 8.0
			pts.append(a.lerp(z, f) + Vector2(sin(k * 1.7) * 1.2, 0))
		traco.draw_polyline(pts, Color(VERMELHO, 0.6), 7.0, true))
	b.add_child(traco)
	_txt(b, nome, 56, AZUL_ESCURO, 18, 92, FONTE, 140, 640, HORIZONTAL_ALIGNMENT_LEFT)
	var est := _txt(b, "", 42, AZUL, 88, 148, FONTE, 140, 640, HORIZONTAL_ALIGNMENT_LEFT)
	var cx := TextureRect.new()
	cx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var lado := 84.0
	var tam: float = lado * 1.35
	cx.position = Vector2(r.size.x - 150, r.size.y / 2.0 - lado / 2.0 + lado - tam)
	cx.size = Vector2(tam, tam)
	cx.pivot_offset = Vector2(lado / 2.0, tam - lado / 2.0)
	cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cx)
	var pintar := func():
		var on: bool = _estado[chave]
		cx.texture = load(CAIXA_MARCADA if on else CAIXA_VAZIA)
		est.text = "ligado" if on else "desligado"
		est.add_theme_color_override("font_color", AZUL if on else Color(AZUL_ESCURO, 0.5))
		_pintar(ic, AZUL_ESCURO if on else Color(AZUL_ESCURO, 0.35))
	pintar.call()
	b.pressed.connect(func():
		_estado[chave] = not _estado[chave]
		pintar.call()
		cx.scale = Vector2(1.25, 1.25)
		create_tween().tween_property(cx, "scale", Vector2.ONE, 0.15)
		# Risca ao desligar; o risco some ao ligar
		var t := create_tween()
		t.tween_method(func(v: float):
			risco["p"] = v
			traco.queue_redraw(), risco["p"], 0.0 if _estado[chave] else 1.0, 0.22)
		alterar.emit(chave, _estado[chave]))
	_btns.append(b)
