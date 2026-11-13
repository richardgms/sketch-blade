extends "res://JanelaAtualizacao.gd"
## Desafio do dia v2: folha "Prova surpresa" (gerada no ChatGPT), com a regra,
## a cartela de carimbos (3 = bônus) e o prêmio.
func _folha_nova(d: Dictionary) -> void:
	var r := Rect2(70, 130, 940, 1670)
	var c := Control.new()
	c.position = r.position; c.size = r.size
	_bloco.add_child(c)
	var f := TextureRect.new()
	f.texture = load("res://assets/ui/desafio_folha.png")
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.size = r.size
	c.add_child(f)
	# Caixa do cabeçalho da arte: x 100–605, y 160–270
	_txt(c, "PROVA SURPRESA", 52, AZUL_ESCURO, 160, 270, FONTE, 100, 605)
	_txt(c, d["data"], 38, AZUL, 300, 352, FONTE, 0, r.size.x)
	_txt(c, d["regra"], 66, AZUL_ESCURO, 400, 490, FONTE, 0, r.size.x)
	var y := 500.0
	for l in d["desc"]:
		_txt(c, l, 42, AZUL, y, y + 58, FONTE, 0, r.size.x)
		y += 58.0
	y += 40.0
	_txt(c, "3 páginas + o chefe do seu capítulo", 36, Color(AZUL, 0.8), y, y + 50, FONTE, 0, r.size.x)
	y += 90.0
	# Cartela: 3 carimbos; o 3º dá bônus
	_txt(c, "Cartela de carimbos", 40, AZUL_ESCURO, y, y + 56, FONTE, 0, r.size.x)
	y += 70.0
	for i in 3:
		var x := 250.0 + i * 160.0
		var cx := Control.new()
		cx.position = Vector2(x, y); cx.size = Vector2(120, 120)
		var cheio: bool = i < d["carimbos"]
		cx.draw.connect(func():
			cx.draw_arc(Vector2(60, 60), 54, 0, TAU, 40, Color(AZUL, 0.7), 4.0, true)
			if cheio:
				cx.draw_circle(Vector2(60, 60), 46, Color("c62828", 0.85)))
		c.add_child(cx)
		if cheio:
			_txt(cx, "OK", 40, Color.WHITE, 30, 90, FONTE, 0, 120)
	_txt(c, "+5 clipes", 34, Color("2e7d32"), y + 125, y + 170, FONTE, 400, 840, HORIZONTAL_ALIGNMENT_RIGHT)
	y += 190.0
	_traco(c, 200, 740, y, Color(AZUL_ESCURO, 0.35), 2.5)
	_txt(c, "Prêmio: %s" % d["premio"], 46, Color("2e7d32"), y + 20, y + 86, FONTE, 0, r.size.x)
	_botao_atualizar(Rect2(r.position.x + 160, r.position.y + y + 120, 620, 140))
	_btns[0].text = "FAZER A PROVA"
	_btn_fechar = _botao_fechar("Agora não", Rect2(r.position.x + 220, r.position.y + y + 285, 500, 100))
