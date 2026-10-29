extends "res://TelaFim.gd"
## Tela de derrota ("Página arruinada"), irmã da vitória (aprovada em 29/10/2026,
## versão A). Ordem: título vermelho → desenho do capítulo (ou o chefe, se
## morreu nele) → até onde chegou na trilha → recorde → tinta guardada → XP →
## "Nova tentativa começa na página 1." → botões.
## Botões, anúncio e peças desenhadas ficam na base TelaFim.gd.

const ARTE := Rect2(240, 225, 600, 470)
const Y_FRASE := 712.0
const TAM_RECORDE := 52 # textos azuis maiores, pedido para ler no celular
const TAM_REGRA := 50

var _arte: TextureRect
var _frase: Label
var _trilha: Control
var _recorde: Control
var _rotulo_total: Label
var _icone_total: TextureRect
var _total: Label
var _bloco: Control # linhas da tinta + XP (refeito depois do anúncio)

# Estado da trilha (animado)
var _pagina := 1
var _total_paginas := 8
var _melhor := 0
var _progresso := 0.0 # casas já preenchidas (sobe na animação)
var _x_escala := 1.0 # 0 = X ainda não apareceu

func _montar_fixo() -> void:
	_txt(_conteudo, "PÁGINA ARRUINADA!", 74, VERMELHO, 70, 170)
	_traco(_conteudo, 170, 910, 180, Color(VERMELHO, 0.85), 5.0)

	_arte = TextureRect.new()
	_arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arte.position = ARTE.position
	_arte.size = ARTE.size
	_arte.pivot_offset = ARTE.size / 2.0
	_arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_arte)

	_frase = _txt(_conteudo, "", 46, AZUL_ESCURO, Y_FRASE, Y_FRASE + 64)
	_trilha = Control.new()
	_trilha.position = Vector2(100, Y_FRASE + 80)
	_trilha.size = Vector2(880, 100)
	_trilha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trilha.draw.connect(_desenhar_trilha)
	_conteudo.add_child(_trilha)
	_recorde = Control.new()
	_recorde.size = Vector2(1080, 80)
	_recorde.position = Vector2(0, Y_FRASE + 192)
	_recorde.pivot_offset = Vector2(540, 40)
	_recorde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_recorde)

	_rotulo_total = _txt(_conteudo, "Tinta guardada", 46, AZUL_ESCURO, 1015, 1075)
	_icone_total = TextureRect.new()
	_icone_total.texture = load("res://assets/ink.svg")
	_icone_total.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icone_total.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icone_total.size = Vector2(90, 90)
	_icone_total.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_icone_total)
	_total = _txt(_conteudo, "", 120, AZUL, 1065, 1205, NUM, 0, 1080, HORIZONTAL_ALIGNMENT_LEFT)

	_bloco = Control.new()
	_bloco.size = Vector2(1080, 1920)
	_bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_bloco)

	_txt(_conteudo, "Nova tentativa começa na página 1.", TAM_REGRA, AZUL, 1474, 1548)
	_criar_botoes("VOLTAR AO CADERNO")

## d: cap, nome (com artigo, ex. "o Compasso"), arte_chefe, pagina, total_paginas,
## recorde_antes, tinta_partida, bonus_cap, tinta_final, xp_ganho, nivel, xp,
## xp_req, niveis_ganhos, clipes
func mostrar(d: Dictionary) -> void:
	_dados = d
	var cap: int = int(d["cap"])
	_papel.configurar_para_capitulo(cap)
	_total_paginas = int(d["total_paginas"])
	_pagina = clamp(int(d["pagina"]), 1, _total_paginas)
	var antes: int = int(d["recorde_antes"])
	_melhor = max(_pagina, antes)
	var no_chefe: bool = _pagina >= _total_paginas
	# Morreu no chefe: ele aparece colorido (venceu); senão, o desenho do capítulo
	if no_chefe:
		_arte.texture = load(d["arte_chefe"])
		var nome: String = d["nome"]
		_frase.text = nome.substr(0, 1).to_upper() + nome.substr(1) + " venceu desta vez!"
	else:
		_arte.texture = load(_arte_capitulo(cap))
		_frase.text = "Você chegou à página %d  de %d" % [_pagina, _total_paginas]
	# Recorde: marca-texto quando bateu o anterior (na 1ª tentativa não há o que bater)
	for f in _recorde.get_children():
		f.queue_free()
	if antes > 0 and _pagina > antes:
		_marca_texto(_recorde, "Novo recorde!")
	else:
		_txt(_recorde, "Melhor tentativa: página %d  de %d" % [_melhor, _total_paginas],
			TAM_RECORDE, AZUL, 0, 78)
	_montar_valores(false)
	_animar()

static func _arte_capitulo(cap: int) -> String:
	if ResourceLoader.exists("res://assets/images/stage%d.svg" % cap):
		return "res://assets/images/stage%d.svg" % cap
	if ResourceLoader.exists("res://assets/images/stage%d.png" % cap):
		return "res://assets/images/stage%d.png" % cap
	return "res://assets/images/stage1.png"

func _montar_valores(com_anuncio: bool) -> void:
	for f in _bloco.get_children():
		f.queue_free()
	var tf: int = int(_dados["tinta_final"])
	_rotulo_total.text = "Tinta guardada (com anúncio)" if com_anuncio else "Tinta guardada"
	_definir_total(tf * 2 if com_anuncio else tf)
	var linhas: Array = [["Tinta coletada", int(_dados["tinta_partida"])]]
	if int(_dados["bonus_cap"]) > 0:
		linhas.append(["Bônus do capítulo", int(_dados["bonus_cap"])])
	if com_anuncio:
		linhas.append(["Bônus do anúncio", tf])
	var y0 := 1215.0
	for i in linhas.size():
		var y := y0 + i * 52.0
		_txt(_bloco, linhas[i][0], 42, AZUL_ESCURO, y, y + 52, FONTE, 220, 700, HORIZONTAL_ALIGNMENT_LEFT)
		_txt(_bloco, "+" + _milhar(linhas[i][1]), 46, AZUL_ESCURO, y, y + 52, NUM, 700, 860, HORIZONTAL_ALIGNMENT_RIGHT)
	var y_xp := y0 + linhas.size() * 52.0 + 26.0
	_traco(_bloco, 200, 880, y_xp - 10.0, Color(AZUL_ESCURO, 0.45), 2.5)
	var nivel: int = int(_dados["nivel"])
	var frac: float = float(_dados["xp"]) / max(1.0, float(_dados["xp_req"]))
	_barra_xp(_bloco, y_xp, nivel, frac, int(_dados["xp_ganho"]))
	if int(_dados["niveis_ganhos"]) > 0:
		_txt(_bloco, "Novo nível %d!  +%d clipes" % [nivel, int(_dados["clipes"])], 36, VERDE, y_xp + 56.0, y_xp + 96.0)

func _definir_total(valor: int) -> void:
	_total.text = "+%s tinta" % _milhar(valor)
	var tw: float = NUM.get_string_size(_total.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 120).x
	var x0: float = 540.0 - (tw + 104.0) / 2.0
	_icone_total.position = Vector2(x0, 1093)
	_total.position.x = x0 + 104.0
	_total.size.x = tw + 40.0

# ------------------------------------------------------------
# Trilha: casas vencidas cheias, X vermelho onde caiu, azul-claro até o recorde
# ------------------------------------------------------------
func _desenhar_trilha() -> void:
	var c := _trilha
	var y: float = c.size.y / 2.0
	var r_pag := 22.0
	var r_chefe := 42.0
	var x0: float = r_pag + 4.0
	var x_chefe: float = c.size.x - r_chefe - 6.0
	var passo: float = (x_chefe - r_chefe - r_pag - 34.0 - x0) / float(_total_paginas - 2)
	var xs: Array = []
	for i in range(_total_paginas - 1):
		xs.append(x0 + passo * i)
	xs.append(x_chefe)
	for i in range(_total_paginas - 1):
		var rb: float = r_chefe if i == _total_paginas - 2 else r_pag
		c.draw_line(Vector2(xs[i] + r_pag, y), Vector2(xs[i + 1] - rb, y), AZUL_ESCURO, 3.0, true)
	for i in range(_total_paginas):
		var casa: int = i + 1
		var centro := Vector2(xs[i], y)
		var r: float = r_chefe if casa == _total_paginas else r_pag
		var fundo := Color(1, 1, 1, 0.95)
		if casa < _pagina and casa <= _progresso:
			fundo = AZUL
		elif casa > _pagina and casa <= _melhor and _x_escala > 0.0:
			fundo = Color("b9cdee") # recorde ainda à frente
		_disco(c, centro, r, fundo)
		_circulo_caneta(c, centro, r, AZUL_ESCURO, 4.0 if casa == _total_paginas else 3.0, i)
		if casa == _total_paginas and casa != _pagina:
			var w: float = FONTE.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, 56).x
			c.draw_string(FONTE, centro + Vector2(-w / 2.0, 56 * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, AZUL_ESCURO)
		if casa == _pagina and _x_escala > 0.0:
			var k: float = r * 1.05 * _x_escala
			c.draw_line(centro + Vector2(-k, -k), centro + Vector2(k, k * 0.9), VERMELHO, 7.0, true)
			c.draw_line(centro + Vector2(k * 0.95, -k), centro + Vector2(-k, k), VERMELHO, 7.0, true)

func _disco(c: Control, centro: Vector2, raio: float, cor: Color) -> void:
	var pts: PackedVector2Array = []
	for i in range(48):
		var t: float = float(i) / 48.0 * TAU
		pts.append(centro + Vector2(cos(t), sin(t)) * raio)
	c.draw_colored_polygon(pts, cor)

## Círculo de caneta com leve tremor determinístico (semente = casa).
func _circulo_caneta(c: Control, centro: Vector2, raio: float, cor: Color, esp: float, semente: int) -> void:
	var pts: PackedVector2Array = []
	for i in range(49):
		var t: float = float(i) / 48.0 * TAU * 1.06 + semente
		pts.append(centro + Vector2(cos(t), sin(t)) * (raio + sin(i * 2.1 + semente) * 0.8))
	c.draw_polyline(pts, cor, esp, true)

func _set_progresso(v: float) -> void:
	_progresso = v
	_trilha.queue_redraw()

func _set_x(v: float) -> void:
	_x_escala = v
	_trilha.queue_redraw()

# ------------------------------------------------------------
# Animação: desenho entra → trilha se preenche → X bate → recorde →
# tinta conta → botões. Um toque pula para o fim.
# ------------------------------------------------------------
func _animar() -> void:
	_iniciar_animacao()
	_arte.modulate.a = 0.0
	_arte.scale = Vector2(0.9, 0.9)
	_set_progresso(0.0)
	_set_x(0.0)
	_recorde.modulate.a = 0.0
	_recorde.scale = Vector2(0.7, 0.7)
	_definir_total(0)
	var tf: int = int(_dados["tinta_final"])
	var t_trilha: float = 0.07 * float(_pagina - 1)
	var t_x: float = 0.25 + t_trilha

	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_tween.tween_property(_arte, "modulate:a", 1.0, 0.25)
	_tween.tween_property(_arte, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _pagina > 1:
		_tween.tween_method(_set_progresso, 0.0, float(_pagina - 1), t_trilha).set_delay(0.25)
	_tween.tween_method(_set_x, 2.0, 1.0, 0.14).set_delay(t_x) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(_recorde, "modulate:a", 1.0, 0.12).set_delay(t_x + 0.2)
	_tween.tween_property(_recorde, "scale", Vector2.ONE, 0.3).set_delay(t_x + 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_method(func(v: float): _definir_total(int(v)), 0.0, float(tf), 0.6).set_delay(t_x + 0.35) \
		.set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(_finalizar_animacao)

func _finalizar_animacao() -> void:
	if not _animando:
		return
	_arte.modulate.a = 1.0
	_arte.scale = Vector2.ONE
	_set_progresso(float(_pagina))
	_set_x(1.0)
	_recorde.modulate.a = 1.0
	_recorde.scale = Vector2.ONE
	_definir_total(int(_dados["tinta_final"]))
	_liberar_botoes()
