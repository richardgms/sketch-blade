extends Node2D
## Aviso de tiro: linhas tracejadas piscando na direção dos tiros que vêm a
## seguir. Filho do atirador (acompanha o movimento) e some sozinho.

var direcoes: Array = [Vector2.DOWN]
var cor: Color = Color("e8743b")
var duracao: float = 0.5
var comprimento: float = 220.0
var inicio: Vector2 = Vector2.ZERO # deslocamento a partir do atirador
## true: fica atrás do desenho do atirador. false: aviso solto no cenário
## (ex.: rasante do Avião), que não pode ir para trás do papel.
var atras_do_atirador: bool = true

var _t: float = 0.0

func _ready() -> void:
	# Por trás do desenho do atirador (o desenho também fica atrás do pai,
	# então o aviso vai para o começo da lista de filhos)
	if not atras_do_atirador:
		z_index = 15
		return
	show_behind_parent = true
	if get_parent():
		get_parent().move_child.call_deferred(self, 0)

func _process(delta: float) -> void:
	_t += delta
	if _t >= duracao:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p: float = _t / duracao
	# Pisca cada vez mais rápido até o disparo
	var a: float = 0.25 + 0.35 * absf(sin(p * p * 18.0))
	var c := cor
	c.a = a
	for d in direcoes:
		var dir: Vector2 = (d as Vector2).normalized()
		var passo: float = 20.0
		var x: float = 0.0
		while x < comprimento:
			draw_line(inicio + dir * x, inicio + dir * minf(x + 9.0, comprimento), c, 2.5, true)
			x += passo
