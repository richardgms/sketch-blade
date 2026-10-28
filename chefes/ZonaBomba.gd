extends Node2D
## X marcado no chão pelo Pirata do mapa (chefe 6).
##
## O X aparece primeiro (aviso), depois a bomba voa em arco do pirata até ele
## e explode. Fere a caneta que estiver perto do X (só a distância no eixo X
## conta: a caneta só anda na horizontal). Some sozinho se o chefe morrer.

const Y_CHAO: float = 1690.0
const RAIO: float = 105.0
const TEMPO_EXPLOSAO: float = 0.4
const JANELA_DANO: float = 0.2
const MEIA_LARGURA_CANETA: float = 18.0
const ALTURA_ARCO: float = 260.0

var alvo_x: float = 540.0
var atraso: float = 0.5 # só o X, antes da bomba sair
var voo: float = 0.7 # tempo da bomba no ar
var chefe: Node2D = null

var _t: float = 0.0
var _origem: Vector2 = Vector2.ZERO
var _saiu: bool = false
var _explodiu: bool = false
var _feriu: bool = false
var _cacos: Array = []

const COR_X := Color("d63a2f")
const COR_FOGO := Color("e8743b")

func _process(delta: float) -> void:
	if not is_instance_valid(chefe) or chefe.is_queued_for_deletion():
		queue_free()
		return
	_t += delta
	if not _saiu and _t >= atraso:
		_saiu = true
		_origem = chefe.global_position + Vector2(-90.0, 0.0) # mão da bomba
	if not _explodiu and _t >= atraso + voo:
		_explodir()
	if _explodiu:
		var te: float = _t - atraso - voo
		if not _feriu and te <= JANELA_DANO:
			_checar_caneta()
		for c in _cacos:
			c["v"].y += 1200.0 * delta
			c["p"] += c["v"] * delta
		if te >= TEMPO_EXPLOSAO + 0.3:
			queue_free()
			return
	queue_redraw()

func _explodir() -> void:
	_explodiu = true
	for i in 10:
		var a: float = randf_range(PI * 1.1, PI * 1.9) # para cima
		_cacos.append({
			"p": Vector2(alvo_x, Y_CHAO),
			"v": Vector2.from_angle(a) * randf_range(350.0, 750.0),
			"r": randf_range(5.0, 10.0),
		})
	var main = get_parent()
	if main and main.has_method("_tocar_som"):
		main._tocar_som(main._gerar_som_procedural(90.0, 0.22, "square"))

func _checar_caneta() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and absf(player.global_position.x - alvo_x) < RAIO + MEIA_LARGURA_CANETA:
		_feriu = true
		player.receber_dano(1)

func _draw() -> void:
	var centro := Vector2(alvo_x, Y_CHAO)
	if not _explodiu:
		var p: float = clampf(_t / (atraso + voo), 0.0, 1.0)
		var pisca: float = 0.55 + 0.45 * absf(sin(p * p * 20.0))
		# área da explosão: círculo tracejado claro
		var area := COR_X
		area.a = 0.18 + 0.2 * p
		draw_circle(centro, RAIO, Color(COR_FOGO, 0.10 + 0.15 * p))
		var n: int = 24
		for i in n:
			if i % 2 == 0:
				draw_arc(centro, RAIO, TAU * i / n, TAU * (i + 1) / n, 4, Color(COR_X, 0.5 * pisca), 3.0, true)
		# o X do mapa
		var k := COR_X
		k.a = 0.95 * pisca
		var l: float = 34.0 + 6.0 * p
		draw_line(centro + Vector2(-l, -l), centro + Vector2(l, l), k, 11.0, true)
		draw_line(centro + Vector2(-l, l), centro + Vector2(l, -l), k, 11.0, true)
		if _saiu:
			_desenhar_bomba(clampf((_t - atraso) / voo, 0.0, 1.0))
	else:
		var pe: float = clampf((_t - atraso - voo) / TEMPO_EXPLOSAO, 0.0, 1.0)
		var r: float = RAIO * (0.6 + 0.5 * pe)
		draw_circle(centro, r, Color(COR_X, 0.7 * (1.0 - pe)))
		draw_circle(centro, r * 0.6, Color(Color("ffd36b"), 0.8 * (1.0 - pe)))
		for c in _cacos:
			var a: float = clampf(1.0 - pe, 0.0, 1.0)
			draw_circle(c["p"], c["r"], Color(Color("2a2420"), a))

## Bomba preta com pavio aceso, em arco do pirata até o X.
func _desenhar_bomba(p: float) -> void:
	var fim := Vector2(alvo_x, Y_CHAO)
	var pos: Vector2 = _origem.lerp(fim, p)
	pos.y -= ALTURA_ARCO * 4.0 * p * (1.0 - p)
	var r: float = 22.0
	draw_circle(pos, r, Color("1b1b22"))
	draw_circle(pos + Vector2(-7, -7), 6.0, Color(1, 1, 1, 0.5))
	var pavio: Vector2 = pos + Vector2(10, -r - 6)
	draw_line(pos + Vector2(5, -r + 2), pavio, Color("6b4a2b"), 4.0)
	var brilho: float = 6.0 + 3.0 * sin(_t * 40.0)
	draw_circle(pavio, brilho, Color("ffcc33"))
	draw_circle(pavio, brilho * 0.5, Color.WHITE)
