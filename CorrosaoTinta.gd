extends Node2D
class_name CorrosaoTinta
## Tinta Corrosiva no alvo, em 3 estilos para escolher:
##   A = rabiscado: riscos verdes de caneta tremendo por cima do corpo + pingos
##   B = vapor: fiozinhos de fumaça à caneta subindo e chiadinhos na borda
##   C = bolhas à caneta: bolhas de contorno verde (miolo de papel) + pingos
## Filho do monstro/chefe; o dono chama renovar() a cada acerto. Some sozinho
## quando o efeito acaba e as últimas partículas terminam.

const VERDE := Color("2e9d3a")
const PAPEL := Color("fbf8ef")

static var estilo: String = "A"

var raio: float = 35.0

var _restante: float = 0.0
var _t: float = 0.0
var _acum: float = 0.0
var _acum_pingo: float = 0.0
var _parts: Array = []  # bolhas (C) ou fumaças (B): [pos, vel_y, vida, vida_max, tam, fase]
var _pingos: Array = [] # [pos, vel_y, vida]
var _riscos: Array = [] # A: polylines atuais
var _troca_risco: float = 0.0

## Cria (ou reaproveita) o efeito no dono e renova a duração.
static func aplicar(dono: Node2D, atual: Node2D, raio_alvo: float, duracao: float) -> Node2D:
	var fx: Node2D = atual
	if fx == null or not is_instance_valid(fx) or fx.is_queued_for_deletion():
		fx = Node2D.new()
		fx.set_script(load("res://CorrosaoTinta.gd"))
		fx.raio = raio_alvo
		dono.add_child(fx)
	fx.renovar(duracao)
	return fx

func renovar(duracao: float) -> void:
	_restante = maxf(_restante, duracao)

func _ready() -> void:
	z_index = 1

func _gerar_riscos() -> void:
	_riscos.clear()
	for i in 4:
		var pts := PackedVector2Array()
		var y0: float = lerpf(-0.55, 0.45, i / 3.0) * raio + randf_range(-4.0, 4.0)
		var n: int = 7
		for k in n:
			var x: float = lerpf(-0.6, 0.6, float(k) / (n - 1)) * raio
			var y: float = y0 + (-0.22 if k % 2 == 0 else 0.22) * raio + randf_range(-3.0, 3.0)
			pts.append(Vector2(x, y + x * 0.35))
		_riscos.append(pts)

func _process(delta: float) -> void:
	_t += delta
	_restante -= delta
	var ativo := _restante > 0.0
	if ativo:
		match estilo:
			"A":
				_troca_risco -= delta
				if _troca_risco <= 0.0:
					_troca_risco = 0.09
					_gerar_riscos()
			"B":
				_acum += delta * 7.0
				while _acum >= 1.0:
					_acum -= 1.0
					_parts.append([Vector2(randf_range(-0.45, 0.45) * raio, -0.45 * raio), randf_range(55.0, 80.0), 0.85, 0.85, randf_range(0.8, 1.2), randf() * TAU])
			_:
				_acum += delta * 8.0
				while _acum >= 1.0:
					_acum -= 1.0
					var vida := randf_range(0.5, 0.9)
					_parts.append([Vector2(randf_range(-0.55, 0.55) * raio, randf_range(-0.2, 0.5) * raio), randf_range(45.0, 80.0), vida, vida, randf_range(6.0, 11.0), randf() * TAU])
		if estilo != "B":
			_acum_pingo += delta * 3.5
			while _acum_pingo >= 1.0:
				_acum_pingo -= 1.0
				_pingos.append([Vector2(randf_range(-0.45, 0.45) * raio, raio * 0.55), 20.0, 0.7])
	else:
		_riscos.clear()
	for b in _parts:
		b[0].y -= b[1] * delta
		b[0].x += sin(_t * 6.0 + b[5]) * 10.0 * delta
		b[2] -= delta
	for g in _pingos:
		g[1] += 520.0 * delta
		g[0].y += g[1] * delta
		g[2] -= delta
	_parts = _parts.filter(func(b): return b[2] > 0.0)
	_pingos = _pingos.filter(func(g): return g[2] > 0.0)
	if not ativo and _parts.is_empty() and _pingos.is_empty():
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var forca: float = clampf(_restante / 0.4, 0.0, 1.0)
	match estilo:
		"A":
			for pts in _riscos:
				draw_polyline(pts, Color(VERDE, 0.85 * forca), 3.5, true)
		"B":
			for f in _parts:
				var vida_rel: float = f[2] / f[3]
				var pts := PackedVector2Array()
				for k in 12:
					var y: float = -k * 7.0 * f[4]
					pts.append(f[0] + Vector2(sin(_t * 5.0 + k * 0.7 + f[5]) * (2.0 + k * 1.1), y))
				draw_polyline(pts, Color(VERDE, sin(vida_rel * PI)), 5.0, true)
			if forca > 0.0:
				# Chiadinho: risquinhos curtos piscando na borda
				for j in 5:
					var ang: float = -PI * 0.9 + j * 0.45 + sin(_t * 9.0 + j) * 0.1
					var d := Vector2.from_angle(ang)
					if fmod(_t * 8.0 + j * 0.37, 1.0) < 0.6:
						draw_line(d * raio * 0.75, d * (raio * 0.75 + 11.0), Color(VERDE, 0.9 * forca), 3.0, true)
		_:
			for b in _parts:
				var vida_rel: float = b[2] / b[3]
				var r: float = b[4] * (1.0 + (1.0 - vida_rel) * 0.4)
				if vida_rel < 0.15:
					draw_arc(b[0], r * 1.4, 0.0, TAU, 12, Color(VERDE, vida_rel / 0.15), 2.0, true)
				else:
					draw_circle(b[0], r, Color(PAPEL, 0.85))
					draw_arc(b[0], r, 0.0, TAU, 16, VERDE, 2.6, true)
					draw_arc(b[0], r * 0.6, PI * 1.05, PI * 1.45, 6, VERDE, 2.0, true)
	for g in _pingos:
		var a: float = clampf(g[2] / 0.3, 0.0, 1.0)
		var along: float = clampf(g[1] / 300.0, 0.0, 1.0) * 6.0
		draw_colored_polygon(PackedVector2Array([g[0] + Vector2(0, -11.0 - along), g[0] + Vector2(5.0, 0), g[0] + Vector2(-5.0, 0)]), Color(VERDE, a))
		draw_circle(g[0], 5.5, Color(VERDE, a))
