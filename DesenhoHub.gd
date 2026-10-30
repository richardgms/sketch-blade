extends Node2D

var aba_ativa: String = "lutar"

func _ready() -> void:
	# Redesenha quando a tela muda (linha da nav acompanha o rodapé real)
	get_viewport().size_changed.connect(queue_redraw)

func _draw() -> void:
	# Cores de caneta
	var cor_tinta = Color("1a1a2e", 0.7)

	# 1. Linha divisória do Bottom Navigation, colada ao topo da nav — que é
	# ancorada no rodapé REAL da tela (240px de altura), não no 1920 de design
	var y_nav: float = get_viewport_rect().size.y - 240.0
	draw_line(Vector2(0, y_nav), Vector2(1080, y_nav), cor_tinta, 3.0)
	draw_dashed_line(Vector2(0, y_nav + 10.0), Vector2(1080, y_nav + 10.0), Color("1a1a2e", 0.35), 2.0, 12.0)
