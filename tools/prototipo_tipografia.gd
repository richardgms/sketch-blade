extends SceneTree
## Teste de legibilidade (13/11/2026): a prova do dia com outras fontes nas
## linhas (manuscrita só no título). Fontes fora do projeto, carregadas do disco.
## Uso (com janela e backup do save do PC):
##   Godot --path . -s tools/prototipo_tipografia.gd -- <pasta_das_fontes> <pasta_saida> nome:arquivo.ttf:tamanho ...
var _sv: SubViewport

func _initialize() -> void:
	_rodar()

func _rodar() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var fontes: String = a[0]
	var saida: String = a[1]
	DirAccess.make_dir_recursive_absolute(saida)
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tutorial_visto"] = true; d["novidades_vistas"] = 9999; d["run_snapshot"] = {"ativa": false}
	d["ultimo_login"] = Time.get_date_string_from_system()
	# [nome, arquivo .ttf ("" = atual), tamanho das linhas]
	var lista: Array = [["atual", "", 46]]
	for linha in a.slice(2):
		var p: PackedStringArray = linha.split(":")
		lista.append([p[0], fontes + "/" + p[1], int(p[2])])
	for par in lista:
		_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
		_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(_sv)
		var h: Node = load("res://hub.tscn").instantiate(); _sv.add_child(h)
		await create_timer(1.5).timeout
		var j: Control = Control.new()
		j.set_script(load("res://JanelaDesafio.gd"))
		h.get_node("HUD").add_child(j); await process_frame
		var dd := {"nome": "Caneta Azul", "data": "sexta, 13/11", "regra": "Caneta de vidro",
			"desc": ["Metade dos corações,", "mas toda tinta vale o triplo."], "carimbos": 2}
		if par[1] != "":
			dd["fonte_corpo"] = par[1]
		dd["tam_corpo"] = par[2]
		j.mostrar(dd)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		_sv.get_texture().get_image().save_png("%s/prova-%s.png" % [saida, par[0]])
		_sv.queue_free(); await process_frame
	quit()
