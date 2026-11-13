extends SceneTree
## Teste do pedido de avaliação (JanelaAvaliacao na vitória): aparece depois da
## animação, uma vez por versão, nunca depois de AVALIAR; voltar fecha.
## Uso (com janela e backup do save do PC):
##   Godot --path . -s tools/teste_avaliacao.gd -- <pasta_dos_prints>
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

func _confere(nome: String, obtido, esperado) -> void:
	if obtido != esperado:
		_falhas += 1
	print("[teste_avaliacao] %s: %s (esperado %s) %s" % [nome, obtido, esperado, "OK" if obtido == esperado else "FALHOU"])

func _vitoria() -> Node:
	var d := _d()
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true; d["run_snapshot"] = {"ativa": false}
	d["capitulo_selecionado"] = 3; d["capitulo_desbloqueado"] = 5
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var m: Node = load("res://main.tscn").instantiate(); _sv.add_child(m)
	await create_timer(1.0).timeout
	m.player.invencivel = true; m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.capitulo_atual = 3; m.tinta_partida = 420; m.monstros_derrotados_partida = 40; m.boss_derrotado_partida = true
	m._processar_fim_de_jogo(true); m.menu_vitoria.visible = true
	return m

func _fechar() -> void:
	paused = false
	_sv.queue_free(); await process_frame; await process_frame

func _rodar() -> void:
	await process_frame
	var cod: int = root.get_node("GameData").VERSAO_CODIGO
	# 1. Primeira vitória da versão: não aparece durante a animação, aparece depois
	_d()["avaliacao_pedida"] = 0; _d()["avaliou"] = false
	var m = await _vitoria()
	await create_timer(0.3).timeout
	_confere("durante a animação", is_instance_valid(m.janela_avaliacao), false)
	await create_timer(4.0).timeout
	_confere("depois da animação", is_instance_valid(m.janela_avaliacao), true)
	_confere("marcou a versão", int(_d()["avaliacao_pedida"]), cod)
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png(_saida + "/avaliacao.png")
	m._tratar_voltar()
	await create_timer(0.2).timeout
	_confere("voltar fecha", is_instance_valid(m.janela_avaliacao), false)
	_confere("vitória continua", m.menu_vitoria.visible, true)
	await _fechar()
	# 2. Outra vitória na mesma versão: não repete
	m = await _vitoria(); await create_timer(4.5).timeout
	_confere("mesma versão", is_instance_valid(m.janela_avaliacao), false)
	await _fechar()
	# 3. AVALIAR marca e nunca mais pede
	_d()["avaliacao_pedida"] = 0
	m = await _vitoria(); await create_timer(4.5).timeout
	m.janela_avaliacao._btns[0].pressed.emit()
	await create_timer(0.2).timeout
	_confere("AVALIAR marcou", _d()["avaliou"], true)
	await _fechar()
	_d()["avaliacao_pedida"] = 0
	m = await _vitoria(); await create_timer(4.5).timeout
	_confere("depois de avaliar", is_instance_valid(m.janela_avaliacao), false)
	await _fechar()
	print("[teste_avaliacao] falhas: ", _falhas)
	quit()
