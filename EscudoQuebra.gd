extends Node2D
## Escudo de Borracha bloqueou: os traços do anel voam para fora girando e a
## borracha solta farelo (vermelho e azul, como o ícone) que cai e some.

const DURACAO: float = 0.6
const CORES_FARELO := [Color("c8473f"), Color("c8473f"), Color("24317a"), Color("8d8d8d")]

var cor := Color("0047ab")
var raio: float = 90.0
var rot_inicial: float = 0.0
var n_tracos: int = 16

var _t: float = 0.0
var _tracos: Array = [] # [angulo, velocidade, giro]
var _farelo: Array = [] # [pos, vel, poligono, cor]

func _ready() -> void:
	z_index = 22
	for i in n_tracos:
		_tracos.append([rot_inicial + TAU * i / n_tracos, randf_range(260.0, 460.0), randf_range(-9.0, 9.0)])
	for i in 16:
		var dir := Vector2.from_angle(randf() * TAU)
		var pts := PackedVector2Array()
		var lados := randi_range(4, 6)
		var tam := randf_range(4.0, 9.0)
		for k in lados:
			pts.append(Vector2.from_angle(TAU * k / lados + randf_range(-0.3, 0.3)) * tam * randf_range(0.6, 1.0))
		_farelo.append([dir * raio * 0.6, dir * randf_range(180.0, 420.0) + Vector2(0, -220.0), pts, CORES_FARELO.pick_random()])

func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACAO:
		queue_free()
		return
	for f in _farelo:
		f[1].y += 1500.0 * delta
		f[0] += f[1] * delta
	queue_redraw()

func _draw() -> void:
	var p: float = _t / DURACAO
	var a: float = 1.0 - p * p
	var arco: float = TAU / n_tracos * 0.55
	for tr in _tracos:
		var desloc: float = tr[1] * _t * (1.0 - p * 0.5)
		var centro := Vector2.from_angle(tr[0] + arco / 2.0) * (raio + desloc)
		draw_set_transform(centro, tr[2] * _t, Vector2.ONE)
		var pts := PackedVector2Array()
		for k in 4:
			var ang: float = tr[0] + arco * k / 3.0
			pts.append(Vector2.from_angle(ang) * raio - Vector2.from_angle(tr[0] + arco / 2.0) * raio)
		draw_polyline(pts, Color(cor, a), 5.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for f in _farelo:
		draw_set_transform(f[0], _t * 6.0, Vector2.ONE)
		draw_colored_polygon(f[2], Color(f[3], a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
