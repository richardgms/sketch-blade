extends Node2D
## Respingo curto de tinta no ponto onde o tiro acertou.
## Gotas saem do centro, desaceleram e somem em ~0,25 s. Só desenho, sem física.

var cor: Color = Color(0.1, 0.1, 0.15)
var critico: bool = false

const DURACAO: float = 0.25

var _gotas: Array = [] # [direcao, distancia_final, raio]
var _t: float = 0.0

func _ready() -> void:
	z_index = 20
	var qtd: int = 9 if critico else 6
	var alcance: float = 64.0 if critico else 42.0
	for i in qtd:
		var ang := randf() * TAU
		_gotas.append([Vector2.from_angle(ang), alcance * randf_range(0.5, 1.0), randf_range(4.5, 9.0)])

func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACAO:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p: float = clampf(_t / DURACAO, 0.0, 1.0)
	var saida: float = 1.0 - pow(1.0 - p, 3.0) # rápido no começo, freia no fim
	var c := cor
	c.a = 1.0 - p * p
	# Mancha central que encolhe
	draw_circle(Vector2.ZERO, (20.0 if critico else 14.0) * (1.0 - p), c)
	for g in _gotas:
		draw_circle(g[0] * g[1] * saida, g[2] * (1.0 - p * 0.6), c)
	if critico:
		# Anel de "estalo" no crítico
		var anel := Color(1.0, 0.75, 0.2, 1.0 - p)
		draw_arc(Vector2.ZERO, 20.0 + 40.0 * saida, 0.0, TAU, 24, anel, 4.0 * (1.0 - p), true)
