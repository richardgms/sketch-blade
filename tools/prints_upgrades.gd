extends SceneTree
## Prints dos efeitos dos upgrades (escudo, borrão, corrosiva) em combate real.
## Uso (com janela): Godot --path . -s tools/prints_upgrades.gd -- <pasta> [casos]
## casos: escudo,borrao,corrosiva (padrão: todos); estilos: A,B,C (sufixo do arquivo). Salva o quadro inteiro e um
## recorte ampliado (zoom-*.png) em volta do efeito.
## Grava o save do PC em alguns eventos: faça backup antes e restaure depois.

var _saida := "C:/Users/joalh/Documentos/Sketch Blade - design/upgrades/prints"
var _sv: SubViewport
var _casos := ["escudo", "borrao", "corrosiva"]
var _sufixo := ""
var _estilos := ["A", "B", "C"]
var _gif := true

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_saida = args[0]
	if args.size() > 1:
		_casos = Array(args[1].split(","))
	if args.size() > 2:
		_estilos = Array(args[2].split(","))
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	for e in _estilos:
		ExplosaoBorrao.estilo = e
		_sufixo = "-" + e
		if "escudo" in _casos:
			await _escudo()
		if "borrao" in _casos:
			await _borrao()
		if "corrosiva" in _casos:
			await _corrosiva()
	print("[prints_upgrades] pronto em: ", _saida)
	quit()

func _preparar_save(capitulo: int) -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["capitulo_desbloqueado"] = 5
	d["capitulo_selecionado"] = capitulo
	d["nivel_dano"] = 4
	d["nivel_hp"] = 4
	d["nivel_cadencia"] = 4
	d["caneta_equipada"] = "bic_azul"
	d["tutorial_visto"] = true
	d["recompensa_coletada_hoje"] = true
	d["run_snapshot"] = {"ativa": false}
	root.get_node("SaveManager").retomar_run_pendente = false

func _abrir(capitulo: int, pagina: int, upgrades: Array, atirar: bool) -> Node:
	_preparar_save(capitulo)
	_sv = SubViewport.new()
	_sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var main: Node = load("res://main.tscn").instantiate()
	_sv.add_child(main)
	await create_timer(0.5).timeout
	main.player.invencivel = true
	for id in upgrades:
		main.player.aplicar_upgrade(id)
	main.player.position = Vector2(540, 1700)
	main.player.mover_para(Vector2(540, 1700))
	main.jogo_iniciado = true
	main.menu_iniciar.visible = false
	if atirar:
		main.player.attack_timer.start()
	main.wave_manager.iniciar_fase_na_pagina(capitulo, pagina)
	return main

func _foto(nome: String, centro: Vector2, lado: int = 560) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = _sv.get_texture().get_image()
	nome += _sufixo
	img.save_png("%s/%s.png" % [_saida, nome])
	var x := clampi(int(centro.x) - lado / 2, 0, 1080 - lado)
	var y := clampi(int(centro.y) - lado / 2, 0, 1920 - lado)
	img.get_region(Rect2i(x, y, lado, lado)).save_png("%s/zoom-%s.png" % [_saida, nome])
	print("[prints_upgrades] ", nome)

func _fechar() -> void:
	paused = false
	Engine.time_scale = 1.0
	_sv.queue_free()
	await process_frame
	await process_frame

func _escudo() -> void:
	var main := await _abrir(3, 5, ["escudo_borracha", "escudo_borracha", "escudo_borracha"], false)
	var p: Node2D = main.player
	await create_timer(1.5).timeout
	await _foto("escudo-1-ativo", p.global_position)
	p.invencivel = false
	p.receber_dano(1)
	p.invencivel = true
	await create_timer(0.05).timeout
	await _foto("escudo-2-quebra", p.global_position)
	await create_timer(0.15).timeout
	await _foto("escudo-3-quebra", p.global_position)
	await create_timer(1.6).timeout
	await _foto("escudo-4-recarga", p.global_position)
	await create_timer(2.5).timeout
	await _foto("escudo-5-voltou", p.global_position)
	await _fechar()

## Inimigo vivo e já em jogo que tenha outro perto (para a explosão pegar).
func _alvo_com_vizinho(main: Node) -> Node2D:
	var vivos: Array = main.get_tree().get_nodes_in_group("enemies").filter(
		func(e): return not e.is_queued_for_deletion() and e.get("entrada_concluida") == true and e.global_position.y > 200)
	for e in vivos:
		for o in vivos:
			if o != e and e.global_position.distance_to(o.global_position) < 260.0:
				return e
	return vivos[0] if not vivos.is_empty() else null

func _borrao() -> void:
	var main := await _abrir(3, 7, ["borrao_explosivo", "borrao_explosivo", "borrao_explosivo"], false)
	var alvo: Node2D = null
	for i in 40:
		await create_timer(0.25).timeout
		alvo = _alvo_com_vizinho(main)
		if alvo and main.get_tree().get_nodes_in_group("enemies").size() >= 4:
			break
	if alvo == null:
		push_error("sem alvo para o borrão")
		await _fechar()
		return
	var pos := alvo.global_position
	alvo.receber_dano(99999)
	await create_timer(0.04).timeout
	await _foto("borrao-1", pos, 640)
	await create_timer(0.1).timeout
	await _foto("borrao-2", pos, 640)
	await create_timer(0.18).timeout
	await _foto("borrao-3", pos, 640)
	await _fechar()

func _corrosiva() -> void:
	await _corrosiva_em(3, 5, "corrosiva", 320)
	await _corrosiva_em(1, 8, "corrosiva-chefe", 640)

func _corrosiva_em(cap: int, pag: int, nome: String, lado: int) -> void:
	var main := await _abrir(cap, pag, ["tinta_corrosiva", "tinta_corrosiva", "tinta_corrosiva"], true)
	if nome == "corrosiva":
		main.player.dano = 4 # o monstro dura mais na tela para o GIF
	for i in 3:
		var alvo: Node2D = null
		for tentativa in 40:
			await create_timer(0.35 if tentativa == 0 else 0.2).timeout
			for e in main.get_tree().get_nodes_in_group("enemies"):
				if e.get("dot_restante") != null and e.dot_restante > 0.0 and not e.is_queued_for_deletion() and e.global_position.y < 1350.0:
					alvo = e
					break
			if alvo:
				break
		await _foto("%s-%d" % [nome, i + 1], alvo.global_position if alvo else Vector2(540, 700), lado)
		if i == 0 and alvo and _gif:
			# Sequência para GIF: recorte acompanhando o monstro, ~15 quadros/s
			DirAccess.make_dir_recursive_absolute(_saida + "/gif-" + nome + _sufixo)
			for q in 36:
				if not is_instance_valid(alvo):
					break
				await RenderingServer.frame_post_draw
				var img: Image = _sv.get_texture().get_image()
				var c := alvo.global_position
				var x := clampi(int(c.x) - lado / 2, 0, 1080 - lado)
				var y := clampi(int(c.y) - lado / 2, 0, 1920 - lado)
				img.get_region(Rect2i(x, y, lado, lado)).save_png("%s/gif-%s%s/%03d.png" % [_saida, nome, _sufixo, q])
				await create_timer(0.066).timeout
	await _fechar()
