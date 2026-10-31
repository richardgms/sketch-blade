extends "res://TelaEstojo.gd"
## Missões de hoje no estilo caderno (aprovadas em 31/10/2026): folha
## arrancada do caderno sobre o Hub escurecido, lista de tarefas com caixinha
## de marcar, barra igual à de XP do Hub e o prêmio à direita.
## Só o visual: o Hub sorteia, mede o progresso e paga a recompensa pelo
## sinal coletar(indice); fechar some com a janela.

signal coletar(indice: int)
signal fechar

const CLIPE_BRANCO := "res://assets/ui/clipe_branco.png"
const GOTA_BRANCA := "res://assets/ui/gota_branca.png"
const FOLHA := "res://assets/ui/fundo_missoes.png"
# Peças do ChatGPT (originais em Documentos\Sketch Blade - design\missoes-nova\gerados\)
const BTN_COLETAR := "res://assets/ui/missao_coletar.png"
const BTN_RECEBIDO := "res://assets/ui/missao_recebido.png"
const BTN_PREMIO := "res://assets/ui/missao_premio.png"
const BTN_FECHAR := "res://assets/ui/missao_fechar.png"
const CAIXA_VAZIA := "res://assets/ui/caixa_vazia.png"
const CAIXA_MARCADA := "res://assets/ui/caixa_marcada.png"
# Barra igual à de XP do Hub: moldura do level-and-progressbar.svg (só a
# parte da barra) + rabisco do texture_progress.svg pintado de azul
const MOLDURA_XP := "res://assets/level-and-progressbar.svg"
const MOLDURA_XP_RECORTE := Rect2(215, 87, 385, 71)
const RABISCO_XP := "res://assets/texture_progress.svg"

var _escuro: ColorRect
var _btn_fechar: Button

func _montar_fixo() -> void:
	super._montar_fixo()
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100 # por cima do cabeçalho e da barra de abas do Hub
	_escuro = ColorRect.new()
	_escuro.color = Color(0.1, 0.1, 0.15, 0.5)
	# Sob um CanvasLayer as âncoras não resolvem: tamanho da tela na mão
	_escuro.size = get_viewport_rect().size
	add_child(_escuro)
	move_child(_escuro, 0)

## Progresso de cada missão a partir do save (mesma conta do Hub).
static func montar_dados(save: Dictionary) -> Dictionary:
	var lista: Array = []
	for m in save["missoes_dia"]:
		var def: Dictionary = GameData.get_missao(m["id"])
		if def.is_empty():
			continue
		var atual := int(save["stats"].get(def["stat"], 0))
		var prog: int = clamp(atual - int(m["base"]), 0, def["alvo"])
		lista.append({"desc": def["desc"], "alvo": int(def["alvo"]), "progresso": prog,
			"completa": prog >= int(def["alvo"]), "coletada": bool(m["coletada"]),
			"tinta": int(def["tinta"]), "clipes": int(def["clipes"])})
	return {"missoes": lista}

## d: missoes (de montar_dados); "coletada": índice que acabou de ser pago;
## nova: true quando acabou de abrir (trava os botões um instante).
func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	if _btn_fechar:
		_btn_fechar.queue_free()
	_btns.clear()
	_fichas_atuais.clear()
	_janela(d["missoes"])
	var pago: int = d.get("coletada", -1)
	if pago >= 0 and pago < _fichas_atuais.size():
		_animar_compra(_fichas_atuais[pago])
	_btn_fechar.pressed.connect(func(): fechar.emit())
	if d.get("nova", false):
		var todos: Array = _btns + [_btn_fechar]
		for b in todos:
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t := create_tween()
		t.tween_interval(0.4)
		t.tween_callback(func():
			for b in todos:
				if is_instance_valid(b):
					b.mouse_filter = Control.MOUSE_FILTER_STOP)

# ------------------------------------------------------------
# Janela
# ------------------------------------------------------------
func _janela(missoes: Array) -> void:
	# Folha arrancada do caderno (ChatGPT): picotes em cima, pingo de tinta
	# embaixo à esquerda e ponta dobrada embaixo à direita
	var card := Rect2(50, 330, 980, 1288)
	var c := Control.new()
	c.position = card.position
	c.size = card.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	_bloco.add_child(c)
	var folha := TextureRect.new()
	folha.texture = load(FOLHA)
	folha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	folha.size = card.size
	folha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(folha)
	_txt(c, "MISSÕES DE HOJE", 66, AZUL_ESCURO, 86, 176, FONTE, 0, card.size.x)
	_traco(c, 230, 750, 188, Color(AZUL_ESCURO, 0.85), 5.0)
	_txt(c, "Novas missões amanhã.", 42, AZUL, 206, 266, FONTE, 0, card.size.x)
	var y := 296.0
	var alt := 250.0
	for i in range(missoes.size()):
		var m: Dictionary = missoes[i]
		var linha := Control.new()
		linha.position = Vector2(0, y)
		linha.size = Vector2(card.size.x, alt)
		linha.pivot_offset = linha.size / 2.0
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(linha)
		_fichas_atuais.append(linha)
		if i > 0:
			_tracejado(linha, 70, card.size.x - 85, 0)
		_caixinha(linha, Vector2(70, alt / 2.0 - 34), m)
		_texto_missao(linha, m, Rect2(170, 0, 466, alt))
		_acao(linha, m, i, Rect2(648, alt / 2.0 - 70, 270, 140))
		y += alt
	_btn_fechar = _botao_fechar("Fechar", Rect2(card.position.x + 190, card.end.y - 196, 600, 100))

# ------------------------------------------------------------
# Peças
# ------------------------------------------------------------
## Descrição (números em Caveat) + barra de progresso; recebida fica riscada.
func _texto_missao(pai: Control, m: Dictionary, r: Rect2) -> void:
	var tam := 44
	var linhas: Array = _quebrar(m["desc"], tam, r.size.x)
	var alt_txt: float = linhas.size() * 62.0
	var com_barra: bool = not m["coletada"]
	var bloco: float = alt_txt + (80.0 if com_barra else 0.0)
	var y0: float = r.position.y + (r.size.y - bloco) / 2.0
	var cor: Color = Color(AZUL_ESCURO, 0.45) if m["coletada"] else AZUL_ESCURO
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_OFF
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_override("normal_font", FONTE)
	rt.add_theme_font_size_override("normal_font_size", tam)
	rt.add_theme_color_override("default_color", cor)
	rt.add_theme_constant_override("line_separation", -6)
	rt.position = Vector2(r.position.x, y0 - 4)
	rt.size = Vector2(r.size.x + 40, alt_txt + 20)
	var partes: Array = []
	for l in linhas:
		partes.append(_numeros_caveat(l[0], tam))
	rt.text = "\n".join(partes)
	pai.add_child(rt)
	if m["coletada"]:
		# Riscada à caneta, como tarefa feita no caderno
		for k in range(linhas.size()):
			_risco(pai, r.position.x - 6, r.position.x + float(linhas[k][1]) + 6, y0 + 34.0 + k * 62.0)
		return
	_barra(pai, Rect2(r.position.x, y0 + alt_txt + 18, r.size.x - 150, 54), m)
	var cont := "%d / %d" % [m["progresso"], m["alvo"]]
	_txt(pai, cont, 46, AZUL if m["completa"] else Color(AZUL_ESCURO, 0.7), y0 + alt_txt + 12, y0 + alt_txt + 78,
		NUM, r.end.x - 136, r.end.x, HORIZONTAL_ALIGNMENT_LEFT)

## Quebra a frase em linhas que cabem em larg (números medidos na Caveat):
## [[texto, largura], ...], para o risco da tarefa feita seguir cada linha.
func _quebrar(texto: String, tam: int, larg: float) -> Array:
	var linhas: Array = []
	var atual := ""
	for p in texto.split(" "):
		var teste: String = p if atual == "" else atual + " " + p
		if atual != "" and _largura(teste, tam) > larg:
			linhas.append([atual, _largura(atual, tam)])
			atual = p
		else:
			atual = teste
	linhas.append([atual, _largura(atual, tam)])
	return linhas

func _largura(t: String, tam: int) -> float:
	var w := 0.0
	for p in t.split(" "):
		w += (NUM.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, tam + 8).x if p.is_valid_int()
			else FONTE.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x)
	return w + (t.split(" ").size() - 1) * FONTE.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x

func _numeros_caveat(t: String, tam: int) -> String:
	var re := RegEx.new()
	re.compile("\\d+")
	var s := ""
	var pos := 0
	for achado in re.search_all(t):
		s += t.substr(pos, achado.get_start() - pos)
		s += "[font=%s][font_size=%d]%s[/font_size][/font]" % [NUM.resource_path, tam + 8, achado.get_string()]
		pos = achado.get_end()
	return s + t.substr(pos)

## Barra de progresso igual à de XP do Hub (moldura desenhada + rabisco azul).
func _barra(pai: Control, r: Rect2, m: Dictionary) -> void:
	var moldura := NinePatchRect.new()
	moldura.texture = load(MOLDURA_XP)
	moldura.region_rect = MOLDURA_XP_RECORTE
	moldura.patch_margin_left = 20
	moldura.patch_margin_right = 20
	moldura.patch_margin_top = 20
	moldura.patch_margin_bottom = 20
	moldura.position = r.position
	moldura.size = r.size
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(moldura)
	# Mesmo recuo da barra do Hub dentro da moldura (~5% dos lados, ~21% em cima/embaixo)
	var barra := TextureProgressBar.new()
	barra.texture_progress = load(RABISCO_XP)
	barra.tint_progress = AZUL
	barra.nine_patch_stretch = true
	barra.max_value = m["alvo"]
	barra.value = m["progresso"]
	var dx: float = r.size.x * 0.045
	var dy: float = r.size.y * 0.21
	barra.position = r.position + Vector2(dx, dy)
	barra.size = r.size - Vector2(dx * 2.0, dy * 2.0)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(barra)

## Caixinha de marcar desenhada (ChatGPT): vazia em andamento, ✓ quando
## pronta ou recebida. A imagem tem folga em cima e à direita para o risco
## do ✓ que passa da caixa (caixa = 1/1,35 da imagem, no canto de baixo).
func _caixinha(pai: Control, pos: Vector2, m: Dictionary, lado := 68.0) -> void:
	var cx := TextureRect.new()
	cx.texture = load(CAIXA_MARCADA if m["completa"] or m["coletada"] else CAIXA_VAZIA)
	cx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var tam: float = lado * 1.35
	cx.position = Vector2(pos.x, pos.y + lado - tam)
	cx.size = Vector2(tam, tam)
	cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(cx)

## Fundo desenhado esticado em 9 partes; margem de conteúdo pequena para o
## texto não alargar o botão.
func _estilo_peca(caminho: String, mx: float, my: float) -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = load(caminho)
	st.texture_margin_left = mx
	st.texture_margin_right = mx
	st.texture_margin_top = my
	st.texture_margin_bottom = my
	for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_content_margin(lado, 6.0)
	return st

func _botao_peca(pai: Control, caminho: String, mx: float, my: float, r: Rect2) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var st := _estilo_peca(caminho, mx, my)
	var st_p: StyleBoxTexture = st.duplicate()
	st_p.modulate_color = Color(0.85, 0.85, 0.9)
	for e in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(e, st)
	b.add_theme_stylebox_override("pressed", st_p)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.position = r.position
	b.size = r.size
	pai.add_child(b)
	return b

func _botao_fechar(texto: String, r: Rect2) -> Button:
	var b := _botao_peca(_conteudo, BTN_FECHAR, 60, 50, r)
	b.text = texto
	b.add_theme_font_override("font", FONTE)
	b.add_theme_font_size_override("font_size", 48)
	for e in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(e, AZUL)
	return b

## Peça da direita: COLETAR azul (pronta), RECEBIDO ✓ verde (sem toque) ou
## o prêmio que vem num rótulo tracejado (em andamento, sem toque).
func _acao(pai: Control, m: Dictionary, i: int, r: Rect2) -> void:
	var clipes: bool = m["clipes"] > 0
	var valor: int = m["clipes"] if clipes else m["tinta"]
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", -8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 2.0
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var premio := HBoxContainer.new()
	premio.alignment = BoxContainer.ALIGNMENT_CENTER
	premio.add_theme_constant_override("separation", 8)
	premio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if m["coletada"]:
		var selo := Panel.new()
		selo.add_theme_stylebox_override("panel", _estilo_peca(BTN_RECEBIDO, 50, 50))
		selo.position = r.position
		selo.size = r.size
		selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pai.add_child(selo)
		selo.add_child(col)
		var t1 := _lbl("RECEBIDO", FONTE, 40, Color.WHITE)
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t1)
		var t2 := _lbl("✓", FONTE, 48, Color.WHITE)
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t2)
		return
	if m["completa"]:
		var b := _botao_peca(pai, BTN_COLETAR, 44, 40, r)
		b.add_child(col)
		var l := _lbl("COLETAR", FONTE, 42, Color.WHITE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		premio.add_child(_icone(CLIPE_BRANCO if clipes else GOTA_BRANCA, 48))
		premio.add_child(_lbl("+" + _milhar(valor), NUM, 54, Color.WHITE))
		col.add_child(premio)
		b.pressed.connect(func(): coletar.emit(i))
		_btns.append(b)
		return
	# Em andamento: só mostra o prêmio
	var rotulo := Panel.new()
	rotulo.add_theme_stylebox_override("panel", _estilo_peca(BTN_PREMIO, 56, 56))
	rotulo.position = r.position
	rotulo.size = r.size
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(rotulo)
	rotulo.add_child(col)
	var p := _lbl("prêmio", FONTE, 40, Color(AZUL_ESCURO, 0.7))
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(p)
	premio.add_child(_icone("res://assets/clip.svg" if clipes else "res://assets/ink.svg", 52))
	premio.add_child(_lbl("+" + _milhar(valor), NUM, 60, AZUL))
	col.add_child(premio)

## Linha tracejada clarinha entre as tarefas.
func _tracejado(pai: Control, x0: float, x1: float, y: float) -> void:
	var t := Control.new()
	t.size = pai.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.draw.connect(func():
		var x := x0
		while x < x1:
			t.draw_line(Vector2(x, y), Vector2(min(x + 18.0, x1), y + sin(x) * 0.8), Color(AZUL_ESCURO, 0.25), 3.0, true)
			x += 30.0)
	pai.add_child(t)

## Risco de caneta por cima do texto (tarefa feita).
func _risco(pai: Control, x0: float, x1: float, y: float) -> void:
	var t := Control.new()
	t.size = pai.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.draw.connect(func():
		var pts: PackedVector2Array = []
		for i in range(13):
			pts.append(Vector2(lerp(x0, x1, i / 12.0), y + sin(i * 1.3) * 2.0 - i * 0.4))
		t.draw_polyline(pts, Color(VERDE, 0.85), 5.0, true))
	pai.add_child(t)
