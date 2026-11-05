extends SceneTree
## Percorre os finais reais e mede reprodução/conclusão com a partida pausada.
## Executar com backup e restauração do save (os finais gravam estatísticas).
var falhas := 0

func _initialize() -> void:
	_rodar()

func checar(nome: String, ok: bool) -> void:
	print(("OK " if ok else "FALHA ") + nome)
	if not ok: falhas += 1

func esperar(segundos: float) -> void:
	var fim := Time.get_ticks_usec() + int(segundos * 1000000.0)
	while Time.get_ticks_usec() < fim:
		await create_timer(0.02, true, false, true).timeout

func _rodar() -> void:
	await process_frame
	var sm = root.get_node("SaveManager")
	sm.dados["som_ativo"] = true
	sm.dados["tutorial_visto"] = true
	sm.dados["run_snapshot"] = {"ativa": false}
	root.get_node("AdsManager").revive_usado_na_run = true
	for resultado in ["derrota", "vitoria"]:
		paused = false
		var m = load("res://main.tscn").instantiate()
		root.add_child(m)
		m.menu_iniciar.hide()
		m.jogo_iniciado = true
		m.run_de_teste = true
		m.player.vidas = 1
		m._atualizar_hud()
		root.get_node("Musica").pagina(1)
		await esperar(0.4)
		var jingle := [null]
		var terminou := [false]
		m.child_entered_tree.connect(func(n):
			if n is AudioStreamPlayer and n.stream == m.SONS[resultado]:
				jingle[0] = n
				n.finished.connect(func(): terminou[0] = true))
		if resultado == "derrota":
			m.player.vidas = 0
			m._on_player_morreu()
		else:
			m._on_fase_concluida()
			await esperar(1.7)
		checar(resultado + ": tela aberta e combate pausado", paused and (m.menu_vitoria.visible if resultado == "vitoria" else m.menu_game_over.visible))
		checar(resultado + ": jingle criado", is_instance_valid(jingle[0]))
		await esperar(0.35)
		checar(resultado + ": áudio avança com jogo pausado", is_instance_valid(jingle[0]) and jingle[0].get_playback_position() > 0.15)
		checar(resultado + ": heartbeat parou", not m._coracao_player.playing)
		checar(resultado + ": filtro crítico limpo", root.get_node("Musica")._mistura_critica == 0.0)
		# Combate não pode continuar soando por causa da correção dos jingles.
		m._tocar_som(m.SONS["acerto"])
		var acerto: AudioStreamPlayer
		for n in m.get_children():
			if n is AudioStreamPlayer and n.stream == m.SONS["acerto"]: acerto = n
		checar(resultado + ": efeito de combate permanece pausado", is_instance_valid(acerto) and not acerto.can_process())
		await esperar(m.SONS[resultado].get_length() + 0.2)
		checar(resultado + ": áudio termina e é removido", terminou[0] and not is_instance_valid(jingle[0]))
		sm.dados["som_ativo"] = false
		var antes: int = m.get_child_count()
		m._tocar_som(m.SONS[resultado])
		checar(resultado + ": respeita som desligado", m.get_child_count() == antes)
		sm.dados["som_ativo"] = true
		m.queue_free()
		await process_frame
	paused = false
	await esperar(0.4)
	print("RESULTADO: %d falha(s)" % falhas)
	quit(1 if falhas else 0)
