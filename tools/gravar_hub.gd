extends SceneTree
## Grava o áudio real da música do hub: hub parado, LUTAR, tela antes da partida,
## COMEÇAR e o começo da partida (a música do hub desce e a da partida entra).
## Uso (Movie Maker; faça backup do save, o hub grava no save):
##   Godot --path . --write-movie <saida.avi> --fixed-fps 60 --resolution 540x960 \
##     -s tools/gravar_hub.gd -- [hub.ogg alternativo]
## Roteiro: 0 s hub · 22 s LUTAR · 30 s COMEÇAR · 42 s fim.

const T_LUTAR := 22.0
const T_COMECAR := 30.0
const T_FIM := 42.0

func _initialize() -> void:
	_rodar()

func _rodar() -> void:
	await process_frame
	var a := OS.get_cmdline_user_args()
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}; d["som_ativo"] = true
	if a.size() > 0:
		root.get_node("Musica").hub_trocar_arquivo(a[0])
		print("[gravar_hub] hub alternativo: ", a[0])
	change_scene_to_file("res://hub.tscn")
	var t := 0.0
	var lutou := false
	var comecou := false
	while t < T_FIM:
		await process_frame
		t += 1.0 / 60.0
		if not lutou and t >= T_LUTAR:
			lutou = true
			current_scene._on_botao_jogar_pressed()
			print("[gravar_hub] LUTAR em %.1f s" % t)
		if not comecou and t >= T_COMECAR and current_scene and current_scene.has_method("_on_enemy_morreu"):
			comecou = true
			current_scene._on_botao_jogar_pressed()
			current_scene.player.invencivel = true
			print("[gravar_hub] COMEÇAR em %.1f s" % t)
		if comecou and is_instance_valid(current_scene) and current_scene.get("player"):
			current_scene.player.invencivel = true
	quit()
