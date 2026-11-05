@tool
extends Node2D
## Cena auxiliar; não altera tabelas do jogo ou o save.
const NOMES := ["Borrão", "Avião", "Mancha", "Grade", "Compasso", "Pirata", "Tsuru", "Fantasma", "Pena", "Estojo"]

func _draw() -> void:
	draw_rect(Rect2(-40, -50, 1960, 840), Color("f4f0e6"))
	var fonte := ThemeDB.fallback_font
	draw_string(fonte, Vector2(0, -4), "AJUSTE DOS ROSTOS — selecione Rosto no painel Cena, mova ou escale e salve com Ctrl+S.", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("002867"))
	for i in range(10):
		var centro := Vector2(180 + (i % 5) * 380, 180 + (i / 5) * 380)
		draw_arc(centro, 102.0, 0, TAU, 96, Color("002867"), 3.0, true)
		draw_string(fonte, centro + Vector2(-135, -125), "%d · %s" % [i + 1, NOMES[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("002867"))
		draw_string(fonte, centro + Vector2(-135, 145), "Selecione: Chefe%02d / Rosto" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("002867"))
