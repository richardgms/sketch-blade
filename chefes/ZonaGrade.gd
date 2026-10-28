extends Node2D
## Colunas do chão marcadas pelo Monstro da grade (chefe 4).
##
## Cada coluna vira um quadriculado que vai enchendo de laranja de baixo para
## cima (aviso), explode e fere a caneta que estiver dentro dela.
## Some sozinha no fim ou se o chefe morrer.

const LARGURA_COLUNA: float = 180.0 # 6 colunas em 1080 px
const Y_TOPO: float = 1480.0 # um pouco acima da zona da caneta (1550)
const CELULA: float = 60.0
const TEMPO_EXPLOSAO: float = 0.35
const JANELA_DANO: float = 0.2 # tempo da explosão em que ainda fere
const MEIA_LARGURA_CANETA: float = 18.0

var colunas: Array = [] # índices 0..5
var aviso: float = 1.2
var atraso: float = 0.0 # espera invisível antes de começar o aviso
var chefe: Node = null

var _t: float = 0.0
var _explodiu: bool = false
var _feriu: bool = false
var _cacos: Array = [] # quadradinhos voando na explosão

const COR_LINHA := Color("2b4fa3")
const COR_AVISO := Color("e8743b")
const COR_EXPLOSAO := Color("d63a2f")

func _process(delta: float) -> void:
	if not is_instance_valid(chefe) or chefe.is_queued_for_deletion():
		queue_free()
		return
	_t += delta
	var t: float = _t - atraso
	if t < 0.0:
		return
	if not _explodiu and t >= aviso:
		_explodir()
	if _explodiu:
		var te: float = t - aviso
		if not _feriu and te <= JANELA_DANO:
			_checar_caneta()
		for c in _cacos:
			c["v"].y += 1400.0 * delta
			c["p"] += c["v"] * delta
			c["r"] += c["giro"] * delta
		if te >= TEMPO_EXPLOSAO + 0.3:
			queue_free()
			return
	queue_redraw()

func _altura() -> float:
	return get_viewport_rect().size.y - Y_TOPO

func _explodir() -> void:
	_explodiu = true
	for col in colunas:
		var x0: float = col * LARGURA_COLUNA
		for i in 6:
			_cacos.append({
				"p": Vector2(x0 + randf_range(20.0, LARGURA_COLUNA - 20.0), Y_TOPO + randf_range(40.0, 260.0)),
				"v": Vector2(randf_range(-160.0, 160.0), randf_range(-900.0, -500.0)),
				"r": randf() * TAU, "giro": randf_range(-8.0, 8.0),
				"lado": randf_range(18.0, 30.0),
			})
	var main = get_parent()
	if main and main.has_method("_tocar_som"):
		main._tocar_som(main._gerar_som_procedural(110.0, 0.18, "square"))

func _checar_caneta() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var x: float = player.global_position.x
	for col in colunas:
		var x0: float = col * LARGURA_COLUNA
		if x + MEIA_LARGURA_CANETA > x0 and x - MEIA_LARGURA_CANETA < x0 + LARGURA_COLUNA:
			_feriu = true
			player.receber_dano(1)
			return

func _draw() -> void:
	var t: float = _t - atraso
	if t < 0.0:
		return
	var h: float = _altura()
	for col in colunas:
		var r := Rect2(col * LARGURA_COLUNA + 4.0, Y_TOPO, LARGURA_COLUNA - 8.0, h)
		if not _explodiu:
			_desenhar_aviso(r, t / aviso)
		else:
			var p: float = clampf((t - aviso) / TEMPO_EXPLOSAO, 0.0, 1.0)
			var c := COR_EXPLOSAO.lerp(Color.WHITE, 0.35 * (1.0 - p))
			c.a = 0.75 * (1.0 - p)
			draw_rect(r, c)
	for c in _cacos:
		var k := COR_AVISO
		k.a = clampf(1.0 - (t - aviso) / (TEMPO_EXPLOSAO + 0.3), 0.0, 1.0)
		draw_set_transform(c["p"], c["r"])
		var l: float = c["lado"]
		draw_rect(Rect2(-l / 2.0, -l / 2.0, l, l), Color(1, 1, 1, k.a))
		draw_rect(Rect2(-l / 2.0, -l / 2.0, l, l), k, false, 3.0)
	draw_set_transform(Vector2.ZERO)

## Quadriculado azul de caderno + enchimento laranja de baixo para cima,
## piscando cada vez mais rápido perto da explosão.
func _desenhar_aviso(r: Rect2, p: float) -> void:
	p = clampf(p, 0.0, 1.0)
	var pisca: float = 0.55 + 0.45 * absf(sin(p * p * 22.0))
	# enchimento
	var alt: float = r.size.y * p
	var cheio := COR_AVISO
	cheio.a = 0.30 + 0.25 * p
	draw_rect(Rect2(r.position.x, r.end.y - alt, r.size.x, alt), cheio)
	# grade
	var linha := COR_LINHA
	linha.a = 0.45 * pisca
	var x: float = r.position.x
	while x <= r.end.x + 0.5:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), linha, 2.0)
		x += CELULA
	var y: float = r.position.y
	while y <= r.end.y + 0.5:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), linha, 2.0)
		y += CELULA
	# contorno vermelho tracejado no alto (marca a coluna)
	var borda := COR_EXPLOSAO
	borda.a = 0.9 * pisca
	var bx: float = r.position.x
	while bx < r.end.x:
		draw_line(Vector2(bx, r.position.y), Vector2(minf(bx + 14.0, r.end.x), r.position.y), borda, 5.0)
		bx += 24.0
	draw_line(r.position, Vector2(r.position.x, r.end.y), borda, 3.0)
	draw_line(Vector2(r.end.x, r.position.y), r.end, borda, 3.0)
