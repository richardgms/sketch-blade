extends SceneTree
## Grava o ambiente sonoro de uma luta de chefe com o áudio real do jogo
## (música adaptativa, tiros, acertos, dano, vida crítica, vitória), para ouvir
## a mistura antes do build. O robô "segue" persegue o chefe atirando.
## Uso (Movie Maker; faça backup do save, a partida grava checkpoint):
##   Godot --path . --write-movie <saida.avi> --fixed-fps 60 --resolution 540x960 \
##     -s tools/gravar_ambiente.gd -- [cap] [coracao.ogg alternativo]
## Roteiro: chefe surge → luta com 3 corações → 2 danos (12 s e 15 s) → vida
## crítica até 40 s → chefe cai → jingle de vitória.

const Y_CANETA := 1700.0
const T_DANO := [12.0, 15.0]
const T_DERRUBAR := 40.0
const T_FIM_DEPOIS := 7.0

var m
var boss

func _initialize() -> void:
	_rodar()

func _rodar() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var cap: int = int(a[0]) if a.size() > 0 else 10
	seed(20261106)
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}
	d["nivel_dano"] = 9; d["nivel_hp"] = 9; d["nivel_cadencia"] = 9
	d["caneta_equipada"] = "bic_azul"; d["som_ativo"] = true
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 5: await process_frame
	if a.size() > 1:
		var alt := AudioStreamOggVorbis.load_from_file(a[1])
		alt.loop = true
		m._coracao_player.stream = alt
		print("[gravar_ambiente] coração alternativo: ", a[1])
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.capitulo_atual = cap
	for up in ["tiro_duplo", "leque"]:
		m.player.aplicar_upgrade(up)
	m.player.vidas = 3
	m.player.invencivel = true
	m.player.position = Vector2(540, Y_CANETA)
	m.player.mover_para(Vector2(540, Y_CANETA))
	m.player.attack_timer.start()
	m.wave_manager.iniciar_fase_na_pagina(cap, root.get_node("GameData").PAGINAS.size())
	while boss == null:
		await process_frame
		for n in m.get_children():
			if n.has_method("dano_compartilhado"):
				boss = n
	var t := 0.0
	var danos := T_DANO.duplicate()
	var derrubado := false
	var fim := -1.0
	var decide := 0.0
	while true:
		await process_frame
		t += 1.0 / 60.0
		decide -= 1.0 / 60.0
		m.player.invencivel = true # o fim das piscadas do dano desliga; o roteiro manda
		if decide <= 0.0 and is_instance_valid(boss):
			decide = 0.15
			m.player.mover_para(Vector2(clampf(boss.global_position.x, 60.0, 1020.0), Y_CANETA))
		if not danos.is_empty() and t >= danos[0]:
			danos.pop_front()
			m.player.invencivel = false
			m.player.receber_dano(1)
			m.player.invencivel = true
			print("[gravar_ambiente] dano em %.1f s, vidas %d" % [t, m.player.vidas])
		if not derrubado and t >= T_DERRUBAR and is_instance_valid(boss):
			derrubado = true
			boss.hp = 1
			print("[gravar_ambiente] chefe por um fio em %.1f s" % t)
		if fim < 0.0 and m.fim_de_jogo_declarado:
			fim = t
			print("[gravar_ambiente] fim da luta em %.1f s" % t)
		if fim >= 0.0 and t - fim > T_FIM_DEPOIS:
			break
		if t > 90.0:
			print("[gravar_ambiente] tempo esgotado")
			break
	quit()
