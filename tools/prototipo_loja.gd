extends SceneTree
## Protótipo da Loja no estilo caderno (TelaLoja.gd + JanelaCompra.gd), por
## cima do Hub real, sem mexer no Hub.gd.
## Uso (com backup do save do PC): Godot --path . -s tools/prototipo_loja.gd -- <pasta> [A,B]

var _sv: SubViewport
var _saida := ""
var _versoes: PackedStringArray = ["A", "B"]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/loja-nova/v1"
	if args.size() > 1:
		_versoes = args[1].split(",")
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	for v in _versoes:
		await _caso(v, "canetas", "")
		if v == "B":
			await _caso(v, "canetas", "gel_vermelha")
			await _caso(v, "canetas", "nanquim")
		await _caso(v, "pacotes", "")
		await _caso(v, "compra", "")
		await _caso(v, "oferta", "")
		await _caso(v, "abrindo", "")
	quit()

func _save() -> Dictionary:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = 640; d["clipes_ouro"] = 40; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = 5; d["capitulo_selecionado"] = 1
	d["canetas_possuidas"] = ["bic_azul", "lapis_hb"]; d["caneta_equipada"] = "bic_azul"
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true
	d["ultimo_login"] = Time.get_date_string_from_system(); d["recompensa_coletada_hoje"] = true
	d["run_snapshot"] = {"ativa": false}
	return d

func _caso(v: String, caso: String, sel: String) -> void:
	var save := _save()
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var h: Node = load("res://hub.tscn").instantiate(); _sv.add_child(h)
	await create_timer(1.5).timeout
	h._alterar_aba("loja")
	# Some com a loja antiga (cartões e abas), fica só o papel e o cabeçalho
	h.container_loja.visible = false
	for b in h.botoes_sub_aba_loja.values():
		b.visible = false
	if h.sublinhado_loja:
		h.sublinhado_loja.visible = false
	var tela := Control.new()
	tela.set_script(load("res://TelaLoja.gd"))
	tela.versao = v
	tela._sel = sel
	h.tela_loja.add_child(tela)
	await process_frame
	var d: Dictionary = tela.montar_dados(save)
	d["pacotes"] = tela.montar_pacotes()
	d["aba"] = "canetas" if caso == "canetas" else "pacotes"
	tela.mostrar(d)
	if caso in ["compra", "oferta", "abrindo"]:
		var j := Control.new()
		j.set_script(load("res://JanelaCompra.gd"))
		j.versao = v
		h.get_node("HUD").add_child(j)
		await process_frame
		var bm: Node = root.get_node("BillingManager")
		j.mostrar({"nome": bm.nome("tinta"), "icone": "res://assets/pote_tinta.png",
			"preco": bm.preco("tinta"), "disponivel": bm.disponivel("tinta"),
			"falta": 130 if caso == "oferta" else 0, "moeda": "gotas de tinta",
			"estado": "abrindo" if caso == "abrindo" else ""})
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var nome := "%s-%s%s" % [v, caso, ("-" + sel) if sel != "" else ""]
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[prototipo_loja] ", nome)
	_sv.queue_free(); await process_frame; await process_frame
