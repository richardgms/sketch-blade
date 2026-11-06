extends Node2D
## Escudo de Borracha bloqueou: a borracha racha e se parte em pedaços que voam
## e caem, com farelo (assets/ui/borracha_quebra.png: 10 quadros coloridos de uma
## folha do GPT Image, com a borracha do jogo como referência). O fundo azul e
## vermelho do escudo aparece por baixo e some enquanto ela racha. Um pouco de
## farelo extra, com gravidade, cai entre os quadros.

const QUADROS := preload("res://assets/ui/borracha_quebra.png")
const LARGURA_QUADRO: float = 304.0
const ALTURA_QUADRO: float = 316.0
## Altura da borracha inteira no quadro 1 (px da folha): casa com o escudo.
const ALTURA_BORRACHA_FOLHA: float = 222.4
const TEMPOS := [0.04, 0.05, 0.05, 0.05, 0.06, 0.06, 0.06, 0.07, 0.08, 0.09]
const CORES_FARELO := [Color("c8473f"), Color("c8473f"), Color("3456a8"), Color("8d8d8d")]

var altura_escudo: float = 296.0

var _t: float = 0.0
var _duracao: float = 0.0
var _farelo: Array = [] # [pos, vel, poligono, cor]

func _ready() -> void:
	z_index = 22
	for d in TEMPOS:
		_duracao += d
	for i in 8:
		var dir := Vector2.from_angle(randf() * TAU)
		var poli := PackedVector2Array()
		var lados := randi_range(4, 6)
		var tam := randf_range(3.5, 7.0)
		for k in lados:
			poli.append(Vector2.from_angle(TAU * k / lados + randf_range(-0.3, 0.3)) * tam * randf_range(0.6, 1.0))
		_farelo.append([Vector2(dir.x * 55.0, dir.y * 120.0), dir * randf_range(120.0, 260.0) + Vector2(0, -120.0), poli, CORES_FARELO.pick_random()])

func _process(delta: float) -> void:
	_t += delta
	if _t >= _duracao + 0.15:
		queue_free()
		return
	for f in _farelo:
		f[1].y += 1400.0 * delta
		f[0] += f[1] * delta
	queue_redraw()

func _quadro_atual() -> int:
	var acum := 0.0
	for i in TEMPOS.size():
		acum += TEMPOS[i]
		if _t < acum:
			return i
	return -1

func _draw() -> void:
	var q := _quadro_atual()
	# Fundo da borracha: inteiro até rachar (quadro 3), some até o quadro 5
	var fundo: float = 1.0 - clampf((_t - 0.14) / 0.12, 0.0, 1.0)
	if fundo > 0.0:
		draw_set_transform(-EscudoBorracha.CENTRO, 0.0, Vector2.ONE)
		EscudoBorracha.desenhar_fundo(self, fundo)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if q >= 0:
		var esc: float = altura_escudo / ALTURA_BORRACHA_FOLHA
		var tam := Vector2(LARGURA_QUADRO, ALTURA_QUADRO) * esc
		draw_texture_rect_region(QUADROS, Rect2(-tam / 2.0, tam), Rect2(q * LARGURA_QUADRO, 0.0, LARGURA_QUADRO, ALTURA_QUADRO))
	var a: float = clampf(1.0 - (_t - 0.1) / (_duracao + 0.05), 0.0, 1.0)
	for f in _farelo:
		draw_set_transform(f[0], _t * 6.0, Vector2.ONE)
		draw_colored_polygon(f[2], Color(f[3], a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
