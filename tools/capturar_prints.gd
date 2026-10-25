extends SceneTree
## Gera os prints da Play Store (1080x1920, 9:16) rodando as cenas reais do jogo
## dentro de um SubViewport e salvando o quadro em PNG.
##
## Uso (precisa de janela, não roda com --headless):
##   Godot --path . -s tools/capturar_prints.gd -- <pasta_de_saida>
##
## Usa um save fictício em memória, mas alguns eventos do jogo gravam o save do PC
## (%APPDATA%\Godot\app_userdata\SketchBlade\save_data.json). Faça backup desse
## arquivo antes e restaure depois.

const TAM := Vector2i(1080, 1920)
const PASTA_PADRAO := "C:/Users/joalh/Documentos/Sketch Blade - loja/prints-gerados"

var _saida: String = PASTA_PADRAO
var _sv: SubViewport

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_saida = args[0]
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _rodar() -> void:
	await process_frame
	await _combate("01-combate-horda", 3, 7, ["tiro_duplo", "leque", "ricochete"], 9.0)
	await _combate("02-combate-elite", 4, 6, ["tiro_duplo", "tiro_perfurante", "tinta_corrosiva"], 11.0)
	await _roleta("03-roleta-upgrades", 2)
	await _combate("04-boss", 5, 8, ["tiro_duplo", "leque", "ponta_critica", "escudo_borracha"], 8.0)
	await _hub("05-menu-capitulo", "lutar", 4)
	await _hub("06-estojo", "estojo", 4)
	await _hub("07-loja-canetas", "loja", 4)
	print("[capturar_prints] pronto em: ", _saida)
	quit()

# ------------------------------------------------------------------
# Save fictício, só em memória
# ------------------------------------------------------------------
func _preparar_save(capitulo: int) -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	var hoje := Time.get_date_string_from_system()
	d["tinta"] = 640
	d["clipes_ouro"] = 40
	d["nivel_conta"] = 6
	d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = 5
	d["capitulo_selecionado"] = capitulo
	d["nivel_dano"] = 4
	d["nivel_hp"] = 4
	d["nivel_cadencia"] = 4
	d["caneta_equipada"] = "bic_azul"
	d["canetas_possuidas"] = ["bic_azul", "lapis_hb"]
	d["tutorial_visto"] = true
	d["ultimo_login"] = hoje
	d["dia_streak"] = 3
	d["recompensa_coletada_hoje"] = true
	d["run_snapshot"] = {"ativa": false}
	root.get_node("SaveManager").retomar_run_pendente = false

# ------------------------------------------------------------------
# Cenas
# ------------------------------------------------------------------
func _abrir_cena(caminho: String) -> Node:
	_sv = SubViewport.new()
	_sv.size = TAM
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var cena: Node = load(caminho).instantiate()
	_sv.add_child(cena)
	return cena

func _fotografar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = _sv.get_texture().get_image()
	var caminho := "%s/%s.png" % [_saida, nome]
	img.save_png(caminho)
	print("[capturar_prints] ", caminho, " ", img.get_size())

func _fechar() -> void:
	paused = false
	Engine.time_scale = 1.0
	_sv.queue_free()
	await process_frame
	await process_frame

func _hub(nome: String, aba: String, capitulo: int) -> void:
	_preparar_save(capitulo)
	var hub: Node = _abrir_cena("res://hub.tscn")
	await create_timer(1.5).timeout
	hub._alterar_aba(aba)
	await create_timer(1.0).timeout
	await _fotografar(nome)
	await _fechar()

func _iniciar_combate(main: Node, capitulo: int, pagina: int, upgrades: Array) -> void:
	main.player.invencivel = true
	for id in upgrades:
		main.player.aplicar_upgrade(id)
	main.player.position = Vector2(540, 1650)
	main.player.mover_para(Vector2(540, 1650))
	main.jogo_iniciado = true
	main.menu_iniciar.visible = false
	main.player.attack_timer.start()
	main.wave_manager.iniciar_fase_na_pagina(capitulo, pagina)

func _combate(nome: String, capitulo: int, pagina: int, upgrades: Array, espera: float) -> void:
	_preparar_save(capitulo)
	var main: Node = _abrir_cena("res://main.tscn")
	await create_timer(0.5).timeout
	_iniciar_combate(main, capitulo, pagina, upgrades)
	await create_timer(espera).timeout
	await _fotografar(nome)
	await _fechar()

func _roleta(nome: String, capitulo: int) -> void:
	_preparar_save(capitulo)
	var main: Node = _abrir_cena("res://main.tscn")
	await create_timer(0.5).timeout
	main.player.aplicar_upgrade("tiro_duplo")
	main.menu_iniciar.visible = false
	main.jogo_iniciado = true
	main._abrir_roleta_upgrades()
	await create_timer(7.0).timeout
	await _fotografar(nome)
	await _fechar()
