extends "res://TelaFim.gd"
## Janela de compra de pacote no estilo caderno (protótipo de 30/10/2026):
## compra pela aba Pacotes ou oferta quando falta saldo ("Faltam 130 gotas").
## Hub apagado atrás; cartão com o desenho do pacote, o preço da Play Store
## num botão cheio e "Agora não" com contorno. Só o visual: quem compra é o
## Hub (BillingManager), pelos sinais confirmar e cancelar.
## Versões: "A" = card da roleta (caneta + papel); "B" = papel da fase com
## contorno de caneta (como "Partida em andamento").

signal confirmar
signal cancelar

const CARD_IMAGEM := "res://assets/ui/card_roleta.png"
const CARD := Rect2(70, 420, 940, 1110)

var versao := "A"
var _bloco: Control
var _btn_ok: Button
var _btn_nao: Button

func _montar_fixo() -> void:
	_papel.visible = false
	z_index = 100 # por cima do cabeçalho e da barra de abas do Hub
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.1, 0.15, 0.5)
	# Sob um CanvasLayer as âncoras não resolvem: tamanho da tela na mão
	escuro.size = get_viewport_rect().size
	add_child(escuro)
	move_child(escuro, 0)
	_bloco = Control.new()
	_bloco.size = Vector2(1080, 1920)
	_bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(_bloco)

## d: nome, icone, preco, disponivel; falta (0 = compra pela loja), moeda
## ("gotas de tinta"/"clipes"); estado: "" | "abrindo" | mensagem de erro.
func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	for b in [_btn_ok, _btn_nao]:
		if b:
			b.queue_free()
	_cartao()
	var x0 := CARD.position.x
	var y0 := CARD.position.y
	var oferta: bool = int(d.get("falta", 0)) > 0
	if oferta:
		_txt(_bloco, "Faltam %s %s" % [_milhar(int(d["falta"])), d["moeda"]], 58, AZUL_ESCURO, y0 + 60, y0 + 150)
		_traco(_bloco, 250, 830, y0 + 160, Color(AZUL_ESCURO, 0.85), 5.0)
		_txt(_bloco, "Quer o pacote?", 46, AZUL, y0 + 185, y0 + 245)
	else:
		_txt(_bloco, "PACOTE", 66, AZUL_ESCURO, y0 + 70, y0 + 160)
		_traco(_bloco, 360, 720, y0 + 170, Color(AZUL_ESCURO, 0.85), 5.0)
	var ic := TextureRect.new()
	ic.texture = load(d["icone"])
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(390, y0 + 265)
	ic.size = Vector2(300, 300)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloco.add_child(ic)
	_txt(_bloco, d["nome"], 56, AZUL_ESCURO, y0 + 585, y0 + 665)
	var estado: String = d.get("estado", "")
	var nota := "Pagamento pela Google Play."
	var cor_nota := Color(AZUL_ESCURO, 0.7)
	if estado == "abrindo":
		nota = "Abrindo a loja..."
		cor_nota = AZUL
	elif not d["disponivel"]:
		nota = "A loja não respondeu ainda.\nTente de novo em instantes."
	elif estado != "":
		nota = estado
		cor_nota = VERMELHO
	var n := _txt(_bloco, nota, 42, cor_nota, y0 + 670, y0 + 770)
	n.add_theme_constant_override("line_spacing", -6)
	var texto_ok: String = "COMPRAR · %s" % d["preco"] if d["disponivel"] else "COMPRAR"
	_btn_ok = _botao_cheio(texto_ok, Rect2(x0 + 90, y0 + 790, 760, 125))
	_btn_ok.disabled = not d["disponivel"] or estado == "abrindo"
	if _btn_ok.disabled:
		_btn_ok.modulate = Color(1, 1, 1, 0.5)
	_btn_ok.pressed.connect(func(): confirmar.emit())
	_btn_nao = _botao_contorno(Rect2(x0 + 140, y0 + 945, 660, 100))
	var l := Label.new()
	l.text = "Agora não"
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", 46)
	l.add_theme_color_override("font_color", AZUL)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_linha_anuncio.add_child(l)
	_btn_nao.pressed.connect(func(): cancelar.emit())

## Moldura do cartão: card da roleta (A) ou papel da fase com contorno (B).
func _cartao() -> void:
	var c := Control.new()
	c.position = CARD.position
	c.size = CARD.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	_bloco.add_child(c)
	if versao == "A":
		var st := StyleBoxTexture.new()
		st.texture = load(CARD_IMAGEM)
		st.texture_margin_left = 40
		st.texture_margin_top = 40
		st.texture_margin_right = 55
		st.texture_margin_bottom = 55
		c.draw.connect(func(): c.draw_style_box(st, Rect2(Vector2.ZERO, c.size)))
		return
	var recorte := Control.new()
	recorte.clip_contents = true
	recorte.size = c.size
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(recorte)
	var papel := ColorRect.new()
	papel.set_script(preload("res://Paper.gd"))
	papel.desenhar_margem = false
	papel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	papel.position = -CARD.position
	recorte.add_child(papel)
	var borda := Control.new()
	borda.size = c.size
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	borda.draw.connect(func():
		var pts: PackedVector2Array = []
		var w := borda.size.x
		var h := borda.size.y
		var cantos := [Vector2(4, 6), Vector2(w - 6, 3), Vector2(w - 3, h - 5), Vector2(5, h - 3)]
		for i in range(4):
			var a: Vector2 = cantos[i]
			var b: Vector2 = cantos[(i + 1) % 4]
			for k in range(12):
				var t := float(k) / 12.0
				pts.append(a.lerp(b, t) + Vector2(sin(k * 2.1 + i), cos(k * 1.7 + i)) * 1.3)
		pts.append(pts[0])
		borda.draw_polyline(pts, AZUL_ESCURO, 5.0, true)
		var pts2: PackedVector2Array = []
		for p in pts:
			pts2.append(p + Vector2(4, 5))
		borda.draw_polyline(pts2, Color(AZUL, 0.35), 2.5, true))
	c.add_child(borda)
