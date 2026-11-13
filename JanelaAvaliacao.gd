extends "res://JanelaAtualizacao.gd"
## Pedido de avaliação (aprovado em 13/11/2026, opção A): folha por cima da
## vitória com 5 estrelas à mão em giz de cera, AVALIAR e "Agora não".
## Texto neutro: a Play não permite perguntar se gostou antes de pedir a nota.
## AVALIAR emite `atualizar` (o Main abre a janela de avaliação da Play).
## Página: https://claude.ai/artifact/BXbJ4T8URU4jiSXyFngChn

const ESTRELA := "res://assets/ui/estrela_giz.png"
## Cada estrela um pouco torta e de tamanho diferente, como feitas uma a uma.
const GIRO := [-8.0, 5.0, -3.0, 7.0, -5.0]
const ESCALA := [0.96, 1.04, 1.0, 0.95, 1.02]
const SOBE := [3.0, -4.0, 0.0, -2.0, 4.0]

func _folha_nova(_d: Dictionary) -> void:
	var alt := 900.0
	var card := Rect2(50, round((1920.0 - alt) / 2.0), 980, alt)
	var c := _folha_curta(card)
	_txt(c, "AVALIE O JOGO", 70, AZUL_ESCURO, 86, 180, FONTE, 0, card.size.x)
	_traco(c, 200, 780, 192, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(c, "Sua nota na Play Store ajuda o", 42, AZUL, 220, 280, FONTE, 0, card.size.x)
	_txt(c, "Sketch Blade a chegar a mais gente.", 42, AZUL, 280, 340, FONTE, 0, card.size.x)
	var tex: Texture2D = load(ESTRELA)
	for i in 5:
		var l: float = 120.0 * ESCALA[i]
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.size = Vector2(l, l)
		t.pivot_offset = t.size / 2.0
		t.position = Vector2(190.0 + 120.0 * (i + 0.5), 440.0 + SOBE[i]) - t.size / 2.0
		t.rotation_degrees = GIRO[i]
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(t)
	_botao_atualizar(Rect2(card.position.x + 190, card.position.y + 560, 600, 140))
	_btns[0].text = "AVALIAR"
	_btn_fechar = _botao_fechar("Agora não", Rect2(card.position.x + 240, card.position.y + 730, 500, 100))
