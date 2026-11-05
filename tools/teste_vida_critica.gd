extends SceneTree
var falhas := 0

func _initialize() -> void:
	_rodar()

func checar(nome: String, ok: bool) -> void:
	print(("OK " if ok else "FALHA ") + nome)
	if not ok: falhas += 1

func esperar(s: float) -> void:
	# Import/carregamento no primeiro quadro pode adiantar timers de SceneTree.
	# Conferir tempo físico, pois OGG e a rampa crítica usam esse relógio.
	var fim := Time.get_ticks_usec() + int(s * 1000000.0)
	while Time.get_ticks_usec() < fim:
		await create_timer(0.02, true, false, true).timeout

func _rodar() -> void:
	await process_frame
	var sm = root.get_node("SaveManager")
	sm.dados["som_ativo"] = true
	sm.dados["run_snapshot"] = {"ativa": false}
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	m.menu_iniciar.hide()
	m.jogo_iniciado = true
	var fx = m._vida_critica
	var mu = root.get_node("Musica")
	mu.pagina(1)
	await esperar(0.2)
	m.player.vidas = 1
	m._atualizar_hud()
	checar("entrada crítica dispara zumbido", fx.zumbido.playing)
	checar("heartbeat inicia", m._coracao_player.playing)
	await esperar(0.45)
	var bus: int = AudioServer.get_bus_index("MusicaVidaCritica")
	print("[critico] mistura=", mu._mistura_critica, " volume=", AudioServer.get_bus_volume_db(bus), " corte=", mu._filtro_critico.cutoff_hz, " tempo=", Engine.time_scale)
	checar("música atenua 4 dB", absf(AudioServer.get_bus_volume_db(bus) + 4.0) < 0.01)
	checar("filtro suave 5 kHz", absf(mu._filtro_critico.cutoff_hz - 5000.0) < 1.0)
	checar("partida passa pelo tratamento", AudioServer.get_bus_send(AudioServer.get_bus_index("MusicaPartida")) == "MusicaVidaCritica")
	checar("efeitos não passam pelo tratamento", m._coracao_player.bus == "Master" and fx.zumbido.bus == "Master")
	var pos: float = fx.zumbido.get_playback_position()
	m._atualizar_hud()
	checar("atualizar HUD não reinicia zumbido", fx.zumbido.get_playback_position() >= pos - 0.03)
	paused = true
	await esperar(0.15)
	checar("pausa suspende alerta", m._coracao_player.stream_paused and fx.zumbido.stream_paused)
	checar("pausa limpa tratamento sem mudar player", AudioServer.get_bus_volume_db(bus) == 0.0)
	paused = false
	await esperar(0.45)
	checar("retoma heartbeat sem impacto novo", fx.zumbido.get_playback_position() >= pos and m._coracao_player.playing)
	await esperar(0.8)
	checar("zumbido curto termina", not fx.zumbido.playing)
	mu.entrar_chefe()
	await esperar(4.5)
	checar("transição do boss mantém tratamento", absf(AudioServer.get_bus_volume_db(bus) + 4.0) < 0.01 and mu._chefe.tocando)
	checar("boss também passa pelo tratamento", AudioServer.get_bus_send(AudioServer.get_bus_index("MusicaChefe")) == "MusicaVidaCritica")
	mu.raiva_chefe()
	m.player.vidas = 3
	m._atualizar_hud()
	checar("cura começa saída gradual", m._coracao_player.playing)
	await esperar(1.1)
	checar("cura restaura música", AudioServer.get_bus_volume_db(bus) == 0.0 and not AudioServer.is_bus_effect_enabled(bus, 0))
	checar("cura encerra heartbeat", not m._coracao_player.playing)
	m.player.vidas = 1
	m._atualizar_hud()
	checar("nova entrada pode repetir impacto", fx.zumbido.playing)
	await esperar(0.4)
	m.player.vidas = 0
	m.jogo_iniciado = false
	m._atualizar_coracao()
	mu.abafar(true)
	await esperar(0.4)
	checar("morte limpa alerta", not m._coracao_player.playing and not fx.zumbido.playing and AudioServer.get_bus_volume_db(bus) == 0.0)
	checar("revive mantém sua atenuação independente", mu._chefe.player.volume_db < mu._chefe.volume_base - 8.0)
	mu.abafar(false)
	m.player.vidas = 1
	m.jogo_iniciado = true
	m._atualizar_coracao()
	checar("retomada com 1 coração sem impacto", not fx.zumbido.playing)
	await esperar(0.4)
	sm.dados["som_ativo"] = false
	await esperar(0.1)
	checar("som desligado limpa alerta", not m._coracao_player.playing and not fx.zumbido.playing and AudioServer.get_bus_volume_db(bus) == 0.0)
	sm.dados["som_ativo"] = true
	await esperar(0.4)
	checar("religar retoma sem impacto", m._coracao_player.playing and not fx.zumbido.playing)
	m.fim_de_jogo_declarado = true
	await esperar(0.1)
	checar("vitória limpa estado", AudioServer.get_bus_volume_db(bus) == 0.0 and not m._coracao_player.playing)
	m.queue_free()
	await process_frame
	checar("saída não deixa música abafada", not mu._critico and mu._mistura_critica == 0.0)
	mu.parar(0.1)
	await esperar(0.2)
	print("RESULTADO: %d falha(s)" % falhas)
	quit(1 if falhas else 0)
