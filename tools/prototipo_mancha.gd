extends SceneTree
## Protótipo da mancha de tinta na morte dos monstros: mata monstros reais
## na página e grava o respingo (logo depois) e a mancha que fica.
## Uso (com backup do save do PC): Godot --path . -s tools/prototipo_mancha.gd -- <pasta>

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/mancha/antes"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	for cap in [1]:
		await _caso(cap)
	quit()

func _caso(cap: int) -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["capitulo_desbloqueado"] = cap; d["capitulo_selecionado"] = cap
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true; d["run_snapshot"] = {"ativa": false}
	d["nivel_dano"] = 10; d["nivel_cadencia"] = 10
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var m: Node = load("res://main.tscn").instantiate(); _sv.add_child(m)
	await create_timer(1.0).timeout
	m.player.invencivel = true
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	# Mortes em posições fixas com as cores reais dos monstros; a última é
	# fotografada no meio do estouro, depois tudo assentado na página
	var cores := [Color("26238c"), Color("3b2c64"), Color("0a473a"), Color("a8401c"), Color("1a1a2e"), Color("26238c")]
	var pos := [Vector2(300, 420), Vector2(760, 560), Vector2(420, 820), Vector2(820, 1000), Vector2(260, 1180), Vector2(560, 640)]
	for i in range(pos.size()):
		m._spawn_particles(cores[i], pos[i])
		m._spawn_mancha(pos[i], cores[i])
		await create_timer(0.5 if i < pos.size() - 1 else 0.07).timeout
	await _foto("cap%d-estouro" % cap)
	await create_timer(1.5).timeout
	await _foto("cap%d-manchas" % cap)
	# Câmera lenta de uma morte (quadros de 0,03 s de jogo, recorte 420x420)
	var pasta := "%s/lento-cap%d" % [_saida, cap]
	DirAccess.make_dir_recursive_absolute(pasta)
	Engine.time_scale = 0.05
	var p := Vector2(540, 1250)
	m._spawn_particles(cores[0], p)
	m._spawn_mancha(p, cores[0])
	var t0 := Time.get_ticks_msec()
	var proximo := 0.0
	var n := 0
	while proximo <= 0.9:
		await process_frame
		if (Time.get_ticks_msec() - t0) / 1000.0 * 0.05 >= proximo:
			await RenderingServer.frame_post_draw
			_sv.get_texture().get_image().get_region(Rect2i(330, 1040, 420, 420)).save_png("%s/q%03d.png" % [pasta, n])
			n += 1
			proximo += 0.03
	Engine.time_scale = 1.0
	_sv.queue_free(); await process_frame; await process_frame

func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[prototipo_mancha] ", nome)
