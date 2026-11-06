extends Node2D
class_name ExplosaoBorrao
## Borrão Explosivo: o monstro estoura e um anel tracejado fino marca até onde
## a explosão alcança. Desenhos brancos tingidos na cor do monstro. 3 estilos:
##   A = nuvem de quadrinho à caneta (assets/ui/explosao_nuvem.png, ChatGPT)
##   B = estrela de quadrinho à caneta (assets/ui/explosao_estrela.png, ChatGPT)
##   C = respingo do ícone, menor e mais claro (assets/ui/explosao_borrao.png)
## Fica na camada do jogo (z 0): o "MORREU!" aparece por cima.

const TEXTURAS := {
	"A": preload("res://assets/ui/explosao_nuvem.png"),
	"B": preload("res://assets/ui/explosao_estrela.png"),
	"C": preload("res://assets/ui/explosao_borrao.png"),
}
const TAMANHO := {"A": 1.15, "B": 1.2, "C": 1.1} # lado do desenho em raios
const DURACAO: float = 0.5

static var estilo: String = "A"

var cor := Color("26238c")
var raio: float = 200.0

var _t: float = 0.0
var _rot: float = 0.0
var _tremor: Array = []

func _ready() -> void:
	_rot = randf_range(-0.25, 0.25) if estilo != "C" else randf() * TAU
	for i in 22:
		_tremor.append(randf_range(-0.04, 0.04))

func _process(delta: float) -> void:
	_t += delta
	if _t >= DURACAO:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var p: float = _t / DURACAO
	var s: float
	if _t < 0.1:
		s = lerpf(0.3, 1.1, 1.0 - pow(1.0 - _t / 0.1, 3.0))
	else:
		s = lerpf(1.1, 1.0, clampf((_t - 0.1) / 0.1, 0.0, 1.0))
	var a: float = 1.0 if _t < 0.22 else 1.0 - (_t - 0.22) / (DURACAO - 0.22)
	var lado: float = raio * TAMANHO[estilo] * s
	var alfa: float = 0.7 if estilo == "C" else 0.95
	draw_set_transform(Vector2.ZERO, _rot + (0.08 * _t if estilo != "C" else 0.0), Vector2.ONE)
	draw_texture_rect(TEXTURAS[estilo], Rect2(-lado / 2.0, -lado / 2.0, lado, lado), false, Color(cor, alfa * a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Anel fino do alcance
	var abre: float = 1.0 - pow(1.0 - clampf(p / 0.4, 0.0, 1.0), 2.0)
	var r: float = raio * lerpf(0.6, 1.0, abre)
	var c_anel := Color(cor, 0.45 * (1.0 - p))
	var n := _tremor.size()
	for i in n:
		var a0: float = _rot + TAU * i / n
		var pts := PackedVector2Array()
		for k in 4:
			pts.append(Vector2.from_angle(a0 + (TAU / n) * 0.5 * k / 3.0) * r * (1.0 + _tremor[i]))
		draw_polyline(pts, c_anel, 3.0, true)
