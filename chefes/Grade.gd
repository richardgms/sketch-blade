extends RefCounted
## Chefe do capítulo 4: Monstro da grade.
##
## Fica no alto balançando e atira o leque mirado (aviso: incha). Entre um
## leque e outro sorteia um ataque, sem repetir o último:
## - ESMAGAR: a coluna do chão onde a caneta está enche e explode
##   (com raiva, mais uma coluna longe dela).
## - XADREZ: 3 colunas alternadas (sempre com a da caneta) enchem e explodem;
##   com raiva, logo depois explodem as outras 3.
## - PEDRAS: dois leques mirados seguidos (com raiva, + 2 gotas perseguidoras).
## O chão tem 6 colunas de 180 px: sempre sobra brecha larga para fugir.

enum Fase { ENTRADA, PASSEIO, ATAQUE }

const Y_ALVO: float = 330.0
const ATAQUES: Array = ["esmagar", "xadrez", "pedras"]
const N_COLUNAS: int = 6
const ZONA := preload("res://chefes/ZonaGrade.gd")

var boss: Node2D
var fase: Fase = Fase.ENTRADA
var _t: float = 0.0
var _t_balanco: float = 0.0
var _tempo_passeio: float = 1.8
var _duracao_ataque: float = 0.0
var _ultimo_ataque: String = ""
var _ataque: String = ""
var _leques_feitos: int = 0
var _avisou: bool = false

func _init(b: Node2D) -> void:
	boss = b

func _furioso() -> bool:
	return boss.hp <= boss.hp_max / 2

func processar(delta: float) -> void:
	_t += delta
	match fase:
		Fase.ENTRADA:
			boss.position.y += 220.0 * delta
			if boss.position.y >= Y_ALVO:
				boss.position.y = Y_ALVO
				boss.entrada_concluida = true
				boss.set_deferred("monitoring", true)
				boss.set_deferred("monitorable", true)
				_ir(Fase.PASSEIO)
		Fase.PASSEIO:
			_balancar(delta)
			# Um leque mirado no meio do passeio
			if not _avisou and _t >= _tempo_passeio * 0.5 - boss.TEMPO_AVISO:
				_avisou = true
				boss._avisar_leque()
			if _avisou and _leques_feitos == 0 and _t >= _tempo_passeio * 0.5:
				_leques_feitos = 1
				boss._disparar_leque()
			if _t >= _tempo_passeio:
				_escolher_ataque()
		Fase.ATAQUE:
			_balancar(delta * 0.25) # quase parado: janela para acertar
			if _ataque == "pedras":
				_processar_pedras()
			if _t >= _duracao_ataque:
				_tempo_passeio = randf_range(1.6, 2.4) * (0.8 if _furioso() else 1.0)
				_ir(Fase.PASSEIO)

func _ir(nova: Fase) -> void:
	fase = nova
	_t = 0.0
	_avisou = false
	_leques_feitos = 0

func _balancar(delta: float) -> void:
	_t_balanco += delta
	boss.position.x = 540.0 + sin(_t_balanco * 1.1) * 280.0

func _escolher_ataque() -> void:
	var opcoes: Array = ATAQUES.filter(func(a): return a != _ultimo_ataque)
	_iniciar_ataque(opcoes[randi() % opcoes.size()])

func _iniciar_ataque(nome: String) -> void:
	_ataque = nome
	_ultimo_ataque = nome
	match _ataque:
		"esmagar":
			var cols: Array = [_coluna_caneta()]
			if _furioso():
				# Outra coluna longe da caneta (fica brecha dos dois lados)
				var longe: Array = range(N_COLUNAS).filter(func(c): return absi(c - cols[0]) >= 2)
				cols.append(longe[randi() % longe.size()])
			var aviso: float = 1.0 if _furioso() else 1.2
			_marcar(cols, aviso, 0.0)
			_duracao_ataque = aviso + 0.5
		"xadrez":
			var par: int = _coluna_caneta() % 2
			var cols: Array = range(N_COLUNAS).filter(func(c): return c % 2 == par)
			_marcar(cols, 1.4, 0.0)
			_duracao_ataque = 1.9
			if _furioso():
				var outras: Array = range(N_COLUNAS).filter(func(c): return c % 2 != par)
				_marcar(outras, 1.1, 1.5) # começa a encher logo após a 1ª explosão
				_duracao_ataque = 3.1
		"pedras":
			_duracao_ataque = 1.9
	_socar()
	_ir(Fase.ATAQUE)

## Dois leques mirados (com aviso) e, com raiva, 2 perseguidoras no fim.
func _processar_pedras() -> void:
	var tempos: Array = [0.6, 1.3]
	if _leques_feitos < tempos.size():
		var alvo: float = tempos[_leques_feitos]
		if not _avisou and _t >= alvo - boss.TEMPO_AVISO:
			_avisou = true
			boss._avisar_leque()
		if _t >= alvo:
			boss._disparar_leque()
			_leques_feitos += 1
			_avisou = false
			if _leques_feitos == tempos.size() and _furioso():
				var d: Vector2 = boss.mira(boss.position)
				for ang in [-30.0, 30.0]:
					var dir := d.rotated(deg_to_rad(ang))
					boss.atirar(boss.position + dir * 90.0, dir, 250.0, 12.0, "perseguidora")

func _coluna_caneta() -> int:
	var player = boss.get_tree().get_first_node_in_group("player")
	var x: float = player.global_position.x if player else 540.0
	return clampi(int(x / ZONA.LARGURA_COLUNA), 0, N_COLUNAS - 1)

## Cria a zona no cenário, logo atrás da caneta (por cima do papel).
func _marcar(cols: Array, aviso: float, atraso: float) -> void:
	var main = boss.get_parent()
	var z = ZONA.new()
	z.colunas = cols
	z.aviso = aviso
	z.atraso = atraso
	z.chefe = boss
	main.add_child(z)
	var player = boss.get_tree().get_first_node_in_group("player")
	if player and player.get_parent() == main:
		main.move_child(z, player.get_index())

## O monstro "soca" o chão: encolhe e estica rápido.
func _socar() -> void:
	var tw: Tween = boss.create_tween()
	tw.tween_property(boss, "_pulso", -0.08, 0.12)
	tw.tween_property(boss, "_pulso", 0.1, 0.1)
	tw.tween_property(boss, "_pulso", 0.0, 0.25)
