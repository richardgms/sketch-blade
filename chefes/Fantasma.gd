extends RefCounted
## Chefe do capítulo 8: Fantasma de página.
##
## Meio transparente e com SOMBRA no papel. Fica no alto balançando e atira o
## leque mirado (aviso: incha). Entre os leques sorteia, sem repetir o último:
## - CÓPIAS: some e reaparece em 3 lugares; só o verdadeiro tem sombra.
##   Todos incham e atiram igual. Cópia some com 1 tiro. Acaba em 6 s ou
##   quando todas as cópias somem. Com raiva, no meio todos piscam e TROCAM
##   de lugar (4 fantasmas não cabem na tela sem se encostar).
## - FOLHAS: arranca páginas que caem balançando, a 1ª em cima da caneta
##   (4 folhas; 6 com raiva).
## - UIVO: 3 gotas perseguidoras (5 com raiva).

enum Fase { ENTRADA, PASSEIO, ATAQUE }

const Y_ALVO: float = 400.0 # abaixo do aviso no topo
const ATAQUES: Array = ["copias", "folhas", "uivo"]
const TRANSPARENCIA: float = 0.82
const TEMPO_SUMIR: float = 0.35
const TEMPO_COPIAS: float = 6.0
const INTERVALO_TIRO_COPIAS: float = 2.3 # era 1,8: 3 fantasmas atirando pesavam demais
const COPIA := preload("res://chefes/CopiaFantasma.gd")
const FOLHA := preload("res://chefes/FolhaFantasma.gd")

var boss: Node2D
var fase: Fase = Fase.ENTRADA
var _t: float = 0.0
var _tp: float = 0.0
var _t_balanco: float = 0.0
var _tempo_passeio: float = 1.8
var _ultimo_ataque: String = ""
var _ataque: String = ""
var _passo: String = ""
var _avisou: bool = false
var _feitos: int = 0
var _fim: bool = false

# cópias
var _copias: Array = []
var _vagas: Array = [] # posições: [verdadeiro, cópia, cópia...]
var _relogios: Array = [] # relógio de tiro de cada fantasma (0 = verdadeiro)
var _sombra: Node2D
var _trocou: bool = false
var _troca_t: float = -1.0 # < 0: sem troca acontecendo

func _init(b: Node2D) -> void:
	boss = b
	if boss._arte:
		boss._arte.modulate.a = TRANSPARENCIA
	_sombra = Node2D.new()
	_sombra.show_behind_parent = true
	_sombra.draw.connect(func():
		_sombra.draw_set_transform(Vector2(0, 205), 0.0, Vector2(1.0, 0.24))
		_sombra.draw_circle(Vector2.ZERO, 85.0, Color(0.1, 0.12, 0.25, 0.22))
		_sombra.draw_circle(Vector2.ZERO, 55.0, Color(0.1, 0.12, 0.25, 0.25))
	)
	boss.add_child(_sombra)

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
				"copias": _processar_copias(delta)
				"folhas": _processar_folhas(delta)
				"uivo": _processar_uivo(delta)
			if _fim and _tp >= 0.5:
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

func _terminar() -> void:
	_fim = true
	_tp = 0.0

func _balancar(delta: float) -> void:
	_t_balanco += delta
	var alvo: float = 540.0 + sin(_t_balanco * 0.9) * 300.0
	boss.position.x = move_toward(boss.position.x, alvo, 700.0 * delta)

func _iniciar_ataque(nome: String) -> void:
	_ataque = nome
	_ultimo_ataque = nome
	_ir(Fase.ATAQUE)
	if nome == "copias":
		_passo = "some"
		_trocou = false
		_troca_t = -1.0
	elif nome == "uivo":
		boss._avisar_leque()

# --- CÓPIAS -----------------------------------------------------------------

func _processar_copias(delta: float) -> void:
	match _passo:
		"some":
			boss.modulate.a = 1.0 - minf(_tp / TEMPO_SUMIR, 1.0)
			if _tp >= TEMPO_SUMIR:
				_espalhar()
				_passo = "aparece"
				_tp = 0.0
		"aparece":
			var a: float = minf(_tp / TEMPO_SUMIR, 1.0)
			boss.modulate.a = a
			for c in _copias:
				if is_instance_valid(c):
					c.modulate.a = a
			_flutuar()
			if _tp >= TEMPO_SUMIR:
				_passo = "luta"
				_tp = 0.0
		"luta":
			_flutuar()
			if _furioso() and not _trocou and _tp >= TEMPO_COPIAS / 2.0:
				_trocou = true
				_troca_t = 0.0
			if _troca_t >= 0.0:
				_trocar_lugares(delta)
			else:
				_atirar_todos(delta)
			var vivas: int = _copias.filter(func(c): return is_instance_valid(c) and not c.morrendo).size()
			if _tp >= TEMPO_COPIAS or vivas == 0:
				_passo = "junta"
				_tp = 0.0
		"junta":
			var a: float = 1.0 - minf(_tp / TEMPO_SUMIR, 1.0)
			boss.modulate.a = a
			for c in _copias:
				if is_instance_valid(c) and not c.morrendo:
					c.modulate.a = a
			if _tp >= TEMPO_SUMIR:
				for c in _copias:
					if is_instance_valid(c) and not c.morrendo:
						c.queue_free()
				_copias.clear()
				boss.position = Vector2(540.0, Y_ALVO)
				_passo = "volta"
				_tp = 0.0
		"volta":
			boss.modulate.a = minf(_tp / TEMPO_SUMIR, 1.0)
			if _tp >= TEMPO_SUMIR:
				boss.modulate.a = 1.0
				_passo = ""
				_terminar()

## Sorteia as vagas; o verdadeiro vai para uma delas e as cópias para as outras.
func _espalhar() -> void:
	var xs: Array = [200.0, 540.0, 880.0]
	_vagas.clear()
	_relogios.clear()
	for i in xs.size():
		_vagas.append(Vector2(xs[i], Y_ALVO + randf_range(-20.0, 30.0)))
		_relogios.append(-0.45 * i) # desencontra os tiros
	_vagas.shuffle() # a 1ª vaga é a do verdadeiro
	boss.position = _vagas[0]
	var main = boss.get_parent()
	for i in range(1, _vagas.size()):
		var c = COPIA.new()
		c.fantasma = self
		c.raio = boss.get_node("CollisionShape2D").shape.radius
		c.escala = boss._escala_arte
		c.position = _vagas[i]
		c.modulate = Color(1, 1, 1, 0)
		main.add_child(c)
		_copias.append(c)
	if main.has_method("aviso_topo"):
		main.aviso_topo("QUAL É O VERDADEIRO?", Color("2b3a6b"))

## Com raiva: todos somem rápido, as vagas são sorteadas de novo (o
## verdadeiro também troca) e todos reaparecem.
func _trocar_lugares(delta: float) -> void:
	var antes: float = _troca_t
	_troca_t += delta
	var a: float = absf(_troca_t - 0.25) / 0.25
	_alfa_todos(clampf(a, 0.0, 1.0))
	if antes < 0.25 and _troca_t >= 0.25:
		var antigo: Vector2 = _vagas[0]
		while _vagas[0] == antigo: # o verdadeiro sempre muda de lugar
			_vagas.shuffle()
	if _troca_t >= 0.5:
		_alfa_todos(1.0)
		_troca_t = -1.0

func _alfa_todos(a: float) -> void:
	boss.modulate.a = a
	for c in _copias:
		if is_instance_valid(c) and not c.morrendo:
			c.modulate.a = a

func _flutuar() -> void:
	var rel: float = _t
	boss.position = _vagas[0] + Vector2(sin(rel * 1.3) * 25.0, sin(rel * 2.0) * 12.0)
	for i in _copias.size():
		var c = _copias[i]
		if is_instance_valid(c) and not c.morrendo:
			c.position = _vagas[i + 1] + Vector2(sin(rel * 1.3 + i + 1) * 25.0, sin(rel * 2.0 + i + 1) * 12.0)

## Todos (verdadeiro e cópias) incham e soltam 1 tiro mirado, cada um no seu
## tempo: o tiro não entrega quem é o verdadeiro, só a sombra.
func _atirar_todos(delta: float) -> void:
	for i in _relogios.size():
		var antes: float = _relogios[i]
		_relogios[i] += delta
		var agora: float = _relogios[i]
		var no = boss if i == 0 else _copias[i - 1] # sem tipo: a cópia pode já ter sumido
		if not is_instance_valid(no) or (i > 0 and no.morrendo):
			continue
		var aviso_em: float = INTERVALO_TIRO_COPIAS - boss.TEMPO_AVISO
		if antes < aviso_em and agora >= aviso_em:
			if i == 0:
				_inchar_verdadeiro()
			else:
				no.inchar(boss.TEMPO_AVISO)
		if agora >= INTERVALO_TIRO_COPIAS:
			_relogios[i] = 0.0
			var d: Vector2 = boss.mira(no.global_position)
			boss.atirar(no.global_position + d * 80.0, d, 470.0, 12.0, "chefe")

func _inchar_verdadeiro() -> void:
	var tw: Tween = boss.create_tween()
	tw.tween_property(boss, "_pulso", 0.12, boss.TEMPO_AVISO * 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(boss, "_pulso", 0.0, boss.TEMPO_AVISO * 0.2)

func copia_sumiu(_c) -> void:
	pass # a contagem de vivas é feita no "luta"

# --- FOLHAS e UIVO ----------------------------------------------------------

func _processar_folhas(delta: float) -> void:
	_balancar(delta * 0.4)
	if _fim:
		return
	var total: int = 6 if _furioso() else 4
	if _feitos < total and _tp >= 0.3 + _feitos * 0.4:
		var f = FOLHA.new()
		f.x_base = _x_caneta() if _feitos == 0 else randf_range(90.0, 990.0)
		f.velocidade = 340.0 if _furioso() else 280.0
		f.chefe = boss
		_por_no_cenario(f)
		_feitos += 1
		if _feitos == 1:
			_som(500.0, 0.06, "square") # "rasgo" da página
	if _feitos >= total:
		_terminar()

func _processar_uivo(delta: float) -> void:
	_balancar(delta * 0.4)
	if _fim:
		return
	var total: int = 5 if _furioso() else 3
	if _feitos < total and _tp >= boss.TEMPO_AVISO + _feitos * 0.3:
		var lado: float = float(_feitos) - (total - 1) / 2.0
		var dir := Vector2.DOWN.rotated(deg_to_rad(-lado * 22.0))
		boss.atirar(boss.position + dir * 80.0, dir, 250.0, 12.0, "perseguidora")
		_feitos += 1
	if _feitos >= total:
		_terminar()

# --- comum ------------------------------------------------------------------

func _x_caneta() -> float:
	var player = boss.get_tree().get_first_node_in_group("player")
	return player.global_position.x if player else 540.0

func _por_no_cenario(n: Node) -> void:
	var main = boss.get_parent()
	main.add_child(n)
	var player = boss.get_tree().get_first_node_in_group("player")
	if player and player.get_parent() == main:
		main.move_child(n, player.get_index())

func _som(freq: float, dur: float, tipo: String) -> void:
	var main = boss.get_parent()
	if main and main.has_method("_tocar_som"):
		main._tocar_som(main._gerar_som_procedural(freq, dur, tipo))
