extends Node2D
## Folha arrancada pelo Fantasma de página (chefe 8): cai balançando e fere
## a caneta que encostar. Some no rodapé ou se o chefe morrer.

const LARGURA: float = 130.0
const ALTURA: float = 170.0
const MEIA_LARGURA_CANETA: float = 18.0

var x_base: float = 540.0
var velocidade: float = 280.0
var chefe: Node2D = null
var _t: float = 0.0
var _fase: float = 0.0
var _feriu: bool = false

func _ready() -> void:
	_fase = randf() * TAU
	position = Vector2(x_base, 230.0)

func _process(delta: float) -> void:
	if not is_instance_valid(chefe) or chefe.is_queued_for_deletion():
		queue_free()
		return
	_t += delta
	position.y += velocidade * delta
	position.x = x_base + sin(_t * 2.2 + _fase) * 50.0
	rotation = sin(_t * 2.2 + _fase + 0.6) * 0.25
	_checar_caneta()
	if position.y > get_viewport_rect().size.y + ALTURA:
		queue_free()

func _checar_caneta() -> void:
	if _feriu:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var p: Vector2 = player.global_position
	if absf(p.x - position.x) < LARGURA / 2.0 + MEIA_LARGURA_CANETA * 0.5 \
			and position.y + ALTURA / 2.0 > p.y - 100.0 and position.y - ALTURA / 2.0 < p.y + 25.0:
		_feriu = true
		player.receber_dano(1)

## Folha de caderno pautada, com a margem vermelha e um rasgo em cima.
func _draw() -> void:
	var r := Rect2(-LARGURA / 2.0, -ALTURA / 2.0, LARGURA, ALTURA)
	draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.12))
	draw_rect(r, Color("fbf8ef"))
	var linha := Color("8fa3d9")
	var y: float = r.position.y + 28.0
	while y < r.end.y - 6.0:
		draw_line(Vector2(r.position.x + 6, y), Vector2(r.end.x - 6, y), linha, 2.0)
		y += 18.0
	draw_line(Vector2(r.position.x + 24, r.position.y + 6), Vector2(r.position.x + 24, r.end.y), Color("e07a7a"), 2.0)
	draw_rect(r, Color("2b3a6b"), false, 3.0)
	# rasgo: dentes no alto
	var pts := PackedVector2Array()
	var x: float = r.position.x
	var i: int = 0
	while x <= r.end.x:
		pts.append(Vector2(x, r.position.y + (6.0 if i % 2 == 0 else -4.0)))
		x += 13.0
		i += 1
	draw_polyline(pts, Color("2b3a6b"), 3.0)
