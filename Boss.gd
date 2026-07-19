extends Area2D

signal hp_alterado(novo_hp: int)
signal morreu

enum EstadoBoss { PATRULHA, TELEGRAFANDO, MERGULHO, RETORNO }

# 300: com stats iniciais a luta dura ~35s (era 100 → ~11s, boss nascia
# trivial). Escala por capítulo aplicada no WaveManager._preparar_boss.
@export var hp_max: int = 300
@export var dano_contato: int = 2
@export var velocidade_patrulha: float = 250.0
@export var velocidade_mergulho: float = 800.0
@export var intervalo_mergulho: float = 4.0
@export var raio_visual: float = 70.0
@export var cor_tinta: Color = Color.BLACK

var hp: int = 100
var morre_no_contato: bool = false
var estado: EstadoBoss = EstadoBoss.PATRULHA
var direcao_patrulha: float = 1.0  # 1 = direita, -1 = esquerda
var posicao_alvo_mergulho: Vector2

# Invulnerável durante a descida de entrada (até chegar em Y=300):
# colisões desligadas (projéteis atravessam) + guarda no receber_dano.
var entrada_concluida: bool = false

# Padrão de ataque (varia por faixa de capítulo via configurar_padrao)
var angulos_leque: Array = [90, 75, 105]
var spawna_reforcos: bool = false

var timer_acao: float = 0.0
var timer_telegrafo: float = 0.0
var timer_tiro: float = 0.0

# Profundidade máxima do mergulho: cruza a zona da caneta, que termina perto
# do rodapé real da tela (recalculado no _ready)
var y_limite_mergulho: float = 1800.0

# Tinta Corrosiva (dano contínuo)
var dot_dps: int = 0
var dot_restante: float = 0.0
var dot_acumulado: float = 0.0

func _ready() -> void:
	hp = hp_max
	add_to_group("enemies")
	y_limite_mergulho = get_viewport_rect().size.y - 120.0
	# Entrada: sem colisão até terminar de descer
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

## Define o padrão de ataque do boss conforme a faixa de capítulos.
func configurar_padrao(capitulo: int) -> void:
	if capitulo <= 3:
		# Padrão clássico: leque de 3, mergulho a cada 4s
		angulos_leque = [90, 75, 105]
		intervalo_mergulho = 4.0
	elif capitulo <= 6:
		# Agressivo: leque de 5 tiros e mergulhos mais frequentes
		angulos_leque = [90, 75, 105, 60, 120]
		intervalo_mergulho = 3.0
	else:
		# Invocador: leque de 3, mas chama 2 reforços ao telegrafar o mergulho
		angulos_leque = [90, 75, 105]
		intervalo_mergulho = 3.5
		spawna_reforcos = true

func _draw() -> void:
	# Desenha o Boss de Tinta (círculo preto grande)
	draw_circle(Vector2.ZERO, raio_visual, cor_tinta)
	
	# Detalhe de borda irregular
	draw_arc(Vector2.ZERO, raio_visual + 2, 0, TAU, 48, Color(0.1, 0.1, 0.1, 0.5), 3.0)
	
	# Olhos vermelhos ameaçadores
	draw_circle(Vector2(-20, -10), 10.0, Color.RED)
	draw_circle(Vector2(20, -10), 10.0, Color.RED)
	draw_circle(Vector2(-20, -10), 4.0, Color.BLACK)
	draw_circle(Vector2(20, -10), 4.0, Color.BLACK)

func _process(delta: float) -> void:
	if is_queued_for_deletion():
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

	match estado:
		EstadoBoss.PATRULHA:
			_processar_patrulha(delta)
		EstadoBoss.TELEGRAFANDO:
			_processar_telegrafo(delta)
		EstadoBoss.MERGULHO:
			_processar_mergulho(delta)
		EstadoBoss.RETORNO:
			_processar_retorno(delta)

func _processar_patrulha(delta: float) -> void:
	# Move-se horizontalmente lado a lado no terço superior (Y=300)
	# Entrada suave: se acabou de nascer, desce até Y=300 primeiro
	if not entrada_concluida:
		if position.y < 300.0:
			position.y += 150.0 * delta
			return
		entrada_concluida = true
		set_deferred("monitoring", true)
		set_deferred("monitorable", true)


	position.x += velocidade_patrulha * direcao_patrulha * delta
	
	# Bate nas bordas da tela e inverte
	if position.x > 980.0:
		position.x = 980.0
		direcao_patrulha = -1.0
	elif position.x < 100.0:
		position.x = 100.0
		direcao_patrulha = 1.0
		
	# Atira periodicamente durante a patrulha
	timer_tiro += delta
	if timer_tiro >= 1.5:
		timer_tiro = 0.0
		_disparar_leque()
		
	# Conta tempo para o mergulho
	timer_acao += delta
	if timer_acao >= intervalo_mergulho:
		timer_acao = 0.0
		timer_tiro = 0.0 # Reseta o timer de tiro ao telegrafar
		estado = EstadoBoss.TELEGRAFANDO
		timer_telegrafo = 0.5

		# Boss Invocador (cap. 7+): chama 2 reforços rabiscados ao telegrafar
		if spawna_reforcos:
			_invocar_reforcos()

		# Som de telegrafia
		var main_node = get_parent()
		if main_node and main_node.has_method("_tocar_som"):
			var som = main_node._gerar_som_procedural(400.0, 0.2, "square")
			main_node._tocar_som(som)

func _processar_telegrafo(delta: float) -> void:
	timer_telegrafo -= delta
	
	# Pisca modulate vermelho/branco
	if int(timer_telegrafo * 20.0) % 2 == 0:
		modulate = Color.RED
	else:
		modulate = Color.WHITE
		
	if timer_telegrafo <= 0.0:
		modulate = Color.WHITE
		estado = EstadoBoss.MERGULHO
		# Trava a direção do mergulho apontando para o jogador
		var player_node = get_tree().get_first_node_in_group("player")
		if player_node:
			posicao_alvo_mergulho = (player_node.global_position - global_position).normalized()
		else:
			posicao_alvo_mergulho = Vector2.DOWN

func _processar_mergulho(delta: float) -> void:
	# Desce na direção travada
	position += posicao_alvo_mergulho * velocidade_mergulho * delta
	
	# Chegou na zona limite (cruzando a zona inferior onde o jogador se move)
	if position.y >= y_limite_mergulho or position.x < 50.0 or position.x > 1030.0:
		estado = EstadoBoss.RETORNO

func _processar_retorno(delta: float) -> void:
	# Retorna suavemente ao Y=300
	var destino = Vector2(position.x, 300.0)
	position = position.lerp(destino, 5.0 * delta)
	
	if abs(position.y - 300.0) < 5.0:
		position.y = 300.0
		estado = EstadoBoss.PATRULHA
		timer_acao = 0.0

## Aplica dano contínuo de Tinta Corrosiva (mantém o maior DPS recebido).
func aplicar_dot(dps: int, duracao: float) -> void:
	dot_dps = max(dot_dps, dps)
	dot_restante = duracao

func receber_dano(quantidade: int) -> void:
	receber_dano_detalhado(quantidade, false)

func receber_dano_detalhado(quantidade: int, critico: bool) -> void:
	if not entrada_concluida:
		return
	hp -= quantidade
	if hp < 0:
		hp = 0
	hp_alterado.emit(hp)

	# Aciona popup de dano no Main apenas se o Boss sobreviver ao golpe
	if hp > 0:
		var main_node = get_parent()
		if main_node and main_node.has_method("spawn_damage_number"):
			main_node.spawn_damage_number(quantidade, global_position, false, critico)
	
	# Flash branco ao receber dano
	modulate = Color(2.0, 2.0, 2.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0:
		morrer()

func morrer() -> void:
	morreu.emit()
	queue_free()

func _disparar_leque() -> void:
	var eproj_scene = preload("res://enemy_projectile.tscn")

	for angulo_graus in angulos_leque:
		var proj = eproj_scene.instantiate()
		proj.position = global_position + Vector2(0, 50) # Spawna logo abaixo do corpo do boss
		var dir = Vector2.from_angle(deg_to_rad(angulo_graus))
		proj.setup(dir, 500.0, 14.0)
		get_parent().add_child(proj)

	# Som de tiro rápido senoidal
	var main_node = get_parent()
	if main_node and main_node.has_method("_tocar_som"):
		var som = main_node._gerar_som_procedural(650.0, 0.06, "sin")
		main_node._tocar_som(som)

## Invoca 2 inimigos comuns como reforço (padrão Invocador, cap. 7+)
func _invocar_reforcos() -> void:
	var main_node = get_parent()
	if not main_node:
		return
	var enemy_scene = load("res://enemy.tscn")
	for offset_x in [-250.0, 250.0]:
		var enemy = enemy_scene.instantiate()
		enemy.position = Vector2(clamp(global_position.x + offset_x, 100.0, 980.0), -60.0)
		main_node.add_child(enemy)
		enemy.configurar_tipo(0) # Comum
		if main_node.has_method("_on_enemy_morreu"):
			enemy.morreu.connect(main_node._on_enemy_morreu)


