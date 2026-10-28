extends RefCounted
## Chefe do capítulo 5: Compasso.
##
## Ciclo: ANDA até um ponto no alto → AVISO (gira cada vez mais rápido e pisca
## um círculo tracejado) → ESPIRAL (gira soltando tiros em 2 braços; só os que
## vão para baixo saem, para a tela não lotar) → DESCANSO (janela tranquila).
## Com menos da metade da vida: 3 braços e a espiral inverte o sentido no meio.

enum Fase { ENTRADA, ANDANDO, AVISO, ESPIRAL, DESCANSO }

const Y_ALVO: float = 380.0
const TEMPO_AVISO: float = 0.8
const TEMPO_ESPIRAL: float = 3.2
const TEMPO_DESCANSO: float = 1.6
const INTERVALO_TIRO: float = 0.16
const GIRO_POR_TIRO: float = deg_to_rad(16.0)
const VEL_TIRO: float = 300.0

var boss: Node2D
var controla_rotacao: bool = true # o Boss não aplica o balanço no desenho
var fase: Fase = Fase.ENTRADA
var _t: float = 0.0
var _tiro_t: float = 0.0
var _angulo: float = 0.0
var _sentido: float = 1.0
var _destino: Vector2 = Vector2(540, Y_ALVO)
var _inverteu: bool = false
var _aviso_circulo: Node2D = null

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
				_ir(Fase.AVISO)
		Fase.ANDANDO:
			boss.position = boss.position.move_toward(_destino, 520.0 * delta)
			_girar(1.5, delta)
			if boss.position.distance_to(_destino) < 4.0:
				_ir(Fase.AVISO)
		Fase.AVISO:
			# Acelera o giro: o aviso é o próprio compasso "dando corda"
			_girar(2.0 + 14.0 * (_t / TEMPO_AVISO), delta)
			if _t >= TEMPO_AVISO:
				_angulo = randf() * TAU
				_sentido = 1.0 if randf() < 0.5 else -1.0
				_inverteu = false
				_ir(Fase.ESPIRAL)
		Fase.ESPIRAL:
			_girar(16.0 * _sentido, delta)
			if _furioso() and not _inverteu and _t >= TEMPO_ESPIRAL / 2.0:
				_inverteu = true
				_sentido = -_sentido
			_tiro_t += delta
			while _tiro_t >= INTERVALO_TIRO:
				_tiro_t -= INTERVALO_TIRO
				_soltar_bracos()
			if _t >= TEMPO_ESPIRAL:
				_ir(Fase.DESCANSO)
		Fase.DESCANSO:
			_girar(1.0, delta)
			if _t >= TEMPO_DESCANSO:
				_destino = Vector2(randf_range(220.0, 860.0), randf_range(300.0, 460.0))
				_ir(Fase.ANDANDO)

func _ir(nova: Fase) -> void:
	fase = nova
	_t = 0.0
	_tiro_t = 0.0
	if nova == Fase.AVISO:
		_mostrar_aviso()

## Gira só o desenho (a área de acerto é um círculo, não muda).
func _girar(vel: float, delta: float) -> void:
	if boss._arte:
		boss._arte.rotation += vel * delta

func _soltar_bracos() -> void:
	var bracos: int = 3 if _furioso() else 2
	_angulo += GIRO_POR_TIRO * _sentido
	for i in bracos:
		var a: float = _angulo + TAU * i / bracos
		var dir := Vector2.from_angle(a)
		if dir.y < 0.25: # só os que descem: os que sobem não ameaçam e só pesam
			continue
		var main = boss.get_parent()
		var proj = main.obter_projetil_inimigo() if main.has_method("obter_projetil_inimigo") \
			else preload("res://enemy_projectile.tscn").instantiate()
		proj.position = boss.position + dir * 60.0
		proj.setup(dir, VEL_TIRO, 10.0, "chefe")
		if not proj.is_inside_tree():
			main.add_child(proj)

## Círculo tracejado pulsando em volta do compasso durante o aviso.
func _mostrar_aviso() -> void:
	var c := Node2D.new()
	var dur: float = TEMPO_AVISO
	var cor := Color("d63a2f")
	var t0: Array = [0.0]
	c.draw.connect(func():
		var p: float = t0[0] / dur
		var a: float = 0.35 + 0.45 * absf(sin(p * p * 18.0))
		var k := cor
		k.a = a
		var raio: float = 120.0 + 40.0 * p
		var n: int = 28
		for i in n:
			if i % 2 == 0:
				c.draw_arc(Vector2.ZERO, raio, TAU * i / n, TAU * (i + 1) / n, 4, k, 5.0, true)
	)
	c.set_process(true)
	boss.add_child(c)
	var tw := c.create_tween()
	tw.tween_method(func(v: float):
		t0[0] = v
		c.queue_redraw(), 0.0, dur, dur)
	tw.tween_callback(c.queue_free)
