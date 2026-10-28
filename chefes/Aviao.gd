extends RefCounted
## Chefe do capítulo 2: Avião de papel.
##
## Ciclo: no TOPO atira o leque (janela para acertar) → SAI pela lateral →
## AVISO tracejado na altura do rasante → RASANTE de lado a lado soltando
## bombas, sempre com uma brecha larga sem bombas → VOLTA pelo topo.
## Com menos da metade da vida: rasantes mais rápidos e dois seguidos.

enum Fase { ENTRADA, TOPO, SAINDO, AVISO, RASANTE, VOLTANDO, MIRA_MERGULHO, MERGULHO, ESQUADRILHA }

## Ataques sorteados depois do topo (nunca o mesmo duas vezes seguidas)
const ATAQUES: Array = ["rasante", "mergulho", "esquadrilha"]
var _ultimo_ataque: String = ""
var _tempo_topo: float = 3.0
var _dir_mergulho: Vector2 = Vector2.DOWN
var _esquadrilha_tiros: int = 0

const Y_TOPO: float = 260.0
const TEMPO_TOPO: float = 3.6
const TEMPO_AVISO_RASANTE: float = 0.9
const VEL_SAIDA: float = 900.0
const VEL_RASANTE: float = 950.0
const VEL_RASANTE_FURIOSO: float = 1200.0
const PASSO_BOMBA: float = 115.0
const LARGURA_BRECHA: float = 300.0
const VEL_BOMBA: float = 360.0

var boss: Node2D
var fase: Fase = Fase.ENTRADA
var _t: float = 0.0
var _tiro_t: float = 0.0
var _avisou: bool = false
var _dir: float = 1.0 # sentido do movimento horizontal
var _rasantes_restantes: int = 0
var _y_rasante: float = 600.0
var _brecha_x: float = 0.0
var _ultima_bomba_x: float = 0.0

func _init(b: Node2D) -> void:
	boss = b

func _furioso() -> bool:
	return boss.hp <= boss.hp_max / 2

func processar(delta: float) -> void:
	_t += delta
	match fase:
		Fase.ENTRADA:
			boss.position.y += 220.0 * delta
			if boss.position.y >= Y_TOPO:
				boss.position.y = Y_TOPO
				boss.entrada_concluida = true
				boss.set_deferred("monitoring", true)
				boss.set_deferred("monitorable", true)
				_ir(Fase.TOPO)
		Fase.TOPO:
			_processar_topo(delta)
		Fase.SAINDO:
			boss.position.x += _dir * VEL_SAIDA * delta
			if boss.position.x < -260.0 or boss.position.x > 1340.0:
				_rasantes_restantes = 2 if _furioso() else 1
				_preparar_rasante()
		Fase.AVISO:
			if _t >= TEMPO_AVISO_RASANTE:
				_ir(Fase.RASANTE)
		Fase.RASANTE:
			_processar_rasante(delta)
		Fase.VOLTANDO:
			boss.position.y = move_toward(boss.position.y, Y_TOPO, 500.0 * delta)
			_virar(0.0, delta)
			if boss.position.y >= Y_TOPO:
				_ir(Fase.TOPO)
		Fase.MIRA_MERGULHO:
			# Treme no lugar mirando; a linha de aviso mostra a direção travada
			_virar(_dir_mergulho.angle() - PI / 2.0, delta)
			boss.position.x += sin(_t * 60.0) * 1.5
			if _t >= 0.75:
				_ir(Fase.MERGULHO)
		Fase.MERGULHO:
			boss.position += _dir_mergulho * (1250.0 if _furioso() else 1050.0) * delta
			var p: Vector2 = boss.position
			if p.y > 1750.0 or p.x < -200.0 or p.x > 1280.0:
				boss.position = Vector2(randf_range(250.0, 830.0), -180.0)
				boss.rotation = 0.0
				_ir(Fase.VOLTANDO)
		Fase.ESQUADRILHA:
			_virar(0.0, delta)
			_tiro_t += delta
			# 3 (ou 5 com raiva) gotas perseguidoras, uma a cada 0,35 s
			var total: int = 5 if _furioso() else 3
			if _tiro_t >= 0.35 and _esquadrilha_tiros < total:
				_tiro_t = 0.0
				var lado: float = float(_esquadrilha_tiros) - (total - 1) / 2.0
				var dir := Vector2.DOWN.rotated(deg_to_rad(-lado * 22.0))
				boss.atirar(boss.position + dir * 80.0, dir, 250.0, 12.0, "perseguidora")
				_esquadrilha_tiros += 1
			if _esquadrilha_tiros >= total and _tiro_t >= 0.6:
				_ir(Fase.TOPO)

func _ir(nova: Fase) -> void:
	fase = nova
	_t = 0.0
	_tiro_t = 0.0
	_avisou = false

## No topo: balança de lado e atira o leque (com aviso), como o Borrão.
func _processar_topo(delta: float) -> void:
	boss.position.x = 540.0 + sin(_t * 1.4) * 300.0
	_virar(0.0, delta)
	_tiro_t += delta
	if not _avisou and _tiro_t >= 1.2 - boss.TEMPO_AVISO:
		_avisou = true
		boss._avisar_leque()
	if _tiro_t >= 1.2:
		_tiro_t = 0.0
		_avisou = false
		boss._disparar_leque()
	if _t >= _tempo_topo:
		_escolher_ataque()

## Sorteia o próximo ataque, sem repetir o último.
func _escolher_ataque() -> void:
	var opcoes: Array = ATAQUES.filter(func(a): return a != _ultimo_ataque)
	var ataque: String = opcoes[randi() % opcoes.size()]
	_ultimo_ataque = ataque
	_tempo_topo = randf_range(1.8, 3.4) # tempo no topo também varia
	match ataque:
		"rasante":
			_dir = 1.0 if boss.position.x >= 540.0 else -1.0
			_ir(Fase.SAINDO)
		"mergulho":
			_dir_mergulho = boss.mira(boss.position)
			var aviso = preload("res://AvisoTiro.gd").new()
			aviso.direcoes = [_dir_mergulho]
			aviso.cor = Color("d63a2f")
			aviso.duracao = 0.75
			aviso.comprimento = 1500.0
			aviso.atras_do_atirador = false
			aviso.position = boss.position
			boss.get_parent().add_child(aviso)
			_ir(Fase.MIRA_MERGULHO)
		"esquadrilha":
			_esquadrilha_tiros = 0
			boss._avisar_leque()
			_ir(Fase.ESQUADRILHA)

## Escolhe a altura e a brecha do próximo rasante e mostra o aviso na borda.
func _preparar_rasante() -> void:
	_y_rasante = randf_range(480.0, 780.0)
	_dir = -_dir # entra pelo lado oposto ao que saiu
	var x_entrada: float = -240.0 if _dir > 0.0 else 1320.0
	boss.position = Vector2(x_entrada, _y_rasante)
	_brecha_x = randf_range(90.0, 1080.0 - 90.0 - LARGURA_BRECHA)
	_ultima_bomba_x = x_entrada
	var aviso = preload("res://AvisoTiro.gd").new()
	aviso.direcoes = [Vector2(_dir, 0.0)]
	aviso.cor = Color("d63a2f")
	aviso.duracao = TEMPO_AVISO_RASANTE
	aviso.comprimento = 1080.0
	aviso.atras_do_atirador = false
	aviso.position = Vector2(0.0 if _dir > 0.0 else 1080.0, _y_rasante)
	boss.get_parent().add_child(aviso)
	_ir(Fase.AVISO)

func _processar_rasante(delta: float) -> void:
	var vel: float = VEL_RASANTE_FURIOSO if _furioso() else VEL_RASANTE
	boss.position.x += _dir * vel * delta
	_virar(-PI / 2.0 if _dir > 0.0 else PI / 2.0, delta)
	# Bombas a cada PASSO_BOMBA, menos dentro da brecha e fora da tela
	var x: float = boss.position.x
	if absf(x - _ultima_bomba_x) >= PASSO_BOMBA:
		_ultima_bomba_x = x
		var na_tela: bool = x > 40.0 and x < 1040.0
		var na_brecha: bool = x > _brecha_x and x < _brecha_x + LARGURA_BRECHA
		if na_tela and not na_brecha:
			_soltar_bomba()
	if (_dir > 0.0 and x > 1340.0) or (_dir < 0.0 and x < -260.0):
		_rasantes_restantes -= 1
		if _rasantes_restantes > 0:
			_preparar_rasante()
		else:
			boss.position = Vector2(540.0, -180.0)
			boss.rotation = 0.0
			_ir(Fase.VOLTANDO)

func _soltar_bomba() -> void:
	var main = boss.get_parent()
	var proj = null
	if main.has_method("obter_projetil_inimigo"):
		proj = main.obter_projetil_inimigo()
	else:
		proj = preload("res://enemy_projectile.tscn").instantiate()
	proj.position = boss.position + Vector2(0, 40)
	proj.setup(Vector2.DOWN, VEL_BOMBA, 11.0, "chefe")
	if not proj.is_inside_tree():
		main.add_child(proj)

## Gira o desenho (o nariz do avião aponta para baixo no desenho original).
func _virar(alvo: float, delta: float) -> void:
	boss.rotation = lerp_angle(boss.rotation, alvo, minf(1.0, 10.0 * delta))
