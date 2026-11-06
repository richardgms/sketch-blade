extends Node2D
class_name CorrosaoTinta
## Tinta Corrosiva no alvo: bolhas verdes sobem e estouram, pingos escorrem
## por baixo e dois fiozinhos de fumaça ondulam em cima (como o ícone).
## Filho do monstro/chefe; o dono chama renovar() a cada acerto. Some sozinho
## quando o efeito acaba e as últimas bolhas terminam.

const VERDE := Color("43a047")
const VERDE_ESCURO := Color("1b5e20")
const MANCHA := preload("res://assets/ui/mancha_respingo_2.png")

var raio: float = 35.0

var _restante: float = 0.0
var _t: float = 0.0
var _acum_bolha: float = 0.0
var _acum_pingo: float = 0.0
var _bolhas: Array = [] # [pos, vel_y, vida, vida_max, raio, fase]
var _pingos: Array = [] # [pos, vel_y, vida]

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

func _process(delta: float) -> void:
	_t += delta
	_restante -= delta
	if _restante > 0.0:
		_acum_bolha += delta * 14.0
		_acum_pingo += delta * 4.0
		while _acum_bolha >= 1.0:
			_acum_bolha -= 1.0
			var vida := randf_range(0.45, 0.85)
			_bolhas.append([Vector2(randf_range(-0.6, 0.6) * raio, randf_range(-0.2, 0.5) * raio),
				randf_range(45.0, 85.0), vida, vida, randf_range(6.0, 11.0), randf() * TAU])
		while _acum_pingo >= 1.0:
			_acum_pingo -= 1.0
			_pingos.append([Vector2(randf_range(-0.45, 0.45) * raio, raio * 0.55), 20.0, 0.7])
	for b in _bolhas:
		b[0].y -= b[1] * delta
		b[0].x += sin(_t * 7.0 + b[5]) * 12.0 * delta
		b[2] -= delta
	for g in _pingos:
		g[1] += 520.0 * delta
		g[0].y += g[1] * delta
		g[2] -= delta
	_bolhas = _bolhas.filter(func(b): return b[2] > 0.0)
	_pingos = _pingos.filter(func(g): return g[2] > 0.0)
	if _restante <= 0.0 and _bolhas.is_empty() and _pingos.is_empty():
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var forca: float = clampf(_restante / 0.4, 0.0, 1.0)
	# Tinta verde espalhada no corpo, girando devagar
	if forca > 0.0:
		var lado: float = raio * 1.9
		draw_set_transform(Vector2.ZERO, _t * 0.6, Vector2.ONE)
		draw_texture_rect(MANCHA, Rect2(-lado / 2.0, -lado / 2.0, lado, lado), false, Color(VERDE, 0.5 * forca))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Fumaça: dois fios ondulados saindo de cima
	if forca > 0.0:
		for lado in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			var x0: float = lado * raio * 0.3
			for k in 9:
				var y: float = -raio * 0.7 - k * 7.0
				pts.append(Vector2(x0 + sin(_t * 5.0 + k * 0.8 + lado) * (3.0 + k * 1.3), y))
			draw_polyline(pts, Color(VERDE, 0.65 * forca), 4.5, true)
	for g in _pingos:
		var a: float = clampf(g[2] / 0.3, 0.0, 1.0)
		var along: float = clampf(g[1] / 300.0, 0.0, 1.0) * 6.0
		draw_colored_polygon(PackedVector2Array([g[0] + Vector2(0, -11.0 - along), g[0] + Vector2(5.5, 0), g[0] + Vector2(-5.5, 0)]), Color(VERDE, a))
		draw_circle(g[0], 6.0, Color(VERDE, a))
	for b in _bolhas:
		var vida_rel: float = b[2] / b[3]
		var r: float = b[4] * (1.0 + (1.0 - vida_rel) * 0.4)
		if vida_rel < 0.15:
			# Estouro: anelzinho que abre
			draw_arc(b[0], r * 1.4, 0.0, TAU, 12, Color(VERDE_ESCURO, vida_rel / 0.15), 2.0, true)
		else:
			draw_circle(b[0], r, Color(VERDE, 0.85))
			draw_arc(b[0], r, 0.0, TAU, 14, VERDE_ESCURO, 2.4, true)
			draw_circle(b[0] + Vector2(-r * 0.35, -r * 0.35), r * 0.28, Color(1, 1, 1, 0.8))
