extends Area2D
## Pedaço da Mancha (chefe do cap. 3). Tem vida própria e morre sozinho; a
## barra do chefe mostra a soma da vida dos pedaços. Pedaço grande (geração 1)
## se divide em 2 pequenos quando perde metade da vida dele.

var mancha                    # comportamento (chefes/Mancha.gd)
var hp: int = 100
var hp_inicial: int = 100
var geracao: int = 1
var raio: float = 60.0
var indice: int = 0           # posição no "carrossel" de pedaços
var morre_no_contato: bool = false
var dano_contato: int = 2

var _arte: Sprite2D
var _escala: Vector2 = Vector2.ONE
var _t: float = 0.0
var _tiro_t: float = 0.0
var _tiros: int = 0
var _avisou: bool = false
var _dir_tiro: Vector2 = Vector2.DOWN
var _tween_flash: Tween
var _morto: bool = false
var _pulso: float = 0.0

# Tinta Corrosiva no próprio pedaço
var _dot_dps: int = 0
var _dot_restante: float = 0.0
var _dot_acum: float = 0.0

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
	_tiro_t = randf_range(0.0, 0.8) # desencontra os tiros

func _process(delta: float) -> void:
	if _morto or mancha == null:
		return
	_t += delta
	var r: float = sin(_t * 6.0)
	var bravo: float = 1.0 + (0.15 if mancha.pedacos_vivos() == 1 else 0.0)
	_arte.scale = _escala * Vector2(1.0 + 0.08 * r, 1.0 - 0.08 * r) * bravo * (1.0 + _pulso)
	mancha.mover_pedaco(self, delta)

	if _dot_restante > 0.0:
		_dot_restante -= delta
		_dot_acum += _dot_dps * delta
		if _dot_acum >= 1.0:
			var d := int(_dot_acum)
			_dot_acum -= d
			receber_dano(d)
			if _morto:
				return

	_tiro_t += delta
	var intervalo: float = mancha.intervalo_tiro()
	if not _avisou and _tiro_t >= intervalo - 0.5:
		_avisou = true
		_dir_tiro = mancha.boss.mira(global_position)
		mancha.avisar(self, _dir_tiro)
	if _tiro_t >= intervalo:
		_tiro_t = 0.0
		_avisou = false
		_tiros += 1
		# Alterna gota mirada (rápida) e gota perseguidora (lenta, curva)
		if _tiros % 2 == 0:
			mancha.boss.atirar(global_position + _dir_tiro * raio, _dir_tiro, 260.0, 11.0, "perseguidora")
		else:
			mancha.boss.atirar(global_position + _dir_tiro * raio, _dir_tiro, 470.0, 11.0, "chefe")

## Incha durante 'duracao' segundos antes de atirar (o aviso do tiro).
func inchar(duracao: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_pulso", 0.2, duracao * 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_pulso", 0.0, duracao * 0.2)

func receber_dano(quantidade: int) -> void:
	receber_dano_detalhado(quantidade, false)

func receber_dano_detalhado(quantidade: int, critico: bool) -> void:
	if _morto or mancha == null:
		return
	var q: int = mini(quantidade, hp)
	hp -= q
	mancha.tirar_da_barra(q)
	var main = get_parent()
	if hp > 0 and main and main.has_method("spawn_dano_chefe"):
		main.spawn_dano_chefe(quantidade, critico)
	_piscar()
	if hp <= 0:
		_morrer()
	elif geracao == 1 and hp <= hp_inicial / 2:
		_morto = true
		mancha.dividir_pedaco(self)

func aplicar_dot(dps: int, duracao: float) -> void:
	_dot_dps = maxi(_dot_dps, dps)
	_dot_restante = duracao
	modulate = Color(0.75, 1.1, 0.75)

func _piscar() -> void:
	if _tween_flash:
		_tween_flash.kill()
	material.set_shader_parameter("flash", 0.75)
	_tween_flash = create_tween()
	_tween_flash.tween_method(func(v: float): material.set_shader_parameter("flash", v), 0.75, 0.0, 0.1)

func _morrer() -> void:
	_morto = true
	remove_from_group("enemies")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	mancha.pedaco_morreu(self)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.35, 0.6), 0.06)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.12)
	tw.finished.connect(queue_free)
