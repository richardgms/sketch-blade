extends RefCounted
## Chefe do capítulo 9: Pena de escrever.
##
## Fica no alto balançando e atira o leque mirado (aviso: incha). Entre os
## leques sorteia um ataque, sem repetir o último:
## - PAREDE: vai a um canto e atravessa a tela escrevendo uma linha grossa de
##   tinta (a escrita é o aviso) com uma fresta PERTO da caneta; a linha desce
##   e fere quem não estiver na fresta. Com raiva, escreve uma 2ª parede na
##   volta, com a fresta do outro lado da caneta.
## - CHUVA: pingos de tinta caem do alto por 2 s, alguns mirando a caneta
##   (com raiva, mais densos).
## - MERGULHO: linha tracejada travada na caneta e a pena crava a ponta no
##   papel, fica presa um instante e volta (com raiva, 2 mergulhos).

enum Fase { ENTRADA, PASSEIO, ATAQUE }
enum Passo { NENHUM, IR_CANTO, ESCREVER, MIRA, MERGULHO, PRESA, VOLTA }

const Y_ALVO: float = 300.0
const PONTA_Y: float = 105.0 # da origem do chefe até a ponta da pena
const ATAQUES: Array = ["parede", "chuva", "mergulho"]
const PAREDE := preload("res://chefes/ParedeTinta.gd")
const LARGURA_FRESTA: float = 230.0

var boss: Node2D
var fase: Fase = Fase.ENTRADA
var passo: Passo = Passo.NENHUM
var _t: float = 0.0
var _tp: float = 0.0 # tempo dentro do passo
var _t_balanco: float = 0.0
var _tempo_passeio: float = 1.8
var _ultimo_ataque: String = ""
var _ataque: String = ""
var _avisou: bool = false
var _feitos: int = 0
var _fim: bool = false # ataque terminado: espera _tp e volta ao passeio

# parede
var _parede = null
var _lado_fresta: float = 1.0
var _destino_x: float = 0.0
# mergulho
var _dir_mergulho: Vector2 = Vector2.DOWN
# chuva
var _pingo_t: float = 0.0

func _init(b: Node2D) -> void:
	boss = b

func _furioso() -> bool:
	return boss.hp <= boss.hp_max / 2

func processar(delta: float) -> void:
	_t += delta
	_tp += delta
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
			_virar(0.0, delta)
			_balancar(delta)
			if not _avisou and _t >= _tempo_passeio * 0.5 - boss.TEMPO_AVISO:
				_avisou = true
				boss._avisar_leque()
			if _avisou and _feitos == 0 and _t >= _tempo_passeio * 0.5:
				_feitos = 1
				boss._disparar_leque()
			if _t >= _tempo_passeio:
				var opcoes: Array = ATAQUES.filter(func(a): return a != _ultimo_ataque)
				_iniciar_ataque(opcoes[randi() % opcoes.size()])
		Fase.ATAQUE:
			match _ataque:
				"parede": _processar_parede(delta)
				"chuva": _processar_chuva(delta)
				"mergulho": _processar_mergulho(delta)
			if _fim and _tp >= 0.6:
				# volta a balançar a partir de onde está (sem pulo)
				_t_balanco = asin(clampf((boss.position.x - 540.0) / 300.0, -1.0, 1.0)) / 0.9
				_tempo_passeio = randf_range(1.6, 2.4) * (0.8 if _furioso() else 1.0)
				_ir(Fase.PASSEIO)

func _ir(nova: Fase) -> void:
	fase = nova
	_t = 0.0
	_tp = 0.0
	_avisou = false
	_feitos = 0
	_fim = false
	passo = Passo.NENHUM

func _passo(novo: Passo) -> void:
	passo = novo
	_tp = 0.0

func _terminar() -> void:
	_fim = true
	passo = Passo.NENHUM
	_tp = 0.0

func _balancar(delta: float) -> void:
	_t_balanco += delta
	boss.position.x = 540.0 + sin(_t_balanco * 0.9) * 300.0

func _iniciar_ataque(nome: String) -> void:
	_ataque = nome
	_ultimo_ataque = nome
	_ir(Fase.ATAQUE)
	match nome:
		"parede":
			_destino_x = 0.0 if boss.position.x < 540.0 else 1080.0
			_passo(Passo.IR_CANTO)
		"chuva":
			_pingo_t = 0.0
			boss._avisar_leque()
		"mergulho":
			_mirar_mergulho()

# --- PAREDE -----------------------------------------------------------------

func _processar_parede(delta: float) -> void:
	match passo:
		Passo.IR_CANTO:
			boss.position.x = move_toward(boss.position.x, _destino_x, 1500.0 * delta)
			if absf(boss.position.x - _destino_x) < 1.0:
				_comecar_parede()
		Passo.ESCREVER:
			boss.position.x = move_toward(boss.position.x, _destino_x, 1250.0 * delta)
			_parede.escrito_ate = boss.position.x
			if absf(boss.position.x - _destino_x) < 1.0:
				_parede.soltar()
				_feitos += 1
				if _furioso() and _feitos < 2:
					_comecar_parede(-_lado_fresta)
				else:
					_terminar()

## Cria a linha a partir da ponta da pena; fresta a 130–220 px da caneta.
## `lado` 0 = sorteia; senão força o lado (2ª parede: o outro lado).
func _comecar_parede(lado: float = 0.0) -> void:
	var px: float = _x_caneta()
	_lado_fresta = lado if lado != 0.0 else (1.0 if randf() < 0.5 else -1.0)
	var d: float = randf_range(130.0, 220.0)
	var meio: float = px + _lado_fresta * d
	var minimo: float = LARGURA_FRESTA / 2.0 + 20.0
	if meio < minimo or meio > 1080.0 - minimo:
		_lado_fresta = -_lado_fresta
		meio = px + _lado_fresta * d
	_parede = PAREDE.new()
	_parede.y = boss.position.y + PONTA_Y
	_parede.fresta_x = clampf(meio, minimo, 1080.0 - minimo)
	_parede.largura_fresta = LARGURA_FRESTA
	_parede.velocidade = 430.0 if _furioso() else 380.0
	_parede.chefe = boss
	_parede.escrito_de = boss.position.x
	_parede.escrito_ate = boss.position.x
	_por_no_cenario(_parede)
	_destino_x = 1080.0 - boss.position.x # atravessa para o outro canto
	_passo(Passo.ESCREVER)

# --- CHUVA ------------------------------------------------------------------

func _processar_chuva(delta: float) -> void:
	_balancar(delta * 0.4)
	if _fim:
		return
	if _tp < 0.5: # incha antes de começar
		return
	var intervalo: float = 0.09 if _furioso() else 0.14
	_pingo_t += delta
	while _pingo_t >= intervalo:
		_pingo_t -= intervalo
		_feitos += 1
		var x: float = _x_caneta() if _feitos % 3 == 0 else randf_range(60.0, 1020.0)
		boss.atirar(Vector2(x, 200.0), Vector2.DOWN, 520.0, 12.0, "tinta")
	if _tp >= 2.5:
		_terminar()

# --- MERGULHO ---------------------------------------------------------------

func _mirar_mergulho() -> void:
	_dir_mergulho = boss.mira(boss.position)
	if _dir_mergulho.y < 0.5: # nunca quase na horizontal
		_dir_mergulho = Vector2(signf(_dir_mergulho.x) * 0.866, 0.5)
	var aviso = preload("res://AvisoTiro.gd").new()
	aviso.direcoes = [_dir_mergulho]
	aviso.cor = Color("d63a2f")
	aviso.duracao = 0.75
	aviso.comprimento = 1500.0
	aviso.atras_do_atirador = false
	aviso.position = boss.position
	boss.get_parent().add_child(aviso)
	_passo(Passo.MIRA)

func _processar_mergulho(delta: float) -> void:
	match passo:
		Passo.MIRA:
			_virar(_dir_mergulho.angle() - PI / 2.0, delta)
			boss.position.x += sin(_tp * 60.0) * 1.5
			if _tp >= 0.75:
				_passo(Passo.MERGULHO)
		Passo.MERGULHO:
			boss.position += _dir_mergulho * 1300.0 * delta
			var p: Vector2 = boss.position
			if p.y >= 1600.0 or p.x < 40.0 or p.x > 1040.0:
				boss.position.x = clampf(p.x, 40.0, 1040.0)
				_respingar()
				_passo(Passo.PRESA)
		Passo.PRESA:
			# cravada no papel: treme e é a melhor hora de acertar
			boss.position.x += sin(_tp * 50.0) * 1.0
			if _tp >= 0.55:
				_passo(Passo.VOLTA)
		Passo.VOLTA:
			_virar(0.0, delta)
			boss.position.y = move_toward(boss.position.y, Y_ALVO, 900.0 * delta)
			if boss.position.y <= Y_ALVO + 0.5:
				_feitos += 1
				if _furioso() and _feitos < 2:
					_mirar_mergulho()
				else:
					_terminar()

## Ao cravar: respingo de tinta e som de impacto (só visual).
func _respingar() -> void:
	var main = boss.get_parent()
	if main and main.has_method("spawn_impacto"):
		main.spawn_impacto(boss.position + Vector2(0, PONTA_Y * 0.5), Color("16323d"), true)
	if main and main.has_method("_tocar_som"):
		main._tocar_som(main._gerar_som_procedural(140.0, 0.15, "square"))

# --- comum ------------------------------------------------------------------

func _x_caneta() -> float:
	var player = boss.get_tree().get_first_node_in_group("player")
	return player.global_position.x if player else 540.0

## Nó no cenário logo atrás da caneta (por cima do papel).
func _por_no_cenario(n: Node) -> void:
	var main = boss.get_parent()
	main.add_child(n)
	var player = boss.get_tree().get_first_node_in_group("player")
	if player and player.get_parent() == main:
		main.move_child(n, player.get_index())

## Gira o chefe todo (a ponta da pena aponta para baixo no desenho).
func _virar(alvo: float, delta: float) -> void:
	boss.rotation = lerp_angle(boss.rotation, alvo, minf(1.0, 10.0 * delta))
