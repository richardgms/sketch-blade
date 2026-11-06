extends Node2D
class_name CorrosaoTinta
## Tinta Corrosiva no alvo: o monstro fica esverdeado (o dono faz o tom) e
## fiapos de vapor desenhados à caneta (assets/ui/vapor_1..3.png, do GPT Image,
## branco tingível) sobem do alto da cabeça, ondulando, crescendo e sumindo,
## defasados. Bolhas à caneta (assets/ui/bolha_quadros.png: 6 quadros de uma
## folha do GPT Image) nascem nas laterais e no alto do corpo, sobem tremendo e
## estouram lá em cima; no chefe (que não fica verde) saem mais bolhas.
## Nada passa na frente do rosto.
## Filho do monstro/chefe; o dono chama renovar() a cada acerto. Some sozinho
## quando o efeito acaba e o último fiapo termina.

const VERDE := Color("1f7a2c")
const TEXTURAS := [preload("res://assets/ui/vapor_1.png"), preload("res://assets/ui/vapor_2.png"),
	preload("res://assets/ui/vapor_3.png")]
const VIDA: float = 1.1
const POR_SEGUNDO: float = 3.2
const BOLHAS := preload("res://assets/ui/bolha_quadros.png")
const QUADRO: float = 96.0           # lado de cada quadro na folha
const PAPEL := Color("fbf8ef")

## Ondulação: desloca a textura na horizontal em onda que sobe; mais forte na
## ponta de cima do fiapo (que fica solta) e quase nada na base.
const SHADER_ONDA := """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	float solto = 1.0 - uv.y;
	uv.x += sin(uv.y * 8.0 - TIME * 3.2) * 0.07 * (0.25 + solto);
	COLOR = texture(TEXTURE, uv) * COLOR;
	if (uv.x < 0.0 || uv.x > 1.0) { COLOR.a = 0.0; }
}
"""
static var _material: ShaderMaterial

var raio: float = 35.0

var _restante: float = 0.0
var _t: float = 0.0
var _acum: float = 0.6
var _fiapos: Array = [] # [textura, x, idade, fase, lado (espelha)]
var _bolhas: Array = [] # [pos, vel, idade, vida_ate_estourar, escala, fase]
var _acum_bolha: float = 0.3
var _camada_bolhas: Node2D # sem o shader de onda

## Cria (ou reaproveita) o efeito no dono e renova a duração.
static func aplicar(dono: Node2D, atual: Node2D, raio_alvo: float, duracao: float) -> Node2D:
	var fx: Node2D = atual
	if fx == null or not is_instance_valid(fx) or fx.is_queued_for_deletion():
		fx = Node2D.new()
		fx.set_script(load("res://CorrosaoTinta.gd"))
		fx.raio = raio_alvo
		dono.add_child(fx)
	fx.renovar(duracao)
	return fx

func renovar(duracao: float) -> void:
	_restante = maxf(_restante, duracao)

func _ready() -> void:
	z_index = 1
	if _material == null:
		var sh := Shader.new()
		sh.code = SHADER_ONDA
		_material = ShaderMaterial.new()
		_material.shader = sh
	material = _material
	_camada_bolhas = Node2D.new()
	_camada_bolhas.use_parent_material = false
	_camada_bolhas.material = CanvasItemMaterial.new()
	add_child(_camada_bolhas)
	_camada_bolhas.draw.connect(_desenhar_bolhas)

## Mais bolhas no chefe (raio grande) do que no monstro comum.
func _bolhas_por_segundo() -> float:
	return 4.0 if raio > 70.0 else 1.5

func _process(delta: float) -> void:
	_t += delta
	_restante -= delta
	if _restante > 0.0:
		_acum += delta * POR_SEGUNDO
		while _acum >= 1.0:
			_acum -= 1.0
			_fiapos.append([TEXTURAS.pick_random(), randf_range(-0.8, 0.8) * raio, 0.0, randf() * TAU,
				-1.0 if randf() < 0.5 else 1.0])
		_acum_bolha += delta * _bolhas_por_segundo()
		while _acum_bolha >= 1.0:
			_acum_bolha -= 1.0
			# Nasce na borda do corpo (laterais e alto), longe do rosto
			var ang := randf_range(-PI * 0.95, -PI * 0.05)
			if absf(ang + PI / 2.0) < 0.5:
				ang += 0.5 * signf(ang + PI / 2.0 + 0.001)
			var pos := Vector2.from_angle(ang) * raio * randf_range(0.75, 0.95)
			_bolhas.append([pos, Vector2(cos(ang) * 18.0, randf_range(-95.0, -65.0)), 0.0,
				randf_range(0.7, 1.05), randf_range(0.8, 1.15) * clampf(raio / 40.0, 0.9, 2.0), randf() * TAU])
	for f in _fiapos:
		f[2] += delta
	_fiapos = _fiapos.filter(func(f): return f[2] < VIDA)
	for b in _bolhas:
		b[2] += delta
		if b[2] < b[3]:
			b[0] += b[1] * delta
			b[0].x += sin(_t * 5.0 + b[5]) * 14.0 * delta
	_bolhas = _bolhas.filter(func(b): return b[2] < b[3] + 0.3)
	_camada_bolhas.queue_redraw()
	if _restante <= 0.0 and _fiapos.is_empty() and _bolhas.is_empty():
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	for f in _fiapos:
		var tex: Texture2D = f[0]
		var rel: float = f[2] / VIDA
		var alto: float = minf(raio * 2.4, 190.0) * lerpf(0.75, 1.1, rel)
		var largo: float = alto * tex.get_width() / tex.get_height()
		# A base nasce no alto da cabeça e sobe; balança de leve para os lados
		# Nas laterais a base fica mais baixa (segue a curva da cabeça) e inclina para fora
		var lado_rel: float = f[1] / raio
		var base := Vector2(f[1] + sin(_t * 2.2 + f[3]) * raio * 0.08 + lado_rel * rel * raio * 0.5,
			-raio * (0.5 - absf(lado_rel) * 0.25) - rel * raio * 0.6)
		var a: float = minf(1.0, sin(rel * PI) * 1.6)
		draw_set_transform(base, lado_rel * 0.35, Vector2(f[4], 1.0))
		draw_texture_rect(tex, Rect2(-largo / 2.0, -alto, largo, alto), false, Color(VERDE, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Bolha: quadros 0 e 1 alternando enquanto sobe; depois 2..5 no estouro (0,06 s cada).
func _desenhar_bolhas() -> void:
	var ci := _camada_bolhas
	for b in _bolhas:
		var quadro: int
		if b[2] < b[3]:
			quadro = int((b[2] + b[5]) / 0.16) % 2
		else:
			quadro = mini(5, 2 + int((b[2] - b[3]) / 0.06))
		var lado: float = 70.0 * b[4]
		var a: float = clampf(b[2] / 0.12, 0.0, 1.0)
		if quadro < 3:
			ci.draw_circle(b[0], lado * 0.17, Color(PAPEL, 0.55 * a))
		ci.draw_texture_rect_region(BOLHAS, Rect2(b[0] - Vector2(lado, lado) / 2.0, Vector2(lado, lado)),
			Rect2(quadro * QUADRO, 0.0, QUADRO, QUADRO), Color(VERDE, a))
