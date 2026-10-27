extends SceneTree
## Fotografa as telas de menu e HUD para revisão visual (1080x1920).
##
## Uso (precisa de janela, não roda com --headless):
##   Godot --path . -s tools/capturar_telas.gd -- <pasta_de_saida> [tela1,tela2,...]
## Sem lista, captura todas. Telas: hub, missoes, config, recompensa, compra,
## hud, roleta, pausa, descanso, derrota, vitoria, revive.
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
	d["canetas_possuidas"] = ["bic_azul", "lapis_hb"]; d["tutorial_visto"] = true
	var hoje := Time.get_date_string_from_system()
	d["ultimo_login"] = hoje; d["dia_streak"] = 3; d["recompensa_coletada_hoje"] = true
	d["run_snapshot"] = {"ativa": false}
	# Missões: uma completa (para coletar), uma recebida, uma em andamento.
	d["stats"]["monstros_derrotados"] = 100
	d["stats"]["paginas_perfeitas"] = 1
	d["stats"]["tinta_coletada_total"] = 120
	d["data_missoes"] = hoje
	d["missoes_dia"] = [
		{"id": "matador", "base": 50, "coletada": false},
		{"id": "perfeccionista", "base": 0, "coletada": false},
		{"id": "colecionador", "base": 0, "coletada": false},
	]

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

func _hub(nome: String, acao: Callable) -> void:
	if not _quer(nome):
		return
	_save(1)
	var hub = _abrir("res://hub.tscn"); await create_timer(1.5).timeout
	acao.call(hub); await create_timer(0.8).timeout
	await _foto(nome); await _fechar()

## Abre o combate já em andamento (tela inicial escondida, como no jogo real).
func _combate() -> Node:
	_save(1)
	var m = _abrir("res://main.tscn"); await create_timer(1.0).timeout
	m.player.invencivel = true
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	return m

func _rodar() -> void:
	await process_frame
	await _hub("hub", func(_h): pass)
	await _hub("missoes", func(h): h._abrir_painel_missoes())
	await _hub("config", func(h): h._abrir_painel_config())
	await _hub("recompensa", func(h): h._mostrar_popup_recompensa_diaria(3))
	await _hub("compra", func(h): h._abrir_popup_compra("clipes"))

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
		var m = await _combate()
		m.tinta_partida = 180; m.monstros_derrotados_partida = 23
		m._processar_fim_de_jogo(false); m.menu_game_over.visible = true
		await create_timer(0.8).timeout; await _foto("derrota"); await _fechar()
	if _quer("vitoria"):
		var m = await _combate()
		m.tinta_partida = 420; m.monstros_derrotados_partida = 40; m.boss_derrotado_partida = true
		m._processar_fim_de_jogo(true); m.menu_vitoria.visible = true
		await create_timer(0.8).timeout; await _foto("vitoria"); await _fechar()
	if _quer("revive"):
		var m = await _combate()
		m.menu_revive.visible = true; await create_timer(0.5).timeout
		await _foto("revive"); await _fechar()
	quit()
