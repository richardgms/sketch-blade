extends "res://TelaFim.gd"
## Tela antes da partida no estilo caderno (aprovada em 31/10, versão C
## "ficha colada"): a folha arrancada das janelas do Hub por cima da página
## da partida, com capítulo, nome, desenho do objeto, trilha das 8 páginas,
## melhor tentativa e COMEÇAR; a caneta fica à vista embaixo com a dica de
## controle. Só o visual: o Main começa a partida pelo sinal comecar.

signal comecar

const FOLHA := "res://assets/ui/fundo_missoes.png"

var _travado := true

## d: cap, nome, arte, recorde (melhor página, 0 = nunca), total.
func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _conteudo.get_children():
		f.queue_free()
	_papel.visible = false
	_ficha_colada(d)
	# Entra subindo um pouco; só aceita toque depois
	_conteudo.modulate.a = 0.0
	var y0: float = _conteudo.position.y
	_conteudo.position.y = y0 + 30.0
	_travado = true
	var t := create_tween().set_parallel()
	t.tween_property(_conteudo, "modulate:a", 1.0, 0.35)
	t.tween_property(_conteudo, "position:y", y0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.chain().tween_interval(0.2)
	t.chain().tween_callback(func(): _travado = false)

# ------------------------------------------------------------
# Ficha colada
# ------------------------------------------------------------
func _ficha_colada(d: Dictionary) -> void:
	_veu(0.7)
	var card := Rect2(50, 230, 980, 1240)
	var folha := NinePatchRect.new()
	folha.texture = load(FOLHA)
	folha.patch_margin_top = 90
	folha.patch_margin_bottom = 240
	folha.patch_margin_left = 60
	folha.patch_margin_right = 60
	folha.position = card.position
	folha.size = card.size
	folha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(folha)
	var y0: float = card.position.y
	_txt(_conteudo, "CAPÍTULO %d" % d["cap"], 52, AZUL, y0 + 90, y0 + 160)
	_txt(_conteudo, d["nome"], 84, AZUL_ESCURO, y0 + 160, y0 + 270)
	_traco(_conteudo, 260, 820, y0 + 285, Color(AZUL_ESCURO, 0.85), 5.0)
	_arte(_conteudo, d["arte"], Rect2(380, y0 + 320, 320, 320))
	_trilha(_conteudo, y0 + 680, int(d.get("recorde", 0)), int(d.get("total", 8)))
	_txt(_conteudo, _frase_recorde(d), 42, AZUL, y0 + 790, y0 + 850)
	var b := _botao_cheio("COMEÇAR", Rect2(180, y0 + 900, 720, 130))
	b.add_theme_font_size_override("font_size", 68)
	b.pressed.connect(_apertar)
	_txt(_conteudo, "Arraste o dedo para mover a caneta.", 42, AZUL_ESCURO, 1730, 1790)
	_txt(_conteudo, "Parada, ela atira sozinha.", 42, AZUL_ESCURO, 1790, 1850)

## Véu de papel por cima do combate; mais fraco embaixo para a caneta aparecer.
func _veu(alfa: float) -> void:
	var veu := Control.new()
	veu.size = Vector2(1080, 1920)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veu.draw.connect(func():
		var cor := Color(0.98, 0.965, 0.933)
		veu.draw_rect(Rect2(0, -600, 1080, 2000), Color(cor, alfa))
		for i in range(20):
			var f := float(i) / 20.0
			veu.draw_rect(Rect2(0, 1400 + i * 4, 1080, 4), Color(cor, lerp(alfa, 0.2, f)))
		veu.draw_rect(Rect2(0, 1480, 1080, 1040), Color(cor, 0.2)))
	_conteudo.add_child(veu)

func _apertar() -> void:
	if _travado:
		return
	_travado = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.18)
	t.tween_callback(func(): comecar.emit())

# ------------------------------------------------------------
# Peças
# ------------------------------------------------------------
func _frase_recorde(d: Dictionary) -> String:
	var rec := int(d.get("recorde", 0))
	var total := int(d.get("total", 8))
	if rec <= 0:
		return "%d páginas · o chefe espera na última." % total
	if rec >= total:
		return "Melhor tentativa: chegou ao chefe!"
	return "Melhor tentativa: página %d de %d" % [rec, total]

func _arte(pai: Control, caminho: String, r: Rect2) -> void:
	if not ResourceLoader.exists(caminho):
		return
	var a := TextureRect.new()
	a.texture = load(caminho)
	a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	a.position = r.position
	a.size = r.size
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(a)

## Trilha das páginas: as já alcançadas em azul, a 1 com anel verde.
func _trilha(pai: Control, y: float, recorde: int, total: int) -> void:
	var t: Control = preload("res://TrilhaPaginas.gd").new()
	t.total = total
	t.cheias = recorde
	t.atual = 0
	t.position = Vector2(0, y)
	pai.add_child(t)
