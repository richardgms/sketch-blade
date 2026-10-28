extends RefCounted
## Chefe do capítulo 10: Estojo (o "desfile" dos chefes anteriores).
##
## A luta tem 3 fases pela vida. Entre ataques, balança no alto e atira o
## leque mirado (aviso: incha). Em cada fase sorteia, sem repetir o último:
## 1 (100–67%) RÉGUA E COMPASSO: esmagar (Grade), tesouro (Pirata),
##   espiral de 2 braços (Compasso).
## 2 (67–34%) TINTA E MAPA: parede (Pena), chuva de X (Pirata), folhas
##   (Fantasma).
## 3 (< 34%) ESTOJO ABERTO: xadrez duplo, parede dupla, espiral de 3 braços,
##   3 X seguidos + perseguidoras.
## Na troca de fase treme 1,2 s sem atacar e mostra o nome no topo.
##
## Cada ataque vira uma "agenda" de eventos [tempo, função]; o relógio do
## comportamento dispara os eventos (um relógio só para tudo).

enum Fase { ENTRADA, PASSEIO, ATAQUE, TROCA }

const Y_ALVO: float = 400.0 # abaixo do nome da fase no topo
const PONTA_Y: float = 175.0 # a linha de tinta nasce abaixo dos pés
const ATAQUES: Dictionary = {
	1: ["esmagar", "tesouro", "espiral"],
	2: ["parede", "chuva", "folhas"],
	3: ["xadrez", "parede_dupla", "espiral_3", "tesouro_3"],
}
const NOMES: Dictionary = {
	1: "FASE 1: RÉGUA E COMPASSO",
	2: "FASE 2: TINTA E MAPA",
	3: "FASE 3: ESTOJO ABERTO!",
}
const ZONA_GRADE := preload("res://chefes/ZonaGrade.gd")
const ZONA_BOMBA := preload("res://chefes/ZonaBomba.gd")
const PAREDE := preload("res://chefes/ParedeTinta.gd")
const FOLHA := preload("res://chefes/FolhaFantasma.gd")
const LARGURA_FRESTA: float = 230.0

var boss: Node2D
var fase: Fase = Fase.ENTRADA
var fase_vida: int = 1
var _t: float = 0.0
var _t_balanco: float = 0.0
var _tempo_passeio: float = 1.8
var _ultimo_ataque: String = ""
var _ataque: String = ""
var _duracao: float = 0.0
var _agenda: Array = [] # [[tempo, Callable], ...] em ordem
var _avisou: bool = false
var _leque_feito: bool = false
var _angulo_espiral: float = 0.0
var _lado_fresta: float = 1.0

func _init(b: Node2D) -> void:
	boss = b

func _fase_pela_vida() -> int:
	var f: float = float(boss.hp) / float(boss.hp_max)
	if f > 2.0 / 3.0:
		return 1
	if f > 1.0 / 3.0:
		return 2
	return 3

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
				var main = boss.get_parent()
				if main and main.has_method("aviso_topo"):
					main.aviso_topo(NOMES[1])
				_ir(Fase.PASSEIO)
		Fase.PASSEIO:
			if _fase_pela_vida() != fase_vida:
				_trocar_fase()
				return
			_balancar(delta)
			if not _avisou and _t >= _tempo_passeio * 0.5 - boss.TEMPO_AVISO:
				_avisou = true
				boss._avisar_leque()
			if _avisou and not _leque_feito and _t >= _tempo_passeio * 0.5:
				_leque_feito = true
				boss._disparar_leque()
			if _t >= _tempo_passeio:
				var lista: Array = ATAQUES[fase_vida]
				var opcoes: Array = lista.filter(func(a): return a != _ultimo_ataque)
				_iniciar_ataque(opcoes[randi() % opcoes.size()])
		Fase.ATAQUE:
			_balancar(delta * 0.3)
			while not _agenda.is_empty() and _t >= _agenda[0][0]:
				var ev: Array = _agenda.pop_front()
				(ev[1] as Callable).call()
			if _t >= _duracao and _agenda.is_empty():
				_tempo_passeio = randf_range(1.4, 2.2) * (0.85 if fase_vida == 3 else 1.0)
				_ir(Fase.PASSEIO)
		Fase.TROCA:
			boss.position.x += sin(_t * 70.0) * 2.5 # treme
			if _t >= 1.2:
				_ir(Fase.PASSEIO)

func _ir(nova: Fase) -> void:
	fase = nova
	_t = 0.0
	_avisou = false
	_leque_feito = false

func _trocar_fase() -> void:
	fase_vida = _fase_pela_vida()
	_ultimo_ataque = ""
	var main = boss.get_parent()
	if main and main.has_method("aviso_topo"):
		main.aviso_topo(NOMES[fase_vida])
	_som(180.0, 0.25, "square")
	var tw: Tween = boss.create_tween()
	tw.tween_property(boss, "_pulso", 0.15, 0.3)
	tw.tween_property(boss, "_pulso", 0.0, 0.9)
	_ir(Fase.TROCA)

func _balancar(delta: float) -> void:
	_t_balanco += delta
	var alvo: float = 540.0 + sin(_t_balanco * 0.9) * 280.0
	boss.position.x = move_toward(boss.position.x, alvo, 600.0 * delta)

## Monta a agenda do ataque. Os tempos contam a partir do início do ataque.
func _iniciar_ataque(nome: String) -> void:
	_ataque = nome
	_ultimo_ataque = nome
	_ir(Fase.ATAQUE)
	_agenda.clear()
	match nome:
		"esmagar":
			_ev(0.0, func(): _colunas([_coluna_caneta()], 1.2, 0.0))
			_duracao = 1.8
		"xadrez":
			_ev(0.0, func():
				var par: int = _coluna_caneta() % 2
				_colunas(range(6).filter(func(c): return c % 2 == par), 1.4, 0.0)
				_colunas(range(6).filter(func(c): return c % 2 != par), 1.1, 1.5))
			_duracao = 3.1
		"tesouro":
			_ev(0.0, func(): _bomba(_x_caneta(), 0.4, 0.7))
			_duracao = 1.6
		"tesouro_3":
			for i in 3:
				_ev(i * 0.5, func(): _bomba(_x_caneta(), 0.4, 0.7))
			_ev(1.6, _perseguidoras)
			_duracao = 2.6
		"chuva":
			_ev(0.0, func(): _chuva(_x_caneta()))
			_duracao = 2.2
		"espiral", "espiral_3":
			var bracos: int = 3 if nome == "espiral_3" else 2
			_ev(0.0, func(): boss._avisar_leque())
			_angulo_espiral = randf() * TAU
			var t: float = 0.6
			while t < 3.2:
				_ev(t, func(): _soltar_bracos(bracos))
				t += 0.16
			_duracao = 3.4
		"parede":
			_ev(0.0, func(): _parede(0.0))
			_duracao = 1.4
		"parede_dupla":
			_ev(0.0, func(): _parede(0.0))
			_ev(1.0, func(): _parede(-_lado_fresta))
			_duracao = 2.4
		"folhas":
			for i in 4:
				_ev(0.3 + i * 0.4, func(): _folha(_x_caneta() if i == 0 else randf_range(90.0, 990.0)))
			_duracao = 2.0
	_agenda.sort_custom(func(a, b): return a[0] < b[0])
	_socar()

func _ev(t: float, f: Callable) -> void:
	_agenda.append([t, f])

# --- ataques emprestados ----------------------------------------------------

## Colunas do chão (Grade).
func _colunas(cols: Array, aviso: float, atraso: float) -> void:
	var z = ZONA_GRADE.new()
	z.colunas = cols
	z.aviso = aviso
	z.atraso = atraso
	z.chefe = boss
	_por_no_cenario(z)

## X com bomba em arco (Pirata).
func _bomba(x: float, atraso: float, voo: float) -> void:
	var z = ZONA_BOMBA.new()
	z.alvo_x = x
	z.atraso = atraso
	z.voo = voo
	z.chefe = boss
	_por_no_cenario(z)

func _chuva(x0: float) -> void:
	var xs: Array = []
	var x: float = x0
	while x - 360.0 >= 40.0:
		x -= 360.0
	while x <= 1040.0:
		xs.append(clampf(x + randf_range(-25.0, 25.0), 60.0, 1020.0))
		x += 360.0
	xs.shuffle()
	for i in xs.size():
		_bomba(xs[i], 0.6 + 0.18 * i, 0.6)

## Espiral (Compasso): só os tiros que descem.
func _soltar_bracos(bracos: int) -> void:
	_angulo_espiral += deg_to_rad(16.0)
	for i in bracos:
		var dir := Vector2.from_angle(_angulo_espiral + TAU * i / bracos)
		if dir.y < 0.25:
			continue
		boss.atirar(boss.position + dir * 70.0, dir, 300.0, 10.0, "chefe")

## Parede de tinta (Pena), riscada de um canto ao outro pela régua.
## `lado` 0 = sorteia; senão força o lado da fresta em relação à caneta.
func _parede(lado: float) -> void:
	var px: float = _x_caneta()
	_lado_fresta = lado if lado != 0.0 else (1.0 if randf() < 0.5 else -1.0)
	var d: float = randf_range(130.0, 220.0)
	var minimo: float = LARGURA_FRESTA / 2.0 + 20.0
	var meio: float = px + _lado_fresta * d
	if meio < minimo or meio > 1080.0 - minimo:
		_lado_fresta = -_lado_fresta
		meio = px + _lado_fresta * d
	var p = PAREDE.new()
	p.y = boss.position.y + PONTA_Y
	p.fresta_x = clampf(meio, minimo, 1080.0 - minimo)
	p.largura_fresta = LARGURA_FRESTA
	p.velocidade = 430.0 if fase_vida == 3 else 380.0
	p.chefe = boss
	var de: float = 0.0 if randf() < 0.5 else 1080.0
	p.escrito_de = de
	p.escrito_ate = de
	_por_no_cenario(p)
	var tw: Tween = boss.create_tween()
	tw.tween_property(p, "escrito_ate", 1080.0 - de, 0.85)
	tw.tween_callback(func():
		if is_instance_valid(p):
			p.soltar())

func _folha(x: float) -> void:
	var f = FOLHA.new()
	f.x_base = x
	f.velocidade = 300.0
	f.chefe = boss
	_por_no_cenario(f)

func _perseguidoras() -> void:
	var d: Vector2 = boss.mira(boss.position)
	for ang in [-30.0, 30.0]:
		var dir := d.rotated(deg_to_rad(ang))
		boss.atirar(boss.position + dir * 90.0, dir, 250.0, 12.0, "perseguidora")

# --- comum ------------------------------------------------------------------

func _coluna_caneta() -> int:
	return clampi(int(_x_caneta() / ZONA_GRADE.LARGURA_COLUNA), 0, 5)

func _x_caneta() -> float:
	var player = boss.get_tree().get_first_node_in_group("player")
	return player.global_position.x if player else 540.0

func _por_no_cenario(n: Node) -> void:
	var main = boss.get_parent()
	main.add_child(n)
	var player = boss.get_tree().get_first_node_in_group("player")
	if player and player.get_parent() == main:
		main.move_child(n, player.get_index())

func _socar() -> void:
	var tw: Tween = boss.create_tween()
	tw.tween_property(boss, "_pulso", -0.08, 0.12)
	tw.tween_property(boss, "_pulso", 0.1, 0.1)
	tw.tween_property(boss, "_pulso", 0.0, 0.25)

func _som(freq: float, dur: float, tipo: String) -> void:
	var main = boss.get_parent()
	if main and main.has_method("_tocar_som"):
		main._tocar_som(main._gerar_som_procedural(freq, dur, tipo))
