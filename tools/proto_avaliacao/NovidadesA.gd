extends "res://JanelaAtualizacao.gd"
## Opção A das novidades: a folha do aviso de atualização, um botão só.
func _folha_nova(d: Dictionary) -> void:
	var linhas: Array = []
	for n in d["novidades"]:
		var partes: Array = _quebrar(n, 42, 680)
		for i in range(partes.size()):
			linhas.append([partes[i][0], i == 0])
	var alt: float = 330.0 + 70.0 + linhas.size() * 60.0 + 40.0 + 140.0 + 130.0
	var card := Rect2(50, round((1920.0 - alt) / 2.0), 980, alt)
	var c := _folha_curta(card)
	_txt(c, "NOVIDADES!", 70, AZUL_ESCURO, 86, 180, FONTE, 0, card.size.x)
	_traco(c, 240, 740, 192, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(c, "Você está na versão %s." % d["versao"], 42, AZUL, 210, 270, FONTE, 0, card.size.x)
	var y := 300.0
	_txt(c, "O que tem de novo:", 46, AZUL_ESCURO, y, y + 64, FONTE, 110, 900, HORIZONTAL_ALIGNMENT_LEFT)
	y += 74.0
	for l in linhas:
		if l[1]:
			_ponto(c, Vector2(140, y + 32))
		_txt(c, l[0], 42, AZUL_ESCURO, y, y + 60, FONTE, 170, 920, HORIZONTAL_ALIGNMENT_LEFT)
		y += 60.0
	y += 40.0
	_botao_atualizar(Rect2(card.position.x + 190, card.position.y + y, 600, 140))
	_btns[0].text = "BORA JOGAR!"
	_btn_fechar = Button.new() # sem "Agora não"
	add_child(_btn_fechar)
	_btn_fechar.visible = false

