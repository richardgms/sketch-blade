extends "res://TelaFim.gd"
## Menu de reviver ("Segunda chance?"), no estilo das telas de fim (30/10/2026).
## Aparece 1 vez por partida quando a caneta perde o último coração.
## Sinais da base: anuncio_pressionado = continuar com anúncio;
## voltar_pressionado = desistir (vai para a "Página arruinada").
## Os botões só aceitam toque depois de ~0,8 s (o dedo ainda está na tela
## quando a caneta morre: evita tocar no anúncio sem querer).

## true = versão A (CONTINUAR com anúncio é o botão cheio);
## false = versão B (VER RESULTADO cheio, anúncio com contorno).
var anuncio_principal := true

var _arte: TextureRect
var _coracoes: HBoxContainer
var _frase: Label
var _aviso_anuncio: Label
var _lbl_continuar: Label

func _montar_fixo() -> void:
	_txt(_conteudo, "SEGUNDA CHANCE?", 74, AZUL_ESCURO, 70, 170)
	_traco(_conteudo, 170, 910, 180, Color(AZUL_ESCURO, 0.85), 5.0)

	_arte = TextureRect.new()
	_arte.texture = load("res://assets/ui/caneta_asas.png") # gerada no ChatGPT
	_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arte.position = Vector2(190, 215)
	_arte.size = Vector2(700, 770)
	_arte.pivot_offset = _arte.size / 2.0
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_arte)

	_coracoes = HBoxContainer.new()
	_coracoes.alignment = BoxContainer.ALIGNMENT_CENTER
	_coracoes.add_theme_constant_override("separation", 22)
	_coracoes.position = Vector2(0, 1005)
	_coracoes.size = Vector2(1080, 110)
	_coracoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_coracoes)
	for i in range(3):
		var c := TextureRect.new()
		c.texture = load("res://assets/ui/icone_coracao.png")
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.custom_minimum_size = Vector2(100, 100)
		c.pivot_offset = Vector2(50, 50)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_coracoes.add_child(c)
	# Bloco de texto ancorado perto dos botões (como no hub)
	_txt(_conteudo, "Volte com 3 corações", 50, AZUL_ESCURO, 1125, 1195)
	_frase = _txt(_conteudo, "", 50, AZUL, 1215, 1285)
	_txt(_conteudo, "Só 1 vez por partida.", 42, AZUL_ESCURO, 1295, 1355)
	_aviso_anuncio = _txt(_conteudo, "Assista a um anúncio para continuar.", 42, AZUL_ESCURO, 1480, 1545)

## Monta os botões conforme a versão (chamado em mostrar()).
func _montar_botoes() -> void:
	for b in [_btn_voltar, _btn_anuncio]:
		if b:
			b.queue_free()
	if anuncio_principal:
		# Ícone do anúncio em branco + CONTINUAR, centrados juntos no botão
		_btn_anuncio = _botao_cheio("", BOTAO_VOLTAR)
		var linha := HBoxContainer.new()
		linha.alignment = BoxContainer.ALIGNMENT_CENTER
		linha.add_theme_constant_override("separation", 20)
		linha.set_anchors_preset(Control.PRESET_FULL_RECT)
		linha.offset_top = 4.0
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_btn_anuncio.add_child(linha)
		var ic := TextureRect.new()
		ic.texture = load("res://assets/ads.svg")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(66, 66)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;
void fragment() { COLOR = vec4(1.0, 1.0, 1.0, texture(TEXTURE, UV).a); }"
		var mat := ShaderMaterial.new()
		mat.shader = sh
		ic.material = mat
		linha.add_child(ic)
		_lbl_continuar = Label.new()
		_lbl_continuar.text = "CONTINUAR"
		_lbl_continuar.add_theme_font_override("font", FONTE)
		_lbl_continuar.add_theme_font_size_override("font_size", 60)
		_lbl_continuar.add_theme_color_override("font_color", Color.WHITE)
		_lbl_continuar.add_theme_color_override("font_outline_color", Color(AZUL_ESCURO, 0.6))
		_lbl_continuar.add_theme_constant_override("outline_size", 6)
		_lbl_continuar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_lbl_continuar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_child(_lbl_continuar)
		_btn_voltar = _botao_contorno(BOTAO_ANUNCIO)
		_conteudo_linha([["", "Desistir", VERMELHO]])
		_aviso_anuncio.visible = true
	else:
		_btn_voltar = _botao_cheio("VER RESULTADO", BOTAO_VOLTAR)
		_btn_anuncio = _botao_contorno(BOTAO_ANUNCIO)
		_conteudo_linha([["res://assets/ads.svg", "", AZUL], ["", "Ver anúncio · continuar", AZUL]])
		_aviso_anuncio.visible = false
	_btn_voltar.pressed.connect(func(): voltar_pressionado.emit())
	_btn_anuncio.pressed.connect(func():
		_btn_anuncio.disabled = true
		if anuncio_principal:
			_lbl_continuar.text = "Carregando..."
		else:
			_conteudo_linha([["", "Carregando...", AZUL]])
		anuncio_pressionado.emit())

## Ícones e textos dentro do botão de contorno.
func _conteudo_linha(partes: Array) -> void:
	for f in _linha_anuncio.get_children():
		f.queue_free()
	for p in partes:
		if p[0] != "":
			var ic := TextureRect.new()
			ic.texture = load(p[0])
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(58, 58)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ic.modulate = p[2]
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_linha_anuncio.add_child(ic)
		else:
			var l := Label.new()
			l.text = p[1]
			l.add_theme_font_override("font", FONTE)
			l.add_theme_font_size_override("font_size", 48)
			l.add_theme_color_override("font_color", p[2])
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_linha_anuncio.add_child(l)

## d: cap, pagina, total_paginas
func mostrar(d: Dictionary) -> void:
	_dados = d
	_papel.configurar_para_capitulo(int(d["cap"]))
	_frase.text = "Continue da página %d  de %d" % [int(d["pagina"]), int(d["total_paginas"])]
	_montar_botoes()
	_animando = true
	_pular.mouse_filter = Control.MOUSE_FILTER_STOP
	_travar_botoes(true)
	_arte.modulate.a = 0.0
	_arte.scale = Vector2(0.85, 0.85)
	for c in _coracoes.get_children():
		c.scale = Vector2.ZERO
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_tween.tween_property(_arte, "modulate:a", 1.0, 0.2)
	_tween.tween_property(_arte, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var i := 0
	for c in _coracoes.get_children():
		_tween.tween_property(c, "scale", Vector2.ONE, 0.22).set_delay(0.25 + i * 0.1) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	_tween.chain().tween_interval(0.15)
	_tween.chain().tween_callback(_finalizar_animacao)

func _finalizar_animacao() -> void:
	if not _animando:
		return
	_arte.modulate.a = 1.0
	_arte.scale = Vector2.ONE
	for c in _coracoes.get_children():
		c.scale = Vector2.ONE
	_liberar_botoes()

## O anúncio não carregou: volta a oferecer.
func anuncio_falhou() -> void:
	_btn_anuncio.disabled = false
	if anuncio_principal:
		_lbl_continuar.text = "CONTINUAR"
	else:
		_conteudo_linha([["res://assets/ads.svg", "", AZUL], ["", "Ver anúncio · continuar", AZUL]])
