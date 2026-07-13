@tool
extends Area2D

signal recebeu_dano(vidas_restantes: int)
signal morreu

@export var dano: int = 10
@export var intervalo_ataque: float = 0.75 # Cadência de tiro mais lenta e estratégica
@export var vidas_max: int = 5
@export var cor_caneta: Color = Color("1a1a2e")
var textura_caneta: Texture2D = null:
	set(valor):
		textura_caneta = valor
		_atualizar_hitbox()

var vidas: int = 5
var posicao_alvo: Vector2
var raio_corpo: float = 25.0
var invencivel: bool = false

# Limite inferior de movimento, calculado da altura real da tela (telas mais
# altas que 1920 ganham zona de jogo até perto do rodapé)
var limite_inferior_y: float = 1850.0

# Bases usadas para recalcular atributos quando upgrades são aplicados
var fator_lerp_base: float = 12.0
var intervalo_ataque_base: float = 0.75

# Fatores ajustáveis por upgrades in-run
var fator_lerp: float = 12.0
var bonus_velocidade_projetil: float = 1.0

# Passivas da caneta equipada (aplicadas pelo Main)
var chance_critica_passiva: float = 0.0
var cor_projetil: Color = Color(0.15, 0.15, 0.15, 0.9):
	set(valor):
		cor_projetil = valor
		if trilha_tinta:
			trilha_tinta.gradient.set_color(0, Color(valor, 0.0))
			trilha_tinta.gradient.set_color(1, Color(valor, 0.4))

# Rastro de tinta que a caneta deixa no papel ao se mover
var trilha_tinta: Line2D

# Upgrades in-run ativos: id -> nível (ex: {"tiro_duplo": 2})
var upgrades: Dictionary = {}

# Medidor de repouso para o "Move-and-Shoot" inteligente
var _tempo_alvo_estatico: float = 0.0
var _ultima_posicao_alvo: Vector2 = Vector2.ZERO

# Controle do Escudo de Borracha
var tem_escudo_ativo: bool = false
var tempo_recarga_escudo: float = 8.0
var timer_escudo: float = 0.0

var projectile_scene: PackedScene = preload("res://projectile.tscn")

@onready var attack_timer: Timer = $AttackTimer

func obter_y_ponta() -> float:
	return -100.0 if textura_caneta else -60.0

## Recalcula a hitbox de contato para acompanhar o tamanho real da caneta.
## Sem isso, a ponta (topo do SVG) fica muito acima do círculo central e o
## inimigo só "morre" ao afundar até o meio da caneta. Usamos uma cápsula
## vertical que vai da ponta (obter_y_ponta) até a base do corpo (raio_corpo).
func _atualizar_hitbox() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		return
	var y_ponta := obter_y_ponta()   # topo da hitbox (ponta da caneta)
	var y_base := raio_corpo         # base do corpo, logo abaixo da origem
	var cap := CapsuleShape2D.new()
	cap.radius = raio_corpo * 0.85   # largura ~ corpo da caneta
	cap.height = max(y_base - y_ponta, cap.radius * 2.0)
	cs.shape = cap
	cs.position = Vector2(0, (y_ponta + y_base) * 0.5)  # centraliza entre ponta e base

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	vidas = vidas_max
	posicao_alvo = position
	intervalo_ataque_base = intervalo_ataque
	attack_timer.wait_time = intervalo_ataque
	add_to_group("player")
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	area_entered.connect(_on_area_entered)
	_criar_trilha_tinta()
	_atualizar_hitbox()
	_atualizar_limites_tela()
	get_viewport().size_changed.connect(_atualizar_limites_tela)
	_ultima_posicao_alvo = position

func _atualizar_limites_tela() -> void:
	# Recuamos 115px para que o corpo do SVG não ultrapasse o rodapé da tela
	limite_inferior_y = get_viewport_rect().size.y - 115.0

## Cria a Line2D do rastro de tinta (em coordenadas de mundo, sob a caneta).
func _criar_trilha_tinta() -> void:
	trilha_tinta = Line2D.new()
	trilha_tinta.top_level = true
	# Acima do papel (o Player vem depois do Paper na árvore), mas atrás do
	# corpo da caneta — z_index -1 ficava ABAIXO do papel e o rastro nunca aparecia
	trilha_tinta.z_index = 0
	trilha_tinta.show_behind_parent = true
	trilha_tinta.width = 9.0
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.15))
	curva.add_point(Vector2(1.0, 1.0))
	trilha_tinta.width_curve = curva
	var grad := Gradient.new()
	grad.set_color(0, Color(cor_projetil, 0.0))
	grad.set_color(1, Color(cor_projetil, 0.4))
	trilha_tinta.gradient = grad
	trilha_tinta.joint_mode = Line2D.LINE_JOINT_ROUND
	trilha_tinta.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(trilha_tinta)

## Alimenta o rastro no bico da caneta; parado, o traço se dissolve.
func _atualizar_trilha_tinta() -> void:
	# Ponta real da caneta (calculada dinamicamente com base na presença de textura)
	var bico := global_position + Vector2(0, obter_y_ponta())
	var n := trilha_tinta.get_point_count()
	if n == 0 or trilha_tinta.get_point_position(n - 1).distance_to(bico) > 6.0:
		trilha_tinta.add_point(bico)
	elif n > 0:
		trilha_tinta.remove_point(0)
	while trilha_tinta.get_point_count() > 22:
		trilha_tinta.remove_point(0)

## Nível atual de um upgrade (0 = não possui).
func nivel_upgrade(id: String) -> int:
	return upgrades.get(id, 0)

## Sobe um upgrade de nível e aplica efeitos imediatos. Retorna o novo nível.
func aplicar_upgrade(id: String) -> int:
	var novo_nivel = nivel_upgrade(id) + 1
	upgrades[id] = novo_nivel

	match id:
		"escudo_borracha":
			tempo_recarga_escudo = GameData.valor_upgrade(id, novo_nivel)
			tem_escudo_ativo = true
			timer_escudo = 0.0
			queue_redraw()
		"apontador_rapido":
			_recalcular_atributos()

	return novo_nivel

## Recalcula cadência/agilidade a partir das bases + bônus do Apontador.
## Chamado também pelo Main após aplicar os upgrades RPG do Estojo.
func _recalcular_atributos() -> void:
	var bonus: float = 0.0
	var nivel_apontador = nivel_upgrade("apontador_rapido")
	if nivel_apontador > 0:
		bonus = GameData.valor_upgrade("apontador_rapido", nivel_apontador)

	fator_lerp = fator_lerp_base * (1.0 + bonus)
	bonus_velocidade_projetil = 1.0 + bonus
	intervalo_ataque = intervalo_ataque_base * (1.0 - bonus)
	attack_timer.wait_time = intervalo_ataque

func _draw() -> void:
	# Desenha a caneta in-game usando o SVG real quando disponível
	if textura_caneta:
		var tex_w := float(textura_caneta.get_width())
		var tex_h := float(textura_caneta.get_height())
		# Escala para ~200px de altura, mantendo proporção
		var escala_alvo := 200.0 / float(max(tex_w, tex_h))
		# Rotaciona 150° para a ponta da caneta apontar pra cima (12h)
		draw_set_transform(Vector2(0, -10), deg_to_rad(150.0), Vector2(escala_alvo, escala_alvo))
		draw_texture(textura_caneta, Vector2(-tex_w * 0.5, -tex_h * 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# Fallback: desenho procedural 1.3x
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * 1.3)
		DesenhoCaneta.desenhar(self, cor_caneta, cor_projetil)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Gotinha de tinta pulsante indicando que a caneta está carregada/pronta no bico
	var perto_o_suficiente = position.distance_to(posicao_alvo) < 28.0
	var dedo_parado = _tempo_alvo_estatico > 0.08
	if (perto_o_suficiente or dedo_parado) and not Engine.is_editor_hint():
		var y_ponta = obter_y_ponta()
		var pulso = 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.015)
		draw_circle(Vector2(0, y_ponta), 5.8 * pulso, cor_projetil)
		draw_circle(Vector2(-1, y_ponta - 1.0), 2.0 * pulso, Color(1.0, 1.0, 1.0, 0.6))

	# Desenho do Escudo de Borracha (arco tracejado envolvendo a caneta)
	if nivel_upgrade("escudo_borracha") > 0 and tem_escudo_ativo:
		draw_arc(Vector2.ZERO, raio_corpo + 23.0, 0, TAU, 32, Color("5bc0de"), 4.0)
		draw_arc(Vector2.ZERO, raio_corpo + 23.0, 0, TAU, 16, Color.WHITE, 2.0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Segue o dedo/mouse suavemente
	position = position.lerp(posicao_alvo, fator_lerp * delta)
	# Mantém dentro dos limites da tela (abaixo da pauta limite de Y=1550,
	# até perto do rodapé real — que varia com a proporção do aparelho)
	position = _clampar_aos_limites(position)

	_atualizar_trilha_tinta()

	# Rastreia se o alvo mudou (indica movimento ativo do dedo)
	if posicao_alvo.distance_to(_ultima_posicao_alvo) < 2.0:
		_tempo_alvo_estatico += delta
	else:
		_tempo_alvo_estatico = 0.0
	_ultima_posicao_alvo = posicao_alvo

	# Solicita redesenho a cada frame para a gotinha da ponta pulsar suavemente
	queue_redraw()

	# Lógica do Cooldown do Escudo de Borracha
	if nivel_upgrade("escudo_borracha") > 0 and not tem_escudo_ativo:
		timer_escudo += delta
		if timer_escudo >= tempo_recarga_escudo:
			tem_escudo_ativo = true
			queue_redraw() # Desenha o escudo ativo

			# Feedback flutuante na tela de escudo pronto
			var main_node = get_parent()
			if main_node and main_node.has_method("_spawn_feedback"):
				main_node._spawn_feedback("ESCUDO ATIVO!", "perfect", global_position)

func _clampar_aos_limites(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, 60.0, 1020.0),
		clamp(pos.y, 1550.0, limite_inferior_y)
	)

func mover_para(pos: Vector2) -> void:
	# O alvo usa os MESMOS limites da caneta: dedo além da borda deixaria o
	# alvo inalcançável e a checagem "parado?" do tiro nunca passaria
	posicao_alvo = _clampar_aos_limites(pos)

func _on_attack_timer_timeout() -> void:
	if Engine.is_editor_hint():
		return
	
	# Só atira se o jogador estiver parado.
	# Lógica inteligente: permite atirar se a caneta já estiver muito perto do alvo (tolerância ampliada de 28px)
	# OU se o dedo do jogador estiver imóvel na tela por pelo menos 0.08s (compensando o lag do LERP visual).
	var perto_o_suficiente = position.distance_to(posicao_alvo) < 28.0
	var dedo_parado = _tempo_alvo_estatico > 0.08
	
	if not (perto_o_suficiente or dedo_parado):
		return

	# Monta a lista de tiros desta rajada de acordo com os upgrades (escalados 1.3x)
	var tiros: Array = []
	var nivel_duplo = nivel_upgrade("tiro_duplo")
	var y_ponta = obter_y_ponta()
	if nivel_duplo > 0:
		var mult_duplo: float = GameData.valor_upgrade("tiro_duplo", nivel_duplo)
		tiros.append({"offset": Vector2(-20, y_ponta), "direcao": Vector2.UP, "mult": mult_duplo})
		tiros.append({"offset": Vector2(20, y_ponta), "direcao": Vector2.UP, "mult": mult_duplo})
	else:
		tiros.append({"offset": Vector2(0, y_ponta), "direcao": Vector2.UP, "mult": 1.0})

	# Leque de Rabiscos: +2 projéteis diagonais com dano reduzido
	var nivel_leque = nivel_upgrade("leque")
	if nivel_leque > 0:
		var mult_diag: float = GameData.valor_upgrade("leque", nivel_leque)
		var angulo = deg_to_rad(GameData.ANGULO_LEQUE_GRAUS)
		tiros.append({"offset": Vector2(-16, y_ponta + 7.0), "direcao": Vector2.UP.rotated(-angulo), "mult": mult_diag})
		tiros.append({"offset": Vector2(16, y_ponta + 7.0), "direcao": Vector2.UP.rotated(angulo), "mult": mult_diag})

	for tiro in tiros:
		_disparar_projetil(tiro["offset"], tiro["direcao"], tiro["mult"])

func _disparar_projetil(offset: Vector2, direcao: Vector2, mult_dano: float) -> void:
	var main = get_parent()
	var proj = null
	if main and main.has_method("obter_projetil_player"):
		proj = main.obter_projetil_player()
	else:
		proj = projectile_scene.instantiate()
		
	proj.position = global_position + offset
	proj.dano = max(1, int(dano * mult_dano))
	proj.velocidade = 900.0 * bonus_velocidade_projetil
	proj.direcao = direcao

	# Repassa os upgrades ofensivos para o projétil
	proj.perfuracoes_restantes = GameData.valor_upgrade("tiro_perfurante", nivel_upgrade("tiro_perfurante"))
	proj.ricochetes_restantes = GameData.valor_upgrade("ricochete", nivel_upgrade("ricochete"))
	proj.chance_critica = chance_critica_passiva + float(GameData.valor_upgrade("ponta_critica", nivel_upgrade("ponta_critica")))
	proj.dot_dps = GameData.valor_upgrade("tinta_corrosiva", nivel_upgrade("tinta_corrosiva"))
	proj.cor_tinta = cor_projetil
	proj.ultimo_alvo = null
	proj.rotation = direcao.angle() + PI / 2.0

	if not proj.is_inside_tree():
		main.add_child(proj)
	else:
		proj.queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if invencivel:
		return
	if area.is_in_group("enemies"):
		print("[DEBUG] Caneta sofreu dano de contato com: ", area.name)

		# Aplica o dano de contato do inimigo (padrão é 1, Boss causa 2)
		var dano_contato = area.get("dano_contato") if area.get("dano_contato") != null else 1
		receber_dano(dano_contato)

		# O inimigo comum se auto-destrói, mas o Boss continua vivo
		if area.get("morre_no_contato") == true and area.has_method("morrer"):
			area.morrer()

func receber_dano(quantidade: int = 1) -> void:
	if nivel_upgrade("escudo_borracha") > 0 and tem_escudo_ativo:
		tem_escudo_ativo = false
		timer_escudo = 0.0
		queue_redraw()

		# Som e feedback de apagamento/bloqueio
		var main_node = get_parent()
		if main_node and main_node.has_method("spawn_damage_number"):
			main_node.spawn_damage_number(0, global_position, false)
		if main_node and main_node.has_method("_spawn_feedback"):
			main_node._spawn_feedback("APAGADO!", "perfect", global_position)

		# Efeito visual rápido de encolher/voltar
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		return

	vidas -= quantidade
	if vidas < 0:
		vidas = 0
	recebeu_dano.emit(vidas)

	# Aciona popup de dano no Main (vermelho de correção)
	var main_node = get_parent()
	if main_node and main_node.has_method("spawn_damage_number"):
		main_node.spawn_damage_number(quantidade, global_position, true)

	# Flash vermelho de invencibilidade temporária
	invencivel = true
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)
	tween.finished.connect(func(): invencivel = false)

	if vidas <= 0:
		morreu.emit()
