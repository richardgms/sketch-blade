extends Node2D
## Escudo de Borracha bloqueou: os pedaços do contorno voam para fora girando
## e a borracha solta farelo (vermelho e azul, como a borracha) que cai e some.

const DURACAO: float = 0.6
const CORES_FARELO := [Color("c8473f"), Color("c8473f"), Color("3456a8"), Color("8d8d8d")]

var pedacos: Array = [] # [pontos, cor, largura] em volta da origem

var _t: float = 0.0
var _voo: Array = [] # [direcao, velocidade, giro, centro]
var _farelo: Array = [] # [pos, vel, poligono, cor]

func _ready() -> void:
	z_index = 22
	for pc in pedacos:
		var pts: PackedVector2Array = pc[0]
		var c := Vector2.ZERO
		for q in pts:
			c += q
		c /= maxf(1.0, pts.size())
		_voo.append([c.normalized(), randf_range(220.0, 420.0), randf_range(-8.0, 8.0), c])
	for i in 16:
		var dir := Vector2.from_angle(randf() * TAU)
		var poli := PackedVector2Array()
		var lados := randi_range(4, 6)
		var tam := randf_range(4.0, 9.0)
		for k in lados:
			poli.append(Vector2.from_angle(TAU * k / lados + randf_range(-0.3, 0.3)) * tam * randf_range(0.6, 1.0))
		_farelo.append([Vector2(dir.x * 50.0, dir.y * 110.0), dir * randf_range(180.0, 420.0) + Vector2(0, -220.0), poli, CORES_FARELO.pick_random()])

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
	for i in pedacos.size():
		var v: Array = _voo[i]
		var c: Vector2 = v[3]
		var novo_c: Vector2 = c + v[0] * v[1] * _t * (1.0 - p * 0.5)
		draw_set_transform(novo_c, v[2] * _t, Vector2.ONE)
		var pts := PackedVector2Array()
		for q in pedacos[i][0]:
			pts.append(q - c)
		draw_polyline(pts, Color(pedacos[i][1], a), pedacos[i][2], true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for f in _farelo:
		draw_set_transform(f[0], _t * 6.0, Vector2.ONE)
		draw_colored_polygon(f[2], Color(f[3], a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
