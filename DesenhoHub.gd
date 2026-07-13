extends Node2D

var aba_ativa: String = "lutar"

func _ready() -> void:
	# Redesenha quando a tela muda (linha da nav acompanha o rodapé real)
	get_viewport().size_changed.connect(queue_redraw)

func _draw() -> void:
	# Cores de caneta
	var cor_tinta = Color("1a1a2e", 0.7)
	var cor_azul = Color("002867") # Azul BIC esferográfico
	var cor_pauta = Color("92a8d1", 0.6)

	# 1. Linha divisória do Bottom Navigation, colada ao topo da nav — que é
	# ancorada no rodapé REAL da tela (240px de altura), não no 1920 de design
	var y_nav: float = get_viewport_rect().size.y - 240.0
	draw_line(Vector2(0, y_nav), Vector2(1080, y_nav), cor_tinta, 3.0)
	draw_dashed_line(Vector2(0, y_nav + 10.0), Vector2(1080, y_nav + 10.0), Color("1a1a2e", 0.35), 2.0, 12.0)
	
	# 3. Desenho rústico da caixinha do Popup de Compra IAP Sandbox
	var hub = get_parent()
	if hub and hub.has_node("HUD/PopupCompra") and hub.get_node("HUD/PopupCompra").visible:
		var r_popup = Rect2(140, 660, 800, 600)
		draw_rect(r_popup, Color(0.98, 0.965, 0.93, 1), true) # Fundo marfim sólido
		draw_rect(r_popup, cor_tinta, false, 4.0) # Borda preta grossa
		draw_rect(Rect2(132, 652, 816, 616), Color("1a1a2e", 0.35), false, 2.0) # Costura externa
	
	if aba_ativa == "estojo":
		# Fundo marfim semiopaco para suprimir as pautas atrás do card
		draw_rect(Rect2(80, 530, 920, 960), Color(0.98, 0.965, 0.93, 0.90), true)
		# Desenha contorno do estojo de upgrades
		draw_rect(Rect2(80, 530, 920, 960), cor_tinta, false, 4.0)
		draw_rect(Rect2(72, 522, 936, 976), Color("1a1a2e", 0.35), false, 2.0)

		# Divisórias horizontais azuis
		draw_line(Vector2(80, 850), Vector2(1000, 850), cor_pauta, 3.0)
		draw_line(Vector2(80, 1170), Vector2(1000, 1170), cor_pauta, 3.0)
		# Tracinhos de nível agora são desenhados dentro de cada card (Hub.gd),
		# acima do CardBackground — aqui ficariam cobertos pelo HUD.

	elif aba_ativa == "lutar":
		pass
