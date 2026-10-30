extends SceneTree
## Protótipo da pausa no estilo caderno (TelaPausa.gd), por cima do combate
## real, sem mexer no Main.gd.
## Uso (com backup do save do PC): Godot --path . -s tools/prototipo_pausa.gd -- <pasta>

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/pausa-nova/v1"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	await _caso("2melhorias", 3, 4, 7, 8, 260, {"tiro_duplo": 1, "leque": 1})
	await _caso("3melhorias", 5, 5, 6, 9, 460, {"tiro_duplo": 2, "leque": 1, "ricochete": 1})
	await _caso("nenhuma", 1, 1, 8, 8, 0, {})
	await _caso("4melhorias-vibracao-off", 7, 7, 4, 11, 1340,
		{"escudo_borracha": 1, "tiro_duplo": 1, "leque": 1, "ponta_critica": 1})
	await _caso("confirmar", 5, 5, 6, 9, 460, {"tiro_duplo": 2, "leque": 1, "ricochete": 1}, true)
	quit()

func _caso(nome: String, cap: int, pagina: int, vidas: int, vmax: int, tinta: int,
		ups: Dictionary, confirmar := false) -> void:
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
	var mel: Array = []
	for id in ups:
		var u: Dictionary = gd.get_upgrade(id)
		var nv := int(ups[id])
		mel.append({"icone": u["icone"], "nome": u["nome"], "nivel": nv, "efeito": u["stats"][nv - 1]})
	var tela := Control.new()
	tela.set_script(load("res://TelaPausa.gd"))
	m.get_node("HUD").add_child(tela)
	await process_frame
	tela.mostrar({"cap": cap, "pagina": pagina, "total_paginas": 8, "vidas": vidas, "vidas_max": vmax,
		"tinta_partida": tinta, "melhorias": mel, "som": true, "vibracao": not nome.contains("vibracao-off")})
	await create_timer(0.6, true).timeout
	if confirmar:
		tela._pedir_confirmacao()
		await create_timer(0.2, true).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[prototipo_pausa] ", nome)
	paused = false
	_sv.queue_free(); await process_frame; await process_frame
