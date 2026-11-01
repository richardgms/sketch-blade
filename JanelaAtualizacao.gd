extends "res://JanelaMissoes.gd"
## Aviso de versão nova no estilo caderno (aprovado em 01/11/2026, versão A):
## a folha arrancada das Missões com "PÁGINA NOVA!", a versão, o que mudou,
## ATUALIZAR e "Agora não".
## Só o visual: o Hub abre a Play Store pelo sinal atualizar.

signal atualizar

## d: versao ("1.7.4"), novidades (até 3 frases curtas), nova (trava os
## botões 0,4 s).
func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	if _btn_fechar:
		_btn_fechar.queue_free()
	_btns.clear()
	_folha_nova(d)
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

func _folha_nova(d: Dictionary) -> void:
	var novidades: Array = d.get("novidades", [])
	var linhas: Array = []
	for n in novidades:
		var partes: Array = _quebrar(n, 42, 680)
		for i in range(partes.size()):
			linhas.append([partes[i][0], i == 0])
	var meio: float = 70.0 + linhas.size() * 60.0
	var alt: float = 330.0 + meio + 170.0 + 130.0 + 150.0
	var card := Rect2(50, round((1920.0 - alt) / 2.0), 980, alt)
	var c := _folha_curta(card)
	_txt(c, "PÁGINA NOVA!", 70, AZUL_ESCURO, 86, 180, FONTE, 0, card.size.x)
	_traco(c, 200, 780, 192, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(c, "Saiu a versão %s do Sketch Blade." % d.get("versao", ""), 42, AZUL, 210, 270, FONTE, 0, card.size.x)
	var y := 300.0
	_txt(c, "O que mudou:", 46, AZUL_ESCURO, y, y + 64, FONTE, 110, 900, HORIZONTAL_ALIGNMENT_LEFT)
	y += 74.0
	for l in linhas:
		if l[1]:
			_ponto(c, Vector2(140, y + 32))
		_txt(c, l[0], 42, AZUL_ESCURO, y, y + 60, FONTE, 170, 920, HORIZONTAL_ALIGNMENT_LEFT)
		y += 60.0
	y += 40.0
	_botao_atualizar(Rect2(card.position.x + 140, card.position.y + y, 700, 140))
	_btn_fechar = _botao_fechar("Agora não", Rect2(card.position.x + 190, card.position.y + y + 170, 600, 100))

## Marcador da lista: pingo de caneta (o "•" da fonte sai miúdo).
func _ponto(pai: Control, p: Vector2) -> void:
	var t := Control.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.draw.connect(func(): t.draw_circle(p, 8.0, AZUL, true, -1.0, true))
	pai.add_child(t)

func _botao_atualizar(r: Rect2) -> void:
	var b := _botao_peca(_conteudo, BTN_COLETAR, 36, 36, r)
	b.text = "ATUALIZAR"
	b.add_theme_font_override("font", _negrito)
	b.add_theme_font_size_override("font_size", 58)
	for e in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(e, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(AZUL_ESCURO, 0.85))
	b.add_theme_constant_override("outline_size", 8)
	b.pressed.connect(func(): atualizar.emit())
	_btns.append(b)

## A folha das Missões em 9 partes (igual às Configurações).
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
