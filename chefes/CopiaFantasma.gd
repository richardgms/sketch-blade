extends Area2D
## Cópia do Fantasma de página (chefe 8). Igual ao verdadeiro, mas SEM
## sombra; some com 1 tiro (não tira vida do chefe). Quem move e manda
## atirar é o Fantasma.gd (um relógio só).

var morre_no_contato: bool = false
var dano_contato: int = 2
var morrendo: bool = false
var fantasma = null # comportamento (chefes/Fantasma.gd)
var raio: float = 100.0
var escala: Vector2 = Vector2.ONE
var _pulso: float = 0.0
var _t: float = 0.0
var _arte: Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 0
	var forma := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = raio
	forma.shape = c
	add_child(forma)
	_arte = Sprite2D.new()
	_arte.texture = preload("res://assets/inimigos/chefe_8.png")
	_arte.scale = escala
	_arte.modulate.a = 0.82 # mesma transparência do verdadeiro
	add_child(_arte)
	_t = randf() * 10.0

func _process(delta: float) -> void:
	if morrendo:
		return
	if fantasma and not is_instance_valid(fantasma.boss):
		queue_free() # chefe sumiu (ex.: saiu da partida)
		return
	_t += delta
	var r: float = sin(_t * 3.2)
	_arte.scale = escala * Vector2(1.0 + 0.05 * r, 1.0 - 0.05 * r) * (1.0 + _pulso)
	_arte.rotation = 0.05 * sin(_t * 1.7)

## Incha antes de atirar (mesmo aviso do verdadeiro).
func inchar(duracao: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_pulso", 0.12, duracao * 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_pulso", 0.0, duracao * 0.2)

func receber_dano(_q: int) -> void:
	morrer()

func receber_dano_detalhado(_q: int, _critico: bool) -> void:
	morrer()

func aplicar_dot(_dps: int, _dur: float) -> void:
	morrer()

## Some num "puf" de papel.
func morrer() -> void:
	if morrendo:
		return
	morrendo = true
	remove_from_group("enemies")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var main = get_parent()
	if main and main.has_method("spawn_impacto"):
		main.spawn_impacto(global_position, Color("8fa3d9"), false)
	if fantasma:
		fantasma.copia_sumiu(self)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.4, 0.3), 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)
