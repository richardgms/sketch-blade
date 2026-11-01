extends SceneTree
## Protótipo do fundo da página com textura de papel (Paper.textura_papel):
## combate real nos 4 tipos de papel, com monstros e manchas.
## Uso (com backup do save do PC): Godot --path . -s tools/prototipo_fundo.gd -- <pasta>

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0]
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	for cap in [1, 4, 6, 8, 10]:
		await _caso(cap)
	quit()

func _caso(cap: int) -> void:
	seed(cap)
	var d: Dictionary = root.get_node("SaveManager").dados
	d["capitulo_desbloqueado"] = cap; d["capitulo_selecionado"] = cap
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true; d["run_snapshot"] = {"ativa": false}
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var m: Node = load("res://main.tscn").instantiate(); _sv.add_child(m)
	await create_timer(1.0).timeout
	m.player.invencivel = true
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.label_pagina.text = "Página 3 / 8"; m.label_pagina.visible = true
	var cores := [Color("26238c"), Color("0a473a"), Color("a8401c")]
	var pos := [Vector2(300, 520), Vector2(780, 760), Vector2(460, 1060)]
	for i in range(3):
		m._spawn_mancha(pos[i], cores[i])
	m.player.attack_timer.start()
	m.wave_manager.capitulo_atual = cap
	m.wave_manager.pagina_atual = 3
	m.wave_manager.monstros_restantes_spawn = 6
	m.wave_manager.timer_spawn.wait_time = 0.5
	m.wave_manager.timer_spawn.start()
	await create_timer(2.6).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/cap%d.png" % [_saida, cap])
	print("[prototipo_fundo] cap", cap)
	_sv.queue_free(); await process_frame; await process_frame
