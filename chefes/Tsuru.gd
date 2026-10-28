extends RefCounted
## Chefe do capítulo 7: Tsuru (garça de origami).
##
## Ritmo fixo e visível: ABERTO (asas abertas, coração brilhando: só aqui
## toma dano; balança no alto e atira o leque mirado) → FECHADO (asas
## dobradas, tiros batem e mostram "BLOQUEADO"; faz um ataque sorteado sem
## repetir) → ABERTO... Cada abrir/fechar tem som, e as asas tremem antes
## de fechar.
## Ataques de asa fechada:
## - MERGULHO: linha tracejada travada na caneta, mergulha e volta.
## - DOBRAS: 3 gotas perseguidoras (5 com raiva).
## - RAJADA: incha e solta 4 tiros mirados seguidos (6 com raiva).
## Com raiva o ritmo acelera (aberto 2,0 s em vez de 2,4 s), mas continua fixo.

enum Fase { ENTRADA, ABERTO, FECHANDO, FECHADO, ABRINDO }

const Y_ALVO: float = 380.0 # mais baixo: as pontas das asas não entram na barra de vida
const TEMPO_ABERTO: float = 2.4
const TEMPO_ABERTO_FURIOSO: float = 2.0
const TEMPO_FECHADO: float = 3.0
const TEMPO_DOBRA: float = 0.25 # animação de abrir/fechar
const AVISO_FECHAR: float = 0.4 # asas tremem antes de fechar
const ATAQUES: Array = ["mergulho", "dobras", "rajada"]

var boss: Node2D
var controla_rotacao: bool = true
var fase: Fase = Fase.ENTRADA
var _t: float = 0.0
var _t_balanco: float = 0.0
var _abertura: float = 1.0 # 1 = asas abertas, 0 = fechadas
var _avisou: bool = false
var _feitos: int = 0
var _ataque: String = ""
var _ultimo_ataque: String = ""
var _passo: String = "" # dentro do mergulho: mira, desce, sobe, pronto
var _tp: float = 0.0
var _dir_mergulho: Vector2 = Vector2.DOWN
var _ultimo_bloqueio: float = -1.0
var _relogio: float = 0.0

# Partes do desenho (recortes da mesma imagem)
var _asa_e: Sprite2D
var _asa_d: Sprite2D
var _brilho: Node2D

func _init(b: Node2D) -> void:
	boss = b
	_montar_partes()

## Recorta o desenho em corpo, parte de baixo e duas asas. As asas giram em
## torno do ombro e "dobram" encolhendo na largura.
func _montar_partes() -> void:
	var arte: Sprite2D = boss._arte
	if not arte:
		return
	var tex: Texture2D = arte.texture
	var meio := Vector2(tex.get_width(), tex.get_height()) / 2.0
	# Corpo (faixa central de cima) fica no próprio sprite do chefe
	var corpo := Rect2(215, 0, 85, 330)
	arte.region_enabled = true
	arte.region_rect = corpo
	arte.offset = corpo.get_center() - meio
	_parte(arte, tex, Rect2(0, 330, 512, 182), Vector2(0, 330), meio)
	# As asas entram 15 px por baixo do corpo e ficam atrás dele: ao tremer
	# ou dobrar, a emenda nunca abre fresta branca
	_asa_e = _parte(arte, tex, Rect2(0, 0, 230, 330), Vector2(215, 250), meio)
	_asa_d = _parte(arte, tex, Rect2(285, 0, 227, 330), Vector2(300, 250), meio)
	_asa_e.show_behind_parent = true
	_asa_d.show_behind_parent = true
	# Brilho do coração (só com as asas abertas)
	_brilho = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_brilho.material = mat
	_brilho.position = (Vector2(268, 268) - meio) * boss._escala_arte
	_brilho.draw.connect(_desenhar_brilho)
	boss.add_child(_brilho)

func _parte(arte: Sprite2D, tex: Texture2D, rect: Rect2, pivo: Vector2, meio: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = rect
	s.centered = false
	s.position = pivo - meio
	s.offset = rect.position - pivo
	s.use_parent_material = true
	arte.add_child(s)
	return s

func _desenhar_brilho() -> void:
	var a: float = _abertura * (0.55 + 0.25 * sin(_relogio * 6.0))
	if a <= 0.01:
		return
	_brilho.draw_circle(Vector2.ZERO, 46.0, Color(1.0, 0.75, 0.2, a * 0.35))
	_brilho.draw_circle(Vector2.ZERO, 26.0, Color(1.0, 0.9, 0.5, a * 0.5))

func _furioso() -> bool:
	return boss.hp <= boss.hp_max / 2

func _tempo_aberto() -> float:
	return TEMPO_ABERTO_FURIOSO if _furioso() else TEMPO_ABERTO

## Só toma dano de asas abertas. Fechado: mostra "BLOQUEADO" (no máximo
## um a cada 0,5 s) e um "tic" de papel duro.
func bloqueia_dano(pos: Vector2) -> bool:
	if fase == Fase.ABERTO:
		return false
	if _relogio - _ultimo_bloqueio >= 0.5:
		_ultimo_bloqueio = _relogio
		var main = boss.get_parent()
		if main and main.has_method("spawn_damage_number"):
			main.spawn_damage_number(0, pos, false)
		_som(1200.0, 0.03, "square")
	return true

func processar(delta: float) -> void:
	_t += delta
	_tp += delta
	_relogio += delta
	_atualizar_asas()
	match fase:
		Fase.ENTRADA:
			boss.position.y += 220.0 * delta
			if boss.position.y >= Y_ALVO:
				boss.position.y = Y_ALVO
				boss.entrada_concluida = true
				boss.set_deferred("monitoring", true)
				boss.set_deferred("monitorable", true)
				_ir(Fase.ABERTO)
		Fase.ABERTO:
			_virar(0.0, delta)
			_balancar(delta)
			var meio_t: float = _tempo_aberto() * 0.5
			if not _avisou and _t >= meio_t - boss.TEMPO_AVISO:
				_avisou = true
				boss._avisar_leque()
			if _avisou and _feitos == 0 and _t >= meio_t:
				_feitos = 1
				boss._disparar_leque()
			if _t >= _tempo_aberto():
				_ir(Fase.FECHANDO)
		Fase.FECHANDO:
			_abertura = 1.0 - minf(_t / TEMPO_DOBRA, 1.0)
			if _t >= TEMPO_DOBRA:
				var opcoes: Array = ATAQUES.filter(func(a): return a != _ultimo_ataque)
				_iniciar_ataque(opcoes[randi() % opcoes.size()])
		Fase.FECHADO:
			match _ataque:
				"mergulho": _processar_mergulho(delta)
				"dobras": _processar_dobras(delta)
				"rajada": _processar_rajada(delta)
			# Abre no tempo fixo (se ainda estiver voltando do mergulho, espera)
			if _t >= TEMPO_FECHADO and absf(boss.position.y - Y_ALVO) < 1.0:
				_ir(Fase.ABRINDO)
		Fase.ABRINDO:
			_virar(0.0, delta)
			_abertura = minf(_t / TEMPO_DOBRA, 1.0)
			if _t >= TEMPO_DOBRA:
				_ir(Fase.ABERTO)
	_brilho.queue_redraw()

func _ir(nova: Fase) -> void:
	fase = nova
	_t = 0.0
	_tp = 0.0
	_avisou = false
	_feitos = 0
	match nova:
		Fase.FECHANDO:
			_som(330.0, 0.09, "square")
		Fase.ABRINDO:
			_som(660.0, 0.08, "sin")
		Fase.ABERTO:
			_abertura = 1.0
		Fase.FECHADO:
			_abertura = 0.0

func _iniciar_ataque(nome: String) -> void:
	_ataque = nome
	_ultimo_ataque = nome
	_ir(Fase.FECHADO)
	if nome == "mergulho":
		_mirar_mergulho()
	elif nome == "rajada":
		boss._avisar_leque()

## Asas: abertas = tamanho cheio; fechadas = estreitas e mais escuras.
## Nos últimos instantes abertas, tremem (aviso de que vão fechar).
func _atualizar_asas() -> void:
	if not _asa_e:
		return
	var sx: float = lerpf(0.18, 1.0, _abertura)
	var sy: float = lerpf(0.85, 1.0, _abertura)
	var tremor: float = 0.0
	if fase == Fase.ABERTO and _t >= _tempo_aberto() - AVISO_FECHAR:
		tremor = sin(_relogio * 70.0) * 0.08
	_asa_e.scale = Vector2(sx, sy)
	_asa_d.scale = Vector2(sx, sy)
	_asa_e.rotation = tremor
	_asa_d.rotation = -tremor
	var tom: float = lerpf(0.72, 1.0, _abertura)
	var cor := Color(tom, tom, tom)
	_asa_e.modulate = cor
	_asa_d.modulate = cor
	boss._arte.self_modulate = cor

func _balancar(delta: float) -> void:
	_t_balanco += delta
	var alvo_x: float = 540.0 + sin(_t_balanco * 0.9) * 300.0
	boss.position.x = move_toward(boss.position.x, alvo_x, 700.0 * delta)

# --- ataques de asa fechada -------------------------------------------------

func _mirar_mergulho() -> void:
	_dir_mergulho = boss.mira(boss.position)
	if _dir_mergulho.y < 0.5:
		_dir_mergulho = Vector2(signf(_dir_mergulho.x) * 0.866, 0.5)
	var aviso = preload("res://AvisoTiro.gd").new()
	aviso.direcoes = [_dir_mergulho]
	aviso.cor = Color("d63a2f")
	aviso.duracao = 0.65
	aviso.comprimento = 1500.0
	aviso.atras_do_atirador = false
	aviso.position = boss.position
	boss.get_parent().add_child(aviso)
	_passo = "mira"
	_tp = 0.0

func _processar_mergulho(delta: float) -> void:
	match _passo:
		"mira":
			_virar(_dir_mergulho.angle() - PI / 2.0, delta)
			boss.position.x += sin(_tp * 60.0) * 1.5
			if _tp >= 0.65:
				_passo = "desce"
		"desce":
			boss.position += _dir_mergulho * (1600.0 if _furioso() else 1300.0) * delta
			var p: Vector2 = boss.position
			if p.y >= 1600.0 or p.x < 40.0 or p.x > 1040.0:
				boss.position.x = clampf(p.x, 40.0, 1040.0)
				_passo = "sobe"
				if _furioso():
					for lado in [-1.0, 1.0]:
						var dir := Vector2(lado * 0.7, -0.7).normalized()
						boss.atirar(boss.position + dir * 80.0, dir, 250.0, 12.0, "perseguidora")
		"sobe":
			_virar(0.0, delta)
			boss.position.y = move_toward(boss.position.y, Y_ALVO, 1100.0 * delta)
			if boss.position.y <= Y_ALVO + 0.5:
				boss.position.y = Y_ALVO
				_passo = "pronto"
		"pronto":
			_virar(0.0, delta)

func _processar_dobras(delta: float) -> void:
	_balancar(delta * 0.4)
	var total: int = 5 if _furioso() else 3
	if _feitos < total and _t >= 0.4 + _feitos * 0.3:
		var lado: float = float(_feitos) - (total - 1) / 2.0
		var dir := Vector2.DOWN.rotated(deg_to_rad(-lado * 22.0))
		boss.atirar(boss.position + dir * 80.0, dir, 250.0, 12.0, "perseguidora")
		_feitos += 1

func _processar_rajada(delta: float) -> void:
	_balancar(delta * 0.4)
	var total: int = 6 if _furioso() else 4
	if _feitos < total and _t >= boss.TEMPO_AVISO + _feitos * 0.35:
		var d: Vector2 = boss.mira(boss.position)
		boss.atirar(boss.position + d * 80.0, d, 560.0, 13.0, "elite")
		_feitos += 1

# --- comum ------------------------------------------------------------------

func _som(freq: float, dur: float, tipo: String) -> void:
	var main = boss.get_parent()
	if main and main.has_method("_tocar_som"):
		main._tocar_som(main._gerar_som_procedural(freq, dur, tipo))

func _virar(alvo: float, delta: float) -> void:
	boss.rotation = lerp_angle(boss.rotation, alvo, minf(1.0, 10.0 * delta))
