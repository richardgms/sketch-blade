@tool
class_name DesenhoCaneta
extends RefCounted

## Arte compartilhada da caneta (jogo + loja), no estilo caderno à mão.
## As funções desenham no CanvasItem recebido — só podem ser chamadas
## de dentro do _draw() dele.

const COR_TRACO := Color(0.13, 0.13, 0.2)
const COR_METAL := Color(0.78, 0.7, 0.54)

const MEIA_LARGURA := 10.5
const TOPO_CORPO := -20.0
const BASE_CORPO := 45.0
const PONTA_Y := -46.0

## Caneta vertical apontando para as 12h, centrada na origem.
static func desenhar(ci: CanvasItem, cor_corpo: Color, cor_projetil: Color) -> void:
	# Corpo com fundo arredondado
	ci.draw_rect(Rect2(-MEIA_LARGURA, TOPO_CORPO, MEIA_LARGURA * 2.0, BASE_CORPO - TOPO_CORPO), cor_corpo)
	ci.draw_circle(Vector2(0, BASE_CORPO), MEIA_LARGURA, cor_corpo)

	# Brilho no lado esquerdo
	ci.draw_rect(Rect2(-MEIA_LARGURA + 3.0, TOPO_CORPO + 5.0, 3.5, (BASE_CORPO - TOPO_CORPO) - 8.0), Color(1, 1, 1, 0.16))

	# Anel entre bico e corpo
	ci.draw_rect(Rect2(-MEIA_LARGURA, TOPO_CORPO, MEIA_LARGURA * 2.0, 5.0), cor_corpo.darkened(0.35))

	# Clip lateral
	var clip := Rect2(MEIA_LARGURA - 4.0, -6.0, 4.5, 34.0)
	ci.draw_rect(clip, cor_corpo.lightened(0.45))
	ci.draw_rect(clip, COR_TRACO, false, 1.5)

	# Bico metálico com fenda e ponta molhada na cor da tinta
	var bico := PackedVector2Array([
		Vector2(-9, TOPO_CORPO),
		Vector2(0, PONTA_Y),
		Vector2(9, TOPO_CORPO),
	])
	ci.draw_colored_polygon(bico, COR_METAL)
	ci.draw_line(Vector2(0, PONTA_Y + 4.0), Vector2(0, TOPO_CORPO - 3.0), COR_TRACO, 1.8, true)
	ci.draw_circle(Vector2(0, PONTA_Y + 2.0), 2.5, cor_projetil)

	# Contorno à mão fechando a silhueta (bico + corpo + fundo arredondado)
	var pontos := PackedVector2Array()
	pontos.append(Vector2(-9, TOPO_CORPO))
	pontos.append(Vector2(0, PONTA_Y))
	pontos.append(Vector2(9, TOPO_CORPO))
	pontos.append(Vector2(MEIA_LARGURA, TOPO_CORPO))
	for k in range(9):
		var ang := (float(k) / 8.0) * PI
		pontos.append(Vector2(cos(ang), sin(ang)) * MEIA_LARGURA + Vector2(0, BASE_CORPO))
	pontos.append(Vector2(-MEIA_LARGURA, TOPO_CORPO))
	pontos.append(Vector2(-9, TOPO_CORPO))
	ci.draw_polyline(pontos, COR_TRACO, 2.5, true)

## Rabisco ondulado horizontal — o "traço" que a caneta escreve no papel.
static func desenhar_rabisco(ci: CanvasItem, inicio: Vector2, largura: float, cor: Color) -> void:
	var pontos := PackedVector2Array()
	var passos := int(largura / 8.0)
	for k in range(passos + 1):
		var x := inicio.x + k * 8.0
		var y := inicio.y + sin(k * 1.15) * 3.5 + sin(k * 0.5) * 1.5
		pontos.append(Vector2(x, y))
	ci.draw_polyline(pontos, cor, 3.0, true)
