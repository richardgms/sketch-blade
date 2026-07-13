extends Node2D
## Gota de tinta derrubada pelos monstros.
## Ciclo de vida: explosão inicial → escorre pela página → ímã ao aproximar
## da caneta → coleta. Gota ignorada "seca" e some. Na vitória, o Main força
## a coleta e as gotas restantes voam para o contador do HUD.

const RAIO_IMA: float = 200.0        # Distância da caneta que ativa a atração
const RAIO_COLETA: float = 40.0      # Distância que conta como coletada
const TEMPO_SECAGEM: float = 6.0     # Vida total da gota no papel
const INICIO_AVISO: float = 4.5      # Quando começa a piscar avisando que vai secar

# Rodapé onde a gota empoça (recalculado da altura real da tela no _ready)
var y_poca: float = 1870.0

var valor_tinta: int = 5
var global_target_pos: Vector2       # Contador do HUD (usado só na coleta forçada)

var velocity: Vector2
var fase: String = "explosao"        # explosao → queda → ima / hud
var tempo_vida: float = 0.0

var textura_drop: Texture2D = null

func _ready() -> void:
	add_to_group("ink_drops")
	y_poca = get_viewport_rect().size.y - 50.0
	# Fase de explosão inicial: escolhe um ângulo e velocidade aleatórios
	var angulo = randf_range(0, TAU)
	var velocidade_inicial = randf_range(200.0, 400.0)
	velocity = Vector2.from_angle(angulo) * velocidade_inicial

func setup(valor: int, textura: Texture2D, target_pos: Vector2) -> void:
	valor_tinta = valor
	textura_drop = textura
	global_target_pos = target_pos
	queue_redraw()

func _draw() -> void:
	if textura_drop:
		draw_texture_rect(textura_drop, Rect2(Vector2(-18, -18), Vector2(36, 36)), false)
	else:
		draw_circle(Vector2.ZERO, 9.0, Color.BLACK)
		draw_circle(Vector2(-3, -3), 3.0, Color(1.0, 1.0, 1.0, 0.4))

func _process(delta: float) -> void:
	tempo_vida += delta

	match fase:
		"explosao":
			# Espalha em burst e sofre fricção rápida
			position += velocity * delta
			velocity = velocity.lerp(Vector2.ZERO, 6.0 * delta)
			if tempo_vida >= 0.3:
				fase = "queda"
				velocity = Vector2.ZERO
		"queda":
			# A tinta escorre pela página com um balancinho lateral
			velocity.y = min(velocity.y + 900.0 * delta, 520.0)
			position.y = min(position.y + velocity.y * delta, y_poca)
			position.x += sin(tempo_vida * 4.0 + float(get_instance_id() % 7)) * 30.0 * delta

			# Ímã: perto da caneta, a gota é atraída de vez
			var player = get_tree().get_first_node_in_group("player")
			if player and global_position.distance_to(player.global_position) <= RAIO_IMA:
				fase = "ima"
				modulate.a = 1.0
			elif tempo_vida >= TEMPO_SECAGEM:
				_secar()
			elif tempo_vida >= INICIO_AVISO:
				# Pisca avisando que está secando
				modulate.a = 0.45 + 0.55 * abs(sin(tempo_vida * 10.0))
		"ima":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				_voar_para(player.global_position, delta)
			else:
				fase = "queda"
		"hud":
			_voar_para(global_target_pos, delta)

## Voo magnético: acelera conforme chega mais perto do alvo.
func _voar_para(alvo: Vector2, delta: float) -> void:
	var direcao = (alvo - global_position).normalized()
	var distancia = global_position.distance_to(alvo)
	var speed = lerp(800.0, 2000.0, 1.0 - clamp(distancia / 1500.0, 0.0, 1.0))
	global_position += direcao * speed * delta
	if distancia < RAIO_COLETA:
		_coletar()

func _coletar() -> void:
	var main_node = get_parent()
	if main_node and main_node.has_method("_on_ink_drop_coletada"):
		main_node._on_ink_drop_coletada(valor_tinta)
	queue_free()

## Chamado pelo Main na vitória: as gotas restantes voam direto pro contador.
func forcar_coleta_no_hud() -> void:
	fase = "hud"
	modulate.a = 1.0

## Gota ignorada seca no papel e some sem dar tinta.
func _secar() -> void:
	SaveManager.incrementar_stat("gotas_secas")
	set_process(false)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.finished.connect(queue_free)
