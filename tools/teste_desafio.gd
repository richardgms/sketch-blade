extends SceneTree
## Teste do desafio do dia: Hub (bilhete e prova), as 4 regras montando a
## partida certa, prêmio 1x/dia, vistos e bônus, sem mexer na partida guardada.
## Uso (com janela e backup do save do PC):
##   Godot --path . -s tools/teste_desafio.gd -- <pasta_dos_prints>
var _sv: SubViewport
var _saida := "C:/Users/joalh/Documentos/Sketch Blade/design/desafio-do-dia/teste"
var _falhas := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_saida = a[0]
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _sm() -> Node:
	return root.get_node("SaveManager")

func _confere(nome: String, obtido, esperado) -> void:
	if obtido != esperado:
		_falhas += 1
	print("[teste_desafio] %s: %s (esperado %s) %s" % [nome, obtido, esperado, "OK" if obtido == esperado else "FALHOU"])

func _abrir(c: String) -> Node:
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var n: Node = load(c).instantiate(); _sv.add_child(n); return n

func _foto(n: String) -> void:
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, n])

func _fechar() -> void:
	paused = false
	_sv.queue_free(); await process_frame; await process_frame

func _base() -> void:
	var d: Dictionary = _sm().dados
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true; d["novidades_vistas"] = 9999
	d["avaliacao_pedida"] = 9999; d["capitulo_desbloqueado"] = 5; d["capitulo_selecionado"] = 3
	d["ultimo_login"] = Time.get_date_string_from_system()
	d["run_snapshot"] = {"ativa": false, "marca_teste": 1}

func _partida(regra: String) -> Node:
	_sm().desafio_pendente = regra
	var m := _abrir("res://main.tscn")
	await create_timer(1.6).timeout
	return m

func _rodar() -> void:
	await process_frame
	var hoje := Time.get_date_string_from_system()
	_base()
	_sm().dados["desafio_vencido_data"] = ""; _sm().dados["desafio_vistos"] = 2
	# Hub: bilhete e prova
	var h := _abrir("res://hub.tscn"); await create_timer(1.5).timeout
	_confere("bilhete no Hub", is_instance_valid(h.botao_desafio), true)
	await _foto("hub-bilhete")
	h._abrir_desafio(); await create_timer(0.6).timeout
	await _foto("hub-prova")
	await _fechar()
	# As 4 regras
	var m: Node
	m = await _partida("vidro")
	_confere("vidro: metade dos corações", m.player.vidas_max, int(ceil(m.get_node("/root/GameData").HP_POR_NIVEL[_sm().dados["nivel_hp"]] / 2.0)))
	_confere("vidro: tinta x3", m.mult_tinta, 3)
	_confere("desafio: 4 páginas", m.wave_manager.paginas.size(), 4)
	_confere("desafio: começou sozinho", m.jogo_iniciado, true)
	await _foto("partida-vidro")
	await _fechar()
	m = await _partida("chuva")
	m.player.invencivel = true
	await create_timer(3.5).timeout
	var caindo := 0
	for p in m.get_tree().get_nodes_in_group("enemy_projectiles"):
		if p.visible and p.estilo == "tinta":
			caindo += 1
	_confere("chuva: borrões caindo", caindo > 0, true)
	await _foto("partida-chuva")
	await _fechar()
	m = await _partida("ricochete")
	_confere("ricochete: começa com Ricochete", m.player.nivel_upgrade("ricochete"), 1)
	_confere("ricochete: sem duplo/leque na roleta", m._fora_da_roleta, ["tiro_duplo", "leque"])
	await _fechar()
	m = await _partida("turbinado")
	_confere("turbinado: só o chefe", m.wave_manager.paginas.size(), 1)
	_confere("turbinado: chefe +50%", m.wave_manager.mult_vida_chefe, 1.5)
	var ups := 0
	for k in m.player.upgrades:
		ups += m.player.upgrades[k]
	_confere("turbinado: 2 melhorias", ups, 2)
	await create_timer(3.5).timeout
	await _foto("partida-turbinado")
	# Vitória: prêmio, visto 3 = bônus e zera
	var tinta0: int = _sm().dados["tinta"]; var clipes0: int = _sm().dados["clipes_ouro"]
	m.boss_derrotado_partida = true
	m._processar_fim_de_jogo(true); m.menu_vitoria.visible = true
	await create_timer(2.5).timeout
	await _foto("vitoria-prova")
	_confere("venceu: data", _sm().dados["desafio_vencido_data"], hoje)
	_confere("venceu: clipes (3 + 5 do 3º visto)", _sm().dados["clipes_ouro"] - clipes0 >= 8, true)
	_confere("venceu: cartela zerou", int(_sm().dados["desafio_vistos"]), 0)
	_confere("venceu: tinta do prêmio", _sm().dados["tinta"] - tinta0 >= 150, true)
	_confere("não desbloqueou capítulo", int(_sm().dados["capitulo_desbloqueado"]), 5)
	_confere("partida guardada intacta", _sm().dados["run_snapshot"].get("marca_teste", 0), 1)
	await _fechar()
	# Segunda vitória no mesmo dia: sem prêmio
	m = await _partida("vidro")
	clipes0 = _sm().dados["clipes_ouro"]
	m._processar_fim_de_jogo(true)
	_confere("refez: sem prêmio", _sm().dados["clipes_ouro"] - clipes0 < 3, true)
	m._finalizar_derrota()
	m._on_fase_concluida()
	_confere("derrota/vitória não apagam a partida guardada", _sm().dados["run_snapshot"].get("marca_teste", 0), 1)
	await _fechar()
	# Hub depois de vencer: VISTO no bilhete
	h = _abrir("res://hub.tscn"); await create_timer(1.5).timeout
	await _foto("hub-vencido")
	h._abrir_desafio(); await create_timer(0.6).timeout
	await _foto("hub-prova-vencida")
	await _fechar()
	print("[teste_desafio] falhas: ", _falhas)
	quit()
