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

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("enemies")
	y_fuga = get_viewport_rect().size.y + 180.0
	configurar_tipo(tipo)

func configurar_tipo(novo_tipo: TipoInimigo) -> void:
	tipo = novo_tipo
	_desvio_x = 0.0
	
	if tipo == TipoInimigo.COMUM:
		raio_visual = 35.0
		velocidade = 200.0
		hp_max = 20
		cor_tinta = Color("1a1a2e", 0.95)
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
		cor_tinta = Color("4b2c15", 0.95)
		textura_drop = "res://assets/ink-brown.svg"
		dano_contato = 2
		
	hp = hp_max
	pos_inicial_x = position.x
	queue_redraw()

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
	queue_redraw()

func _draw() -> void:
	# 1. Desenho do corpo baseado no tipo
	if tipo == TipoInimigo.COMUM:
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
	
	# 1.5. Aura dourada de Elite (contorno duplo rabiscado)
	if eh_elite:
		draw_arc(Vector2.ZERO, raio_visual + 10.0, 0, TAU, 40, Color("f39c12", 0.9), 5.0)
		draw_arc(Vector2.ZERO, raio_visual + 16.0, 0, TAU, 24, Color("f1c40f", 0.5), 3.0)

	# 2. Olhos brancos expressivos
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
	
	# 3. Barra de HP (só para inimigos com mais de 1 HP em modo de jogo)
	if not Engine.is_editor_hint() and hp_max > 1:
		var barra_largura: float = raio_visual * 1.7
		var barra_altura: float = 6.0
		var barra_y: float = -(raio_visual + 15.0) if tipo != TipoInimigo.NANQUIM else -(raio_visual * 2.5)
		var barra_x: float = -barra_largura / 2.0
		
		# Fundo da barra
		draw_rect(Rect2(barra_x, barra_y, barra_largura, barra_altura), Color(0.3, 0.3, 0.3, 0.5))
		
		# Preenchimento
		var preenchimento = barra_largura * (float(hp) / float(hp_max))
		if preenchimento > 0.0:
			draw_rect(Rect2(barra_x, barra_y, preenchimento, barra_altura), Color(0.8, 0.15, 0.15))

func _process(delta: float) -> void:
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
		if timer_tiro_enemy >= 2.5:
			timer_tiro_enemy = 0.0
			_disparar_projetil_respingo()
		
	# Caso o NANQUIM (Rápido), desce direto sem ajuste de direção, como um dardo!

	# Elite: atira leque de 3 projéteis a cada 3 segundos (qualquer tipo)
	if eh_elite:
		timer_tiro_elite += delta
		if timer_tiro_elite >= 3.0:
			timer_tiro_elite = 0.0
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
	if morrendo:
		return
	hp -= quantidade

	# Aciona popup de dano no Main apenas se sobreviver
	if hp > 0:
		var main_node = get_parent()
		if main_node and main_node.has_method("spawn_damage_number"):
			main_node.spawn_damage_number(quantidade, global_position, false, critico)

	# Flash de dano
	modulate = Color(2.0, 2.0, 2.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

	if hp_max > 1:
		queue_redraw()

	if hp <= 0:
		morrer()

var morrendo: bool = false

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
		proj.setup(Vector2.DOWN, 400.0, 7.0) # Velocidade menor e tamanho original do boss
		
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
			proj.setup(Vector2.from_angle(deg_to_rad(angulo_graus)), 420.0, 9.0)
			
			if not proj.is_inside_tree():
				main.add_child(proj)
			else:
				proj.queue_redraw()
