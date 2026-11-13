extends "res://JanelaAtualizacao.gd"
## Opção A da avaliação: folha própria depois da vitória.
func _folha_nova(_d: Dictionary) -> void:
	var alt := 900.0
	var card := Rect2(50, round((1920.0 - alt) / 2.0), 980, alt)
	var c := _folha_curta(card)
	_txt(c, "AVALIE O JOGO", 70, AZUL_ESCURO, 86, 180, FONTE, 0, card.size.x)
	_traco(c, 200, 780, 192, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(c, "Sua nota na Play Store ajuda o", 42, AZUL, 220, 280, FONTE, 0, card.size.x)
	_txt(c, "Sketch Blade a chegar a mais gente.", 42, AZUL, 280, 340, FONTE, 0, card.size.x)
	var e = load("res://tools/proto_avaliacao/Estrelas.gd").new()
	e.position = Vector2(190, 380)
	e.size = Vector2(600, 120)
	c.add_child(e)
	_botao_atualizar(Rect2(card.position.x + 190, card.position.y + 560, 600, 140))
	_btns[0].text = "AVALIAR"
	_btn_fechar = _botao_fechar("Agora não", Rect2(card.position.x + 240, card.position.y + 730, 500, 100))

