extends SceneTree
## Grava a passagem página 3 → descanso (página 4) → roleta → página 5 com o
## áudio e a imagem reais do jogo, para ouvir a música do descanso e ver as
## viradas de página.
## Uso (Movie Maker; faça backup do save, a partida grava checkpoint):
##   Godot --path . --write-movie <saida.avi> --fixed-fps 60 --resolution 540x960 \
##     -s tools/gravar_descanso.gd -- [antes]
## "antes" = como era: música do combate no descanso, descanso abrindo junto com a
## virada "Página 4" (que passava depois da roleta) e trilha sem o selo do descanso.

const Y_CANETA := 1700.0
const ESPERA_DESCANSO := 3.0 # jogador rápido
const ESPERA_ROLETA := 3.0
const DEPOIS_PAGINA_5 := 9.0

func _initialize() -> void:
	_rodar()

func _rodar() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	seed(20261107)
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}; d["som_ativo"] = true
	d["capitulo_selecionado"] = 2
	if a.has("antes"):
		root.get_node("Musica").descanso_calmo = false
		preload("res://TrilhaPaginas.gd").selo_descanso = false
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if a.has("antes"):
		m.wave_manager.virada_antes_do_descanso = false
	for i in 5: await process_frame
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.player.invencivel = true
	m.player.position = Vector2(540, Y_CANETA)
	m.player.mover_para(Vector2(540, Y_CANETA))
	m.player.attack_timer.start()
	m.wave_manager.iniciar_fase_na_pagina(m.capitulo_atual, 3)
	var t := 0.0
	var t_descanso := -1.0
	var t_roleta := -1.0
	var t_p5 := -1.0
	var limpa := 0.0
	while t < 90.0:
		await process_frame
		t += 1.0 / 60.0
		m.player.invencivel = true
		limpa -= 1.0 / 60.0
		if limpa <= 0.0 and not root.get_tree().paused:
			limpa = 0.4
			for n in m.get_children():
				if n.has_method("morrer") and not n.has_method("dano_compartilhado") and n.position.y > 350.0:
					n.morrer()
		if t_descanso < 0.0 and m.menu_descanso.visible:
			t_descanso = t
			print("[gravar_descanso] descanso abriu em %.1f s" % t)
		if t_descanso >= 0.0 and t_roleta < 0.0 and m.menu_descanso.visible and t - t_descanso > ESPERA_DESCANSO:
			m._on_descanso_escolhido("curar")
		if t_roleta < 0.0 and m.menu_upgrades.visible and t_descanso >= 0.0:
			t_roleta = t
			print("[gravar_descanso] roleta abriu em %.1f s" % t)
		if t_roleta >= 0.0 and t_p5 < 0.0 and m.menu_upgrades.visible and t - t_roleta > ESPERA_ROLETA:
			m._aplicar_upgrade(m.opcoes_roleta[0]["id"], 0)
		if t_p5 < 0.0 and m.wave_manager.pagina_atual == 5:
			t_p5 = t
			print("[gravar_descanso] página 5 em %.1f s" % t)
		if t_p5 >= 0.0 and t - t_p5 > DEPOIS_PAGINA_5:
			break
	quit()
