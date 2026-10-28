extends Node2D
## Parede de tinta da Pena de escrever (chefe 9).
##
## A pena "escreve" a linha de um lado ao outro (o Pena.gd atualiza
## `escrito_ate` com a posição da ponta). A fresta fica perto da caneta.
## Depois de `soltar()`, a parede desce e fere a caneta que estiver fora da
## fresta quando passa por ela. Some no rodapé ou se o chefe morrer.

const ESPESSURA: float = 44.0
const MEIA_LARGURA_CANETA: float = 18.0

var y: float = 470.0
var fresta_x: float = 540.0
var largura_fresta: float = 230.0
var velocidade: float = 380.0
var chefe: Node2D = null
var escrito_de: float = 0.0 # x onde a escrita começou
var escrito_ate: float = 0.0 # x da ponta da pena

var _caindo: bool = false
var _feriu: bool = false
var _t: float = 0.0
var _pingos: Array = [] # escorridos de tinta pendurados na linha

const COR := Color("16323d")
const COR_BRILHO := Color("1f7f93")

func _ready() -> void:
	for i in 14:
		_pingos.append({"x": randf_range(0.0, 1080.0), "l": randf_range(10.0, 34.0), "r": randf_range(5.0, 9.0)})

func soltar() -> void:
	escrito_de = 0.0
	escrito_ate = 1080.0
	_caindo = true

func _process(delta: float) -> void:
	if not is_instance_valid(chefe) or chefe.is_queued_for_deletion():
		queue_free()
		return
	_t += delta
	if _caindo:
		y += velocidade * delta
		_checar_caneta()
		if y > get_viewport_rect().size.y + 80.0:
			queue_free()
			return
	queue_redraw()

func _na_fresta(x: float) -> bool:
	return absf(x - fresta_x) < largura_fresta / 2.0

func _checar_caneta() -> void:
	if _feriu:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	# Faixa do corpo da caneta: da ponta (-100) até a base (+25)
	var py: float = player.global_position.y
	if y + ESPESSURA / 2.0 < py - 100.0 or y - ESPESSURA / 2.0 > py + 25.0:
		return
	var px: float = player.global_position.x
	var dentro: bool = px - MEIA_LARGURA_CANETA > fresta_x - largura_fresta / 2.0 \
		and px + MEIA_LARGURA_CANETA < fresta_x + largura_fresta / 2.0
	if not dentro:
		_feriu = true
		player.receber_dano(1)

func _draw() -> void:
	var a: float = minf(escrito_de, escrito_ate)
	var b: float = maxf(escrito_de, escrito_ate)
	var esq: float = fresta_x - largura_fresta / 2.0
	var dir: float = fresta_x + largura_fresta / 2.0
	for trecho in [[a, minf(b, esq)], [maxf(a, dir), b]]:
		if trecho[1] > trecho[0]:
			_desenhar_trecho(trecho[0], trecho[1])
	# Bordas da fresta: setas tracejadas apontando o caminho (só antes de cair)
	if not _caindo and b >= dir:
		var k := COR_BRILHO
		k.a = 0.5 + 0.4 * absf(sin(_t * 8.0))
		for xx in [esq, dir]:
			var yy: float = y - 40.0
			while yy < y + 40.0:
				draw_line(Vector2(xx, yy), Vector2(xx, yy + 8.0), k, 3.0)
				yy += 14.0

## Traço grosso e ondulado, como tinta de pena, com pingos escorrendo.
func _desenhar_trecho(x0: float, x1: float) -> void:
	var pts := PackedVector2Array()
	var x: float = x0
	while x < x1:
		pts.append(Vector2(x, y + sin(x * 0.03 + _t * 2.0) * 5.0))
		x += 12.0
	pts.append(Vector2(x1, y + sin(x1 * 0.03 + _t * 2.0) * 5.0))
	if pts.size() >= 2:
		draw_polyline(pts, COR, ESPESSURA, true)
		var brilho := COR_BRILHO
		brilho.a = 0.55
		var pts2 := PackedVector2Array()
		for p in pts:
			pts2.append(p + Vector2(0, -ESPESSURA * 0.22))
		draw_polyline(pts2, brilho, 5.0, true)
	draw_circle(Vector2(x0, y), ESPESSURA / 2.0, COR)
	draw_circle(Vector2(x1, y), ESPESSURA / 2.0, COR)
	for g in _pingos:
		if g["x"] > x0 + 10.0 and g["x"] < x1 - 10.0:
			var base := Vector2(g["x"], y + ESPESSURA * 0.4)
			draw_line(base, base + Vector2(0, g["l"]), COR, g["r"] * 1.2)
			draw_circle(base + Vector2(0, g["l"]), g["r"], COR)
