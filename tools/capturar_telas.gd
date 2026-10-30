extends SceneTree
## Fotografa as telas de menu e HUD para revisão visual (1080x1920).
##
## Uso (precisa de janela, não roda com --headless):
##   Godot --path . -s tools/capturar_telas.gd -- <pasta_de_saida> [tela1,tela2,...]
## Sem lista, captura todas. Telas: hub, hub-cap5-recorde, hub-cap5-chefe, hub-cap5-primeira, hub-cap1/3/4-concluido, retomar, retomar-revive-usado, retomar-confirmar, estojo, loja, missoes, config, recompensa, compra,
## stats, dica-gotas, canetas, hud-vida, hud, roleta, pausa, descanso, derrota, vitoria, revive.
##
## Usa um save fictício, mas alguns eventos gravam o save do PC
## (%APPDATA%\Godot\app_userdata\SketchBlade\save_data.json): faça backup antes.

var _sv: SubViewport
var _saida := "C:/Users/joalh/Documentos/Sketch Blade - loja/revisao-telas"
var _telas: PackedStringArray = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_saida = args[0]
	if args.size() > 1:
		_telas = args[1].split(",")
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _quer(nome: String) -> bool:
	return _telas.is_empty() or _telas.has(nome)

func _save(cap: int) -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = 640; d["clipes_ouro"] = 40; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = 5; d["capitulo_selecionado"] = cap
	d["nivel_dano"] = 4; d["nivel_hp"] = 4; d["nivel_cadencia"] = 4
	d["canetas_possuidas"] = ["bic_azul", "lapis_hb"]; d["caneta_equipada"] = "bic_azul"; d["tutorial_visto"] = true
	d["dica_gotas_vista"] = true
	var hoje := Time.get_date_string_from_system()
	d["ultimo_login"] = hoje; d["dia_streak"] = 3; d["recompensa_coletada_hoje"] = true
	d["run_snapshot"] = {"ativa": false}
	# Missões: uma completa (para coletar), uma recebida, uma em andamento.
	d["stats"]["monstros_derrotados"] = 100
	d["stats"]["paginas_perfeitas"] = 1
	d["stats"]["tinta_coletada_total"] = 300
	d["data_missoes"] = hoje
	d["missoes_dia"] = [
		{"id": "matador", "base": 50, "coletada": false},
		{"id": "perfeccionista", "base": 0, "coletada": false},
		{"id": "colecionador", "base": 0, "coletada": true},
	]

func SaveManager_dados() -> Dictionary:
	return root.get_node("SaveManager").dados

func _abrir(c: String) -> Node:
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var n: Node = load(c).instantiate(); _sv.add_child(n); return n

func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[capturar_telas] ", nome)

func _fechar() -> void:
	paused = false; Engine.time_scale = 1.0
	_sv.queue_free(); await process_frame; await process_frame

func _hub(nome: String, acao: Callable, cap: int = 1, recorde: int = -1) -> void:
	if not _quer(nome):
		return
	_save(cap)
	if recorde >= 0:
		root.get_node("SaveManager").dados["stats"]["melhor_pagina"] = {str(cap): recorde}
	var hub = _abrir("res://hub.tscn"); await create_timer(1.5).timeout
	acao.call(hub); await create_timer(0.8).timeout
	await _foto(nome); await _fechar()

## Abre o combate já em andamento (tela inicial escondida, como no jogo real).
func _combate() -> Node:
	_save(1)
	var m = _abrir("res://main.tscn"); await create_timer(1.0).timeout
	# Como no jogo real: o rótulo da página já está na tela ao fim da partida
	m.label_pagina.text = "Página 8 / 8"; m.label_pagina.visible = true
	m.player.invencivel = true
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	return m

func _rodar() -> void:
	await process_frame
	await _hub("hub", func(_h): pass)
	# Hub novo (rascunho do amigo): capítulo 5 não vencido, com recorde e 1ª vez
	await _hub("hub-cap5-recorde", func(_h): pass, 5, 6)
	await _hub("hub-cap5-chefe", func(_h): pass, 5, 8)
	await _hub("hub-cap5-primeira", func(_h): pass, 5, 0)
	# Concluído: capítulos vencidos (cap < capitulo_desbloqueado = 5)
	for c in [1, 3, 4]:
		await _hub("hub-cap%d-concluido" % c, func(_h): pass, c, 8)
	# Retomar partida (capítulo 5, página 4): reviver disponível e já usado
	for usado in [false, true]:
		await _hub("retomar" + ("-revive-usado" if usado else ""), func(h):
			SaveManager_dados()["run_snapshot"] = {"ativa": true, "capitulo": 5, "pagina": 4, "hp": 3,
				"tinta_partida": 120, "upgrades": {"tiro_duplo": 1}, "revive_usado": usado}
			h._mostrar_prompt_retomar_run(), 5, 6)
	await _hub("retomar-confirmar", func(h):
		SaveManager_dados()["run_snapshot"] = {"ativa": true, "capitulo": 5, "pagina": 4, "hp": 3,
			"tinta_partida": 120, "upgrades": {"tiro_duplo": 1}, "revive_usado": false}
		h._mostrar_prompt_retomar_run()
		h._confirmar_abandono(h.get_node("HUD/PromptRetomarRun"), load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")), 5, 6)
	await _hub("estojo", func(h): h._alterar_aba("estojo"))
	await _hub("loja", func(h): h._alterar_aba("loja"))
	await _hub("missoes", func(h): h._abrir_painel_missoes())
	await _hub("config", func(h): h._abrir_painel_config())
	# Painel "Stats de teste" com vitórias/derrotas e páginas em que perdeu
	await _hub("stats", func(h):
		var st: Dictionary = SaveManager_dados()["stats"]
		st["por_capitulo"] = {"1": [3, 1, 0], "2": [2, 4, 1], "3": [1, 7, 2]}
		st["mortes_pagina"] = {"1": {"5": 1}, "2": {"3": 1, "6": 2, "8": 1}, "3": {"4": 5, "8": 2}}
		h._abrir_painel_stats())
	await _hub("recompensa", func(h): h._mostrar_popup_recompensa_diaria(3))
	await _hub("compra", func(h): h._abrir_popup_compra("clipes"))

	if _quer("dica-gotas"):
		# Primeira gota de tinta da conta: círculo na gota + dica
		var m = await _combate()
		SaveManager_dados()["dica_gotas_vista"] = false
		m.player.attack_timer.start()
		m.wave_manager.iniciar_fase_na_pagina(1, 1); await create_timer(2.5).timeout
		m._on_enemy_morreu(Vector2(620, 820), Color.BLACK, "res://assets/ink.svg")
		await create_timer(0.9).timeout; await _foto("dica-gotas"); await _fechar()
	if _quer("canetas"):
		# Cada caneta da loja parada (gotinha da ponta visível)
		for id in ["bic_azul", "lapis_hb", "nanquim", "gel_vermelha", "nanquim_real"]:
			_save(1)
			SaveManager_dados()["caneta_equipada"] = id
			SaveManager_dados()["canetas_possuidas"] = [id]
			var m = _abrir("res://main.tscn"); await create_timer(1.0).timeout
			m.player.invencivel = true
			m.jogo_iniciado = true; m.menu_iniciar.visible = false
			await create_timer(0.6).timeout
			await _foto("caneta-" + id); await _fechar()
	if _quer("hud-vida"):
		# Barra de vida riscada com 3 de 8 e com 1 de 8
		var m = await _combate()
		for v in [3, 1]:
			m.player.vidas = v; m._atualizar_hud(); await create_timer(0.3).timeout
			await _foto("hud-vida-%d" % v)
		await _fechar()
	if _quer("hud"):
		var m = await _combate()
		for id in ["tiro_duplo", "leque"]: m.player.aplicar_upgrade(id)
		m.player.attack_timer.start()
		m.wave_manager.iniciar_fase_na_pagina(1, 2); await create_timer(5.0).timeout
		await _foto("hud"); await _fechar()
	if _quer("roleta"):
		var m = await _combate()
		m.player.aplicar_upgrade("tiro_duplo")
		m._abrir_roleta_upgrades(); await create_timer(7.0).timeout
		await _foto("roleta"); await _fechar()
	if _quer("pausa"):
		var m = await _combate()
		for id in ["tiro_duplo", "leque", "ricochete"]: m.player.aplicar_upgrade(id)
		m._on_botao_pausa_pressed(); await create_timer(0.8).timeout
		await _foto("pausa"); await _fechar()
	if _quer("descanso"):
		var m = await _combate()
		m._on_descanso_iniciado(); await create_timer(1.5).timeout
		await _foto("descanso"); await _fechar()
	if _quer("derrota"):
		# [nome, capítulo, página onde caiu, recorde antes]
		for caso in [["derrota-cap5-pagina6", 5, 6, 7], ["derrota-cap5-chefe-recorde", 5, 8, 6],
				["derrota-cap1-primeira", 1, 3, 0]]:
			var m = await _combate()
			SaveManager_dados()["stats"]["melhor_pagina"] = {str(caso[1]): caso[3]}
			m.capitulo_atual = caso[1]; m.wave_manager.pagina_atual = caso[2]
			m.tinta_partida = 180; m.monstros_derrotados_partida = 23
			m._processar_fim_de_jogo(false); m.menu_game_over.visible = true
			if caso[0] == "derrota-cap5-pagina6":
				await create_timer(0.35).timeout; await _foto("derrota-cap5-animando")
			await create_timer(2.0).timeout; await _foto(caso[0])
			if caso[0] == "derrota-cap5-pagina6":
				# Anúncio assistido (recompensa confirmada): "Bônus recebido ✓" e total 2x
				m._executar_dobro_tinta(); await create_timer(0.3).timeout
				await _foto("derrota-cap5-bonus")
			await _fechar()
	if _quer("vitoria"):
		# Capítulo 5 (nome curto) e 9 (nome longo no selo)
		for cap in [5, 9]:
			var m = await _combate()
			m.capitulo_atual = cap
			m.tinta_partida = 420; m.monstros_derrotados_partida = 40; m.boss_derrotado_partida = true
			m._processar_fim_de_jogo(true); m.menu_vitoria.visible = true
			await create_timer(0.35).timeout; await _foto("vitoria-cap%d-animando" % cap)
			await create_timer(2.0).timeout; await _foto("vitoria-cap%d" % cap)
			if cap == 5:
				# Anúncio assistido (recompensa confirmada): "Bônus recebido ✓" e total 2x
				m._executar_dobro_tinta(); await create_timer(0.3).timeout
				await _foto("vitoria-cap5-bonus")
			await _fechar()
		# Toque durante a animação: pula direto para o fim
		var mp = await _combate()
		mp.capitulo_atual = 3
		mp.tinta_partida = 420; mp.monstros_derrotados_partida = 40; mp.boss_derrotado_partida = true
		mp._processar_fim_de_jogo(true); mp.menu_vitoria.visible = true
		await create_timer(0.2).timeout
		mp.tela_vitoria._finalizar_animacao(); await create_timer(0.1).timeout
		await _foto("vitoria-cap3-pulada"); await _fechar()
	if _quer("revive-fluxo"):
		# Desistir leva à página arruinada; continuar (anúncio simulado) volta com 3 corações
		root.get_node("AdsManager").revive_usado_na_run = false
		var m = await _combate()
		m.wave_manager.pagina_atual = 6
		m._on_player_morreu(); await create_timer(1.5).timeout
		m.tela_reviver.voltar_pressionado.emit(); await create_timer(1.0).timeout
		print("[capturar_telas] desistir -> derrota visivel: ", m.menu_game_over.visible)
		await _foto("revive-desistir"); await _fechar()
		root.get_node("AdsManager").revive_usado_na_run = false
		var m2 = await _combate()
		m2.wave_manager.pagina_atual = 6
		m2._on_player_morreu(); await create_timer(1.5).timeout
		m2.tela_reviver._btn_anuncio.pressed.emit(); await create_timer(4.0).timeout
		print("[capturar_telas] continuar -> menu visivel: ", m2.menu_revive.visible, " vidas: ", m2.player.vidas, " pausado: ", paused)
		await _foto("revive-continuar"); await _fechar()
	if _quer("revive"):
		# A caneta perde o último coração na página 6 (versões A e B)
		for versao in ["a", "b"]:
			root.get_node("AdsManager").revive_usado_na_run = false
			var m = await _combate()
			m.wave_manager.pagina_atual = 6
			m.tela_reviver.anuncio_principal = versao == "a"
			m._on_player_morreu()
			if versao == "a":
				await create_timer(0.3).timeout; await _foto("revive-a-animando")
			await create_timer(1.3).timeout; await _foto("revive-" + versao); await _fechar()
	quit()
