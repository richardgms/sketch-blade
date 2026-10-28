extends RefCounted
## Chefe do capítulo 3: Mancha de 4 lobos.
##
## Inteira: patrulha no alto e atira o leque (com aviso).
## Com 50% da vida se divide em 2 pedaços; com 25%, em 4. A vida é uma só
## (acertar qualquer pedaço tira da mesma barra). Os pedaços andam desencontrados
## e cada um atira uma gota mirada na caneta, sempre com aviso; quanto mais
## pedaços, mais devagar cada um atira (a pressão total fica parecida).

const PEDACO = preload("res://chefes/PedacoMancha.gd")
const Y_TOPO: float = 280.0
const MAX_PEDACOS: int = 4

var boss: Node2D
var _entrou: bool = false
var _t: float = 0.0
var _tiro_t: float = 0.0
var _avisou: bool = false
var divisoes: int = 1 # 1 inteira, 2 ou 4 pedaços
var _pedacos: Array = [] # pedaços extras (o próprio chefe é um deles)
var _fase_boss: float = 0.0

func _init(b: Node2D) -> void:
	boss = b
	boss.tree_exiting.connect(_limpar_pedacos)

func processar(delta: float) -> void:
	_t += delta
	if not _entrou:
		boss.position.y += 200.0 * delta
		if boss.position.y >= Y_TOPO:
			boss.position.y = Y_TOPO
			_entrou = true
			boss.entrada_concluida = true
			boss.set_deferred("monitoring", true)
			boss.set_deferred("monitorable", true)
		return

	# Divide ao cruzar 50% e 25% da vida
	if divisoes == 1 and boss.hp <= boss.hp_max * 0.5:
		_dividir(2)
	elif divisoes == 2 and boss.hp <= boss.hp_max * 0.25:
		_dividir(4)

	if divisoes == 1:
		boss.position.x = 540.0 + sin(_t * 0.9) * 330.0
		_tiro_t += delta
		if not _avisou and _tiro_t >= 1.5 - boss.TEMPO_AVISO:
			_avisou = true
			boss._avisar_leque()
		if _tiro_t >= 1.5:
			_tiro_t = 0.0
			_avisou = false
			boss._disparar_leque()
	else:
		# O próprio chefe vira um dos pedaços
		mover_pedaco(boss, _t, _fase_boss, delta)
		_tiro_t += delta
		if not _avisou and _tiro_t >= intervalo_tiro() - 0.5:
			_avisou = true
			avisar_tiro_mirado(boss)
		if _tiro_t >= intervalo_tiro():
			_tiro_t = 0.0
			_avisou = false
			atirar_mirado(boss)

## Cada pedaço passeia por uma faixa própria no alto da tela.
func mover_pedaco(no: Node2D, _t_pedaco: float, fase: float, delta: float) -> void:
	# Relógio único (o do chefe): os pedaços ficam sempre desencontrados
	var t: float = _t
	var vel: float = 0.8 + 0.25 * (divisoes / 2.0)
	var alvo := Vector2(540.0 + sin(t * vel + fase) * 400.0, 300.0 + sin(t * vel * 1.7 + fase * 2.0) * 110.0)
	no.position = no.position.lerp(alvo, minf(1.0, 3.0 * delta))

func intervalo_tiro() -> float:
	return 1.4 * divisoes # 2 pedaços: 2,8 s cada; 4 pedaços: 5,6 s cada

func _direcao_mirada(no: Node2D) -> Vector2:
	var player = boss.get_tree().get_first_node_in_group("player")
	if player:
		return (player.global_position - no.global_position).normalized()
	return Vector2.DOWN

func avisar_tiro_mirado(no: Node2D) -> void:
	var aviso = preload("res://AvisoTiro.gd").new()
	aviso.direcoes = [_direcao_mirada(no)]
	aviso.cor = Color("d63a2f")
	aviso.duracao = 0.5
	aviso.comprimento = 240.0
	aviso.inicio = Vector2(0, 0)
	no.add_child(aviso)
	no.set_meta("dir_mirada", aviso.direcoes[0])

func atirar_mirado(no: Node2D) -> void:
	var main = boss.get_parent()
	var proj = main.obter_projetil_inimigo() if main.has_method("obter_projetil_inimigo") \
		else preload("res://enemy_projectile.tscn").instantiate()
	var dir: Vector2 = no.get_meta("dir_mirada", Vector2.DOWN)
	proj.position = no.global_position + dir * 40.0
	proj.setup(dir, 430.0, 11.0, "chefe")
	if not proj.is_inside_tree():
		main.add_child(proj)

func _dividir(n: int) -> void:
	var main = boss.get_parent()
	var antes: int = divisoes
	divisoes = n
	# O chefe passa a ser um pedaço (desenho de um lobo só, menor)
	var raio_pedaco: float = 55.0 if n == 2 else 42.0
	boss._aplicar_arte("res://assets/inimigos/chefe_3_pedaco.png", raio_pedaco * 1.6 / boss.raio_visual)
	var forma: CollisionShape2D = boss.get_node_or_null("CollisionShape2D")
	if forma and forma.shape is CircleShape2D:
		forma.shape = forma.shape.duplicate()
		forma.shape.radius = raio_pedaco
	for p in _pedacos:
		if is_instance_valid(p):
			p.queue_free()
	_pedacos.clear()
	for i in range(1, n):
		var p = PEDACO.new()
		p.boss = boss
		p.raio = raio_pedaco
		p.fase_mov = TAU * i / n
		p.atraso_tiro = 1.4 * i
		p.position = boss.position + Vector2(randf_range(-60, 60), randf_range(-30, 30))
		main.add_child(p)
		_pedacos.append(p)
	_fase_boss = 0.0
	_tiro_t = 0.0
	_avisou = false
	# Efeito do "estouro" em pedaços
	if main.has_method("_spawn_particles"):
		for i in 3:
			main._spawn_particles(Color("3b1d6e"), boss.position + Vector2(randf_range(-50, 50), randf_range(-40, 40)))
	if main.has_method("_shake_tela"):
		main._shake_tela(12.0 if antes == 1 else 16.0)
	if main.has_method("_spawn_feedback"):
		main._spawn_feedback("SE DIVIDIU!", "miss", boss.position + Vector2(0, 120))

## Quando o chefe morre, os pedaços estouram junto.
func _limpar_pedacos() -> void:
	var main = boss.get_parent()
	for p in _pedacos:
		if is_instance_valid(p):
			if main and main.has_method("_spawn_particles"):
				main._spawn_particles(Color("3b1d6e"), p.global_position)
			if main and main.has_node("Paper"):
				main.get_node("Paper").adicionar_mancha(p.global_position, Color("3b1d6e"), 26.0)
			p.queue_free()
	_pedacos.clear()
