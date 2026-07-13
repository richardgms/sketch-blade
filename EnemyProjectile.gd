extends Area2D

var velocidade: float = 500.0
var direcao: Vector2 = Vector2.DOWN

# Y de auto-destruição abaixo do rodapé real (recalculado no _ready para o
# projétil alcançar a caneta mesmo em telas mais altas que 1920)
var y_kill: float = 2100.0

func _ready() -> void:
	add_to_group("enemy_projectiles")
	area_entered.connect(_on_area_entered)
	y_kill = get_viewport_rect().size.y + 100.0

func setup(dir: Vector2, speed: float = 500.0, novo_raio: float = 7.0) -> void:
	direcao = dir.normalized()
	velocidade = speed
	rotation = direcao.angle() - PI/2 # Corrige orientação para a cauda ficar atrás
	
	# Ajusta a escala global do projétil proporcionalmente ao raio
	var escala = novo_raio / 7.0
	scale = Vector2(escala, escala)

func _process(delta: float) -> void:
	# Voa na direção configurada
	position += direcao * velocidade * delta
	
	# Auto-destrói se sair das bordas
	if position.y > y_kill or position.y < -100 or position.x < -100 or position.x > 1180:
		_destruir()

func _draw() -> void:
	# Desenha gotinha vermelha de tinta (corretor de caneta vermelha)
	draw_circle(Vector2.ZERO, 7.0, Color("d9534f"))
	
	# Cauda rústica apontando para trás
	var cauda = PackedVector2Array([
		Vector2(-5, 0),
		Vector2(0, -14),
		Vector2(5, 0)
	])
	draw_colored_polygon(cauda, Color("d9534f"))
	
	# Brilho
	draw_circle(Vector2(-2, 2), 2.0, Color(1.0, 1.0, 1.0, 0.4))

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("receber_dano"):
			area.receber_dano(1)
		_destruir()

func _destruir() -> void:
	var main = get_parent()
	if main and main.has_method("devolver_projetil_inimigo"):
		main.devolver_projetil_inimigo(self)
	else:
		queue_free()
