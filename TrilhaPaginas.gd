extends Control
## Trilha das páginas do capítulo: casas ligadas por tracejado, as primeiras
## `cheias` em azul, a `atual` com anel verde e a última maior com "?" (o
## chefe). Usada na tela antes da partida e na virada de página.

const FONTE := preload("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
const AZUL := Color("0047ab")
const AZUL_ESCURO := Color("002867")

var total := 8
var cheias := 0
var atual := 0
var passo := 108.0
var anel := 1.0 # 0..1: o anel verde da casa atual cresce na virada

func _init() -> void:
	size = Vector2(1080, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var x0: float = size.x / 2.0 - passo * (total - 1) / 2.0
	for i in range(total - 1):
		var a := Vector2(x0 + passo * i + 30, 50)
		var b := Vector2(x0 + passo * (i + 1) - 30 - (12 if i == total - 2 else 0), 50)
		draw_dashed_line(a, b, Color(AZUL_ESCURO, 0.5), 3.0, 8.0)
	for i in range(total):
		var p := Vector2(x0 + passo * i, 50)
		var ultimo: bool = i == total - 1
		var r: float = 40.0 if ultimo else 26.0
		draw_circle(p, r, Color(AZUL, 0.85) if i < cheias else Color.WHITE)
		draw_arc(p, r, 0, TAU, 32, AZUL_ESCURO, 3.5, true)
		if ultimo:
			draw_string(FONTE, p + Vector2(-13, 17), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 48,
				Color.WHITE if i < cheias else AZUL_ESCURO)
		if i == atual and anel > 0.0:
			draw_arc(p, r + 9, -PI / 2.0, -PI / 2.0 + TAU * anel, 32, Color("6fd877"), 6.0, true)
