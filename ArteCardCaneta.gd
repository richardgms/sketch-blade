class_name ArteCardCaneta
extends Control

var cor_corpo: Color = Color.BLACK
var cor_projetil: Color = Color.BLACK
var textura_caneta: Texture2D = null

const COR_FUNDO := Color("#fbfaf2")
const COR_BORDA := Color("#2b3a67")

func _draw() -> void:
	_desenhar_card()

	# Caneta em diagonal no canto superior esquerdo
	draw_set_transform(Vector2(80, 96), deg_to_rad(20.0), Vector2.ONE * 1.1)
	if textura_caneta:
		draw_texture_rect(textura_caneta, Rect2(-70, -80, 150, 150), false)
	else:
		DesenhoCaneta.desenhar(self, cor_corpo, cor_projetil)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Rabisco na cor da tinta sob o nome
	DesenhoCaneta.desenhar_rabisco(self, Vector2(150, 96), 190.0, cor_projetil)

func _desenhar_card() -> void:
	var W := size.x
	var H := size.y

	# Polígono com cantos orgânicos — simula card desenhado à mão
	var pontos := PackedVector2Array([
		Vector2(16, 24),
		Vector2(24, 10),
		Vector2(W * 0.35, 5),
		Vector2(W * 0.65, 7),
		Vector2(W - 18, 11),
		Vector2(W - 9, 22),
		Vector2(W - 6, H * 0.38),
		Vector2(W - 8, H * 0.68),
		Vector2(W - 16, H - 16),
		Vector2(W - 26, H - 8),
		Vector2(W * 0.62, H - 5),
		Vector2(W * 0.32, H - 7),
		Vector2(20, H - 13),
		Vector2(10, H - 24),
		Vector2(7, H * 0.65),
		Vector2(9, H * 0.35),
	])

	draw_colored_polygon(pontos, COR_FUNDO)

	# Fecha o polígono adicionando o primeiro ponto no final para o contorno
	var contorno := PackedVector2Array(pontos)
	contorno.append(pontos[0])
	draw_polyline(contorno, COR_BORDA, 3.0, true)
