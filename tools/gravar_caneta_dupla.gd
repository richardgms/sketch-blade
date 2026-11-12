extends SceneTree
## Grava as 5 canetas atirando: cada uma ~1,5 s sem upgrade e ~4 s com o Tiro
## Duplo (caneta de duas pontas, tiro que nasce em cada ponta e abre até a faixa).
## Uso (Movie Maker; faça backup do save, a partida grava checkpoint):
##   Godot --path . --write-movie <saida.avi> --fixed-fps 60 --resolution 540x960 \
##     -s tools/gravar_caneta_dupla.gd
## Sem --write-movie serve de teste rápido: imprime as pontas detectadas de cada caneta.

const Y_CANETA := 1720.0
const CANETAS := ["bic_azul", "lapis_hb", "nanquim", "gel_vermelha", "nanquim_real"]
const ICONES := {
	"bic_azul": "res://assets/bic-azul.svg", "lapis_hb": "res://assets/lapis-hb.svg",
	"nanquim": "res://assets/nanquim.svg", "gel_vermelha": "res://assets/gel-vermelha.svg",
	"nanquim_real": "res://assets/nanquim-real.svg",
}
const T_NORMAL := 1.5
const T_DUPLO := 4.0

var m

func _initialize() -> void:
	_rodar()

func _esperar(seg: float) -> void:
	var t := 0.0
	while t < seg:
		await process_frame
		t += 1.0 / 60.0
		m.player.invencivel = true
		m.player.vidas = m.player.vidas_max

func _rodar() -> void:
	await process_frame
	seed(20261112)
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}
	d["nivel_dano"] = 2; d["nivel_hp"] = 9; d["nivel_cadencia"] = 6
	d["caneta_equipada"] = "bic_azul"; d["som_ativo"] = true
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 5: await process_frame
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.capitulo_atual = 1
	m.player.position = Vector2(540, Y_CANETA)
	m.player.mover_para(Vector2(540, Y_CANETA))
	m.player.attack_timer.start()
	m.wave_manager.iniciar_fase_na_pagina(1, 1)
	var gd = root.get_node("GameData")
	for id in CANETAS:
		var c: Dictionary = gd.get_caneta(id)
		m.player.cor_caneta = Color(c["cor_corpo"])
		m.player.cor_projetil = Color(c["cor_projetil"])
		m.player.textura_caneta = load(ICONES[id])
		m.player.textura_caneta_dupla = load("res://assets/canetas_duplas/%s.png" % id)
		print("[caneta_dupla] %s pontas %s" % [id, str(m.player._pontas_duplas)])
		m.player.upgrades.erase("tiro_duplo")
		await _esperar(T_NORMAL)
		m.player.aplicar_upgrade("tiro_duplo")
		await _esperar(T_DUPLO)
	quit()
