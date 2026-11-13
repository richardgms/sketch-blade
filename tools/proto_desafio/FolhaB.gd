extends "res://JanelaAtualizacao.gd"
## Desafio do dia, opção B: carta da roleta (como os upgrades), com a estrela
## grande e o prêmio num rótulo tracejado.
func _folha_nova(d: Dictionary) -> void:
	var r := Rect2(140, 330, 800, 1180)
	var c := Control.new()
	c.position = r.position; c.size = r.size
	c.pivot_offset = r.size / 2.0; c.rotation_degrees = -1.2
	_bloco.add_child(c)
	var f := NinePatchRect.new()
	f.texture = load("res://assets/ui/card_roleta.png")
	f.patch_margin_left = 40; f.patch_margin_right = 40; f.patch_margin_top = 55; f.patch_margin_bottom = 55
	f.size = r.size
	c.add_child(f)
	_txt(c, "DESAFIO DO DIA", 60, AZUL_ESCURO, 60, 140, FONTE, 0, r.size.x)
	_txt(c, d["data"], 38, AZUL, 140, 192, FONTE, 0, r.size.x)
	var e := TextureRect.new()
	e.texture = load("res://assets/ui/estrela_giz.png")
	e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	e.size = Vector2(300, 300); e.position = Vector2(250, 210); e.rotation_degrees = 8
	c.add_child(e)
	_txt(c, d["regra"], 64, AZUL_ESCURO, 530, 610, FONTE, 0, r.size.x)
	var y := 625.0
	for l in d["desc"]:
		_txt(c, l, 40, AZUL, y, y + 56, FONTE, 0, r.size.x)
		y += 56.0
	var p := _botao_peca(c, BTN_PREMIO, 36, 36, Rect2(170, y + 40, 460, 110))
	p.text = d["premio"]
	p.add_theme_font_override("font", FONTE); p.add_theme_font_size_override("font_size", 44)
	p.add_theme_color_override("font_color", Color("2e7d32"))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_botao_atualizar(Rect2(r.position.x + 100, r.position.y + y + 190, 600, 130))
	_btns[0].text = "JOGAR"
	_btn_fechar = _botao_fechar("Agora não", Rect2(r.position.x + 150, r.position.y + y + 340, 500, 95))
