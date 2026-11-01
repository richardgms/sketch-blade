extends Node2D
## Mancha de tinta na morte de um monstro (aprovada em 31/10, versão A
## "respingo"): a tinta estoura (cresce rápido, passa um pouco e assenta),
## clareia e passa para o Paper, onde fica até a página virar.

var tex: Texture2D
var cor := Color.BLACK
var tam := 150.0
var paper: Node
var alfa_final := 0.3

var _s := 0.3
var _a := 0.95
var _rot := 0.0

func _ready() -> void:
	_rot = randf() * TAU
	var t := create_tween()
	t.tween_method(func(v: float):
		_s = v
		queue_redraw(), 0.3, 1.12, 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_method(func(v: float):
		_s = v
		queue_redraw(), 1.12, 1.0, 0.08)
	t.tween_interval(0.2)
	t.tween_method(func(v: float):
		_a = v
		queue_redraw(), 0.95, alfa_final, 0.45)
	t.tween_callback(func():
		if is_instance_valid(paper) and paper.has_method("adicionar_mancha_textura"):
			paper.adicionar_mancha_textura(global_position, Color(cor, alfa_final), tex, tam, _rot)
		queue_free())

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _rot, Vector2.ONE * _s)
	draw_texture_rect(tex, Rect2(-tam / 2.0, -tam / 2.0, tam, tam), false, Color(cor, _a))
