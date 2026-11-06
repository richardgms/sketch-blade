extends Node2D
## Borrão Explosivo: o monstro estoura num respingo de tinta na cor dele
## (desenho do ícone, branco tingível em assets/ui/explosao_borrao.png) e um
## anel tracejado à mão marca até onde a explosão alcança.

const TEX := preload("res://assets/ui/explosao_borrao.png")
const DURACAO: float = 0.55

var cor := Color("26238c")
var raio: float = 200.0

var _t: float = 0.0
var _rot: float = 0.0
var _tremor: Array = [] # deslocamento do raio por traço do anel

func _ready() -> void:
	z_index = 15
	_rot = randf() * TAU
	for i in 18:
		_tremor.append(randf_range(-0.05, 0.05))

func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACAO:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p: float = _t / DURACAO
	# Respingo: estoura (0,25 → 1,08 em 0,12 s), assenta e some
	var s: float
	if _t < 0.12:
		s = lerpf(0.25, 1.08, 1.0 - pow(1.0 - _t / 0.12, 3.0))
	else:
		s = lerpf(1.08, 1.0, clampf((_t - 0.12) / 0.1, 0.0, 1.0))
	var a: float = 1.0 if _t < 0.18 else 1.0 - (_t - 0.18) / (DURACAO - 0.18)
	var lado: float = raio * 2.1 * s
	draw_set_transform(Vector2.ZERO, _rot, Vector2.ONE)
	draw_texture_rect(TEX, Rect2(-lado / 2.0, -lado / 2.0, lado, lado), false, Color(cor, 0.92 * a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Anel do alcance: traços de caneta que se abrem até o raio e apagam
	var abre: float = 1.0 - pow(1.0 - clampf(p / 0.45, 0.0, 1.0), 2.0)
	var r: float = raio * lerpf(0.55, 1.0, abre)
	var c_anel := Color(cor.darkened(0.25), 0.75 * (1.0 - p))
	var n := _tremor.size()
	for i in n:
		var a0: float = _rot + TAU * i / n
		var pts := PackedVector2Array()
		for k in 5:
			var ang: float = a0 + (TAU / n) * 0.62 * k / 4.0
			pts.append(Vector2.from_angle(ang) * r * (1.0 + _tremor[i] * (1.0 if k % 2 == 0 else 0.6)))
		draw_polyline(pts, c_anel, lerpf(6.0, 2.0, p), true)
