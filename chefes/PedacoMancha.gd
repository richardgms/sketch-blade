extends Area2D
## Pedaço da Mancha (chefe do cap. 3). Não tem vida própria: o dano vai para
## a vida compartilhada do chefe (uma barra só). Anda no alto da tela e atira
## uma gota mirada na caneta, sempre com aviso.

var boss: Node2D
var raio: float = 45.0
var fase_mov: float = 0.0     # desencontra o movimento entre os pedaços
var atraso_tiro: float = 0.0  # desencontra os tiros entre os pedaços
var morre_no_contato: bool = false
var dano_contato: int = 2

var _arte: Sprite2D
var _escala: Vector2 = Vector2.ONE
var _t: float = 0.0
var _tiro_t: float = 0.0
var _avisou: bool = false
var _pulso: float = 0.0
var _tween_flash: Tween

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 0
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = raio
	forma.shape = circulo
	add_child(forma)
	material = ShaderMaterial.new()
	material.shader = preload("res://flash.gdshader")
	material.set_shader_parameter("semente", randf() * 100.0)
	material.set_shader_parameter("tremido", 0.003)
	_arte = Sprite2D.new()
	_arte.texture = preload("res://assets/inimigos/chefe_3_pedaco.png")
	_arte.use_parent_material = true
	_escala = Vector2.ONE * (raio * 2.0 * 1.6 / _arte.texture.get_width())
	_arte.scale = _escala
	add_child(_arte)
	_tiro_t = atraso_tiro

func _process(delta: float) -> void:
	if not is_instance_valid(boss):
		queue_free()
		return
	_t += delta
	var r: float = sin(_t * 6.0)
	_arte.scale = _escala * Vector2(1.0 + 0.08 * r, 1.0 - 0.08 * r) * (1.0 + _pulso)
	boss._comportamento.mover_pedaco(self, _t, fase_mov, delta)
	_tiro_t += delta
	var intervalo: float = boss._comportamento.intervalo_tiro()
	if not _avisou and _tiro_t >= intervalo - 0.5:
		_avisou = true
		boss._comportamento.avisar_tiro_mirado(self)
	if _tiro_t >= intervalo:
		_tiro_t = 0.0
		_avisou = false
		boss._comportamento.atirar_mirado(self)

## Todo dano vai para a vida compartilhada do chefe.
func receber_dano(quantidade: int) -> void:
	receber_dano_detalhado(quantidade, false)

func receber_dano_detalhado(quantidade: int, critico: bool) -> void:
	if not is_instance_valid(boss):
		return
	piscar()
	boss.dano_compartilhado(quantidade, critico, global_position)

func aplicar_dot(dps: int, duracao: float) -> void:
	if is_instance_valid(boss):
		boss.aplicar_dot(dps, duracao)

func piscar() -> void:
	if _tween_flash:
		_tween_flash.kill()
	material.set_shader_parameter("flash", 0.75)
	_tween_flash = create_tween()
	_tween_flash.tween_method(func(v: float): material.set_shader_parameter("flash", v), 0.75, 0.0, 0.1)
