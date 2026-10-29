extends Area2D

var velocidade: float = 900.0
var dano: int = 1
var direcao: Vector2 = Vector2.UP
var cor_tinta: Color = Color(0.15, 0.15, 0.15, 0.9)

# Upgrades repassados pelo Player
var perfuracoes_restantes: int = 0
var ricochetes_restantes: int = 0
var chance_critica: float = 0.0
var dot_dps: int = 0

# Evita ricochetear de volta no mesmo alvo imediatamente
var ultimo_alvo: Area2D = null

# Y de auto-destruição abaixo do rodapé real (ricochete pode mandar pra baixo)
var y_kill: float = 2000.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	rotation = direcao.angle() + PI / 2.0 # Traço aponta na direção do voo
	y_kill = get_viewport_rect().size.y + 80.0

func _process(delta: float) -> void:
	position += direcao * velocidade * delta

	# Auto-destrói ao sair da tela (qualquer borda, pois ricochete muda a direção)
	if position.y < -50 or position.y > y_kill or position.x < -50 or position.x > 1130:
		_destruir()

func _draw() -> void:
	# Gota de tinta em forma de cometa: cabeça redonda na frente (direção do voo)
	# e cauda lisa que desbota. Cor definida pela caneta equipada.
	var c := cor_tinta
	c.a = 1.0
	var fim := c
	fim.a = 0.0
	draw_polygon(PackedVector2Array([Vector2(-10, -9), Vector2(10, -9), Vector2(0, 46)]),
		PackedColorArray([c, c, fim]))
	draw_circle(Vector2(0, -9), 10.0, c)
	var brilho := c.lightened(0.6)
	brilho.a = 0.9
	draw_circle(Vector2(-3.0, -12.5), 3.2, brilho)

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies") or area == ultimo_alvo:
		return
	if not area.has_method("receber_dano"):
		return

	# Rola o crítico (dano x2)
	var dano_final = dano
	var eh_critico = chance_critica > 0.0 and randf() < chance_critica
	if eh_critico:
		dano_final = dano * 2

	# Tinta corrosiva: aplica dano contínuo antes do impacto
	if dot_dps > 0 and area.has_method("aplicar_dot"):
		area.aplicar_dot(dot_dps, GameData.DURACAO_DOT)

	if area.has_method("receber_dano_detalhado"):
		area.receber_dano_detalhado(dano_final, eh_critico)
	else:
		area.receber_dano(dano_final)

	# Respingo de tinta no ponto do acerto
	var main = get_parent()
	if main and main.has_method("spawn_impacto"):
		main.spawn_impacto(global_position, cor_tinta, eh_critico)
	if main and main.has_method("tocar_acerto"):
		main.tocar_acerto(eh_critico)

	# Ordem de sobrevivência do projétil: perfura primeiro, depois ricocheteia
	if perfuracoes_restantes > 0:
		perfuracoes_restantes -= 1
		ultimo_alvo = area
	elif ricochetes_restantes > 0 and _ricochetear(area):
		ricochetes_restantes -= 1
	else:
		_destruir()

func _destruir() -> void:
	var main = get_parent()
	if main and main.has_method("devolver_projetil_player"):
		main.devolver_projetil_player(self)
	else:
		queue_free()

## Redireciona o projétil para o inimigo vivo mais próximo (excluindo o atingido).
## Retorna false se não houver outro alvo (o projétil então se destrói).
func _ricochetear(atingido: Area2D) -> bool:
	var mais_proximo: Area2D = null
	var menor_dist: float = INF

	for inimigo in get_tree().get_nodes_in_group("enemies"):
		if inimigo == atingido or inimigo.is_queued_for_deletion():
			continue
		var dist = global_position.distance_squared_to(inimigo.global_position)
		if dist < menor_dist:
			menor_dist = dist
			mais_proximo = inimigo

	if mais_proximo == null:
		return false

	direcao = (mais_proximo.global_position - global_position).normalized()
	rotation = direcao.angle() + PI / 2.0
	ultimo_alvo = atingido
	return true
