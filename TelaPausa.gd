extends "res://TelaFim.gd"
## Pausa da partida no estilo caderno (versão C + D, 30/10/2026): cabeçalho
## curto (capítulo, página, vida, tinta), as melhorias em cartas grandes com
## nível em bolinhas, som e vibração como ícones nos cantos do título, e
## CONTINUAR + Abandonar (com confirmação; antes saía na hora, sem perguntar).
## Sinais: continuar, abandonar (depois da confirmação) e
## ajuste_alterado(chave, ligado) para "som_ativo"/"vibracao_ativa".

signal continuar
signal abandonar
signal ajuste_alterado(chave: String, ligado: bool)

const CORACAO := "res://assets/ui/icone_coracao.png"
const NOMES_CAPITULOS := ["", "Folha de Rascunho", "Aviãozinho", "Borrão de Tinta",
	"Caderno Quadriculado", "Compasso", "Mapa do Tesouro", "Dobradura", "Página Perdida",
	"Pena de Tinta", "O Estojo Final"]

var _bloco: Control
var _btns: Array = []
var _confirma: Control
var _pagina := 1

func _montar_fixo() -> void:
	_bloco = Control.new()
	_bloco.size = Vector2(1080, 1920)
	_bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_bloco)

## d: cap, pagina, total_paginas, vidas, vidas_max, tinta_partida,
##    melhorias ([{icone, nome, nivel, efeito}])
func mostrar(d: Dictionary) -> void:
	_dados = d
	_papel.configurar_para_capitulo(int(d["cap"]))
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	for b in _btns:
		b.queue_free()
	_btns.clear()
	if _confirma:
		_confirma.queue_free()
		_confirma = null
	_pagina = int(d["pagina"])

	_bloco.position = Vector2.ZERO
	_corpo(d)

	# Botões
	var b_cont := _botao_cheio("CONTINUAR", BOTAO_VOLTAR)
	b_cont.pressed.connect(func(): continuar.emit())
	_btns.append(b_cont)
	var b_ab := _botao_linha(BOTAO_ANUNCIO, "Abandonar partida", VERMELHO)
	b_ab.pressed.connect(_pedir_confirmacao)
	_btns.append(b_ab)
	# Toque só depois de 0,4 s (quem pausou pelo botão do celular não sai sem querer)
	for b in _btns:
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(0.4)
	t.tween_callback(func():
		for b in _btns:
			if is_instance_valid(b):
				b.mouse_filter = Control.MOUSE_FILTER_STOP)

## Botão de contorno (fundo branco) com um texto colorido centrado.
func _botao_linha(rect: Rect2, texto: String, cor: Color) -> Button:
	var b := _botao_contorno(rect)
	for f in _linha_anuncio.get_children():
		f.queue_free()
	_linha_anuncio.add_child(_lbl(texto, FONTE, 48, cor))
	return b

# ------------------------------------------------------------
# Confirmação de abandono (mesmo texto da "Partida em andamento" do hub)
# ------------------------------------------------------------
func _pedir_confirmacao() -> void:
	if _confirma:
		return
	_confirma = Control.new()
	_confirma.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirma.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_confirma)
	var veu := ColorRect.new()
	veu.color = Color(0.1, 0.1, 0.15, 0.45)
	veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirma.add_child(veu)
	var cartao := Control.new()
	cartao.position = Vector2(90, 620 + _conteudo.position.y)
	cartao.size = Vector2(900, 620)
	cartao.draw.connect(func():
		var st := StyleBoxFlat.new()
		st.bg_color = Color.WHITE
		st.set_corner_radius_all(28)
		st.border_color = Color(AZUL_ESCURO, 0.9)
		st.set_border_width_all(4)
		cartao.draw_style_box(st, Rect2(Vector2.ZERO, cartao.size)))
	_confirma.add_child(cartao)
	_txt(cartao, "Abandonar a partida?", 58, VERMELHO, 50, 130, FONTE, 0, cartao.size.x)
	var aviso := _txt(cartao, "Ao abandonar, você perde os ganhos desta partida.", 44, AZUL_ESCURO, 150, 280,
		FONTE, 60, 840)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD
	var voltar := _botao_cheio("VOLTAR", Rect2(0, 0, 720, 120))
	voltar.reparent(cartao, false)
	voltar.position = Vector2(90, 310)
	voltar.pressed.connect(fechar_confirmacao)
	var sim := _botao_linha(Rect2(0, 0, 720, 100), "SIM, ABANDONAR", VERMELHO)
	sim.reparent(cartao, false)
	sim.position = Vector2(90, 470)
	sim.pressed.connect(func(): abandonar.emit())

func fechar_confirmacao() -> void:
	if _confirma:
		_confirma.queue_free()
		_confirma = null

## Voltar do celular: fecha a confirmação; sem ela, continua a partida.
func voltar_do_sistema() -> bool:
	if _confirma:
		fechar_confirmacao()
		return true
	return false

# ------------------------------------------------------------
# Peças
# ------------------------------------------------------------
func _lbl(t: String, f: Font, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _icone(caminho: String, lado: float) -> TextureRect:
	var ic := TextureRect.new()
	ic.texture = load(caminho)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.custom_minimum_size = Vector2(lado, lado)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ic


## Cabeçalho curto (C e D): título, capítulo e uma linha com página, vida e tinta.
func _cabecalho_curto(d: Dictionary, y: float) -> void:
	_txt(_bloco, "PAUSA", 74, AZUL_ESCURO, y, y + 100)
	_traco(_bloco, 380, 700, y + 112, Color(AZUL_ESCURO, 0.85), 5.0)
	var cap := int(d["cap"])
	_txt(_bloco, "Capítulo %d · %s" % [cap, NOMES_CAPITULOS[cap]], 46, AZUL_ESCURO, y + 140, y + 205)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 12)
	linha.position = Vector2(0, y + 215)
	linha.size = Vector2(1080, 80)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(_lbl("Página %d de %d" % [_pagina, int(d["total_paginas"])], NUM, 52, AZUL))
	linha.add_child(_lbl("  ·  ", FONTE, 44, AZUL_ESCURO))
	linha.add_child(_icone(CORACAO, 54))
	linha.add_child(_lbl("%d/%d" % [int(d["vidas"]), int(d["vidas_max"])], NUM, 52, AZUL_ESCURO))
	linha.add_child(_lbl("  ·  ", FONTE, 44, AZUL_ESCURO))
	linha.add_child(_icone("res://assets/ink.svg", 50))
	linha.add_child(_lbl(_milhar(int(d["tinta_partida"])), NUM, 52, AZUL))
	_bloco.add_child(linha)

## As melhorias no centro da tela, em cartas grandes (2 por linha) com
## bolinhas de nível; som e vibração como ícones redondos nos cantos do
## título, longe do CONTINUAR (sem desligar o som sem querer).
func _corpo(d: Dictionary) -> void:
	_cabecalho_curto(d, 120)
	var topo_livre := 430.0
	_ajuste_icone(Vector2(60, 105), "res://assets/volume.svg", "som_ativo", bool(d.get("som", true)))
	_ajuste_icone(Vector2(900, 105), "res://assets/vibrate.svg", "vibracao_ativa", bool(d.get("vibracao", true)))
	var mel: Array = d.get("melhorias", [])
	# Seção "Suas melhorias" centrada entre o que vem em cima e os botões
	var n_cartas: int = max(mel.size(), 2)
	var linhas: int = (n_cartas + 1) / 2
	var alt_secao: float = 65.0 + 25.0 + linhas * 450.0 + (linhas - 1) * 30.0 + (85.0 if mel.is_empty() else 0.0)
	var y_secao: float = topo_livre + (BOTAO_VOLTAR.position.y - 30.0 - topo_livre - alt_secao) / 2.0
	_txt(_bloco, "Suas melhorias", 50, AZUL_ESCURO, y_secao, y_secao + 65)
	var y_cartas: float = y_secao + 90.0
	if mel.is_empty():
		var y_aviso: float = y_cartas + linhas * 450.0 + 20.0
		_txt(_bloco, "A roleta abre nas páginas 2, 4 e 6.", 44, AZUL, y_aviso, y_aviso + 65)
	var estilo := StyleBoxTexture.new()
	estilo.texture = load("res://assets/ui/card_roleta.png")
	estilo.texture_margin_left = 40
	estilo.texture_margin_top = 40
	estilo.texture_margin_right = 55
	estilo.texture_margin_bottom = 55
	var n: int = max(mel.size(), 2) # sem melhoria: mostra 2 espaços vazios
	var larg := 450.0
	var alt := 450.0
	for k in range(n):
		var col := k % 2
		var lin := k / 2
		var na_linha: int = min(2, n - lin * 2)
		var x0: float = (1080.0 - (na_linha * larg + (na_linha - 1) * 40.0)) / 2.0 + col * (larg + 40.0)
		var carta := Control.new()
		carta.position = Vector2(x0, y_cartas + lin * (alt + 30))
		carta.size = Vector2(larg, alt)
		carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bloco.add_child(carta)
		if k >= mel.size():
			# Espaço vazio tracejado: ainda dá para ganhar mais melhorias
			carta.draw.connect(func():
				var r := Rect2(10, 10, larg - 20, alt - 20)
				var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
				for q in range(4):
					carta.draw_dashed_line(pts[q], pts[q + 1], Color(AZUL_ESCURO, 0.45), 4.0, 18.0))
			_txt(carta, "?", 110, Color(AZUL_ESCURO, 0.4), 140, 300, FONTE, 0, larg)
			continue
		var m: Dictionary = mel[k]
		carta.draw.connect(func(): carta.draw_style_box(estilo, Rect2(Vector2.ZERO, carta.size)))
		var ic := _icone(m["icone"], 150)
		ic.position = Vector2((larg - 150) / 2.0, 24)
		ic.size = Vector2(150, 150)
		carta.add_child(ic)
		var nome := _txt(carta, String(m["nome"]).replace("\n", " "), 42, AZUL_ESCURO, 200, 300, FONTE, 24, larg - 24)
		nome.autowrap_mode = TextServer.AUTOWRAP_WORD
		nome.add_theme_constant_override("line_spacing", -8)
		# Depois da quebra de linha: o rótulo volta à largura da carta
		nome.position = Vector2(24, 178)
		nome.size = Vector2(larg - 48, 100)
		var nv := int(m["nivel"])
		var bolinhas := Control.new()
		bolinhas.position = Vector2(0, 284)
		bolinhas.size = Vector2(larg, 40)
		bolinhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bolinhas.draw.connect(func():
			for q in range(3):
				var c := Vector2(larg / 2.0 + (q - 1) * 44.0, 20)
				if q < nv:
					bolinhas.draw_circle(c, 14, AZUL)
				bolinhas.draw_arc(c, 14, 0, TAU, 32, AZUL_ESCURO, 3.0, true))
		carta.add_child(bolinhas)
		# Efeito em até 2 linhas, dentro da carta
		var ef := _txt(carta, String(m["efeito"]).replace("\n", " "), 46, AZUL, 326, 420, NUM, 20, larg - 20)
		ef.autowrap_mode = TextServer.AUTOWRAP_WORD
		ef.add_theme_constant_override("line_spacing", -12)
		ef.position = Vector2(20, 326)
		ef.size = Vector2(larg - 40, 94)



## Ícone redondo de liga/desliga: ✓ azul ligado, X vermelho desligado.
## Tocar troca na hora e avisa o Main (que grava no save).
func _ajuste_icone(pos: Vector2, icone: String, chave: String, ligado_inicial: bool) -> void:
	var estado := {"ligado": ligado_inicial}
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for e in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	b.position = pos
	b.size = Vector2(120, 120)
	b.draw.connect(func():
		var c := Vector2(60, 60)
		b.draw_circle(c, 54, Color.WHITE)
		b.draw_arc(c, 54, 0, TAU, 48, Color(AZUL_ESCURO, 0.9), 4.0, true)
		var m := Vector2(96, 96)
		var ligado: bool = estado["ligado"]
		b.draw_circle(m, 22, AZUL if ligado else VERMELHO)
		if ligado:
			b.draw_polyline(PackedVector2Array([m + Vector2(-10, 0), m + Vector2(-3, 8), m + Vector2(11, -8)]), Color.WHITE, 5.0, true)
		else:
			b.draw_line(m + Vector2(-8, -8), m + Vector2(8, 8), Color.WHITE, 5.0, true)
			b.draw_line(m + Vector2(8, -8), m + Vector2(-8, 8), Color.WHITE, 5.0, true))
	_bloco.add_child(b)
	var ic := _icone(icone, 66)
	ic.position = Vector2(27, 27)
	ic.size = Vector2(66, 66)
	ic.modulate = AZUL_ESCURO if ligado_inicial else Color(AZUL_ESCURO, 0.35)
	b.add_child(ic)
	b.pressed.connect(func():
		estado["ligado"] = not estado["ligado"]
		ic.modulate = AZUL_ESCURO if estado["ligado"] else Color(AZUL_ESCURO, 0.35)
		b.queue_redraw()
		ajuste_alterado.emit(chave, estado["ligado"]))
	_btns.append(b)
