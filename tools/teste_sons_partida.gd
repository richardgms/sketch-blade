extends SceneTree
## Toca os sons novos da partida sem tela (lote 2, docs/sons.md) e confere o
## coração da vida baixa. Faça backup do save antes (a partida grava checkpoint).
## Uso: Godot --headless --path . -s tools/teste_sons_partida.gd

var falhas := 0

func _ok(nome: String, cond: bool) -> void:
	print(("OK    " if cond else "FALHA ") + nome)
	if not cond:
		falhas += 1

func _initialize() -> void:
	_rodar()

func _rodar() -> void:
	var sm = root.get_node("SaveManager")
	sm.dados["som_ativo"] = true
	sm.dados["tutorial_visto"] = true
	sm.dados["run_snapshot"] = {"ativa": false}
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 5:
		await process_frame
	m._on_botao_jogar_pressed()
	await process_frame
	# coração lento: liga com 1 coração, desliga quando a vida sobe
	m.player.vidas = 1
	m._atualizar_hud()
	await process_frame
	_ok("coração toca com 1 coração", m._coracao_player.playing)
	m.player.vidas = 3
	m._atualizar_hud()
	await create_timer(1.0).timeout
	await process_frame
	_ok("coração para quando a vida sobe", not m._coracao_player.playing)
	# variações sem repetir a última
	var a = m._sortear("morte"); var b = m._sortear("morte")
	_ok("sorteio não repete a última", a != b)
	_ok("morte ficou com 6 variações", m.VARIACOES["morte"].size() == 6)
	# O krw acompanha o inchar antes do tiro; o mergulho mantém seu bipe.
	var chefe = load("res://boss.tscn").instantiate()
	m.add_child(chefe)
	chefe.set_process(false)
	chefe.entrada_concluida = true
	var sons_chefe: Array = []
	var observar_som := func(no: Node):
		if no is AudioStreamPlayer:
			sons_chefe.append(no.stream)
	m.child_entered_tree.connect(observar_som)
	chefe._avisar_leque()
	_ok("krw toca ao inchar antes do tiro", sons_chefe.count(m.SONS["krw"]) == 1)
	sons_chefe.clear()
	chefe.timer_tiro = 0.0
	chefe.timer_acao = chefe.intervalo_mergulho
	chefe._processar_patrulha(0.0)
	_ok("mergulho avisa sem usar krw", sons_chefe.size() == 1 and not sons_chefe.has(m.SONS["krw"]))
	m.child_entered_tree.disconnect(observar_som)
	chefe.queue_free()
	# momentos (só não podem dar erro)
	m._on_ink_drop_coletada(1)
	m._tocar_som(m._sortear("dano"))
	m._tocar_som_clunk()
	m.tocar_rosnado_ataque(true)
	m.tocar_tiro_chefe()
	m._on_descanso_escolhido("curar")
	m._on_descanso_escolhido("tinta")
	m._on_botao_pausa_pressed()
	await process_frame
	m._on_retomar_pausa_pressed()
	await create_timer(4.5, true, false, true).timeout
	_ok("contagem terminou e despausou", not paused)
	print("RESULTADO: %d falha(s)" % falhas)
	quit(1 if falhas > 0 else 0)
