extends SceneTree
## Rodar com backup do save, como os demais testes da partida.
var falhas := 0

func _initialize() -> void:
	_rodar()

func verificar(nome: String, ok: bool) -> void:
	print(("OK " if ok else "FALHA ") + nome)
	if not ok:
		falhas += 1

func _rodar() -> void:
	await process_frame
	var sm = root.get_node("SaveManager")
	sm.dados["som_ativo"] = true
	sm.dados["run_snapshot"] = {"ativa": false}
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.jogo_iniciado = true
	m.menu_iniciar.hide()
	m.player.vidas_max = 10
	m.player.vidas = 2
	var alerta = m.get_node("HUD/AlertaVida")
	await create_timer(0.4).timeout
	verificar("vida baixa aparece", alerta.modulate.a > 0.2)
	paused = true
	await create_timer(0.1, true).timeout
	verificar("pausa esconde vinheta", alerta.modulate.a == 0.0)
	paused = false
	m.player.vidas = 10
	await create_timer(0.4).timeout
	verificar("cura remove vinheta", alerta.modulate.a == 0.0)
	m.player.vidas = 1
	await create_timer(0.4).timeout
	verificar("um coração intensifica", alerta.modulate.a > 0.4)
	m.fim_de_jogo_declarado = true
	await process_frame
	await process_frame
	verificar("fim remove vinheta", alerta.modulate.a == 0.0)
	m.fim_de_jogo_declarado = false
	var b = load("res://boss.tscn").instantiate()
	m.add_child(b)
	b.set_process(false)
	b.position = Vector2(540, 700)
	b.entrada_concluida = true
	m.spawn_dano_chefe(12, false, b, b.position)
	var antes: Vector2 = m._lbl_dano_chefe.position
	b.position.x += 100
	m._atualizar_posicao_dano_chefe()
	verificar("dano acompanha chefe", absf(m._lbl_dano_chefe.position.x - antes.x - 100) < 1)
	verificar("dano longe da barra superior", m._lbl_dano_chefe.position.y > 300)
	m.spawn_dano_chefe(7, true, null, Vector2(250, 950))
	verificar("dano compartilhado junto do pedaço", absf(m._lbl_dano_chefe.position.x - 100) < 1)
	b._entrar_raiva()
	var aviso := false
	for n in m.get_node("HUD").get_children():
		if n is Label and n.text == "CHEFE COM RAIVA!":
			aviso = true
	verificar("raiva avisa na tela", aviso)
	if "--foto" in OS.get_cmdline_user_args():
		m.player.vidas = 1
		m._atualizar_hud()
		m.spawn_dano_chefe(120, true, b, b.position)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/joalh/Documentos/Sketch Blade - design/feedback-combate/previa.png")
	m._tocar_som(m.SONS["morte"])
	var bus := AudioServer.get_bus_index("MortesMonstros")
	verificar("mortes com EQ e compressor", bus >= 0 and AudioServer.get_bus_effect_count(bus) == 2)
	var mortes := 0
	for n in m.get_children():
		if n is AudioStreamPlayer and n.bus == "MortesMonstros":
			mortes += 1
			verificar("morte reduzida 7 dB", n.volume_db == -7.0)
	m._tocar_som(m.SONS["morte"])
	var depois := 0
	for n in m.get_children():
		if n is AudioStreamPlayer and n.bus == "MortesMonstros":
			depois += 1
	verificar("mortes simultâneas limitadas", mortes == 1 and depois == 1)
	m.queue_free()
	await process_frame
	var h = load("res://hub.tscn").instantiate()
	root.add_child(h)
	var sons: Array = []
	h.child_entered_tree.connect(func(n):
		if n is AudioStreamPlayer:
			sons.append(n.stream.resource_path))
	h._alterar_aba("estojo")
	verificar("estojo toca clique e zíper", sons.has("res://assets/sons/clique.ogg") and sons.has("res://assets/sons/ziper.ogg"))
	h.queue_free()
	await process_frame
	print("RESULTADO: %d falha(s)" % falhas)
	quit(1 if falhas else 0)
