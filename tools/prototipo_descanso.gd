extends SceneTree
## Protótipo da página de descanso no estilo caderno (TelaDescanso.gd),
## por cima do combate real, sem mexer no Main.gd.
## Uso (com backup do save do PC): Godot --path . -s tools/prototipo_descanso.gd -- <pasta>

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/descanso-novo/v1"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	await _caso("cap1-ferido", 1, 5, 8, 120)
	await _caso("cap7-cheio", 7, 11, 11, 1340)
	await _caso("cap5-tocada", 5, 3, 9, 460, -1.0, 0)
	await _caso("animando", 5, 3, 9, 460, 0.2)
	quit()

func _caso(nome: String, cap: int, vidas: int, vmax: int, tinta: int,
		espera: float = -1.0, marcar: int = -1) -> void:
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
	paused = true
	var gd: Node = root.get_node("GameData")
	var tela := Control.new()
	tela.set_script(load("res://TelaDescanso.gd"))
	m.get_node("HUD").add_child(tela)
	await process_frame
	tela.mostrar({"cap": cap, "pagina": 4, "total_paginas": 8, "vidas": vidas, "vidas_max": vmax,
		"cura": gd.DESCANSO_CURA, "tinta_partida": tinta, "ganho_tinta": gd.tinta_descanso(cap)})
	await create_timer(espera if espera > 0.0 else 1.5, true).timeout
	if marcar >= 0:
		tela.marcar_para_print(marcar)
		await create_timer(0.2, true).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[prototipo_descanso] ", nome)
	paused = false
	_sv.queue_free(); await process_frame; await process_frame
