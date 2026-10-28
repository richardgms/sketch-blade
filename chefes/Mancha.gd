extends RefCounted
## Chefe do capítulo 3: Mancha de 4 lobos.
##
## Inteira: patrulha no alto e atira o leque mirado (com aviso); a cada 2
## leques solta também uma gota perseguidora.
## Com 50% da vida se divide em 2 pedaços grandes; cada um, ao perder metade da
## vida dele, vira 2 pequenos (máx. 4). Cada pedaço tem vida própria e morre
## sozinho; a barra mostra a soma. O último pedaço fica bravo e atira rápido.
## Depois da divisão o nó do chefe vira só o "controle" (invisível, sem colisão).

const PEDACO = preload("res://chefes/PedacoMancha.gd")
const Y_TOPO: float = 280.0
const COR := Color("3b1d6e")

var boss: Node2D
var _entrou: bool = false
var _t: float = 0.0
var _tiro_t: float = 0.0
var _avisou: bool = false
var _leques: int = 0
var dividida: bool = false
var _pedacos: Array = []

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
	if dividida:
		return # os pedaços se movem e atiram sozinhos

	if boss.hp <= boss.hp_max * 0.5:
		_dividir_inicial()
		return

	boss.position.x = 540.0 + sin(_t * 0.9) * 330.0
	_tiro_t += delta
	if not _avisou and _tiro_t >= 1.4 - boss.TEMPO_AVISO:
		_avisou = true
		boss._avisar_leque()
	if _tiro_t >= 1.4:
		_tiro_t = 0.0
		_avisou = false
		boss._disparar_leque()
		_leques += 1
		if _leques % 2 == 0:
			var d: Vector2 = boss.mira(boss.position)
			boss.atirar(boss.position + d * 90.0, d, 260.0, 11.0, "perseguidora")

## --- divisão -------------------------------------------------------------

func _dividir_inicial() -> void:
	dividida = true
	boss.dot_restante = 0.0 # a vida agora é dos pedaços
	boss._arte.visible = false
	boss.remove_from_group("enemies") # explosões e ricochetes miram só os pedaços
	boss.set_deferred("monitoring", false)
	boss.set_deferred("monitorable", false)
	var metade: int = boss.hp / 2
	_criar_pedaco(1, metade, boss.position + Vector2(-90, 0))
	_criar_pedaco(1, boss.hp - metade, boss.position + Vector2(90, 0))
	_efeito_divisao(boss.position, 12.0)

func dividir_pedaco(p) -> void:
	_pedacos.erase(p)
	var metade: int = p.hp / 2
	_criar_pedaco(2, metade, p.position + Vector2(-50, 0))
	_criar_pedaco(2, p.hp - metade, p.position + Vector2(50, 0))
	_efeito_divisao(p.position, 9.0)
	p.queue_free()

func _criar_pedaco(geracao: int, hp: int, pos: Vector2) -> void:
	var p = PEDACO.new()
	p.mancha = self
	p.geracao = geracao
	p.hp = maxi(1, hp)
	p.hp_inicial = p.hp
	p.raio = 60.0 if geracao == 1 else 44.0
	p.position = pos
	# Diferido: a divisão acontece dentro da colisão do tiro, quando o Godot
	# não deixa criar áreas de colisão
	boss.get_parent().add_child.call_deferred(p)
	_pedacos.append(p)
	_reindexar()

func pedaco_morreu(p) -> void:
	_pedacos.erase(p)
	var main = boss.get_parent()
	if main.has_method("_spawn_particles"):
		main._spawn_particles(COR, p.global_position)
	if main.has_node("Paper"):
		main.get_node("Paper").adicionar_mancha(p.global_position, COR, 26.0)
	_reindexar()
	if _pedacos.is_empty():
		boss.position = p.global_position # efeitos de vitória onde o último caiu
		boss.hp = 0
		boss.hp_alterado.emit(0)
		boss.morrer()

func tirar_da_barra(q: int) -> void:
	boss.hp = maxi(0, boss.hp - q)
	boss.hp_alterado.emit(boss.hp)

func pedacos_vivos() -> int:
	return _pedacos.size()

## --- movimento e tiros dos pedaços ---------------------------------------

func _reindexar() -> void:
	for i in _pedacos.size():
		_pedacos[i].indice = i

## Carrossel: cada pedaço passeia numa faixa própria, sempre desencontrado.
func mover_pedaco(p, delta: float) -> void:
	var n: int = maxi(1, _pedacos.size())
	var fase: float = TAU * p.indice / n
	var vel: float = 0.9 if n > 1 else 1.4
	var alvo := Vector2(540.0 + sin(_t * vel + fase) * 400.0, 310.0 + sin(_t * vel * 1.7 + fase * 2.0) * 120.0)
	p.position = p.position.lerp(alvo, minf(1.0, 2.5 * delta))

## Intervalo entre tiros de cada pedaço: mais pedaços, um pouco mais lento;
## o último fica bravo.
func intervalo_tiro() -> float:
	match _pedacos.size():
		1: return 0.9
		2: return 1.4
		3: return 1.7
		_: return 1.9

func avisar(p, dir: Vector2) -> void:
	var aviso = preload("res://AvisoTiro.gd").new()
	aviso.direcoes = [dir]
	aviso.cor = Color("d63a2f")
	aviso.duracao = 0.5
	aviso.comprimento = 220.0
	aviso.inicio = dir * p.raio
	p.add_child(aviso)

func _efeito_divisao(pos: Vector2, tremor: float) -> void:
	var main = boss.get_parent()
	if main.has_method("_spawn_particles"):
		for i in 3:
			main._spawn_particles(COR, pos + Vector2(randf_range(-50, 50), randf_range(-40, 40)))
	if main.has_method("_shake_tela"):
		main._shake_tela(tremor)
	if main.has_method("aviso_topo"):
		main.aviso_topo("SE DIVIDIU!", Color("6c3483"))

func _limpar_pedacos() -> void:
	for p in _pedacos:
		if is_instance_valid(p):
			p.queue_free()
	_pedacos.clear()
