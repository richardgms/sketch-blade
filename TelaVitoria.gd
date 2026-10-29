extends Control
## Tela de vitória (conclusão de capítulo), redesenhada em 29/10/2026 a partir
## do rascunho do amigo designer + conselho. Ordem: título → chefe com selo →
## tinta conquistada → bônus → XP → desbloqueio → botões.
## O Main só chama mostrar(), bonus_recebido() e anuncio_falhou(); a lógica do
## anúncio e da economia continua no Main/AdsManager.

signal voltar_pressionado
signal anuncio_pressionado

const FONTE := preload("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
const NUM := preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")
const AZUL := Color("0047ab")
const AZUL_ESCURO := Color("002867")
const VERDE := Color("2e7d32")
const VERDE_OK := Color("2e9e44")
const BOTAO_RISCADO := "res://assets/ui/botao_riscado.png"

# Layout pensado em 1080x1920; em telas mais altas o conteúdo fica centrado.
const ARTE := Rect2(190, 215, 700, 640)
const SELO_CENTRO := Vector2(728, 665)
const Y_DESBLOQUEIO := 1450.0
const BOTAO_VOLTAR := Rect2(130, 1580, 820, 125)
const BOTAO_ANUNCIO := Rect2(150, 1740, 780, 100)

var _papel: ColorRect
var _conteudo: Control
var _arte: TextureRect
var _selo: Control
var _rotulo_total: Label
var _icone_total: TextureRect
var _total: Label
var _bloco: Control # bônus + XP (refeito depois do anúncio)
var _destaque: Control
var _btn_voltar: Button
var _btn_anuncio: Button
var _linha_anuncio: HBoxContainer
var _pular: Control
var _tween: Tween
var _dados: Dictionary = {}
var _animando := false
var _bonus_recebido := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Papel da fase cobre tudo (inclusive o HUD da partida por trás)
	_papel = ColorRect.new()
	_papel.set_script(preload("res://Paper.gd"))
	_papel.desenhar_margem = false
	_papel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_papel)
	_conteudo = Control.new()
	_conteudo.size = Vector2(1080, 1920)
	_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_conteudo)
	_montar_fixo()
	# Camada que recebe o toque para pular a animação (fica por cima de tudo)
	_pular = Control.new()
	_pular.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pular.gui_input.connect(func(ev: InputEvent):
		if _animando and ev is InputEventMouseButton and ev.pressed:
			_finalizar_animacao())
	add_child(_pular)
	get_viewport().size_changed.connect(_centralizar)
	_centralizar()

func _centralizar() -> void:
	var alt: float = get_viewport_rect().size.y
	_conteudo.position = Vector2(0, max(0.0, (alt - 1920.0) / 2.0))

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

	_btn_voltar = _botao_cheio("VOLTAR AO CADERNO", BOTAO_VOLTAR)
	_btn_voltar.pressed.connect(func(): voltar_pressionado.emit())
	_btn_anuncio = _botao_contorno(BOTAO_ANUNCIO)
	_btn_anuncio.pressed.connect(func():
		if _bonus_recebido:
			return
		_btn_anuncio.disabled = true
		_conteudo_anuncio("carregando")
		anuncio_pressionado.emit())

## d: cap, nome (sem artigo), arte, tinta_partida, bonus_vida, bonus_cap,
## tinta_final, xp_ganho, nivel, xp, xp_req, niveis_ganhos, clipes, cap_desbloqueado
func mostrar(d: Dictionary) -> void:
	_dados = d
	_bonus_recebido = false
	_papel.configurar_para_capitulo(int(d["cap"]))
	_arte.texture = load(d["arte"])
	_selo.configurar(int(d["cap"]), d["nome"])
	_montar_valores(false)
	# Desbloqueio num espaço fixo: na vitória repetida o espaço fica vazio
	for f in _destaque.get_children():
		f.queue_free()
	if int(d["cap_desbloqueado"]) > 0:
		_marca_texto(_destaque, "Capítulo %d desbloqueado!" % int(d["cap_desbloqueado"]))
	_btn_anuncio.visible = int(d["tinta_final"]) > 0
	_btn_anuncio.disabled = false
	_conteudo_anuncio("oferta")
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
	var frac: float = clamp(float(_dados["xp"]) / max(1.0, float(_dados["xp_req"])), 0.0, 1.0)
	var xp_ganho: int = int(_dados["xp_ganho"])
	var barra := Control.new()
	barra.position = Vector2(200, y_xp)
	barra.size = Vector2(680, 60)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.draw.connect(func():
		var r := Rect2(100, 14, 400, 30)
		barra.draw_rect(r, Color.WHITE)
		barra.draw_rect(Rect2(r.position, Vector2(r.size.x * frac, r.size.y)), AZUL)
		barra.draw_rect(r, AZUL_ESCURO, false, 3.0)
		barra.draw_string(NUM, Vector2(0, 43), "Nv. %d" % nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, AZUL_ESCURO)
		barra.draw_string(NUM, Vector2(518, 43), "+%d XP" % xp_ganho, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, AZUL_ESCURO))
	_bloco.add_child(barra)
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
# rápido → desbloqueio → botões. Um toque pula para o fim. Os botões só
# funcionam 0,5 s depois que a contagem termina (sem toque sem querer no anúncio).
# ------------------------------------------------------------
func _animar() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_animando = true
	_pular.mouse_filter = Control.MOUSE_FILTER_STOP
	_travar_botoes(true)
	_arte.modulate.a = 0.0
	_arte.scale = Vector2(0.85, 0.85)
	(_arte.material as ShaderMaterial).set_shader_parameter("desat", 0.0)
	_selo.modulate.a = 0.0
	_selo.scale = Vector2(2.2, 2.2) * 0.72
	_destaque.modulate.a = 0.0
	_destaque.scale = Vector2(0.7, 0.7)
	_total.text = "+0 tinta"
	var tf: int = int(_dados["tinta_final"])

	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_tween.tween_property(_arte, "modulate:a", 1.0, 0.25)
	_tween.tween_property(_arte, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Batida curta do selo
	_tween.tween_property(_selo, "modulate:a", 1.0, 0.06).set_delay(0.45)
	_tween.tween_property(_selo, "scale", Vector2(0.72, 0.72), 0.14).set_delay(0.45) \
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
	_animando = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_arte.modulate.a = 1.0
	_arte.scale = Vector2.ONE
	(_arte.material as ShaderMaterial).set_shader_parameter("desat", 1.0)
	_selo.modulate.a = 1.0
	_selo.scale = Vector2(0.72, 0.72)
	_destaque.modulate.a = 1.0
	_destaque.scale = Vector2.ONE
	_definir_total(int(_dados["tinta_final"]))
	_pular.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Botões aparecem já, mas só aceitam toque depois de 0,5 s
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_btn_voltar, "modulate:a", 1.0, 0.15)
	t.parallel().tween_property(_btn_anuncio, "modulate:a", 1.0, 0.15)
	t.tween_interval(0.35)
	t.tween_callback(func(): _travar_botoes(false))

func _travar_botoes(travar: bool) -> void:
	for b in [_btn_voltar, _btn_anuncio]:
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE if travar else Control.MOUSE_FILTER_STOP
		if travar:
			b.modulate.a = 0.0

## Toque de voltar do Android: durante a animação só pula; depois, sai.
func voltar_do_sistema() -> bool:
	if _animando:
		_finalizar_animacao()
		return true
	return false

# ------------------------------------------------------------
# Anúncio (chamado pelo Main)
# ------------------------------------------------------------
func bonus_recebido() -> void:
	_bonus_recebido = true
	_btn_anuncio.disabled = true
	_conteudo_anuncio("recebido")
	_montar_valores(true)

func anuncio_falhou() -> void:
	if _bonus_recebido:
		return
	_btn_anuncio.disabled = false
	_conteudo_anuncio("oferta")

func _conteudo_anuncio(estado: String) -> void:
	for f in _linha_anuncio.get_children():
		f.queue_free()
	var cor := VERDE_OK if estado == "recebido" else AZUL
	var partes: Array
	match estado:
		"recebido":
			partes = [["", "Bônus recebido  ✓"]]
		"carregando":
			partes = [["", "Carregando..."]]
		_:
			partes = [["res://assets/ads.svg", ""], ["", "Ver anúncio ·"], ["res://assets/ink.svg", ""],
				["", "+" + _milhar(int(_dados.get("tinta_final", 0)))]]
	for p in partes:
		if p[0] != "":
			var ic := TextureRect.new()
			ic.texture = load(p[0])
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(58, 58)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if p[0].ends_with("ads.svg"):
				ic.modulate = AZUL
			_linha_anuncio.add_child(ic)
		else:
			var numero: bool = p[1].begins_with("+")
			var l := Label.new()
			l.text = p[1]
			l.add_theme_font_override("font", NUM if numero else FONTE)
			l.add_theme_font_size_override("font_size", 58 if numero else 46)
			l.add_theme_color_override("font_color", cor)
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_linha_anuncio.add_child(l)

# ------------------------------------------------------------
# Peças desenhadas (mesmo estilo do hub)
# ------------------------------------------------------------
func _txt(pai: Control, t: String, tam: int, cor: Color, y0: float, y1: float, fonte: Font = FONTE,
		x0: float = 0.0, x1: float = 1080.0, alinh := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.horizontal_alignment = alinh
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(x0, y0)
	l.size = Vector2(x1 - x0, y1 - y0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(l)
	return l

## Traço de caneta levemente ondulado.
func _traco(pai: Control, x0: float, x1: float, y: float, cor: Color, esp: float) -> void:
	var c := Control.new()
	c.size = Vector2(1080, 1920)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var pts: PackedVector2Array = []
		for i in range(21):
			pts.append(Vector2(lerp(x0, x1, float(i) / 20.0), y + sin(i * 1.9 + y) * 1.2))
		c.draw_polyline(pts, cor, esp, true))
	pai.add_child(c)

func _marca_texto(pai: Control, t: String) -> void:
	var w: float = FONTE.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 50).x + 60.0
	var faixa := ColorRect.new()
	faixa.color = Color(1.0, 0.92, 0.35, 0.75)
	faixa.position = Vector2(540 - w / 2.0, 6)
	faixa.size = Vector2(w, 66)
	faixa.rotation_degrees = -1.0
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(faixa)
	_txt(pai, t, 50, AZUL_ESCURO, 0, 78)

func _botao_cheio(t: String, rect: Rect2) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", FONTE)
	b.add_theme_font_size_override("font_size", 60)
	for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(e, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(AZUL_ESCURO, 0.6))
	b.add_theme_constant_override("outline_size", 6)
	var st := StyleBoxTexture.new()
	st.texture = load(BOTAO_RISCADO)
	st.texture_margin_left = 48.0
	st.texture_margin_right = 48.0
	st.texture_margin_top = 36.0
	st.texture_margin_bottom = 36.0
	for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_content_margin(lado, 6.0)
	var st_p: StyleBoxTexture = st.duplicate()
	st_p.modulate_color = Color(0.8, 0.8, 0.85)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st)
	b.add_theme_stylebox_override("pressed", st_p)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.position = rect.position
	b.size = rect.size
	_conteudo.add_child(b)
	return b

## Botão de contorno (fundo branco, moldura de caneta) com uma linha de
## ícones + textos centrada por dentro.
func _botao_contorno(rect: Rect2) -> Button:
	var b := Button.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(14)
	var sb_p: StyleBoxFlat = sb.duplicate()
	sb_p.bg_color = Color(0.94, 0.94, 0.94)
	for e in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(e, sb)
	b.add_theme_stylebox_override("pressed", sb_p)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.position = rect.position
	b.size = rect.size
	b.draw.connect(func():
		var r := 22.0
		var m := -6.0
		var w := b.size.x
		var h := b.size.y
		var cantos := [[Vector2(w - m - r, m + r), -PI / 2.0], [Vector2(w - m - r, h - m - r), 0.0],
			[Vector2(m + r, h - m - r), PI / 2.0], [Vector2(m + r, m + r), PI]]
		var pts: PackedVector2Array = []
		var idx := 0
		for c in cantos:
			for i in range(9):
				var a: float = c[1] + float(i) / 8.0 * PI / 2.0
				pts.append(c[0] + Vector2(cos(a), sin(a)) * r + Vector2(3, 3)
					+ Vector2(sin(idx * 7.31), cos(idx * 5.17)) * 1.2)
				idx += 1
		pts.append(pts[0] + Vector2(-14, -1.5))
		b.draw_polyline(pts, Color(AZUL_ESCURO, 0.9), 3.5, true))
	_conteudo.add_child(b)
	_linha_anuncio = HBoxContainer.new()
	_linha_anuncio.alignment = BoxContainer.ALIGNMENT_CENTER
	_linha_anuncio.add_theme_constant_override("separation", 14)
	_linha_anuncio.set_anchors_preset(Control.PRESET_FULL_RECT)
	_linha_anuncio.offset_top = 6.0
	_linha_anuncio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(_linha_anuncio)
	return b

## 1058 → "1.058"
static func _milhar(n: int) -> String:
	var s := str(abs(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
