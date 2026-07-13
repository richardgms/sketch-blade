extends Node2D

func _draw() -> void:
	# Cor caneta preta clássica
	var cor_tinta = Color("1a1a2e", 0.7)
	var cor_azul = Color("002867") # Azul BIC esferográfico
	
	# Contorno principal do estojo (estilo rascunho de caneta)
	draw_rect(Rect2(80, 450, 920, 960), cor_tinta, false, 4.0)
	
	# Segunda linha de borda (detalhe costurado tracejado)
	draw_rect(Rect2(72, 442, 936, 976), Color("1a1a2e", 0.35), false, 2.0)
	
	# Divisórias horizontais combinando com a pauta azul de caderno
	draw_line(Vector2(80, 770), Vector2(1000, 770), Color("92a8d1", 0.6), 3.0)
	draw_line(Vector2(80, 1090), Vector2(1000, 1090), Color("92a8d1", 0.6), 3.0)
	
	# Desenha as bolinhas de progresso procedurais com antialiasing ativo e contornos idênticos
	var hub = get_parent()
	if hub and "dados_save" in hub:
		_desenhar_bolinhas(Vector2(180, 625), int(hub.dados_save.get("nivel_dano", 1)), cor_azul)
		_desenhar_bolinhas(Vector2(180, 945), int(hub.dados_save.get("nivel_hp", 1)), cor_azul)
		_desenhar_bolinhas(Vector2(180, 1265), int(hub.dados_save.get("nivel_cadencia", 1)), cor_azul)

func _desenhar_bolinhas(pos_inicial: Vector2, nivel: int, cor: Color) -> void:
	var raio: float = 10.0
	var espacamento: float = 35.0
	
	for i in range(5):
		var centro = pos_inicial + Vector2(i * espacamento, 0)
		if i < nivel:
			# Bolinha cheia: preenchimento interno + contorno suavizado (antialiased)
			# Reduzimos ligeiramente o raio do preenchimento para que o arco externo de draw_arc controle o limite visual exato
			draw_circle(centro, raio - 0.5, cor)
			draw_arc(centro, raio, 0.0, TAU, 64, cor, 2.0, true)
		else:
			# Bolinha vazia: contorno suavizado (antialiased)
			draw_arc(centro, raio, 0.0, TAU, 64, cor, 2.0, true)
