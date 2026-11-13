extends SceneTree
## Protótipo (13/11/2026): aviso de novidades depois de atualizar e pedido de
## avaliação, 2 opções de cada, sem mexer no código do jogo.
## Uso (com janela e backup do save do PC):
##   Godot --path . -s tools/prototipo_novidades_avaliacao.gd -- <pasta>

const NOVIDADES := ["Tiros dos inimigos somem quando a página termina.",
	"Desafio do dia: uma regra nova a cada dia.", "Caneta nova no Estojo."]

var _sv: SubViewport
var _saida := "C:/Users/joalh/Documentos/Sketch Blade/design/novidades-avaliacao/v1"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_saida = args[0]
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _save() -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = 640; d["clipes_ouro"] = 40; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = 5; d["capitulo_selecionado"] = 3
	d["tutorial_visto"] = true; d["dica_gotas_vista"] = true
	d["ultimo_login"] = Time.get_date_string_from_system(); d["recompensa_coletada_hoje"] = true
	d["run_snapshot"] = {"ativa": false}

func _abrir(c: String) -> Node:
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var n: Node = load(c).instantiate(); _sv.add_child(n); return n

func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])

func _fechar() -> void:
	paused = false
	_sv.queue_free(); await process_frame; await process_frame

func _janela(pai: Node, classe) -> Control:
	var j: Control = load(classe).new()
	pai.add_child(j)
	await process_frame
	j.mostrar({"versao": "1.9.1", "novidades": NOVIDADES})
	return j

func _vitoria() -> Node:
	_save()
	var m = _abrir("res://main.tscn"); await create_timer(1.0).timeout
	m.player.invencivel = true; m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.capitulo_atual = 3
	m.tinta_partida = 420; m.monstros_derrotados_partida = 40; m.boss_derrotado_partida = true
	m._processar_fim_de_jogo(true); m.menu_vitoria.visible = true
	await create_timer(2.5).timeout
	return m

func _rodar() -> void:
	await process_frame
	for par in [["novidades-A", "res://tools/proto_avaliacao/NovidadesA.gd"], ["novidades-B", "res://tools/proto_avaliacao/NovidadesB.gd"]]:
		_save()
		var h = _abrir("res://hub.tscn"); await create_timer(1.5).timeout
		await _janela(h.get_node("HUD"), par[1]); await create_timer(0.8).timeout
		await _foto(par[0]); await _fechar()
	var m = await _vitoria()
	await _foto("vitoria-atual")
	await _janela(m.get_node("HUD"), "res://tools/proto_avaliacao/AvaliacaoA.gd"); await create_timer(0.5).timeout
	await _foto("avaliacao-A"); await _fechar()
	# Opção B: faixa de estrelas dentro da própria tela de vitória
	m = await _vitoria()
	var tv: Control = m.tela_vitoria
	var e = load("res://tools/proto_avaliacao/Estrelas.gd").new()
	e.lado = 70.0
	e.position = Vector2(290, 1400)
	e.size = Vector2(500, 84)
	tv.add_child(e)
	tv._txt(tv, "Toque para avaliar o Sketch Blade", 40, Color("0047ab"), 1484, 1540, tv.FONTE, 0, 1080)
	await create_timer(0.3).timeout
	await _foto("avaliacao-B"); await _fechar()
	quit()
