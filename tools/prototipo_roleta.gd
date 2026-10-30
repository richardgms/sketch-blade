extends SceneTree
## Protótipo da roleta de melhorias no estilo caderno (TelaRoleta.gd),
## por cima do combate real, sem mexer no Main.gd.
## Uso: bash tools/capturar_telas.sh não serve; rode com backup do save:
##   Godot --path . -s tools/prototipo_roleta.gd -- <pasta>

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/roleta-nova/v1"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	await _caso("A-pag2-cap1", "A", 1, 2, {}, ["tiro_duplo", "apontador_rapido", "corretivo_liquido"])
	await _caso("A-pag4-cap5", "A", 5, 4, {"tiro_duplo": 1, "leque": 2}, ["tiro_duplo", "leque", "pote_tinta"])
	await _caso("A-pag6-cap7", "A", 7, 6, {"tiro_duplo": 2, "leque": 2, "ricochete": 1},
		["borrao_explosivo", "tinta_corrosiva", "ricochete"])
	await _caso("A-4icones", "A", 7, 6, {"escudo_borracha": 1, "tiro_duplo": 1, "leque": 2, "ricochete": 1},
		["borrao_explosivo", "tinta_corrosiva", "ricochete"])
	await _caso("A-tocada", "A", 5, 4, {"tiro_duplo": 1, "leque": 2}, ["tiro_duplo", "leque", "pote_tinta"], -1.0, 1)
	await _caso("A-animando", "A", 5, 4, {"tiro_duplo": 1, "leque": 2}, ["tiro_duplo", "leque", "pote_tinta"], 0.3)
	await _caso("B-pag4-cap5", "B", 5, 4, {"tiro_duplo": 1, "leque": 2}, ["tiro_duplo", "leque", "pote_tinta"], -1.0, 1)
	await _caso("B-sem-marcar", "B", 5, 4, {"tiro_duplo": 1, "leque": 2}, ["tiro_duplo", "leque", "pote_tinta"])
	quit()

func _caso(nome: String, versao: String, cap: int, pagina: int, ups: Dictionary, ids: Array,
		espera: float = -1.0, marcar: int = -1) -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["capitulo_desbloqueado"] = cap; d["capitulo_selecionado"] = cap
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true; d["run_snapshot"] = {"ativa": false}
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var m: Node = load("res://main.tscn").instantiate(); _sv.add_child(m)
	await create_timer(1.0).timeout
	m.capitulo_atual = cap
	m.player.invencivel = true
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	for id in ups:
		for k in range(int(ups[id])):
			m.player.aplicar_upgrade(id)
	var gd: Node = root.get_node("GameData")
	var opcoes: Array = []
	for id in ids:
		opcoes.append(gd.get_upgrade(id))
	paused = true
	var tela := Control.new()
	tela.set_script(load("res://TelaRoleta.gd"))
	tela.versao = versao
	m.get_node("HUD").add_child(tela)
	await process_frame
	# Teste de card em imagem: ROLETA_CARD=<png> ROLETA_MARGEM=l,t,r,b
	var card := OS.get_environment("ROLETA_CARD")
	if card != "":
		var mg := OS.get_environment("ROLETA_MARGEM").split(",")
		tela.usar_card_imagem(ImageTexture.create_from_image(Image.load_from_file(card)),
			Vector4(float(mg[0]), float(mg[1]), float(mg[2]), float(mg[3])))
	tela.mostrar(tela.montar_dados(opcoes, m.player, cap, pagina, 8))
	if espera > 0.0:
		await create_timer(espera, true).timeout
	else:
		await create_timer(2.0, true).timeout
	if marcar >= 0:
		tela.marcar_para_print(marcar)
		await create_timer(0.2, true).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[prototipo_roleta] ", nome)
	paused = false
	_sv.queue_free(); await process_frame; await process_frame
