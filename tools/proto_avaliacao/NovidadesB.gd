extends "res://JanelaAtualizacao.gd"
## Opção B das novidades: bilhete preso no topo do Hub, sem escurecer.
func _folha_nova(d: Dictionary) -> void:
	_escuro.visible = false
	var r := Rect2(70, 250, 940, 420)
	var c := Control.new()
	c.position = r.position
	c.size = r.size
	c.pivot_offset = r.size / 2.0
	c.rotation_degrees = -1.5
	_bloco.add_child(c)
	var folha := NinePatchRect.new()
	folha.texture = load("res://assets/ui/card_roleta.png")
	folha.patch_margin_left = 40
	folha.patch_margin_right = 40
	folha.patch_margin_top = 55
	folha.patch_margin_bottom = 55
	folha.size = r.size
	c.add_child(folha)
	# Fita adesiva no topo
	var fita := ColorRect.new()
	fita.color = Color(0.95, 0.88, 0.55, 0.75)
	fita.size = Vector2(200, 54)
	fita.position = Vector2(r.size.x / 2.0 - 100, -26)
	fita.rotation_degrees = 3
	c.add_child(fita)
	_txt(c, "Novo na versão %s" % d["versao"], 54, AZUL_ESCURO, 50, 130, FONTE, 0, r.size.x)
	_traco(c, 220, 720, 134, Color(AZUL_ESCURO, 0.7), 4.0)
	var y := 160.0
	for n in d["novidades"].slice(0, 3):
		_ponto(c, Vector2(80, y + 30))
		_txt(c, n, 34, AZUL_ESCURO, y, y + 58, FONTE, 110, 880, HORIZONTAL_ALIGNMENT_LEFT)
		y += 64.0
	_txt(c, "toque para fechar", 32, Color(AZUL, 0.7), r.size.y - 70, r.size.y - 24, FONTE, 0, r.size.x)
	_btn_fechar = Button.new()
	add_child(_btn_fechar)
	_btn_fechar.visible = false

