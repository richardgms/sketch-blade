extends RefCounted
## Chefe do capítulo 6: Pirata do mapa.
##
## Fica no alto balançando e atira o leque mirado (aviso: incha). Não tem fase
## invulnerável. Entre os leques sorteia um ataque, sem repetir o último:
## - TESOURO: um X no chão onde a caneta está; a bomba voa em arco e explode
##   (com raiva, 3 X seguidos, cada um onde a caneta estiver).
## - CHUVA: vários X espalhados (um na caneta, brechas largas entre eles)
##   que explodem um depois do outro; com raiva, uma 2ª chuva fecha as brechas.
## - CANHÃO: 3 balas miradas seguidas (com raiva, + 2 perseguidoras).

enum Fase { ENTRADA, PASSEIO, ATAQUE }

const Y_ALVO: float = 320.0
const ATAQUES: Array = ["tesouro", "chuva", "canhao"]
const ESPACO_CHUVA: float = 360.0 # distância entre X da mesma chuva
const BOMBA := preload("res://chefes/ZonaBomba.gd")

var boss: Node2D
var fase: Fase = Fase.ENTRADA
var _t: float = 0.0
var _t_balanco: float = 0.0
var _tempo_passeio: float = 1.8
var _duracao_ataque: float = 0.0
var _ultimo_ataque: String = ""
var _ataque: String = ""
var _feitos: int = 0 # marcas/tiros já feitos no ataque atual
var _avisou: bool = false
var _x_chuva: float = 540.0

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
			_balancar(delta * 0.4)
			match _ataque:
				"tesouro": _processar_tesouro()
				"chuva": _processar_chuva()
				"canhao": _processar_canhao()
			if _t >= _duracao_ataque:
				_tempo_passeio = randf_range(1.6, 2.4) * (0.8 if _furioso() else 1.0)
				_ir(Fase.PASSEIO)

func _ir(nova: Fase) -> void:
	fase = nova
	_t = 0.0
	_avisou = false
	_feitos = 0

func _balancar(delta: float) -> void:
	_t_balanco += delta
	boss.position.x = 540.0 + sin(_t_balanco * 0.9) * 300.0

func _iniciar_ataque(nome: String) -> void:
	_ataque = nome
	_ultimo_ataque = nome
	match nome:
		"tesouro":
			_duracao_ataque = 2.6 if _furioso() else 1.6
		"chuva":
			_x_chuva = _x_caneta()
			_duracao_ataque = 3.6 if _furioso() else 2.2
		"canhao":
			_duracao_ataque = 1.9
	_ir(Fase.ATAQUE)

## Um X na caneta (com raiva, 3 X com 0,5 s entre eles).
func _processar_tesouro() -> void:
	var total: int = 3 if _furioso() else 1
	if _feitos < total and _t >= _feitos * 0.5:
		_marcar(_x_caneta(), 0.4, 0.7)
		_feitos += 1

## X a cada 360 px a partir da caneta, caindo em ordem aleatória.
## Com raiva, 1,4 s depois uma 2ª chuva no meio das brechas da 1ª.
func _processar_chuva() -> void:
	if _feitos == 0:
		_chuva(_x_chuva)
		_feitos = 1
	elif _feitos == 1 and _furioso() and _t >= 1.4:
		_chuva(_x_chuva + ESPACO_CHUVA / 2.0)
		_feitos = 2

func _chuva(x0: float) -> void:
	var xs: Array = []
	var x: float = x0
	while x - ESPACO_CHUVA >= 40.0:
		x -= ESPACO_CHUVA
	while x <= 1040.0:
		xs.append(clampf(x + randf_range(-25.0, 25.0), 60.0, 1020.0))
		x += ESPACO_CHUVA
	xs.shuffle()
	for i in xs.size():
		_marcar(xs[i], 0.6 + 0.18 * i, 0.6)
	_socar()

## 3 balas de canhão miradas, cada uma avisada pelo inchar.
func _processar_canhao() -> void:
	var tempos: Array = [0.55, 0.95, 1.35]
	if _feitos >= tempos.size():
		return
	var alvo: float = tempos[_feitos]
	if not _avisou and _t >= alvo - boss.TEMPO_AVISO:
		_avisou = true
		boss._avisar_leque()
	if _t >= alvo:
		var d: Vector2 = boss.mira(boss.position)
		boss.atirar(boss.position + d * 80.0, d, 620.0, 16.0, "chefe")
		_feitos += 1
		_avisou = false
		if _feitos == tempos.size() and _furioso():
			for ang in [-30.0, 30.0]:
				var dir := d.rotated(deg_to_rad(ang))
				boss.atirar(boss.position + dir * 90.0, dir, 250.0, 12.0, "perseguidora")

func _x_caneta() -> float:
	var player = boss.get_tree().get_first_node_in_group("player")
	return player.global_position.x if player else 540.0

## Cria o X no cenário, logo atrás da caneta (por cima do papel).
func _marcar(x: float, atraso: float, voo: float) -> void:
	var main = boss.get_parent()
	var z = BOMBA.new()
	z.alvo_x = x
	z.atraso = atraso
	z.voo = voo
	z.chefe = boss
	main.add_child(z)
	var player = boss.get_tree().get_first_node_in_group("player")
	if player and player.get_parent() == main:
		main.move_child(z, player.get_index())

## Joga o braço: encolhe e estica rápido.
func _socar() -> void:
	var tw: Tween = boss.create_tween()
	tw.tween_property(boss, "_pulso", -0.08, 0.12)
	tw.tween_property(boss, "_pulso", 0.1, 0.1)
	tw.tween_property(boss, "_pulso", 0.0, 0.25)
