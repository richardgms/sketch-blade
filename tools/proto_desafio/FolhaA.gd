extends "res://JanelaAtualizacao.gd"
## Desafio do dia, opção A: folha arrancada (padrão das janelas do Hub).
func _folha_nova(d: Dictionary) -> void:
	var alt := 1180.0
	var card := Rect2(50, round((1920.0 - alt) / 2.0), 980, alt)
	var c := _folha_curta(card)
	_txt(c, "DESAFIO DO DIA", 70, AZUL_ESCURO, 86, 180, FONTE, 0, card.size.x)
	_traco(c, 180, 800, 192, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(c, d["data"], 40, AZUL, 210, 266, FONTE, 0, card.size.x)
	var e := TextureRect.new()
	e.texture = load("res://assets/ui/estrela_giz.png")
	e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	e.size = Vector2(150, 150); e.position = Vector2(415, 285); e.rotation_degrees = -6
	c.add_child(e)
	_txt(c, d["regra"], 62, AZUL_ESCURO, 450, 530, FONTE, 0, card.size.x)
	var y := 545.0
	for l in d["desc"]:
		_txt(c, l, 42, AZUL, y, y + 58, FONTE, 0, card.size.x)
		y += 58.0
	_traco(c, 200, 780, y + 30, Color(AZUL_ESCURO, 0.35), 2.5)
	_txt(c, "Prêmio: %s" % d["premio"], 46, Color("2e7d32"), y + 50, y + 116, FONTE, 0, card.size.x)
	_botao_atualizar(Rect2(card.position.x + 140, card.position.y + y + 160, 700, 140))
	_btns[0].text = "JOGAR DESAFIO"
	_btn_fechar = _botao_fechar("Agora não", Rect2(card.position.x + 240, card.position.y + y + 330, 500, 100))
