extends SceneTree
## Teste do aviso de novidades (JanelaNovidades no Hub): aparece uma vez depois
## de atualizar, não repete, conta nova não vê, espera a recompensa diária.
## Uso (com janela e backup do save do PC):
##   Godot --path . -s tools/teste_novidades.gd -- <pasta_dos_prints>
var _sv: SubViewport
var _saida := "C:/Users/joalh/Documentos/Sketch Blade/design/novidades-avaliacao/teste"
var _falhas := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_saida = a[0]
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _d() -> Dictionary:
	return root.get_node("SaveManager").dados

func _hub() -> Node:
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var h: Node = load("res://hub.tscn").instantiate(); _sv.add_child(h)
	await create_timer(1.2).timeout
	return h

func _avisos(h: Node) -> int:
	var s: Script = load("res://JanelaNovidades.gd")
	return h.get_node("HUD").get_children().filter(func(c): return c.get_script() == s).size()

func _confere(nome: String, obtido, esperado) -> void:
	var ok: bool = obtido == esperado
	if not ok:
		_falhas += 1
	print("[teste_novidades] %s: %s (esperado %s) %s" % [nome, obtido, esperado, "OK" if ok else "FALHOU"])

func _fechar() -> void:
	_sv.queue_free(); await process_frame; await process_frame

func _rodar() -> void:
	await process_frame
	var gd: Node = root.get_node("GameData")
	var hoje := Time.get_date_string_from_system()
	# 1. Jogador antigo atualizou: aparece
	_d()["tutorial_visto"] = true; _d()["novidades_vistas"] = 0
	_d()["ultimo_login"] = hoje; _d()["run_snapshot"] = {"ativa": false}
	var h = await _hub()
	_confere("depois de atualizar", _avisos(h), 1)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png(_saida + "/novidades.png")
	_confere("marcou como vista", int(_d()["novidades_vistas"]), gd.VERSAO_CODIGO)
	await _fechar()
	# 2. Abre de novo: não repete
	h = await _hub()
	_confere("segunda abertura", _avisos(h), 0)
	await _fechar()
	# 3. Conta nova: não aparece, mas marca
	_d()["tutorial_visto"] = false; _d()["novidades_vistas"] = 0
	h = await _hub()
	_confere("conta nova", _avisos(h), 0)
	_confere("conta nova marcou", int(_d()["novidades_vistas"]), gd.VERSAO_CODIGO)
	await _fechar()
	# 4. Com a recompensa diária: espera ela fechar
	_d()["tutorial_visto"] = true; _d()["novidades_vistas"] = 0; _d()["ultimo_login"] = "2000-01-01"
	h = await _hub()
	_confere("com recompensa aberta", _avisos(h), 0)
	h._janela_recompensa.queue_free(); await create_timer(0.2).timeout
	_confere("depois da recompensa", _avisos(h), 1)
	await _fechar()
	print("[teste_novidades] falhas: ", _falhas)
	quit()
