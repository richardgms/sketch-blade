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

## Estilo visual por atirador: cor quente/forte com contorno escuro grosso,
## e formato próprio (não depende só da cor). Azul fica só para o jogador.
## "respingo": gota verde; "elite": losango laranja de borda dourada;
## "chefe": bola vermelha com espinhos.
var estilo: String = "respingo"

const CONTORNO := Color("1a1a2e")
const ESTILOS: Dictionary = {
	"respingo": {"miolo": Color("3fbf4f"), "brilho": Color("b7f5a8")},
	"elite": {"miolo": Color("f39c12"), "brilho": Color("ffe08a"), "borda": Color("f1c40f")},
	"chefe": {"miolo": Color("e0352b"), "brilho": Color("ffb3a8")},
}

func setup(dir: Vector2, speed: float = 500.0, novo_raio: float = 7.0, novo_estilo: String = "respingo") -> void:
	direcao = dir.normalized()
	velocidade = speed
	estilo = novo_estilo if ESTILOS.has(novo_estilo) else "respingo"
	rotation = direcao.angle() - PI/2 # Corrige orientação para a cauda ficar atrás

	# Escala proporcional ao raio: vale para a colisão (8 px na base) e o desenho
	var escala = novo_raio / 7.0
	scale = Vector2(escala, escala)
	queue_redraw()

func _process(delta: float) -> void:
	# Voa na direção configurada
	position += direcao * velocidade * delta
	
	# Auto-destrói se sair das bordas
	if position.y > y_kill or position.y < -100 or position.x < -100 or position.x > 1180:
		_destruir()

func _draw() -> void:
	# O desenho é maior que a colisão (raio 8): fácil de ver, justo de desviar.
	# Local: +Y aponta para a frente do voo; a cauda fica em -Y.
	var e: Dictionary = ESTILOS[estilo]
	var miolo: Color = e["miolo"]
	var brilho: Color = e["brilho"]
	var rastro := miolo
	rastro.a = 0.35
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -2), Vector2(6, -2), Vector2(0, -30)]), rastro)

	match estilo:
		"elite":
			# Losango laranja com borda dourada
			var pts := PackedVector2Array([Vector2(0, 15), Vector2(11, 0), Vector2(0, -15), Vector2(-11, 0)])
			var borda := PackedVector2Array([Vector2(0, 19), Vector2(15, 0), Vector2(0, -19), Vector2(-15, 0)])
			draw_colored_polygon(borda, CONTORNO)
			draw_colored_polygon(pts, e["borda"])
			draw_colored_polygon(PackedVector2Array([Vector2(0, 10), Vector2(7, 0), Vector2(0, -10), Vector2(-7, 0)]), miolo)
		"chefe":
			# Bola vermelha com espinhos
			var espinhos := PackedVector2Array()
			for i in 16:
				var r: float = 17.0 if i % 2 == 0 else 12.0
				espinhos.append(Vector2.from_angle(i * TAU / 16.0) * r)
			draw_colored_polygon(espinhos, CONTORNO)
			draw_circle(Vector2.ZERO, 10.5, miolo)
		_:
			# Gota verde: cabeça redonda na frente, ponta atrás
			draw_colored_polygon(PackedVector2Array([Vector2(-11, 1), Vector2(11, 1), Vector2(0, -17)]), CONTORNO)
			draw_circle(Vector2(0, 2), 12.0, CONTORNO)
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 1), Vector2(8, 1), Vector2(0, -12)]), miolo)
			draw_circle(Vector2(0, 2), 9.0, miolo)

	var b := brilho
	b.a = 0.9
	draw_circle(Vector2(-3, 5), 3.0, b)

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
