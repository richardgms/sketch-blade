extends Node2D
class_name ExplosaoBorrao
## Borrão Explosivo: explosão de quadrinho à caneta animada quadro a quadro
## (assets/ui/explosao_quadros.png: 6 quadros de uma folha do GPT Image —
## faísca, estrela, nuvem crescendo, nuvem cheia, nuvem se desfazendo, fiapos),
## branca e tingida na cor do monstro. Um anel tracejado fino marca o alcance.
## Fica na camada do jogo (z 0): o "MORREU!" aparece por cima.

const QUADROS := preload("res://assets/ui/explosao_quadros.png")
const LADO_QUADRO: float = 140.0
## Duração de cada quadro (s): rápido no estouro, segura a nuvem cheia.
const TEMPOS := [0.05, 0.06, 0.08, 0.2, 0.14, 0.14]
const TAMANHO: float = 1.35 # lado do quadro desenhado, em raios

var cor := Color("26238c")
var raio: float = 200.0

var _t: float = 0.0
var _rot: float = 0.0
var _duracao: float = 0.0
var _tremor: Array = []

func _ready() -> void:
	_rot = randf_range(-0.2, 0.2)
	for d in TEMPOS:
		_duracao += d
	for i in 22:
		_tremor.append(randf_range(-0.04, 0.04))

func _process(delta: float) -> void:
	_t += delta
	if _t >= _duracao:
		queue_free()
		return
	queue_redraw()

func _quadro_atual() -> int:
	var acum := 0.0
	for i in TEMPOS.size():
		acum += TEMPOS[i]
		if _t < acum:
			return i
	return TEMPOS.size() - 1

func _draw() -> void:
	var p: float = _t / _duracao
	var q := _quadro_atual()
	var a: float = 1.0 if q < 5 else clampf((_duracao - _t) / TEMPOS[5], 0.0, 1.0)
	var lado: float = raio * TAMANHO
	draw_set_transform(Vector2.ZERO, _rot, Vector2.ONE)
	draw_texture_rect_region(QUADROS, Rect2(-lado / 2.0, -lado / 2.0, lado, lado),
		Rect2(q * LADO_QUADRO, 0.0, LADO_QUADRO, LADO_QUADRO), Color(cor, 0.95 * a))
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
