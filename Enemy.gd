@tool
extends Area2D

signal morreu(posicao: Vector2, cor: Color, textura_drop: String)

enum TipoInimigo { COMUM, NANQUIM, RESPINGO, GUACHE }

@export var tipo: TipoInimigo = TipoInimigo.COMUM

@export var velocidade: float = 200.0
@export var cor_tinta: Color = Color("1a1a2e")
var textura_drop: String = "res://assets/ink-black.svg"
@export var raio_visual: float = 35.0
@export var hp_max: int = 20

var hp: int = 20
var morre_no_contato: bool = true
var dano_contato: int = 1
# Invulnerável até o corpo entrar inteiro na tela (nasce em y=-80 e os
# projéteis do jogador só morrem em y=-50 — sem isso dá pra matar monstro
# que nem apareceu). Mesmo padrão da entrada do Boss.
var entrada_concluida: bool = false
# Y de fuga pelo rodapé (recalculado da altura real da tela no _ready)
var y_fuga: float = 2100.0
var eh_elite: bool = false
var timer_tiro_elite: float = 0.0

# Lógicas físicas especiais
var pos_inicial_x: float = 0.0
var timer_seno: float = 0.0
var timer_tiro_enemy: float = 0.0
var _desvio_x: float = 0.0

# Tinta Corrosiva (dano contínuo)
var dot_dps: int = 0
var dot_restante: float = 0.0
var dot_acumulado: float = 0.0

const ENEMY_PROJECTILE_SCENE = preload("res://enemy_projectile.tscn")
const SHADER_FLASH = preload("res://flash.gdshader")

## Desenho (IA) por tipo. Tipos sem arte continuam desenhados por código.
const ARTE_INIMIGO: Dictionary = {
	TipoInimigo.COMUM: "res://assets/inimigos/comum.png",
	TipoInimigo.NANQUIM: "res://assets/inimigos/nanquim.png",
	TipoInimigo.RESPINGO: "res://assets/inimigos/respingo.png",
	TipoInimigo.GUACHE: "res://assets/inimigos/guache.png",
}
## Tamanho do desenho em relação ao corpo (diâmetro × fator). Os desenhos têm
## respingos em volta; o Nanquim é fino e alto, então precisa de fator maior.
const FATOR_ARTE: Dictionary = {
	TipoInimigo.COMUM: 1.7,
	TipoInimigo.NANQUIM: 3.6,
	TipoInimigo.RESPINGO: 2.6,
	TipoInimigo.GUACHE: 1.45,
}
const TREMIDO_ARTE: float = 0.0035

var _arte: Sprite2D = null
var _escala_arte: Vector2 = Vector2.ONE
var _t_anim: float = 0.0
var _pulso: float = 0.0 # inchaço do aviso de tiro
var _avisou_tiro: bool = false
var _avisou_leque: bool = false

const AVISO_TIRO = preload("res://AvisoTiro.gd")
const TEMPO_AVISO: float = 0.5

## Aviso de tiro: o monstro incha e aparecem linhas tracejadas na direção dos
## tiros. Os tiros saem TEMPO_AVISO depois.
func _avisar_tiro(direcoes: Array, cor: Color) -> void:
	var aviso = AVISO_TIRO.new()
	aviso.direcoes = direcoes
	aviso.cor = cor
	aviso.duracao = TEMPO_AVISO
	aviso.inicio = Vector2(0, raio_visual * _fator_arte() * 0.5 if _arte else raio_visual)
	add_child(aviso)
	var tw := create_tween()
	tw.tween_property(self, "_pulso", 0.18, TEMPO_AVISO * 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_pulso", 0.0, TEMPO_AVISO * 0.2)

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("enemies")
	y_fuga = get_viewport_rect().size.y + 180.0
	# Entrada: sem colisão até aparecer na tela (projéteis atravessam)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	configurar_tipo(tipo)
	material = ShaderMaterial.new()
	material.shader = SHADER_FLASH
	material.set_shader_parameter("semente", randf() * 100.0)
	material.set_shader_parameter("tremido", TREMIDO_ARTE if _arte else 0.0)
	_t_anim = randf() * 10.0

func configurar_tipo(novo_tipo: TipoInimigo) -> void:
	tipo = novo_tipo
	_desvio_x = 0.0
	
	if tipo == TipoInimigo.COMUM:
		raio_visual = 35.0
		velocidade = 200.0
		hp_max = 20
		cor_tinta = Color("26238c", 0.95) # azul do desenho (respingo e mancha)
		textura_drop = "res://assets/ink-black.svg"
		dano_contato = 1
		_desvio_x = randf_range(80.0, 160.0) * (1.0 if randf() < 0.5 else -1.0)
	elif tipo == TipoInimigo.NANQUIM:
		raio_visual = 20.0
		velocidade = 350.0
		hp_max = 10
		cor_tinta = Color("3b2c64", 0.95)
		textura_drop = "res://assets/ink-purple.svg"
		dano_contato = 1
	elif tipo == TipoInimigo.RESPINGO:
		raio_visual = 28.0
		velocidade = 180.0
		hp_max = 20
		cor_tinta = Color("0a473a", 0.95)
		textura_drop = "res://assets/ink-green.svg"
		dano_contato = 1
	elif tipo == TipoInimigo.GUACHE:
		raio_visual = 65.0
		velocidade = 80.0
		hp_max = 50
		cor_tinta = Color("a8401c", 0.95) # ferrugem do desenho
		textura_drop = "res://assets/ink-brown.svg"
		dano_contato = 2
		
	hp = hp_max
	pos_inicial_x = position.x
	_aplicar_arte()
	queue_redraw()

func _fator_arte() -> float:
	return FATOR_ARTE.get(tipo, 1.7)

## Troca o círculo desenhado por código pelo desenho do tipo (se houver).
func _aplicar_arte() -> void:
	var caminho: String = ARTE_INIMIGO.get(tipo, "")
	if caminho == "":
		if _arte:
			_arte.queue_free()
			_arte = null
		if material:
			material.set_shader_parameter("tremido", 0.0)
		return
	if not _arte:
		_arte = Sprite2D.new()
		_arte.use_parent_material = true # flash e tremido do inimigo
		_arte.show_behind_parent = true  # barra de vida e aura por cima
		add_child(_arte)
	var tex: Texture2D = load(caminho)
	_arte.texture = tex
	_escala_arte = Vector2.ONE * (raio_visual * 2.0 * _fator_arte() / tex.get_width())
	_arte.scale = _escala_arte
	if material:
		material.set_shader_parameter("tremido", TREMIDO_ARTE)

## Transforma este inimigo em Elite: gigante, resistente, atira em leque
## e não morre no contato. Chamar DEPOIS de configurar_tipo().
func tornar_elite() -> void:
	eh_elite = true
	hp_max = int(hp_max * GameData.ELITE_MULT_HP)
	hp = hp_max
	velocidade = velocidade * GameData.ELITE_MULT_VELOCIDADE
	scale = Vector2.ONE * GameData.ELITE_MULT_ESCALA
	dano_contato = max(dano_contato, 2)
	morre_no_contato = false
	if _arte:
		_criar_aura_elite()
	queue_redraw()

## Auréola dourada atrás do desenho da Elite (não corta o desenho).
func _criar_aura_elite() -> void:
	var aura := Node2D.new()
	aura.show_behind_parent = true # atrás do inimigo, mas na frente do papel
	var raio: float = raio_visual * _fator_arte() * 0.66
	aura.draw.connect(func():
		aura.draw_circle(Vector2.ZERO, raio, Color(1.0, 0.78, 0.2, 0.38))
		aura.draw_arc(Vector2.ZERO, raio, 0.0, TAU, 48, Color("f39c12", 0.9), 7.0, true)
		aura.draw_arc(Vector2.ZERO, raio + 8.0, 0.0, TAU, 32, Color("f1c40f", 0.45), 3.0, true)
	)
	add_child(aura)
	move_child(aura, 0) # antes do desenho: fica por trás dele

func _draw() -> void:
	# 1. Desenho do corpo baseado no tipo (tipos com arte usam o Sprite2D)
	if _arte:
		pass
	elif tipo == TipoInimigo.COMUM:
		# Rabisco circular básico
		draw_circle(Vector2.ZERO, raio_visual, cor_tinta)
	
	elif tipo == TipoInimigo.NANQUIM:
		# Estrela alongada/rabisco fino pontiagudo
		draw_ellipse(Vector2.ZERO, raio_visual, raio_visual * 1.6, cor_tinta, -1.0, true)
		draw_line(Vector2.ZERO, Vector2(-raio_visual * 1.8, 0), cor_tinta, 4.0)
		draw_line(Vector2.ZERO, Vector2(raio_visual * 1.8, 0), cor_tinta, 4.0)
		draw_line(Vector2.ZERO, Vector2(0, -raio_visual * 2.2), cor_tinta, 4.0)
		draw_line(Vector2.ZERO, Vector2(0, raio_visual * 2.2), cor_tinta, 4.0)
		
	elif tipo == TipoInimigo.RESPINGO:
		# Pingo de tinta espirrado com gotas ao redor
		draw_circle(Vector2.ZERO, raio_visual, cor_tinta)
		for i in range(8):
			var angulo = float(i) * (PI / 4.0)
			var direcao = Vector2(cos(angulo), sin(angulo))
			draw_line(direcao * raio_visual, direcao * (raio_visual + 12.0), cor_tinta, 3.0)
			draw_circle(direcao * (raio_visual + 15.0), 3.0, cor_tinta)
			
	elif tipo == TipoInimigo.GUACHE:
		# Grande mancha borrada irregular
		draw_circle(Vector2.ZERO, raio_visual, cor_tinta)
		draw_circle(Vector2(-15, 10), raio_visual * 0.9, cor_tinta)
		draw_circle(Vector2(20, -10), raio_visual * 0.85, cor_tinta)
		draw_circle(Vector2(-10, -20), raio_visual * 0.8, cor_tinta)
		draw_circle(Vector2(15, 25), raio_visual * 0.8, cor_tinta)
	
	# 1.5. Aura dourada de Elite (contorno duplo rabiscado). Com desenho, a
	# auréola fica atrás dele (_criar_aura_elite).
	if eh_elite and not _arte:
		draw_arc(Vector2.ZERO, raio_visual + 10.0, 0, TAU, 40, Color("f39c12", 0.9), 5.0)
		draw_arc(Vector2.ZERO, raio_visual + 16.0, 0, TAU, 24, Color("f1c40f", 0.5), 3.0)

	# 2. Olhos brancos expressivos (o desenho já tem olhos)
	if not _arte:
		_desenhar_olhos()

	# 3. Barra de HP
	_desenhar_barra_hp()

func _desenhar_olhos() -> void:
	var offset_olho_y = -5 if tipo != TipoInimigo.GUACHE else -15
	var dist_olhos = 10 if tipo != TipoInimigo.GUACHE else 20
	var tam_olho = 5.0 if tipo != TipoInimigo.GUACHE else 8.0
	
	# Olho esquerdo e direito
	draw_circle(Vector2(-dist_olhos, offset_olho_y), tam_olho, Color.WHITE)
	draw_circle(Vector2(dist_olhos, offset_olho_y), tam_olho, Color.WHITE)
	
	# Pupilhas (Nanquim/Rápido tem olhos vermelhos bravos!)
	var cor_pupila = Color.RED if tipo == TipoInimigo.NANQUIM else Color.BLACK
	var tam_pupila = 2.0 if tipo != TipoInimigo.GUACHE else 3.5
	draw_circle(Vector2(-dist_olhos, offset_olho_y), tam_pupila, cor_pupila)
	draw_circle(Vector2(dist_olhos, offset_olho_y), tam_pupila, cor_pupila)
	
func _desenhar_barra_hp() -> void:
	# Só para inimigos com mais de 1 HP em modo de jogo
	if not Engine.is_editor_hint() and hp_max > 1:
		var barra_largura: float = raio_visual * 1.7
		var barra_altura: float = 6.0
		var barra_y: float = -(raio_visual + 15.0) if tipo != TipoInimigo.NANQUIM else -(raio_visual * 2.5)
		if _arte:
			barra_y = -(raio_visual * _fator_arte() * 0.85 + 10.0)
		var barra_x: float = -barra_largura / 2.0
		
		# Fundo da barra
		draw_rect(Rect2(barra_x, barra_y, barra_largura, barra_altura), Color(0.3, 0.3, 0.3, 0.5))
		
		# Preenchimento
		var preenchimento = barra_largura * (float(hp) / float(hp_max))
		if preenchimento > 0.0:
			draw_rect(Rect2(barra_x, barra_y, preenchimento, barra_altura), Color(0.8, 0.15, 0.15))

func _process(delta: float) -> void:
	# Desenho "vivo": respira (estica/achata) e balança de leve
	if _arte and not morrendo:
		_t_anim += delta
		var r: float = sin(_t_anim * 6.0)
		_arte.scale = _escala_arte * Vector2(1.0 + 0.07 * r, 1.0 - 0.07 * r) * (1.0 + _pulso)
		_arte.rotation = 0.08 * sin(_t_anim * 2.6)

	if Engine.is_editor_hint() or is_queued_for_deletion() or morrendo:
		return

	# Tick da Tinta Corrosiva (DoT)
	if dot_restante > 0.0:
		dot_restante -= delta
		dot_acumulado += float(dot_dps) * delta
		if dot_acumulado >= 1.0:
			var dano_tick = int(dot_acumulado)
			dot_acumulado -= dano_tick
			receber_dano(dano_tick)
			if is_queued_for_deletion():
				return
		if dot_restante <= 0.0:
			dot_dps = 0
			modulate = Color.WHITE

	# Movimentação vertical
	position.y += velocidade * delta

	# Fim da entrada: corpo inteiro visível → liga colisão e vulnerabilidade
	if not entrada_concluida and position.y >= raio_visual * scale.y:
		entrada_concluida = true
		set_deferred("monitoring", true)
		set_deferred("monitorable", true)

	# Comportamento horizontal baseado no tipo
	if tipo == TipoInimigo.COMUM:
		# Desce em diagonal e bate nas bordas do papel
		position.x += _desvio_x * delta
		if position.x <= 60.0:
			position.x = 60.0
			_desvio_x = abs(_desvio_x)
		elif position.x >= 1020.0:
			position.x = 1020.0
			_desvio_x = -abs(_desvio_x)
			
	elif tipo == TipoInimigo.GUACHE:
		# Perseguição lenta do Tanque ao jogador (pressão constante)
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node:
			var diff_x = player_node.global_position.x - global_position.x
			position.x += sign(diff_x) * min(abs(diff_x), velocidade * 0.7) * delta
			position.x = clamp(position.x, 60.0, 1020.0)
			
	elif tipo == TipoInimigo.RESPINGO:
		# Movimento de zigue-zague senoidal
		timer_seno += delta
		# Amplitude do zigue-zague é contida para o monstro não sair das bordas da tela
		var amplitude = min(120.0, min(pos_inicial_x - 60.0, 1020.0 - pos_inicial_x))
		position.x = pos_inicial_x + sin(timer_seno * 5.0) * amplitude
		
		# Mecânica de tiro do Respingo
		timer_tiro_enemy += delta
		if not _avisou_tiro and timer_tiro_enemy >= 2.5 - TEMPO_AVISO:
			_avisou_tiro = true
			_avisar_tiro([Vector2.DOWN], Color("2e9e3e"))
		if timer_tiro_enemy >= 2.5:
			timer_tiro_enemy = 0.0
			_avisou_tiro = false
			_disparar_projetil_respingo()
		
	# Caso o NANQUIM (Rápido), desce direto sem ajuste de direção, como um dardo!

	# Elite: atira leque de 3 projéteis a cada 3 segundos (qualquer tipo)
	if eh_elite:
		timer_tiro_elite += delta
		if not _avisou_leque and timer_tiro_elite >= 3.0 - TEMPO_AVISO:
			_avisou_leque = true
			_avisar_tiro([Vector2.from_angle(deg_to_rad(75)), Vector2.DOWN, Vector2.from_angle(deg_to_rad(105))], Color("e67e22"))
		if timer_tiro_elite >= 3.0:
			timer_tiro_elite = 0.0
			_avisou_leque = false
			_disparar_leque_elite()

		# Elite estaciona no meio da tela em vez de sair por baixo
		if position.y > 700.0:
			position.y = 700.0

	# Auto-destrói se passar do rodapé da tela
	if position.y > y_fuga:
		var main_node = get_parent()
		if main_node and main_node.has_method("_on_enemy_escapou"):
			main_node._on_enemy_escapou()
		queue_free()

## Aplica dano contínuo de Tinta Corrosiva (mantém o maior DPS recebido).
func aplicar_dot(dps: int, duracao: float) -> void:
	dot_dps = max(dot_dps, dps)
	dot_restante = duracao
	# Tinge de verde corrosivo enquanto o efeito durar
	modulate = Color(0.6, 1.1, 0.6)

func receber_dano(quantidade: int) -> void:
	receber_dano_detalhado(quantidade, false)

func receber_dano_detalhado(quantidade: int, critico: bool) -> void:
	if morrendo or not entrada_concluida:
		return
	hp -= quantidade

	# Aciona popup de dano no Main apenas se sobreviver
	if hp > 0:
		var main_node = get_parent()
		if main_node and main_node.has_method("spawn_damage_number"):
			main_node.spawn_damage_number(quantidade, global_position, false, critico)

	# Flash branco (shader) + empurrão para trás; tanque e elite quase não se movem
	_piscar()
	var empurrao: float = 5.0 if (tipo == TipoInimigo.GUACHE or eh_elite) else (18.0 if critico else 12.0)
	position.y -= empurrao

	if hp_max > 1:
		queue_redraw()

	if hp <= 0:
		morrer()

var morrendo: bool = false
var _tween_flash: Tween

func _piscar() -> void:
	if not material:
		return
	if _tween_flash:
		_tween_flash.kill()
	material.set_shader_parameter("flash", 0.85)
	_tween_flash = create_tween()
	_tween_flash.tween_method(func(v: float): material.set_shader_parameter("flash", v), 0.85, 0.0, 0.12)

func morrer() -> void:
	if morrendo:
		return
	morrendo = true
	# Recompensas e contagem saem imediatamente; só o visual sobrevive à animação.
	morreu.emit(global_position, cor_tinta, textura_drop)
	# Fora do grupo e sem colisão: não toma tiro nem causa dano de contato enquanto estoura
	remove_from_group("enemies")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Estouro de tinta: achata, depois some num pop rápido
	var escala_base = scale
	var tween = create_tween()
	tween.tween_property(self, "scale", escala_base * Vector2(1.3, 0.65), 0.06)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)

func _disparar_projetil_respingo() -> void:
	var main = get_parent()
	var proj = null
	if main and main.has_method("obter_projetil_inimigo"):
		proj = main.obter_projetil_inimigo()
	elif ENEMY_PROJECTILE_SCENE:
		proj = ENEMY_PROJECTILE_SCENE.instantiate()
		
	if proj:
		proj.position = global_position + Vector2(0, 30)
		proj.setup(Vector2.DOWN, 400.0, 9.0, "respingo")
		
		if not proj.is_inside_tree():
			main.add_child(proj)
		else:
			proj.queue_redraw()

func _disparar_leque_elite() -> void:
	var main = get_parent()
	# Leque de 3 tiros: reto para baixo e duas diagonais
	for angulo_graus in [75, 90, 105]:
		var proj = null
		if main and main.has_method("obter_projetil_inimigo"):
			proj = main.obter_projetil_inimigo()
		elif ENEMY_PROJECTILE_SCENE:
			proj = ENEMY_PROJECTILE_SCENE.instantiate()
			
		if proj:
			proj.position = global_position + Vector2(0, 40)
			proj.setup(Vector2.from_angle(deg_to_rad(angulo_graus)), 420.0, 9.0, "elite")
			
			if not proj.is_inside_tree():
				main.add_child(proj)
			else:
				proj.queue_redraw()
