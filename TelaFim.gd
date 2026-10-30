extends Control
## Base das telas de fim de partida (TelaVitoria e TelaDerrota): papel da fase
## cobrindo o combate, botão cheio riscado + botão de anúncio com contorno,
## toque para pular a animação e botões travados até ela terminar.
## O Main só chama mostrar(), bonus_recebido(), anuncio_falhou() e
## voltar_do_sistema(); a lógica do anúncio e da economia fica no Main.

signal voltar_pressionado
signal anuncio_pressionado

const FONTE := preload("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
const NUM := preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")
const AZUL := Color("0047ab")
const AZUL_ESCURO := Color("002867")
const VERDE := Color("2e7d32")
const VERDE_OK := Color("2e9e44")
const VERMELHO := Color("c62828")
const BOTAO_RISCADO := "res://assets/ui/botao_riscado.png"

# Layout pensado em 1080x1920; em telas mais altas o conteúdo fica centrado.
const BOTAO_VOLTAR := Rect2(130, 1580, 820, 125)
const BOTAO_ANUNCIO := Rect2(150, 1740, 780, 100)

var _papel: ColorRect
var _conteudo: Control
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

# --- Ganchos de cada tela ---------------------------------------
func _montar_fixo() -> void:
	pass

func _montar_valores(_com_anuncio: bool) -> void:
	pass

func _finalizar_animacao() -> void:
	pass

# ------------------------------------------------------------
# Botões e animação
# ------------------------------------------------------------
func _criar_botoes(texto_voltar: String) -> void:
	_btn_voltar = _botao_cheio(texto_voltar, BOTAO_VOLTAR)
	_btn_voltar.pressed.connect(func(): voltar_pressionado.emit())
	_btn_anuncio = _botao_contorno(BOTAO_ANUNCIO)
	_btn_anuncio.pressed.connect(func():
		if _bonus_recebido:
			return
		_btn_anuncio.disabled = true
		_conteudo_anuncio("carregando")
		anuncio_pressionado.emit())

## Prepara o anúncio e trava os botões no começo da animação.
func _iniciar_animacao() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_bonus_recebido = false
	_btn_anuncio.visible = int(_dados.get("tinta_final", 0)) > 0
	_btn_anuncio.disabled = false
	_conteudo_anuncio("oferta")
	_animando = true
	_pular.mouse_filter = Control.MOUSE_FILTER_STOP
	_travar_botoes(true)

## Fim da animação: botões aparecem já, mas só aceitam toque depois de 0,5 s
## (sem toque sem querer no anúncio).
func _liberar_botoes() -> void:
	_animando = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_pular.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

## Linha "Nv. 6 [barra] +110 XP" centrada na página como um bloco só.
func _barra_xp(pai: Control, y: float, nivel: int, frac: float, xp_ganho: int) -> void:
	var t_nivel := "Nv. %d" % nivel
	var t_xp := "+%d XP" % xp_ganho
	var w_nivel: float = NUM.get_string_size(t_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x
	var w_xp: float = NUM.get_string_size(t_xp, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
	var vao := 18.0
	var larg := 400.0
	var x0: float = 540.0 - (w_nivel + vao + larg + vao + w_xp) / 2.0
	var barra := Control.new()
	barra.position = Vector2(0, y)
	barra.size = Vector2(1080, 60)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.draw.connect(func():
		var r := Rect2(x0 + w_nivel + vao, 14, larg, 30)
		barra.draw_rect(r, Color.WHITE)
		barra.draw_rect(Rect2(r.position, Vector2(r.size.x * clamp(frac, 0.0, 1.0), r.size.y)), AZUL)
		barra.draw_rect(r, AZUL_ESCURO, false, 3.0)
		barra.draw_string(NUM, Vector2(x0, 43), t_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, AZUL_ESCURO)
		barra.draw_string(NUM, Vector2(r.end.x + vao, 43), t_xp, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, AZUL_ESCURO))
	pai.add_child(barra)

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
	# Apagado (ex.: "Abrindo a loja..."): o mesmo riscado, esmaecido por modulate
	b.add_theme_stylebox_override("disabled", st)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)
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
