extends SceneTree
## Protótipo da virada de página (VirarPagina.gd, versões A e B) por cima do
## combate real, em câmera lenta, gravando um quadro a cada 0,05 s de jogo.
## Uso (com backup do save do PC): Godot --path . -s tools/prototipo_virada.gd -- <pasta>

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/virada/v1"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	for v in (OS.get_cmdline_user_args()[1].split(",") if OS.get_cmdline_user_args().size() > 1 else ["A3"]):
		await _caso(v, 5, 3)
		await _caso(v, 1, 6)
	quit()

func _caso(versao: String, cap: int, numero: int) -> void:
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
	m.label_pagina.text = "Página %d / 8" % numero; m.label_pagina.visible = true
	await create_timer(0.3).timeout
	var pasta := "%s/%s-cap%d" % [_saida, versao, cap]
	DirAccess.make_dir_recursive_absolute(pasta)
	Engine.time_scale = 0.05
	if versao == "antes":
		m._animar_virada_pagina(numero)
	else:
		var vp: Control = Control.new()
		vp.set_script(load("res://VirarPagina.gd"))
		m.get_node("HUD").add_child(vp)
		vp.iniciar({"cap": cap, "nome": preload("res://TelaPausa.gd").NOMES_CAPITULOS[cap],
			"numero": numero, "total": 8, "versao": versao})
	var t0 := Time.get_ticks_msec()
	var proximo := 0.0
	var n := 0
	while proximo <= 1.5:
		await process_frame
		var tj: float = (Time.get_ticks_msec() - t0) / 1000.0 * 0.05
		if tj >= proximo:
			await RenderingServer.frame_post_draw
			_sv.get_texture().get_image().save_png("%s/q%03d.png" % [pasta, n])
			n += 1
			proximo += 0.05
	print("[prototipo_virada] ", versao, "-cap", cap, " quadros=", n)
	Engine.time_scale = 1.0
	_sv.queue_free(); await process_frame; await process_frame
