extends SceneTree
## Protótipo do Estojo no estilo caderno (TelaEstojo.gd, versões A e B), por
## cima do Hub real, sem mexer no Hub.gd.
## Uso (com backup do save do PC): Godot --path . -s tools/prototipo_estojo.gd -- <pasta>

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/estojo-novo/v1"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	for v in ["A", "B"]:
		# Os 3 estados numa tela: dá para subir, falta tinta, nível máximo
		await _caso(v, "misto", 640, 4, 6, 10)
		await _caso(v, "inicio", 120, 1, 1, 1)
		await _caso(v, "comprou", 2400, 5, 4, 3, "nivel_dano")
	quit()

func _caso(versao: String, nome: String, tinta: int, dano: int, hp: int, cad: int, comprado := "") -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = tinta; d["clipes_ouro"] = 40; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = 5; d["capitulo_selecionado"] = 1
	d["nivel_dano"] = dano; d["nivel_hp"] = hp; d["nivel_cadencia"] = cad
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true; d["run_snapshot"] = {"ativa": false}
	var hoje := Time.get_date_string_from_system()
	d["ultimo_login"] = hoje; d["recompensa_coletada_hoje"] = true
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var h: Node = load("res://hub.tscn").instantiate(); _sv.add_child(h)
	await create_timer(1.5).timeout
	h._alterar_aba("estojo")
	# Esconde o Estojo antigo (título, sublinhado, cards e a moldura do DesenhoHub)
	for f in h.tela_estojo.get_children():
		f.visible = false
	h.desenho_hub.aba_ativa = ""
	h.desenho_hub.queue_redraw()
	var tela := Control.new()
	tela.set_script(load("res://TelaEstojo.gd"))
	tela.versao = versao
	h.tela_estojo.add_child(tela)
	await process_frame
	var dados: Dictionary = tela.montar_dados(d)
	if comprado != "":
		dados["comprado"] = comprado
	tela.mostrar(dados)
	await create_timer(0.13 if comprado != "" else 0.4).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s-%s.png" % [_saida, versao, nome])
	print("[prototipo_estojo] ", versao, "-", nome)
	_sv.queue_free(); await process_frame; await process_frame
