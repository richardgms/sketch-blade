extends SceneTree
## Protótipo do desafio do dia (13/11/2026): 2 entradas no Hub e 2 folhas.
## Uso (com janela e backup do save do PC):
##   Godot --path . -s tools/prototipo_desafio.gd -- <pasta>
var _sv: SubViewport
var _saida := "C:/Users/joalh/Documentos/Sketch Blade/design/desafio-do-dia/v1"
const DADOS := {"data": "Sexta, 14 de novembro", "regra": "Caneta de vidro",
	"desc": ["Você tem só 1 coração,", "mas toda tinta vale o triplo."], "premio": "150 tinta + 3 clipes"}

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0 and not a[0] in ["v2", "v3"]:
		_saida = a[0]
	if a.has("v2"):
		_saida = _saida.replace("/v1", "/v2")
	if a.has("v3"):
		_saida = _saida.replace("/v1", "/v3")
		DirAccess.make_dir_recursive_absolute(_saida)
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _hub() -> Node:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = 640; d["clipes_ouro"] = 40; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = 5; d["capitulo_selecionado"] = 3; d["tutorial_visto"] = true
	d["ultimo_login"] = Time.get_date_string_from_system(); d["novidades_vistas"] = 9999
	d["run_snapshot"] = {"ativa": false}
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var h: Node = load("res://hub.tscn").instantiate(); _sv.add_child(h)
	await create_timer(1.5).timeout
	return h

func _foto(n: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, n])

func _fechar() -> void:
	_sv.queue_free(); await process_frame; await process_frame

func _estrela(pai: Control, pos: Vector2, lado: float, giro: float) -> void:
	var e := TextureRect.new()
	e.texture = load("res://assets/ui/estrela_giz.png")
	e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	e.size = Vector2(lado, lado); e.position = pos; e.pivot_offset = e.size / 2.0; e.rotation_degrees = giro
	pai.add_child(e)

func _rotulo(pai: Control, t: String, tam: int, r: Rect2, cor := Color("002867")) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = r.position; l.size = r.size
	pai.add_child(l)

## A: post-it amarelo colado no canto da página do capítulo.
func _entrada_a(h: Node) -> void:
	var c := Control.new()
	c.position = Vector2(800, 690); c.size = Vector2(250, 220)
	c.pivot_offset = c.size / 2.0; c.rotation_degrees = 5
	h.get_node("HUD").add_child(c)
	var sombra := ColorRect.new(); sombra.color = Color(0, 0, 0, 0.12)
	sombra.position = Vector2(8, 10); sombra.size = c.size; c.add_child(sombra)
	var papel := ColorRect.new(); papel.color = Color("fff1a8"); papel.size = c.size; c.add_child(papel)
	var fita := ColorRect.new(); fita.color = Color(1, 1, 1, 0.55)
	fita.size = Vector2(110, 36); fita.position = Vector2(80, -16); fita.rotation_degrees = -4; c.add_child(fita)
	_estrela(c, Vector2(78, 18), 95, -8)
	_rotulo(c, "Desafio", 38, Rect2(0, 112, 250, 50))
	_rotulo(c, "do dia", 38, Rect2(0, 152, 250, 50))

## B: ícone de estrela no topo, ao lado das Missões, com pontinho de aviso.
func _entrada_b(h: Node) -> void:
	var c := Control.new()
	c.position = Vector2(780, 196); c.size = Vector2(90, 90)
	h.get_node("HUD").add_child(c)
	_estrela(c, Vector2(0, 0), 90, -6)
	var ponto := Control.new()
	ponto.draw.connect(func(): ponto.draw_circle(Vector2(84, 8), 13.0, Color("c62828")))
	c.add_child(ponto)

## v2: bilhete "Prova surpresa" à direita, abaixo da seta do capítulo,
## balançando de leve.
func _entrada_prova(h: Node) -> void:
	var e := TextureRect.new()
	e.texture = load("res://assets/ui/desafio/icone.png")
	e.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	e.size = Vector2(170, 170); e.position = Vector2(870, 450)
	e.pivot_offset = Vector2(85, 10); e.rotation_degrees = 6
	h.get_node("HUD").add_child(e)

func _rodar() -> void:
	if OS.get_cmdline_user_args().has("v3"):
		await _rodar_v3()
		return
	await process_frame
	var h = await _hub(); _entrada_a(h); await _foto("entrada-A"); await _fechar()
	h = await _hub(); _entrada_b(h); await _foto("entrada-B"); await _fechar()
	for par in [["folha-A", "res://tools/proto_desafio/FolhaA.gd"], ["folha-B", "res://tools/proto_desafio/FolhaB.gd"]]:
		h = await _hub()
		var j: Control = load(par[1]).new()
		h.get_node("HUD").add_child(j); await process_frame
		j.mostrar(DADOS)
		await _foto(par[0]); await _fechar()
	quit()

func _rodar_v3() -> void:
	await process_frame
	for estilo in ["prancheta", "fita"]:
		for c in [0, 2]:
			var h = await _hub()
			var j: Control = load("res://tools/proto_desafio/Prova.gd").new()
			h.get_node("HUD").add_child(j); await process_frame
			var d := DADOS.duplicate()
			d["carimbos"] = c; d["estilo"] = estilo; d["nome"] = "Caneta Bic Azul"; d["data"] = "sexta, 14/11"
			j.mostrar(d)
			await _foto("prova-%s-%d" % [estilo, c]); await _fechar()
	quit()
