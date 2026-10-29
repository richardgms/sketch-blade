extends "res://TelaFim.gd"
## Tela de vitória (conclusão de capítulo), redesenhada em 29/10/2026 a partir
## do rascunho do amigo designer + conselho. Ordem: título → chefe com selo →
## tinta conquistada → bônus → XP → desbloqueio → botões.
## Botões, anúncio e peças desenhadas ficam na base TelaFim.gd.

const ARTE := Rect2(190, 215, 700, 640)
const SELO_CENTRO := Vector2(728, 665)
const ESCALA_SELO := 0.82 # maior para o anel (capítulo e nome) ficar legível
const Y_DESBLOQUEIO := 1450.0

var _arte: TextureRect
var _selo: Control
var _rotulo_total: Label
var _icone_total: TextureRect
var _total: Label
var _bloco: Control # bônus + XP (refeito depois do anúncio)
var _destaque: Control

# ------------------------------------------------------------
# Montagem
# ------------------------------------------------------------
func _montar_fixo() -> void:
	_txt(_conteudo, "CAPÍTULO CONCLUÍDO!", 74, VERDE, 70, 170)
	_traco(_conteudo, 170, 910, 180, Color(VERDE, 0.85), 5.0)

	_arte = TextureRect.new()
	_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arte.position = ARTE.position
	_arte.size = ARTE.size
	_arte.pivot_offset = ARTE.size / 2.0
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	# Dessaturação parcial: o corpo perde ~50% da cor, os vermelhos (olhos)
	# ficam intactos; sem clarear nem deixar transparente.
	sh.code = """shader_type canvas_item;
uniform float desat : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float vermelho = clamp((c.r - max(c.g, c.b)) * 3.0, 0.0, 1.0);
	vec3 suave = mix(c.rgb, vec3(g), 0.5 * desat);
	c.rgb = mix(suave, c.rgb, vermelho);
	COLOR = c;
}"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_arte.material = mat
	_conteudo.add_child(_arte)

	_selo = Control.new()
	_selo.set_script(preload("res://SeloDerrotado.gd"))
	_selo.size = Vector2(360, 360)
	_selo.pivot_offset = Vector2(180, 180)
	_selo.position = SELO_CENTRO - Vector2(180, 180)
	_selo.rotation_degrees = -14.0
	_selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_selo)

	_rotulo_total = _txt(_conteudo, "Tinta conquistada", 46, AZUL_ESCURO, 868, 932)
	_icone_total = TextureRect.new()
	_icone_total.texture = load("res://assets/ink.svg")
	_icone_total.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icone_total.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icone_total.size = Vector2(96, 96)
	_icone_total.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_icone_total)
	_total = _txt(_conteudo, "", 130, AZUL, 925, 1075, NUM, 0, 1080, HORIZONTAL_ALIGNMENT_LEFT)

	_bloco = Control.new()
	_bloco.size = Vector2(1080, 1920)
	_bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_bloco)

	_destaque = Control.new()
	_destaque.size = Vector2(1080, 90)
	_destaque.position = Vector2(0, Y_DESBLOQUEIO)
	_destaque.pivot_offset = Vector2(540, 40)
	_destaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_destaque)

	_criar_botoes("VOLTAR AO CADERNO")

## d: cap, nome (sem artigo), arte, tinta_partida, bonus_vida, bonus_cap,
## tinta_final, xp_ganho, nivel, xp, xp_req, niveis_ganhos, clipes, cap_desbloqueado
func mostrar(d: Dictionary) -> void:
	_dados = d
	_papel.configurar_para_capitulo(int(d["cap"]))
	_arte.texture = load(d["arte"])
	_selo.configurar(int(d["cap"]), d["nome"])
	_montar_valores(false)
	# Desbloqueio num espaço fixo: na vitória repetida o espaço fica vazio
	for f in _destaque.get_children():
		f.queue_free()
	if int(d["cap_desbloqueado"]) > 0:
		_marca_texto(_destaque, "Capítulo %d desbloqueado!" % int(d["cap_desbloqueado"]))
	_animar()

func _montar_valores(com_anuncio: bool) -> void:
	for f in _bloco.get_children():
		f.queue_free()
	var tf: int = int(_dados["tinta_final"])
	_rotulo_total.text = "Tinta conquistada (com anúncio)" if com_anuncio else "Tinta conquistada"
	_definir_total(tf * 2 if com_anuncio else tf)
	var linhas: Array = [["Tinta coletada", int(_dados["tinta_partida"])]]
	if int(_dados["bonus_vida"]) > 0:
		linhas.append(["Bônus de vidas", int(_dados["bonus_vida"])])
	if int(_dados["bonus_cap"]) > 0:
		linhas.append(["Bônus do capítulo", int(_dados["bonus_cap"])])
	if com_anuncio:
		linhas.append(["Bônus do anúncio", tf])
	for i in linhas.size():
		var y := 1090.0 + i * 58.0
		_txt(_bloco, linhas[i][0], 42, AZUL_ESCURO, y, y + 56, FONTE, 220, 700, HORIZONTAL_ALIGNMENT_LEFT)
		_txt(_bloco, "+" + _milhar(linhas[i][1]), 46, AZUL_ESCURO, y, y + 56, NUM, 700, 860, HORIZONTAL_ALIGNMENT_RIGHT)
	var y_xp := 1090.0 + linhas.size() * 58.0 + 30.0
	_traco(_bloco, 200, 880, y_xp - 12.0, Color(AZUL_ESCURO, 0.45), 2.5)
	var nivel: int = int(_dados["nivel"])
	var frac: float = float(_dados["xp"]) / max(1.0, float(_dados["xp_req"]))
	_barra_xp(_bloco, y_xp, nivel, frac, int(_dados["xp_ganho"]))
	if int(_dados["niveis_ganhos"]) > 0:
		_txt(_bloco, "Novo nível %d!  +%d clipes" % [nivel, int(_dados["clipes"])], 38, VERDE, y_xp + 62.0, y_xp + 108.0)

func _definir_total(valor: int) -> void:
	_total.text = "+%s tinta" % _milhar(valor)
	var tw: float = NUM.get_string_size(_total.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 130).x
	var x0: float = 540.0 - (tw + 110.0) / 2.0
	_icone_total.position = Vector2(x0, 952)
	_total.position.x = x0 + 110.0
	_total.size.x = tw + 40.0

# ------------------------------------------------------------
# Animação: chefe colorido → selo bate (corpo perde cor) → tinta conta
# rápido → desbloqueio → botões. Um toque pula para o fim.
# ------------------------------------------------------------
func _animar() -> void:
	_iniciar_animacao()
	_arte.modulate.a = 0.0
	_arte.scale = Vector2(0.85, 0.85)
	(_arte.material as ShaderMaterial).set_shader_parameter("desat", 0.0)
	_selo.modulate.a = 0.0
	_selo.scale = Vector2(2.2, 2.2) * ESCALA_SELO
	_destaque.modulate.a = 0.0
	_destaque.scale = Vector2(0.7, 0.7)
	_definir_total(0) # já centrado desde o primeiro quadro
	var tf: int = int(_dados["tinta_final"])

	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_tween.tween_property(_arte, "modulate:a", 1.0, 0.25)
	_tween.tween_property(_arte, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Batida curta do selo
	_tween.tween_property(_selo, "modulate:a", 1.0, 0.06).set_delay(0.45)
	_tween.tween_property(_selo, "scale", Vector2(ESCALA_SELO, ESCALA_SELO), 0.14).set_delay(0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_arte.material, "shader_parameter/desat", 1.0, 0.25).set_delay(0.59)
	_tween.tween_property(_arte, "scale", Vector2(0.96, 0.96), 0.05).set_delay(0.59)
	_tween.tween_property(_arte, "scale", Vector2.ONE, 0.1).set_delay(0.64)
	# Tinta conta rápido
	_tween.tween_method(func(v: float): _definir_total(int(v)), 0.0, float(tf), 0.6).set_delay(0.75) \
		.set_ease(Tween.EASE_OUT)
	if int(_dados["cap_desbloqueado"]) > 0:
		_tween.tween_property(_destaque, "modulate:a", 1.0, 0.12).set_delay(1.4)
		_tween.tween_property(_destaque, "scale", Vector2.ONE, 0.3).set_delay(1.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(_finalizar_animacao)

func _finalizar_animacao() -> void:
	if not _animando:
		return
	_arte.modulate.a = 1.0
	_arte.scale = Vector2.ONE
	(_arte.material as ShaderMaterial).set_shader_parameter("desat", 1.0)
	_selo.modulate.a = 1.0
	_selo.scale = Vector2(ESCALA_SELO, ESCALA_SELO)
	_destaque.modulate.a = 1.0
	_destaque.scale = Vector2.ONE
	_definir_total(int(_dados["tinta_final"]))
	_liberar_botoes()
