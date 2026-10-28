extends Node2D
## Aviso de tiro: linhas tracejadas piscando na direção dos tiros que vêm a
## seguir. Filho do atirador (acompanha o movimento) e some sozinho.

var direcoes: Array = [Vector2.DOWN]
var cor: Color = Color("e8743b")
var duracao: float = 0.5
var comprimento: float = 220.0
var inicio: Vector2 = Vector2.ZERO # deslocamento a partir do atirador

var _t: float = 0.0

func _ready() -> void:
	z_index = 15

func _process(delta: float) -> void:
	_t += delta
	if _t >= duracao:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p: float = _t / duracao
	# Pisca cada vez mais rápido até o disparo
	var a: float = 0.35 + 0.45 * absf(sin(p * p * 18.0))
	var c := cor
	c.a = a
	for d in direcoes:
		var dir: Vector2 = (d as Vector2).normalized()
		var passo: float = 22.0
		var x: float = 0.0
		while x < comprimento:
			draw_line(inicio + dir * x, inicio + dir * minf(x + 12.0, comprimento), c, 5.0, true)
			x += passo
