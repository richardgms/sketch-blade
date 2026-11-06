extends Node2D
class_name CorrosaoTinta
## Tinta Corrosiva no alvo: o monstro fica esverdeado (o dono faz o tom) e
## fiapos de vapor desenhados à caneta (assets/ui/vapor_1..3.png, do GPT Image,
## branco tingível) sobem do alto da cabeça, ondulando, crescendo e sumindo,
## defasados. Nada passa na frente do rosto.
## Filho do monstro/chefe; o dono chama renovar() a cada acerto. Some sozinho
## quando o efeito acaba e o último fiapo termina.

const VERDE := Color("1f7a2c")
const TEXTURAS := [preload("res://assets/ui/vapor_1.png"), preload("res://assets/ui/vapor_2.png"),
	preload("res://assets/ui/vapor_3.png")]
const VIDA: float = 1.1
const POR_SEGUNDO: float = 3.2

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

func _process(delta: float) -> void:
	_t += delta
	_restante -= delta
	if _restante > 0.0:
		_acum += delta * POR_SEGUNDO
		while _acum >= 1.0:
			_acum -= 1.0
			_fiapos.append([TEXTURAS.pick_random(), randf_range(-0.38, 0.38) * raio, 0.0, randf() * TAU,
				-1.0 if randf() < 0.5 else 1.0])
	for f in _fiapos:
		f[2] += delta
	_fiapos = _fiapos.filter(func(f): return f[2] < VIDA)
	if _restante <= 0.0 and _fiapos.is_empty():
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
		var base := Vector2(f[1] + sin(_t * 2.2 + f[3]) * raio * 0.08, -raio * 0.45 - rel * raio * 0.6)
		var a: float = minf(1.0, sin(rel * PI) * 1.6)
		draw_set_transform(base, 0.0, Vector2(f[4], 1.0))
		draw_texture_rect(tex, Rect2(-largo / 2.0, -alto, largo, alto), false, Color(VERDE, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
