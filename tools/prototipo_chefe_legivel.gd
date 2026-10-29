extends SceneTree
## Prints de lutas de chefe para avaliar a legibilidade (números de dano e
## tiros por cima do desenho). Uso:
##   Godot --path . -s tools/prototipo_chefe_legivel.gd -- <pasta> [caps 5,3,1]
## Faça backup do save do PC antes (alguns eventos gravam o save).

var _sv: SubViewport
var _saida := ""
var _caps: Array = [5, 3, 1]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/chefe-legivel/antes"
	if args.size() > 1:
		_caps = Array(args[1].split(",")).map(func(c): return int(c))
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	for cap in _caps:
		await _luta(cap)
	quit()

func _luta(cap: int) -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = 640; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = 5; d["capitulo_selecionado"] = cap
	d["nivel_dano"] = 4; d["nivel_hp"] = 4; d["nivel_cadencia"] = 4
	d["caneta_equipada"] = "bic_azul"; d["tutorial_visto"] = true; d["dica_gotas_vista"] = true
	d["run_snapshot"] = {"ativa": false}
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var m: Node = load("res://main.tscn").instantiate(); _sv.add_child(m)
	await create_timer(0.5).timeout
	m.player.invencivel = true
	for id in ["tiro_duplo", "leque", "ponta_critica"]:
		m.player.aplicar_upgrade(id)
	m.player.position = Vector2(540, 1650); m.player.mover_para(Vector2(540, 1650))
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.player.attack_timer.start()
	m.wave_manager.iniciar_fase_na_pagina(cap, 8)
	# Caneta embaixo do chefe, andando um pouco, para os tiros acertarem
	for i in range(4):
		await create_timer(2.0 if i == 0 else 1.6).timeout
		var boss = m.get_tree().get_first_node_in_group("boss")
		if boss:
			m.player.mover_para(Vector2(clamp(boss.global_position.x + randf_range(-60, 60), 120, 960), 1650))
	for k in range(2):
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		_sv.get_texture().get_image().save_png("%s/cap%d-%d.png" % [_saida, cap, k + 1])
		print("[chefe_legivel] cap%d-%d" % [cap, k + 1])
	paused = false
	_sv.queue_free(); await process_frame; await process_frame
