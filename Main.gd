extends Node2D

const FONTE_NUMEROS = preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")

@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
@export var ink_particles_scene: PackedScene = preload("res://ink_particles.tscn")
@export var feedback_label_scene: PackedScene = preload("res://feedback_label.tscn")
@export var ink_drop_scene: PackedScene = preload("res://ink_drop.tscn")
@export var enemy_projectile_scene: PackedScene = preload("res://enemy_projectile.tscn")
@export var projectile_scene: PackedScene = preload("res://projectile.tscn")

@onready var player: Area2D = $Player
@onready var hp_bar: ProgressBar = $HUD/HPBar
@onready var hp_texto_label: Label = $HUD/HPTextoLabel
@onready var tinta_label: Label = $HUD/TintaLabel

@onready var wave_manager: Node = $WaveManager
@onready var menu_iniciar: Control = $HUD/MenuIniciar
@onready var botao_jogar: Button = $HUD/MenuIniciar/BotaoJogar
@onready var menu_game_over: Control = $HUD/MenuGameOver
@onready var botao_recomecar: Button = $HUD/MenuGameOver/BotaoRecomecar

@onready var menu_vitoria: Control = $HUD/MenuVitoria
@onready var label_detalhes_vitoria: Label = $HUD/MenuVitoria/DetalhesVitoria
@onready var botao_continuar: Button = $HUD/MenuVitoria/BotaoContinuar
@onready var boss_hp_bar: ProgressBar = $HUD/BossHPBar

var jogo_iniciado: bool = false
var arrastando: bool = false
var fim_de_jogo_declarado: bool = false

# Rastreio da página atual (bônus de página perfeita)
var dano_sofrido_na_pagina: bool = false
var label_pagina: Label
var menu_descanso: Control
# Página de descanso no estilo caderno (TelaDescanso.gd, filho de menu_descanso)
var tela_descanso: Control

# Rewarded ads (revive e dobrar tinta)
var menu_revive: Control
var tinta_final_ultima_run: int = 0
var tela_vitoria: Control
var tela_derrota: Control

# Dados de Tinta, Progresso e Save
var tinta_partida: int = 0
var monstros_derrotados_partida: int = 0
var boss_derrotado_partida: bool = false
var capitulo_atual: int = 1

# Telemetria: tempo ATIVO de combate da run (segundos). Acumulado em
# _process, que o SceneTree congela durante pausa/roleta/menus e em
# background — então menus e idle não contam na duração.
var _tempo_ativo_seg: float = 0.0

# Referência ao dicionário central do SaveManager (autoload)
var dados_save: Dictionary

# Cache de texturas de drops de tinta para evitar load() dinâmico em tempo de execução
var texturas_drops: Dictionary = {
	"res://assets/ink-black.svg": preload("res://assets/ink-black.svg"),
	"res://assets/ink-purple.svg": preload("res://assets/ink-purple.svg"),
	"res://assets/ink-green.svg": preload("res://assets/ink-green.svg"),
	"res://assets/ink-brown.svg": preload("res://assets/ink-brown.svg"),
	"res://assets/ink-red.svg": preload("res://assets/ink-red.svg")
}

# Pools de objetos para otimizar performance mobile
var _pool_projeteis_player: Array = []
var _pool_projeteis_inimigos: Array = []
var _pool_partculas: Array = []

# Atributos por nível do Estojo agora vivem em GameData (10 níveis)

# Áudio procedural
var audio_hit: AudioStream
var audio_kill: AudioStream
var audio_dano: AudioStream
var audio_vitoria: AudioStream

# Sistema de Upgrades Roguelite
var menu_upgrades: Control
# Roleta de melhorias no estilo caderno (TelaRoleta.gd, filho de menu_upgrades)
var tela_roleta: Control
var menu_pausa: Control
var botao_pausa_hud: Button
# Pausa no estilo caderno (TelaPausa.gd, filho de menu_pausa)
var tela_pausa: Control
var label_contagem: Label
# Opções sorteadas na roleta atual (definições vindas de GameData.UPGRADES)
var opcoes_roleta: Array = []

func _ready() -> void:
	player.recebeu_dano.connect(_on_player_dano)
	player.morreu.connect(_on_player_morreu)

	# Labels numéricos do HUD (definidos no .tscn com ArchitectsDaughter)
	# trocados para Caveat — padrão de todos os números do jogo.
	hp_texto_label.add_theme_font_override("font", FONTE_NUMEROS)
	tinta_label.add_theme_font_override("font", FONTE_NUMEROS)
	label_detalhes_vitoria.add_theme_font_override("font", FONTE_NUMEROS)

	_criar_tela_vitoria()
	_criar_tela_derrota()

	_ajustar_hud_combate()

	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	botao_recomecar.pressed.connect(_on_botao_recomecar_pressed)
	botao_continuar.pressed.connect(_on_botao_continuar_pressed)
	
	wave_manager.boss_surgiu.connect(_on_boss_surgiu)
	wave_manager.fase_concluida.connect(_on_fase_concluida)
	wave_manager.pagina_iniciada.connect(_on_pagina_iniciada)
	wave_manager.pagina_concluida.connect(_on_pagina_concluida)
	wave_manager.descanso_iniciado.connect(_on_descanso_iniciado)
	
	# Desativa o ataque automático no início
	player.attack_timer.stop()
	
	# Save centralizado no autoload SaveManager
	dados_save = SaveManager.dados
	capitulo_atual = dados_save["capitulo_selecionado"]
	
	# Configura visualmente o papel de acordo com o capítulo jogado
	if has_node("Paper"):
		$Paper.configurar_para_capitulo(capitulo_atual)
		
	# Título do Capítulo no botão de iniciar do combate
	if menu_iniciar.has_node("Titulo"):
		menu_iniciar.get_node("Titulo").text = "Capítulo " + str(capitulo_atual)
	
	_aplicar_upgrades_rpg()
	
	# Sons gravados (assets/sons, CC0; créditos em docs/sons.md). O bipe
	# de "vitória" continua nos momentos menores (descanso, roleta, bônus).
	audio_kill = SONS["morte"]
	audio_hit = SONS["gota"] # coleta da gota de tinta
	audio_dano = SONS["dano"]
	audio_vitoria = _gerar_som_procedural(600.0, 0.6, "sin")
	
	_atualizar_hud()
	
	_criar_menu_upgrades()
	_criar_botao_pausa_hud()
	_criar_menu_pausa()
	_criar_label_contagem()
	_criar_label_pagina()
	_criar_menu_descanso()
	_criar_menu_revive()

	# Ícone de tinta inline no HUD (à direita do número, ancora na borda direita)
	var icone_tinta_hud = TextureRect.new()
	icone_tinta_hud.texture = load("res://assets/ink.svg")
	icone_tinta_hud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone_tinta_hud.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone_tinta_hud.anchor_left = 1.0
	icone_tinta_hud.anchor_right = 1.0
	# Recuado para a esquerda do botão de pause (que fica na borda direita)
	icone_tinta_hud.offset_left = -118.0
	icone_tinta_hud.offset_right = -80.0
	icone_tinta_hud.offset_top = 30.0
	icone_tinta_hud.offset_bottom = 76.0
	icone_tinta_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(icone_tinta_hud)
	# Atrás dos menus, junto do número da tinta, para escurecer com o overlay
	$HUD.move_child(icone_tinta_hud, menu_iniciar.get_index())
	# Número da tinta: com respiro antes da gota e centrado na altura dela
	# (antes ficava mais baixo e colado no ícone)
	tinta_label.offset_right = -134.0
	tinta_label.offset_top = 21.0
	tinta_label.offset_bottom = 85.0
	tinta_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Handler central de recompensas de anúncio
	AdsManager.recompensa_concedida.connect(_on_recompensa_ad)
	AdsManager.anuncio_falhou.connect(_on_anuncio_falhou)

	# Se o Hub nos enviou para retomar uma run interrompida, restaura em vez de
	# mostrar a tela inicial do combate.
	if SaveManager.retomar_run_pendente:
		SaveManager.retomar_run_pendente = false
		_retomar_run_do_snapshot()

func _aplicar_upgrades_rpg() -> void:
	var nd = dados_save.get("nivel_dano", 1)
	var nh = dados_save.get("nivel_hp", 1)
	var nc = dados_save.get("nivel_cadencia", 1)

	# Passivas da caneta equipada modificam os atributos base do Estojo
	var caneta = GameData.get_caneta(dados_save.get("caneta_equipada", "bic_azul"))
	var mods: Dictionary = caneta.get("mods", {})

	player.dano = int(GameData.DANO_POR_NIVEL[nd] * mods.get("mult_dano", 1.0))
	player.vidas_max = GameData.HP_POR_NIVEL[nh]
	player.vidas = player.vidas_max # Inicializa com HP máximo atualizado
	# A cadência do Estojo é a BASE; upgrades in-run (Apontador) multiplicam sobre ela
	player.intervalo_ataque_base = GameData.CADENCIA_POR_NIVEL[nc] * mods.get("mult_cadencia", 1.0)
	player.chance_critica_passiva = mods.get("chance_critica", 0.0)
	player._recalcular_atributos()

	# Visual da caneta e dos projéteis
	player.cor_caneta = Color(caneta["cor_corpo"])
	player.cor_projetil = Color(caneta["cor_projetil"])

	# Carrega o SVG real da caneta para renderização fiel in-game
	const ICONES_CANETA: Dictionary = {
		"bic_azul":     "res://assets/bic-azul.svg",
		"lapis_hb":     "res://assets/lapis-hb.svg",
		"nanquim":      "res://assets/nanquim.svg",
		"gel_vermelha": "res://assets/gel-vermelha.svg",
		"nanquim_real": "res://assets/nanquim-real.svg",
	}
	var caneta_id: String = dados_save.get("caneta_equipada", "bic_azul")
	if caneta_id in ICONES_CANETA:
		player.textura_caneta = load(ICONES_CANETA[caneta_id])
	else:
		player.textura_caneta = null

	player.queue_redraw()

	# Nanquim Real: começa a run com Escudo de Borracha Lv.1
	if mods.get("escudo_inicial", false) and player.nivel_upgrade("escudo_borracha") == 0:
		player.aplicar_upgrade("escudo_borracha")

	hp_bar.max_value = player.vidas_max
	hp_bar.value = player.vidas

func _unhandled_input(event: InputEvent) -> void:
	if not jogo_iniciado:
		return
		
	var clicou = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
	var tocou = event is InputEventScreenTouch
	
	if (clicou or tocou) and event.pressed:
		arrastando = true
		player.mover_para(event.position)
	elif (clicou or tocou) and not event.pressed:
		arrastando = false
	
	var moveu_mouse = event is InputEventMouseMotion
	var moveu_toque = event is InputEventScreenDrag
	
	if arrastando and (moveu_mouse or moveu_toque):
		player.mover_para(event.position)

func _on_botao_jogar_pressed() -> void:
	# Run nova: descarta qualquer snapshot antigo pendente.
	SaveManager.limpar_run_snapshot()
	tinta_partida = 0
	monstros_derrotados_partida = 0
	boss_derrotado_partida = false
	_tempo_ativo_seg = 0.0
	AdsManager.nova_run()
	fim_de_jogo_declarado = false
	
	_atualizar_hud()
	jogo_iniciado = true
	menu_iniciar.visible = false
	player.attack_timer.start()
	run_de_teste = SaveManager.teste_chefe > 0
	if SaveManager.teste_chefe > 0:
		# Modo de teste: vai direto para a página do chefe do capítulo escolhido
		capitulo_atual = SaveManager.teste_chefe
		SaveManager.teste_chefe = 0
		wave_manager.iniciar_fase_na_pagina(capitulo_atual, GameData.PAGINAS.size())
	else:
		wave_manager.iniciar_fase(capitulo_atual)

	# Tutorial na primeira partida da conta
	if not SaveManager.dados.get("tutorial_visto", false):
		_mostrar_tutorial()

func _mostrar_tutorial() -> void:
	SaveManager.dados["tutorial_visto"] = true
	SaveManager.salvar()

	var lbl = Label.new()
	lbl.text = "👆 Arraste o dedo para mover a caneta\n✍️ Fique parado para atirar tinta!"
	lbl.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color("002867"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(0, 1150)
	lbl.size = Vector2(1080, 200)
	lbl.z_index = 80
	$HUD.add_child(lbl)

	# Pulsa suavemente e desaparece após 7 segundos
	var tween = create_tween().set_loops(4)
	tween.tween_property(lbl, "modulate:a", 0.55, 0.7)
	tween.tween_property(lbl, "modulate:a", 1.0, 0.7)
	tween.finished.connect(func():
		var fade = create_tween()
		fade.tween_property(lbl, "modulate:a", 0.0, 0.8)
		fade.finished.connect(lbl.queue_free)
	)

func _on_botao_recomecar_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://hub.tscn")

func _on_botao_continuar_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://hub.tscn")

func _on_enemy_morreu(pos: Vector2, cor: Color, textura: String) -> void:
	_spawn_particles(cor, pos)
	_spawn_feedback("MORREU!", "perfect", pos)
	_spawn_drops_de_tinta(pos, 2, 4, textura)
	_tocar_som(audio_kill, randf_range(0.9, 1.15))
	_hitstop(0.04)
	# O monstro derrotado deixa uma mancha permanente na página
	if has_node("Paper"):
		$Paper.adicionar_mancha(pos, cor)
	monstros_derrotados_partida += 1
	SaveManager.incrementar_stat("monstros_derrotados")

	# Borrão Explosivo: a morte fere inimigos próximos (permite reação em cadeia)
	var nivel_borrao = player.nivel_upgrade("borrao_explosivo") if player else 0
	if nivel_borrao > 0:
		var dano_explosao: int = GameData.valor_upgrade("borrao_explosivo", nivel_borrao)
		for inimigo in get_tree().get_nodes_in_group("enemies"):
			if inimigo.is_queued_for_deletion():
				continue
			if pos.distance_to(inimigo.global_position) <= GameData.RAIO_EXPLOSAO:
				if inimigo.has_method("receber_dano"):
					inimigo.receber_dano.call_deferred(dano_explosao)

func _on_enemy_escapou() -> void:
	print("[DEBUG] Inimigo escapou da tela e causou dano!")
	if player and player.vidas > 0:
		player.receber_dano(1)

func _on_player_dano(vidas_restantes: int) -> void:
	dano_sofrido_na_pagina = true
	_atualizar_hud()
	_tocar_som(audio_dano)
	_shake_tela(10.0)
	if SaveManager.dados.get("vibracao_ativa", true):
		Input.vibrate_handheld(100)

## Micro-congelamento de tempo no impacto (juice de kill).
## O timer ignora time_scale e roda mesmo pausado. Pedidos sobrepostos
## apenas estendem o prazo (kill de elite/boss ganha prioridade sobre o
## hitstop comum já em curso; multi-kill não vira gagueira).
var _hitstop_fim_ms: int = 0

func _hitstop(duracao: float = 0.04, escala: float = 0.05) -> void:
	var novo_fim = Time.get_ticks_msec() + int(duracao * 1000.0)
	if novo_fim <= _hitstop_fim_ms:
		return # um congelamento igual ou mais longo já está em curso
	var estava_ativo = _hitstop_fim_ms > Time.get_ticks_msec()
	_hitstop_fim_ms = novo_fim
	Engine.time_scale = escala
	if estava_ativo:
		return # a corrotina original segue rodando até o novo prazo
	while Time.get_ticks_msec() < _hitstop_fim_ms:
		var restante = float(_hitstop_fim_ms - Time.get_ticks_msec()) / 1000.0
		await get_tree().create_timer(restante, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_fim_ms = 0

func _exit_tree() -> void:
	# Garante que nenhuma troca de cena herde o tempo congelado
	Engine.time_scale = 1.0

# ============================================================
# CICLO DE VIDA DO APP — gesto voltar e app indo para segundo plano
# ============================================================
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Gesto/botão "voltar" do Android. Com quit_on_go_back=false, cabe
			# a nós decidir — nunca fecha o jogo perdendo a run.
			_tratar_voltar()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			# App foi para segundo plano (home/app switcher) ou está fechando.
			# Grava um snapshot para sobreviver a um kill de processo do Android.
			if _run_em_andamento():
				SaveManager.salvar_run_snapshot(_capturar_estado_run())

## Decide o que o gesto "voltar" faz conforme o estado atual da tela.
func _tratar_voltar() -> void:
	# Menus que exigem uma decisão obrigatória: ignoram o voltar.
	if menu_revive and menu_revive.visible:
		return
	if menu_upgrades and menu_upgrades.visible:
		tela_roleta.voltar_do_sistema() # só pula a animação: a escolha é obrigatória
		return
	if menu_descanso and menu_descanso.visible:
		tela_descanso.voltar_do_sistema() # só pula a animação: a escolha é obrigatória
		return
	# Menus de fim de partida: voltar equivale a sair para o Hub.
	if menu_game_over and menu_game_over.visible:
		if tela_derrota and tela_derrota.voltar_do_sistema():
			return
		_on_botao_recomecar_pressed()
		return
	if menu_vitoria and menu_vitoria.visible:
		if tela_vitoria and tela_vitoria.voltar_do_sistema():
			return
		_on_botao_continuar_pressed()
		return
	# Já pausado: voltar retoma a partida.
	if menu_pausa and menu_pausa.visible:
		if not tela_pausa.voltar_do_sistema(): # primeiro fecha a confirmação
			_on_retomar_pausa_pressed()
		return
	# Em plena partida: voltar abre a pausa (em vez de fechar o app).
	if jogo_iniciado:
		_on_botao_pausa_pressed()
		return
	# Fora de run (tela inicial do combate): volta para o Hub.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://hub.tscn")

## True enquanto há uma partida realmente em andamento (inclui menus de pausa/
## roleta/descanso que fazem parte da run), e False em fim de jogo ou tela inicial.
func _process(delta: float) -> void:
	# Telemetria: o SceneTree pausado (menus) ou app em background congela
	# este _process, então só o combate real acumula.
	if jogo_iniciado and _run_em_andamento():
		_tempo_ativo_seg += delta

func _run_em_andamento() -> bool:
	if fim_de_jogo_declarado:
		return false
	if menu_game_over and menu_game_over.visible:
		return false
	if menu_vitoria and menu_vitoria.visible:
		return false
	return wave_manager.pagina_atual >= 1

## Serializa o estado da run atual para o snapshot de retomada.
func _capturar_estado_run() -> Dictionary:
	return {
		"ativa": true,
		"capitulo": capitulo_atual,
		"pagina": max(1, wave_manager.pagina_atual),
		# min 1 coração: se o app foi ao background durante o prompt de revive,
		# a run é restaurada jogável em vez de morta.
		"hp": max(1, player.vidas),
		"tinta_partida": tinta_partida,
		"monstros_derrotados": monstros_derrotados_partida,
		"boss_derrotado": boss_derrotado_partida,
		"upgrades": player.upgrades.duplicate(),
		"revive_usado": AdsManager.revive_usado_na_run,
		"tempo_ativo_seg": _tempo_ativo_seg,
	}

## Restaura uma run a partir do snapshot salvo. A página atual recomeça do zero,
## preservando capítulo, HP, tinta, upgrades roguelite e progresso de kills.
func _retomar_run_do_snapshot() -> void:
	var snap: Dictionary = SaveManager.get_run_snapshot()
	if snap.is_empty() or not snap.get("ativa", false):
		return

	capitulo_atual = int(snap.get("capitulo", capitulo_atual))
	if has_node("Paper"):
		$Paper.configurar_para_capitulo(capitulo_atual)
	if menu_iniciar.has_node("Titulo"):
		menu_iniciar.get_node("Titulo").text = "Capítulo " + str(capitulo_atual)

	tinta_partida = int(snap.get("tinta_partida", 0))
	monstros_derrotados_partida = int(snap.get("monstros_derrotados", 0))
	boss_derrotado_partida = bool(snap.get("boss_derrotado", false))

	# Reaplica os upgrades roguelite por cima do estado base do Estojo (que já foi
	# montado no _ready). Reconstrói do zero para disparar os efeitos (escudo,
	# apontador) exatamente nos níveis salvos.
	player.upgrades = {}
	var ups: Dictionary = snap.get("upgrades", {})
	for id in ups.keys():
		var nivel: int = int(ups[id])
		for _n in range(nivel):
			player.aplicar_upgrade(id)

	player.vidas = clamp(int(snap.get("hp", player.vidas_max)), 1, player.vidas_max)
	player.queue_redraw()

	AdsManager.nova_run()
	AdsManager.revive_usado_na_run = bool(snap.get("revive_usado", false))

	# Preserva a duração já jogada para a telemetria de baseline.
	_tempo_ativo_seg = float(snap.get("tempo_ativo_seg", 0.0))
	fim_de_jogo_declarado = false

	_atualizar_hud()
	jogo_iniciado = true
	menu_iniciar.visible = false
	player.attack_timer.start()

	var pagina: int = clamp(int(snap.get("pagina", 1)), 1, GameData.PAGINAS.size())
	# Limpa ANTES de iniciar: o início da página regrava o checkpoint.
	SaveManager.limpar_run_snapshot()
	wave_manager.iniciar_fase_na_pagina(capitulo_atual, pagina)
	_spawn_feedback("RUN RESTAURADA!", "perfect", Vector2(540, 900))

## Tremor de tela rápido (juice de impacto)
func _shake_tela(intensidade: float = 10.0) -> void:
	var tween = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-intensidade, intensidade), randf_range(-intensidade, intensidade))
		tween.tween_property(self, "position", offset, 0.04)
	tween.tween_property(self, "position", Vector2.ZERO, 0.05)

func _on_player_morreu() -> void:
	# Se a vitória já foi decretada ou o jogo acabou, ignora a morte tardia
	if fim_de_jogo_declarado:
		return

	jogo_iniciado = false
	player.attack_timer.stop()

	# Oferece o revive por anúncio (1x por run) antes do game over
	if not AdsManager.revive_usado_na_run:
		get_tree().paused = true
		menu_revive.visible = true
		tela_reviver.mostrar({"cap": capitulo_atual, "pagina": max(1, wave_manager.pagina_atual),
			"total_paginas": GameData.PAGINAS.size()})
		return

	_finalizar_derrota()

func _finalizar_derrota() -> void:
	fim_de_jogo_declarado = true
	SaveManager.limpar_run_snapshot() # Run encerrada: nada a retomar
	boss_hp_bar.visible = false
	_processar_fim_de_jogo(false)
	_tocar_som(SONS["derrota"])
	get_tree().paused = true
	menu_game_over.visible = true

# ============================================================
# REWARDED ADS — revive e dobrar tinta
# ============================================================
## Menu de reviver ("Segunda chance?"): TelaReviver.gd, no estilo das telas
## de fim. Continuar = anúncio recompensado (1x por partida); desistir =
## página arruinada.
var tela_reviver: Control
func _criar_menu_revive() -> void:
	menu_revive = Control.new()
	menu_revive.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_revive.visible = false
	menu_revive.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(menu_revive)
	tela_reviver = Control.new()
	tela_reviver.set_script(preload("res://TelaReviver.gd"))
	menu_revive.add_child(tela_reviver)
	tela_reviver.anuncio_pressionado.connect(func():
		AdsManager.revive_usado_na_run = true
		AdsManager.mostrar_rewarded("revive"))
	tela_reviver.voltar_pressionado.connect(func():
		AdsManager.revive_usado_na_run = true
		menu_revive.visible = false
		get_tree().paused = false
		_finalizar_derrota())

func _on_recompensa_ad(placement: String) -> void:
	match placement:
		"revive":
			_executar_revive()
		"dobrar_tinta":
			_executar_dobro_tinta()

func _on_anuncio_falhou(placement: String) -> void:
	_tocar_som(audio_dano)
	match placement:
		"revive":
			if tela_reviver:
				tela_reviver.anuncio_falhou()
			AdsManager.revive_usado_na_run = false
			_spawn_feedback("SEM CONEXÃO!", "miss", player.global_position if player else Vector2(540, 960))
		"dobrar_tinta":
			if tela_vitoria and menu_vitoria.visible:
				tela_vitoria.anuncio_falhou()
			if tela_derrota and menu_game_over.visible:
				tela_derrota.anuncio_falhou()
			_spawn_feedback("FALHA DE REDE!", "miss", Vector2(540, 1500))

func _executar_revive() -> void:
	menu_revive.visible = false

	# Cancela a declaração de fim de jogo para permitir novas jogadas
	fim_de_jogo_declarado = false

	# Limpa as ameaças da tela (poupa Boss e Elite, que não morrem por contato)
	for inimigo in get_tree().get_nodes_in_group("enemies"):
		if inimigo.get("morre_no_contato") == true:
			inimigo.queue_free()
	# Devolve ao pool (apagar deixava tiros mortos guardados para reuso)
	for proj in get_tree().get_nodes_in_group("enemy_projectiles"):
		if proj.visible:
			devolver_projetil_inimigo(proj)

	# Restaura o jogador com 3 corações e invencibilidade curta
	player.vidas = min(3, player.vidas_max)
	player.invencivel = true
	player.modulate = Color(1, 1, 1, 0.6)
	_atualizar_hud()
	_spawn_feedback("DE VOLTA!", "perfect", player.global_position)

	get_tree().paused = false
	jogo_iniciado = true
	player.attack_timer.start()

	# Fim da invencibilidade após 2s
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(player, "modulate", Color.WHITE, 0.2)
	tween.finished.connect(func(): player.invencivel = false)

func _executar_dobro_tinta() -> void:
	dados_save["tinta"] += tinta_final_ultima_run
	SaveManager.salvar()

	if tela_vitoria and menu_vitoria.visible:
		tela_vitoria.bonus_recebido()
	if tela_derrota and menu_game_over.visible:
		tela_derrota.bonus_recebido()

	_tocar_som(audio_vitoria)

func _on_boss_surgiu(boss_node: Node2D) -> void:
	_estilizar_barra_chefe()
	# A barra do chefe sobe para o lugar do "Página 8 / 8" (que some) e fica
	# mais fina: libera a faixa de cima para a cabeça do chefe.
	if label_pagina:
		label_pagina.visible = false
	boss_hp_bar.offset_top = 100.0
	boss_hp_bar.offset_bottom = 128.0
	boss_hp_bar.max_value = boss_node.hp_max
	boss_hp_bar.value = boss_node.hp
	boss_hp_bar.visible = true
	
	boss_node.hp_alterado.connect(func(novo_hp):
		boss_hp_bar.value = novo_hp
	)
	boss_node.morreu.connect(func():
		boss_hp_bar.visible = false
		_limpar_tela_vitoria()
		for i in range(4):
			var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			_spawn_particles(Color.BLACK, boss_node.global_position + offset)
			if has_node("Paper"):
				$Paper.adicionar_mancha(boss_node.global_position + offset, Color.BLACK, 34.0)
		_spawn_drops_de_tinta(boss_node.global_position, 10, 8, "res://assets/ink-red.svg")
		_spawn_feedback("BOSS DERROTADO!", "perfect", boss_node.global_position)
		_tocar_som(audio_kill, 0.8)
		_shake_tela(22.0)
		_hitstop(0.12)
		boss_derrotado_partida = true
	)

func _on_fase_concluida() -> void:
	# Se a derrota definitiva (Game Over) já foi exibida, ignora a vitória tardia
	if menu_game_over and menu_game_over.visible:
		return
		
	# Decreta o fim da partida com vitória
	fim_de_jogo_declarado = true
	SaveManager.limpar_run_snapshot() # Run vencida: nada a retomar
	jogo_iniciado = false
	player.attack_timer.stop()
	
	# Torna o jogador invencível para evitar que ele morra nos 1.5s seguintes
	if player:
		player.invencivel = true
		player.modulate = Color.WHITE # Restaura o visual normal se estiver piscando
		
	# Se o menu de revive estava aberto (morte e vitória quase simultâneas), fecha-o
	if menu_revive and menu_revive.visible:
		menu_revive.visible = false

	# Nenhuma gota se perde na vitória: as restantes voam para o contador do HUD
	for drop in get_tree().get_nodes_in_group("ink_drops"):
		drop.forcar_coleta_no_hud()

	# Aguarda os drops voarem
	await get_tree().create_timer(1.5).timeout
	
	_processar_fim_de_jogo(true)
	
	_tocar_som(SONS["vitoria"])
	get_tree().paused = true
	menu_vitoria.visible = true

## true quando a partida foi aberta pelo atalho "Testar chefe" (Stats de teste)
var run_de_teste: bool = false

func _processar_fim_de_jogo(venceu: bool) -> void:
	# "Página X / 8" do combate fica por cima das telas de fim: esconde
	if label_pagina:
		label_pagina.visible = false
	# 1. Bônus por vidas (10% por vida)
	var bonus_vida_pct: int = player.vidas * 10
	var tinta_bonus_vida: int = int(tinta_partida * (float(bonus_vida_pct) / 100.0)) if venceu else 0
	
	# Tinta acumulada na partida antes do multiplicador do Capítulo
	var tinta_base_final = tinta_partida + tinta_bonus_vida
	
	# 2. Bônus de Capítulo (+10% por capítulo acima do 1)
	var bonus_cap_pct: int = (capitulo_atual - 1) * 10
	var tinta_bonus_cap: int = int(tinta_base_final * (float(bonus_cap_pct) / 100.0))
	var tinta_final: int = tinta_base_final + tinta_bonus_cap

	# Guarda para o "Ver anúncio" (dobrar tinta) das telas de fim
	tinta_final_ultima_run = tinta_final
	
	# 3. Calcula XP ganho na run (dificultado)
	var xp_ganho = (monstros_derrotados_partida * 1) + (20 if boss_derrotado_partida else 0) + (50 if venceu else 0)

	# Guarda o estado "antes" para o Hub animar a barra de XP subindo do
	# valor antigo até o novo (em vez de pular direto pro resultado final).
	SaveManager.xp_snapshot_pendente = {
		"nivel": dados_save["nivel_conta"],
		"xp": dados_save["xp_conta"],
		"xp_ganho": xp_ganho,
	}

	# 4. Atualiza o save central e as estatísticas
	dados_save["tinta"] += tinta_final
	dados_save["xp_conta"] += xp_ganho
	SaveManager.incrementar_stat("partidas_jogadas")
	SaveManager.incrementar_stat("tinta_coletada_total", tinta_final)
	if boss_derrotado_partida:
		SaveManager.incrementar_stat("bosses_derrotados")
	if venceu:
		SaveManager.incrementar_stat("capitulos_vencidos")
	# Recorde antes desta partida (a derrota mostra "Novo recorde!")
	var recorde_antes: int = SaveManager.get_melhor_pagina(capitulo_atual)
	if not run_de_teste: # atalho "Testar chefe" não entra na conta
		SaveManager.registrar_capitulo(capitulo_atual, venceu,
			wave_manager.pagina_atual >= GameData.PAGINAS.size())
		SaveManager.registrar_melhor_pagina(capitulo_atual,
			clamp(wave_manager.pagina_atual, 1, GameData.PAGINAS.size()))
		if not venceu:
			SaveManager.registrar_morte_pagina(capitulo_atual,
				clamp(wave_manager.pagina_atual, 1, GameData.PAGINAS.size()))

	# Se venceu, desbloqueia o próximo capítulo
	var texto_desbloqueio = ""
	if venceu:
		if capitulo_atual == dados_save["capitulo_desbloqueado"] and capitulo_atual < 10:
			dados_save["capitulo_desbloqueado"] += 1
			texto_desbloqueio = "[ NOVO CAPÍTULO %d DESBLOQUEADO! ]\n" % dados_save["capitulo_desbloqueado"]
			
	# 5. Processa múltiplos Level Ups se XP ultrapassar limite da curva
	var subiu_nivel: bool = false
	var niveis_ganhos: int = 0
	var xp_req = get_xp_necessario_para_nivel(dados_save["nivel_conta"])
	while dados_save["xp_conta"] >= xp_req:
		dados_save["xp_conta"] -= xp_req
		dados_save["nivel_conta"] += 1
		niveis_ganhos += 1
		subiu_nivel = true
		xp_req = get_xp_necessario_para_nivel(dados_save["nivel_conta"])
		
	if subiu_nivel:
		# Concede 5 clipes por level up
		dados_save["clipes_ouro"] += niveis_ganhos * 5
		
	# 6. Telemetria de baseline P0 + grava save persistente
	_registrar_telemetria_run(tinta_final)
	SaveManager.salvar()
	
	# 7. Telas de fim (TelaVitoria / TelaDerrota) com os números da partida
	var cap_desbloqueado: int = dados_save["capitulo_desbloqueado"] if texto_desbloqueio != "" else 0
	var ficha: Dictionary = FICHAS_CHEFE.get(capitulo_atual, FICHAS_CHEFE[1])
	var dados_tela := {
		"cap": capitulo_atual,
		"tinta_partida": tinta_partida,
		"bonus_vida": tinta_bonus_vida,
		"bonus_cap": tinta_bonus_cap,
		"tinta_final": tinta_final,
		"xp_ganho": xp_ganho,
		"nivel": dados_save["nivel_conta"],
		"xp": dados_save["xp_conta"],
		"xp_req": get_xp_necessario_para_nivel(dados_save["nivel_conta"]),
		"niveis_ganhos": niveis_ganhos,
		"clipes": niveis_ganhos * 5,
	}
	if venceu:
		dados_tela["nome"] = ficha["nome"].substr(2) # sem o artigo ("o Compasso" → "Compasso")
		dados_tela["arte"] = ficha["arte"]
		dados_tela["cap_desbloqueado"] = cap_desbloqueado
		tela_vitoria.mostrar(dados_tela)
	else:
		dados_tela["nome"] = ficha["nome"] # com o artigo: "O Compasso venceu desta vez!"
		dados_tela["arte_chefe"] = ficha["arte"]
		dados_tela["pagina"] = wave_manager.pagina_atual
		dados_tela["total_paginas"] = GameData.PAGINAS.size()
		dados_tela["recorde_antes"] = recorde_antes
		tela_derrota.mostrar(dados_tela)

const FICHAS_CHEFE: Dictionary = preload("res://Boss.gd").FICHAS
## Tela de vitória redesenhada (TelaVitoria.gd). Os nós antigos do .tscn
## ficam escondidos; o BotaoContinuar segue ligado ao voltar do Android.
func _criar_tela_vitoria() -> void:
	for nome in ["FundoDourado", "Titulo", "Subtitulo", "DetalhesVitoria", "BotaoContinuar"]:
		var n := menu_vitoria.get_node_or_null(nome)
		if n:
			n.visible = false
	tela_vitoria = Control.new()
	tela_vitoria.set_script(preload("res://TelaVitoria.gd"))
	menu_vitoria.add_child(tela_vitoria)
	tela_vitoria.voltar_pressionado.connect(_on_botao_continuar_pressed)
	tela_vitoria.anuncio_pressionado.connect(func(): AdsManager.mostrar_rewarded("dobrar_tinta"))

## Tela de derrota redesenhada (TelaDerrota.gd, irmã da vitória). Os nós
## antigos do .tscn ficam escondidos.
func _criar_tela_derrota() -> void:
	for nome in ["FundoVegetal", "Titulo", "DetalhesGameOver", "BotaoRecomecar"]:
		var n := menu_game_over.get_node_or_null(nome)
		if n:
			n.visible = false
	tela_derrota = Control.new()
	tela_derrota.set_script(preload("res://TelaDerrota.gd"))
	menu_game_over.add_child(tela_derrota)
	tela_derrota.voltar_pressionado.connect(_on_botao_recomecar_pressed)
	tela_derrota.anuncio_pressionado.connect(func(): AdsManager.mostrar_rewarded("dobrar_tinta"))

## HUD mais legível no celular: coração ao lado da vida, números maiores e a
## barra do chefe abaixo de "Página X/8" (antes os dois se sobrepunham).
func _ajustar_hud_combate() -> void:
	var coracao := TextureRect.new()
	coracao.texture = load("res://assets/ui/icone_coracao.png") # o mesmo da "Partida em andamento"
	coracao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coracao.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coracao.position = Vector2(30, 28) # centrado na altura da barra (35–75)
	coracao.size = Vector2(54, 54)
	coracao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(coracao)
	$HUD.move_child(coracao, hp_bar.get_index())
	hp_bar.offset_left = 96.0
	hp_bar.offset_right = 356.0
	_estilizar_barra_vida()
	hp_texto_label.offset_left = 372.0
	hp_texto_label.offset_right = 560.0
	hp_texto_label.offset_top = 22.0
	hp_texto_label.offset_bottom = 86.0
	hp_texto_label.add_theme_font_size_override("font_size", 46)
	hp_texto_label.add_theme_color_override("font_color", Color("1a1a2e"))
	tinta_label.add_theme_font_size_override("font_size", 56)
	boss_hp_bar.offset_top = 150.0
	boss_hp_bar.offset_bottom = 190.0

func get_xp_necessario_para_nivel(nivel: int) -> int:
	if nivel == 1:
		return 200
	elif nivel == 2:
		return 500
	elif nivel == 3:
		return 1200
	elif nivel == 4:
		return 2500
	else:
		return 2500 + (nivel - 4) * 1500

## Registra e imprime a telemetria de baseline do P0 ao fim de cada run.
## Só MEDE — não altera economia. Chamado em _processar_fim_de_jogo, depois
## de partidas_jogadas/tinta_coletada_total já terem sido incrementados, então
## as médias abaixo já incluem a run recém-terminada.
## Nota: a duração é tempo ATIVO de combate (menus/pausa/background não contam).
func _registrar_telemetria_run(tinta_final: int) -> void:
	SaveManager.incrementar_stat("tempo_jogado_seg", int(_tempo_ativo_seg))

	var s: Dictionary = SaveManager.dados["stats"]
	var partidas: int = max(1, s["partidas_jogadas"])
	var coletadas: int = s["gotas_coletadas"]
	var secas: int = s["gotas_secas"]
	var total_gotas: int = coletadas + secas
	var taxa_seca: float = (float(secas) / float(total_gotas) * 100.0) if total_gotas > 0 else 0.0

	print("=== TELEMETRIA — esta run ===")
	print("  Duração: %ds | Kills: %d | Tinta ganha: %d" % [int(_tempo_ativo_seg), monstros_derrotados_partida, tinta_final])
	print("=== MÉDIAS acumuladas (%d runs) ===" % partidas)
	print("  Tinta/run:     %.0f" % (float(s["tinta_coletada_total"]) / partidas))
	print("  Kills/run:     %.1f" % (float(s["monstros_derrotados"]) / partidas))
	print("  Duração/run:   %.0fs" % (float(s["tempo_jogado_seg"]) / partidas))
	print("  Gota seca:     %.1f%% (%d secas de %d gotas)" % [taxa_seca, secas, total_gotas])

func _spawn_drops_de_tinta(posicao: Vector2, quantidade: int, valor_por_gota: int, textura_path: String) -> void:
	var tex = texturas_drops.get(textura_path)
	if not tex:
		tex = load(textura_path)
		texturas_drops[textura_path] = tex
	for i in range(quantidade):
		var drop = ink_drop_scene.instantiate()
		drop.position = posicao
		drop.setup(valor_por_gota, tex, tinta_label.global_position)
		add_child(drop)
		if i == 0 and jogo_iniciado and not SaveManager.dados.get("dica_gotas_vista", false):
			_mostrar_dica_gotas(drop)

## Primeira gota de tinta da conta: círculo de caneta em volta dela e uma
## frase curta explicando para que serve (sem pausar o jogo).
func _mostrar_dica_gotas(drop: Node2D) -> void:
	SaveManager.dados["dica_gotas_vista"] = true
	SaveManager.salvar()
	var azul := Color("0047ab")
	var escuro := Color("002867")
	# Círculo de caneta que acompanha a gota (some junto se ela for pega)
	var anel := Control.new()
	anel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anel.draw.connect(func():
		var pts: PackedVector2Array = []
		for k in range(41):
			var t: float = float(k) / 40.0 * TAU * 1.08 - 0.6
			pts.append(Vector2(cos(t), sin(t)) * (40.0 + sin(k * 2.3) * 1.6))
		anel.draw_polyline(pts, azul, 4.5, true))
	drop.add_child(anel)
	var tw_anel := create_tween().set_loops(5)
	tw_anel.tween_property(anel, "scale", Vector2(1.18, 1.18), 0.35)
	tw_anel.tween_property(anel, "scale", Vector2.ONE, 0.35)
	tw_anel.finished.connect(func():
		if is_instance_valid(anel):
			anel.queue_free())

	# Texto no alto da página: a gota cai para baixo e fica à vista
	var bloco := Control.new()
	bloco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloco.position = Vector2(0, 190)
	bloco.size = Vector2(1080, 220)
	bloco.z_index = 80
	$HUD.add_child(bloco)
	var fonte: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
	var titulo := "Gotas de tinta!"
	var w: float = fonte.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x + 50.0
	var faixa := ColorRect.new()
	faixa.color = Color(1.0, 0.92, 0.35, 0.75)
	faixa.position = Vector2(540 - w / 2.0, 12)
	faixa.size = Vector2(w, 62)
	faixa.rotation_degrees = -1.0
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloco.add_child(faixa)
	var linhas := [[titulo, 52, 0.0], ["Passe perto para pegar.", 44, 88.0], ["Use no Estojo para ficar mais forte.", 44, 148.0]]
	for l in linhas:
		var lbl := Label.new()
		lbl.text = l[0]
		lbl.add_theme_font_override("font", fonte)
		lbl.add_theme_font_size_override("font_size", l[1])
		lbl.add_theme_color_override("font_color", escuro)
		lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
		lbl.add_theme_constant_override("outline_size", 10)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(0, l[2])
		lbl.size = Vector2(1080, 80 if l[1] == 52 else 64)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bloco.add_child(lbl)
	bloco.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bloco, "modulate:a", 1.0, 0.25)
	tw.tween_interval(5.0)
	tw.tween_property(bloco, "modulate:a", 0.0, 0.8)
	tw.finished.connect(bloco.queue_free)

var _tween_pulso_tinta: Tween

func _on_ink_drop_coletada(valor: int) -> void:
	tinta_partida += valor
	SaveManager.incrementar_stat("gotas_coletadas")
	_atualizar_hud()
	_tocar_som(audio_hit, randf_range(0.95, 1.1))

	# Pulso no contador do HUD confirmando a coleta
	if _tween_pulso_tinta and _tween_pulso_tinta.is_valid():
		_tween_pulso_tinta.kill()
	tinta_label.pivot_offset = tinta_label.size / 2.0
	tinta_label.scale = Vector2.ONE
	_tween_pulso_tinta = create_tween()
	_tween_pulso_tinta.tween_property(tinta_label, "scale", Vector2(1.25, 1.25), 0.05)
	_tween_pulso_tinta.tween_property(tinta_label, "scale", Vector2.ONE, 0.1)

func _atualizar_hud() -> void:
	if hp_bar:
		hp_bar.max_value = player.vidas_max
		hp_bar.value = player.vidas
	if hp_texto_label:
		hp_texto_label.text = str(player.vidas) + " / " + str(player.vidas_max)
	
	tinta_label.text = str(tinta_partida)

## Barra de vida da caneta: preenchimento riscado à mão em vermelho (mesmo
## traço do botão LUTAR, gerado no ChatGPT) sobre fundo branco com contorno.
## Cantos fixos (9 fatias) para o risco não esmagar quando a barra encurta.
func _estilizar_barra_vida() -> void:
	var tex: Texture2D = load("res://assets/ui/barra_vida_riscada.png")
	if tex == null:
		return
	var cheio := StyleBoxTexture.new()
	cheio.texture = tex
	cheio.texture_margin_left = 12.0
	cheio.texture_margin_right = 12.0
	cheio.texture_margin_top = 10.0
	cheio.texture_margin_bottom = 10.0
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(1, 1, 1, 0.92)
	fundo.border_color = Color(Color("8e1b1b"), 0.55)
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(12)
	hp_bar.add_theme_stylebox_override("fill", cheio)
	hp_bar.add_theme_stylebox_override("background", fundo)

## Barra de vida do chefe no estilo do caderno: vermelho sobre papel, com
## contorno de caneta (o padrão do Godot era cinza sobre cinza, ilegível).
func _estilizar_barra_chefe() -> void:
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.98, 0.96, 0.92, 0.9)
	fundo.border_color = Color("1a1a2e")
	fundo.set_border_width_all(3)
	fundo.set_corner_radius_all(8)
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = Color("c0392b")
	cheio.set_corner_radius_all(6)
	cheio.set_border_width_all(3)
	cheio.border_color = Color(0, 0, 0, 0) # mantém o recuo da borda do fundo
	boss_hp_bar.add_theme_stylebox_override("background", fundo)
	boss_hp_bar.add_theme_stylebox_override("fill", cheio)
	boss_hp_bar.show_percentage = false

## Chefe derrotado: caneta protegida, tiros inimigos somem com um respingo e
## os monstros que sobraram (reforços) morrem junto.
func _limpar_tela_vitoria() -> void:
	if player:
		player.protegido_fim_de_fase = true
	for proj in get_tree().get_nodes_in_group("enemy_projectiles"):
		if proj.visible:
			spawn_impacto(proj.global_position, Color("e0352b"), false)
			devolver_projetil_inimigo(proj)
	for inimigo in get_tree().get_nodes_in_group("enemies"):
		if inimigo.has_method("dano_compartilhado"):
			continue # o próprio chefe
		if inimigo.has_method("morrer") and not inimigo.get("morrendo"):
			inimigo.morrer.call_deferred()
		elif not inimigo.has_method("morrer"):
			inimigo.queue_free()

## Aviso curto no alto da tela (abaixo da barra de vida), longe da área de
## desvio: aparece, segura um instante e some, sem se mexer.
func aviso_topo(texto: String, cor: Color = Color("c0392b")) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(1080, 60)
	lbl.position = Vector2(0, 198) # logo abaixo da barra de vida do chefe
	lbl.modulate.a = 0.0
	$HUD.add_child(lbl) # camada da interface: fica por cima do jogo
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.1)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.35)
	tw.tween_callback(lbl.queue_free)

func _spawn_feedback(texto: String, timing: String, pos: Vector2) -> void:
	var feedback = feedback_label_scene.instantiate()
	add_child.call_deferred(feedback)
	feedback.set_deferred("global_position", pos)
	feedback.call_deferred("setup", texto, timing)

func obter_projetil_player() -> Area2D:
	var proj: Area2D = null
	if _pool_projeteis_player.size() > 0:
		proj = _pool_projeteis_player.pop_back()
		proj.visible = true
		proj.set_process(true)
		proj.set_deferred("monitoring", true)
		proj.set_deferred("monitorable", true)
	else:
		proj = projectile_scene.instantiate()
	return proj

func devolver_projetil_player(proj: Area2D) -> void:
	proj.visible = false
	proj.set_process(false)
	proj.set_deferred("monitoring", false)
	proj.set_deferred("monitorable", false)
	proj.ultimo_alvo = null
	if not proj in _pool_projeteis_player:
		_pool_projeteis_player.append(proj)

func obter_projetil_inimigo() -> Area2D:
	var proj: Area2D = null
	# Pula tiros que já foram apagados (segurança contra o pool ficar com lixo)
	while _pool_projeteis_inimigos.size() > 0 and not is_instance_valid(_pool_projeteis_inimigos.back()):
		_pool_projeteis_inimigos.pop_back()
	if _pool_projeteis_inimigos.size() > 0:
		proj = _pool_projeteis_inimigos.pop_back()
		proj.visible = true
		proj.set_process(true)
		proj.set_deferred("monitoring", true)
		proj.set_deferred("monitorable", true)
	else:
		proj = enemy_projectile_scene.instantiate()
	return proj

func devolver_projetil_inimigo(proj: Area2D) -> void:
	proj.visible = false
	proj.set_process(false)
	proj.set_deferred("monitoring", false)
	proj.set_deferred("monitorable", false)
	if not proj in _pool_projeteis_inimigos:
		_pool_projeteis_inimigos.append(proj)

func obter_particulas() -> CPUParticles2D:
	var part: CPUParticles2D = null
	if _pool_partculas.size() > 0:
		part = _pool_partculas.pop_back()
		part.visible = true
	else:
		part = ink_particles_scene.instantiate()
		part.finished.connect(func(): devolver_particulas(part))
	return part

func devolver_particulas(part: CPUParticles2D) -> void:
	part.visible = false
	part.emitting = false
	if not part in _pool_partculas:
		_pool_partculas.append(part)

func _spawn_particles(cor: Color, pos: Vector2) -> void:
	var particles = obter_particulas()
	particles.global_position = pos
	particles.color = cor
	if not particles.is_inside_tree():
		add_child(particles)
	particles.emitting = true

## Sons gravados (CC0). Fontes e licenças em docs/sons.md.
const SONS: Dictionary = {
	"gota": preload("res://assets/sons/gota.ogg"),
	"morte": preload("res://assets/sons/morte.ogg"),
	"dano": preload("res://assets/sons/dano.ogg"),
	"pagina": preload("res://assets/sons/pagina.ogg"),
	"clique": preload("res://assets/sons/clique.ogg"),
	"chefe_surge": preload("res://assets/sons/chefe_surge.ogg"),
	"chefe_ataque": preload("res://assets/sons/chefe_ataque.ogg"),
	"vitoria": preload("res://assets/sons/vitoria.ogg"),
	"derrota": preload("res://assets/sons/derrota.ogg"),
	"acerto": preload("res://assets/sons/acerto.ogg"),
}

## "Tup" do tiro que acerta um monstro: toca muito, então é baixinho, varia
## o tom e não passa de ~12 por segundo (o crítico sai um pouco mais grave).
var _ultimo_acerto_ms: int = -1000
func tocar_acerto(critico: bool = false) -> void:
	var agora := Time.get_ticks_msec()
	if agora - _ultimo_acerto_ms < 80:
		return
	_ultimo_acerto_ms = agora
	_tocar_som(SONS["acerto"], randf_range(0.8, 0.88) if critico else randf_range(0.93, 1.08))

## Rosnado do chefe ao descer para atacar (rasante e mergulho). Espaçado
## para não repetir em ataques seguidos.
var _ultimo_rosnado_ms: int = -10000
func tocar_rosnado_ataque() -> void:
	var agora := Time.get_ticks_msec()
	if agora - _ultimo_rosnado_ms < 1500:
		return
	_ultimo_rosnado_ms = agora
	_tocar_som(SONS["chefe_ataque"], randf_range(0.95, 1.05))

func _tocar_som(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null or not SaveManager.dados.get("som_ativo", true):
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

# Popup flutuante de número de dano (crítico = dourado e maior)
const IMPACTO_TINTA = preload("res://ImpactoTinta.gd")
var _ultimo_tremor_critico: int = 0

## Respingo de tinta no acerto. No crítico, um tremor curto (no máximo a cada 0,25 s).
func spawn_impacto(pos: Vector2, cor: Color, critico: bool) -> void:
	var fx = IMPACTO_TINTA.new()
	fx.cor = cor
	fx.critico = critico
	fx.position = pos
	add_child(fx)
	if critico and Time.get_ticks_msec() - _ultimo_tremor_critico > 250:
		_ultimo_tremor_critico = Time.get_ticks_msec()
		_shake_tela(5.0)

## Dano no chefe: um número só, logo abaixo da barra de vida (à direita),
## somando os acertos seguidos; some 0,8 s depois do último. O crítico pisca
## em dourado. Assim nada cobre o desenho do chefe.
var _lbl_dano_chefe: Label
var _soma_dano_chefe: int = 0
var _ultimo_dano_chefe_ms: int = -10000
var _tween_dano_chefe: Tween
func spawn_dano_chefe(quantidade: int, critico: bool) -> void:
	if _lbl_dano_chefe == null:
		_lbl_dano_chefe = Label.new()
		_lbl_dano_chefe.add_theme_font_override("font", FONTE_NUMEROS)
		_lbl_dano_chefe.add_theme_font_size_override("font_size", 46)
		_lbl_dano_chefe.add_theme_color_override("font_outline_color", Color("1a1a2e"))
		_lbl_dano_chefe.add_theme_constant_override("outline_size", 10)
		_lbl_dano_chefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		# Encostado na ponta direita da barra (ela é ancorada no centro: usar
		# a posição real, não os offsets)
		_lbl_dano_chefe.position = Vector2(boss_hp_bar.position.x + boss_hp_bar.size.x - 300.0,
			boss_hp_bar.position.y + boss_hp_bar.size.y + 2.0)
		_lbl_dano_chefe.size = Vector2(300, 56)
		_lbl_dano_chefe.pivot_offset = Vector2(300, 28)
		_lbl_dano_chefe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$HUD.add_child(_lbl_dano_chefe)
	var agora := Time.get_ticks_msec()
	if agora - _ultimo_dano_chefe_ms > 800:
		_soma_dano_chefe = 0
	_ultimo_dano_chefe_ms = agora
	_soma_dano_chefe += quantidade
	_lbl_dano_chefe.text = "-%s" % str(_soma_dano_chefe)
	_lbl_dano_chefe.add_theme_color_override("font_color", Color("ffb020") if critico else Color.WHITE)
	_lbl_dano_chefe.modulate.a = 1.0
	if _tween_dano_chefe and _tween_dano_chefe.is_valid():
		_tween_dano_chefe.kill()
	_lbl_dano_chefe.scale = Vector2(1.3, 1.3) if critico else Vector2(1.12, 1.12)
	_tween_dano_chefe = create_tween()
	_tween_dano_chefe.tween_property(_lbl_dano_chefe, "scale", Vector2.ONE, 0.12)
	_tween_dano_chefe.tween_interval(0.15)
	_tween_dano_chefe.tween_callback(func(): _lbl_dano_chefe.add_theme_color_override("font_color", Color.WHITE))
	_tween_dano_chefe.tween_interval(0.55)
	_tween_dano_chefe.tween_property(_lbl_dano_chefe, "modulate:a", 0.0, 0.3)

func spawn_damage_number(quantidade: int, pos: Vector2, eh_jogador: bool, critico: bool = false) -> void:
	var lbl = Label.new()
	lbl.text = ("-" + str(quantidade)) if quantidade > 0 else "BLOQUEADO"
	if critico:
		lbl.text = str(quantidade) + "!"
	lbl.add_theme_font_override("font", FONTE_NUMEROS)
	lbl.add_theme_font_size_override("font_size", 64 if critico else 46)
	# Branco/laranja com contorno escuro: legível sobre papel claro e sobre
	# monstro escuro (antes era tinta escura, sumia no chefe preto)
	var cor = Color("ff6b5e") if eh_jogador else (Color("ffb020") if critico else Color.WHITE)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_outline_color", Color("1a1a2e"))
	lbl.add_theme_constant_override("outline_size", 12 if critico else 10)
	lbl.z_index = 50
	add_child(lbl)
	lbl.global_position = pos + Vector2(randf_range(-20, 20), -40)
	lbl.pivot_offset = lbl.size / 2.0

	var tween = create_tween().set_parallel(true)
	lbl.scale = Vector2(0.4, 0.4)
	tween.tween_property(lbl, "scale", Vector2(1.2, 1.2) if critico else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "global_position:y", lbl.global_position.y - 70.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.finished.connect(lbl.queue_free)

func _gerar_som_procedural(frequencia: float, duracao: float, tipo: String = "sin") -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 44100
	wav.stereo = false
	
	var num_amostras = int(44100 * duracao)
	var dados = PackedByteArray()
	dados.resize(num_amostras * 2)
	
	for i in range(num_amostras):
		var tempo = float(i) / 44100.0
		var valor: int = 0
		
		if tipo == "sin":
			var freq_atual = frequencia
			if frequencia == 600.0:
				freq_atual = frequencia + (tempo * 800.0)
			var volume = exp(-tempo * 5.0)
			var amplitude = 28000.0 * volume
			valor = int(sin(tempo * freq_atual * 2.0 * PI) * amplitude)
		elif tipo == "square":
			var volume = exp(-tempo * 12.0)
			var amplitude = 10000.0 * volume
			var sin_val = sin(tempo * frequencia * 2.0 * PI)
			valor = int((1.0 if sin_val >= 0 else -1.0) * amplitude)
			
		dados.encode_s16(i * 2, valor)
		
	wav.data = dados
	return wav

func _criar_menu_upgrades() -> void:
	menu_upgrades = Control.new()
	menu_upgrades.process_mode = Node.PROCESS_MODE_ALWAYS # Funciona pausado
	menu_upgrades.visible = false
	menu_upgrades.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(menu_upgrades)
	# Papel da fase, 3 cartas com contorno de caneta, nível visível e as
	# melhorias que já tem; cartas travadas até os ícones pararem de girar.
	tela_roleta = Control.new()
	tela_roleta.set_script(preload("res://TelaRoleta.gd"))
	menu_upgrades.add_child(tela_roleta)
	tela_roleta.escolhido.connect(func(i: int):
		if i >= 0 and i < opcoes_roleta.size():
			_aplicar_upgrade(opcoes_roleta[i]["id"], i))
	tela_roleta.icone_parou.connect(_tocar_som_clunk)

# ============================================================
# FLUXO DAS PÁGINAS DO CADERNO
# ============================================================
func _on_pagina_iniciada(numero: int, total: int) -> void:
	dano_sofrido_na_pagina = false
	# Checkpoint a cada página: se o Android matar o app (falta de memória,
	# travamento) sem avisar, a run volta nesta página em vez de do zero.
	if _run_em_andamento():
		SaveManager.salvar_run_snapshot(_capturar_estado_run())
	# Página nova, papel limpo: as manchas de batalha ficam na página anterior
	if has_node("Paper"):
		$Paper.limpar_manchas()
	if label_pagina:
		label_pagina.text = "Página %d / %d" % [numero, total]
	if numero > 1:
		_animar_virada_pagina(numero)

func _on_pagina_concluida(numero: int) -> void:
	# Bônus de página perfeita (nenhum dano sofrido)
	if not dano_sofrido_na_pagina:
		var bonus = GameData.bonus_pagina_perfeita(capitulo_atual)
		tinta_partida += bonus
		SaveManager.incrementar_stat("paginas_perfeitas")
		_spawn_feedback("PÁGINA LIMPA! +%d" % bonus, "perfect", Vector2(540, 900))
		_atualizar_hud()

	if numero in GameData.PAGINAS_COM_UPGRADE:
		_abrir_roleta_upgrades()
	else:
		wave_manager.continuar_proxima_pagina()

func _on_descanso_iniciado() -> void:
	get_tree().paused = true

	# A tela cobre o combate com o papel da fase; o rótulo "Página N / 8"
	# (criado depois dos menus) ficaria por cima, então sai junto com o HUD
	hp_bar.visible = false
	hp_texto_label.visible = false
	tinta_label.visible = false
	if botao_pausa_hud:
		botao_pausa_hud.visible = false
	if label_pagina:
		label_pagina.visible = false

	menu_descanso.visible = true
	tela_descanso.mostrar({"cap": capitulo_atual, "pagina": max(1, wave_manager.pagina_atual),
		"total_paginas": GameData.PAGINAS.size(), "vidas": player.vidas, "vidas_max": player.vidas_max,
		"cura": GameData.DESCANSO_CURA, "tinta_partida": tinta_partida,
		"ganho_tinta": GameData.tinta_descanso(capitulo_atual)})
	_tocar_som(audio_vitoria)

func _criar_label_pagina() -> void:
	label_pagina = Label.new()
	label_pagina.text = ""
	label_pagina.add_theme_font_override("font", FONTE_NUMEROS)
	label_pagina.add_theme_font_size_override("font_size", 42)
	label_pagina.add_theme_color_override("font_color", Color("002867"))
	label_pagina.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_pagina.position = Vector2(0, 92)
	label_pagina.size = Vector2(1080, 54)
	$HUD.add_child(label_pagina)

## Animação de virada de página: uma folha desliza cobrindo e revelando a tela
func _animar_virada_pagina(numero: int) -> void:
	# A folha cobre a altura REAL da tela (viewports mais altos que 1920)
	var altura_tela: float = get_viewport_rect().size.y

	var folha = ColorRect.new()
	folha.color = Color(0.98, 0.965, 0.93)
	folha.size = Vector2(1180, altura_tela)
	folha.position = Vector2(1080, 0)
	folha.z_index = 90
	add_child(folha)

	# Sombra da dobra na borda esquerda da folha
	var sombra = ColorRect.new()
	sombra.color = Color(0.2, 0.2, 0.25, 0.25)
	sombra.size = Vector2(24, altura_tela)
	sombra.position = Vector2(-24, 0)
	folha.add_child(sombra)

	var lbl = Label.new()
	lbl.text = "Página %d" % numero
	lbl.add_theme_font_override("font", FONTE_NUMEROS)
	lbl.add_theme_font_size_override("font_size", 80)
	lbl.add_theme_color_override("font_color", Color("002867"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(0, altura_tela / 2.0 - 150.0)
	lbl.size = Vector2(1080, 300)
	folha.add_child(lbl)

	# Som de folhear
	_tocar_som(SONS["pagina"])

	var tween = create_tween()
	tween.tween_property(folha, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.45)
	tween.tween_property(folha, "position:x", -1180.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(folha.queue_free)

## Evento de Descanso (página 4): escolher entre curar ou ganhar tinta
func _criar_menu_descanso() -> void:
	menu_descanso = Control.new()
	menu_descanso.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_descanso.visible = false
	menu_descanso.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(menu_descanso)
	# Corações + tinta da partida, 2 cartas em pé (curar / tinta) com o
	# resultado de cada uma; cartas travadas ~0,5 s depois de abrir.
	tela_descanso = Control.new()
	tela_descanso.set_script(preload("res://TelaDescanso.gd"))
	menu_descanso.add_child(tela_descanso)
	tela_descanso.escolhido.connect(_on_descanso_escolhido)

func _on_descanso_escolhido(id: String) -> void:
	SaveManager.incrementar_stat("descansos_usados")
	_tocar_som(_gerar_som_procedural(880.0, 0.08, "sin"))

	if id == "curar":
		player.vidas = min(player.vidas + GameData.DESCANSO_CURA, player.vidas_max)
		_spawn_feedback("+%d Corações!" % GameData.DESCANSO_CURA, "perfect", player.global_position)
	else:
		var ganho = GameData.tinta_descanso(capitulo_atual)
		tinta_partida += ganho
		_spawn_feedback("+%d Tinta!" % ganho, "perfect", player.global_position)

	# Restaura a exibição do HUD de gameplay
	hp_bar.visible = true
	hp_texto_label.visible = true
	tinta_label.visible = true
	if botao_pausa_hud:
		botao_pausa_hud.visible = true
	if label_pagina:
		label_pagina.visible = true

	_atualizar_hud()
	menu_descanso.visible = false

	# A página 4 também dá direito à roleta de upgrade
	_abrir_roleta_upgrades()

func _abrir_roleta_upgrades() -> void:
	if not is_inside_tree() or not get_tree():
		return
	get_tree().paused = true

	# Monta o pool: só upgrades NÃO maxados + consumíveis (sempre disponíveis)
	var pool: Array = []
	for up in GameData.UPGRADES:
		if up.get("consumivel", false) or player.nivel_upgrade(up["id"]) < up["nivel_max"]:
			pool.append(up)
	pool.shuffle()

	var opcoes: Array = []
	for up in pool:
		if opcoes.size() >= 3:
			break
		opcoes.append(up)
	# Fallback extremo (tudo maxado): repete consumíveis
	while opcoes.size() < 3:
		opcoes.append(GameData.get_upgrade("corretivo_liquido" if opcoes.size() % 2 == 0 else "pote_tinta"))

	opcoes_roleta = opcoes
	menu_upgrades.visible = true
	# A tela já mostra "Página N de 8": o rótulo do combate (criado depois dos
	# menus, fica por cima) sai enquanto a roleta está aberta
	if label_pagina:
		label_pagina.visible = false
	_tocar_som(audio_vitoria)
	tela_roleta.mostrar(tela_roleta.montar_dados(opcoes, player, capitulo_atual,
		max(1, wave_manager.pagina_atual), GameData.PAGINAS.size()))

func _tocar_som_clunk() -> void:
	var som = _gerar_som_procedural(250.0, 0.08, "square")
	_tocar_som(som)

func _aplicar_upgrade(id: String, _index_escolhido: int) -> void:
	# Som de seleção (a animação da carta escolhida fica na TelaRoleta)
	var som_sel = _gerar_som_procedural(880.0, 0.08, "sin")
	_tocar_som(som_sel)

	menu_upgrades.visible = false
	if label_pagina:
		label_pagina.visible = true
	get_tree().paused = false
	
	# Aplica modificadores no Player
	if player:
		match id:
			"corretivo_liquido":
				player.vidas = min(player.vidas + 1, player.vidas_max)
				_atualizar_hud()
				_spawn_feedback("+1 Coração!", "perfect", player.global_position)
			"pote_tinta":
				tinta_partida += GameData.valor_upgrade("pote_tinta", 1)
				_atualizar_hud()
				_spawn_feedback("+50 Tinta!", "perfect", player.global_position)
			_:
				var novo_nivel = player.aplicar_upgrade(id)
				var up = GameData.get_upgrade(id)
				var nome_curto = up["nome"].replace("\n", " ").capitalize()
				_spawn_feedback("%s Lv.%d!" % [nome_curto, novo_nivel], "perfect", player.global_position)

	# Retoma o fluxo para a próxima página via WaveManager
	wave_manager.continuar_proxima_pagina()

func _criar_botao_pausa_hud() -> void:
	# Ícone de pause (desenhado à mão) ancorado na borda direita, à direita do
	# contador de tinta. Evita a câmera/notch central e libera o topo central.
	botao_pausa_hud = Button.new()
	botao_pausa_hud.icon = load("res://assets/pause.svg")
	botao_pausa_hud.add_theme_constant_override("icon_max_width", 48)
	botao_pausa_hud.expand_icon = true
	botao_pausa_hud.flat = true
	botao_pausa_hud.anchor_left = 1.0
	botao_pausa_hud.anchor_right = 1.0
	botao_pausa_hud.offset_left = -72.0
	botao_pausa_hud.offset_right = -16.0
	botao_pausa_hud.offset_top = 22.0
	botao_pausa_hud.offset_bottom = 90.0
	botao_pausa_hud.process_mode = Node.PROCESS_MODE_ALWAYS # Funciona pausado
	$HUD.add_child(botao_pausa_hud)
	# Fica atrás dos menus (mesma camada do número da tinta): recebe o
	# escurecimento do overlay do MenuIniciar/pausa/etc. em vez de flutuar por cima.
	$HUD.move_child(botao_pausa_hud, menu_iniciar.get_index())

	botao_pausa_hud.pressed.connect(_on_botao_pausa_pressed)

func _on_botao_pausa_pressed() -> void:
	if not jogo_iniciado or menu_upgrades.visible or menu_game_over.visible or menu_vitoria.visible or menu_pausa.visible:
		return
		
	# Som de clique
	_tocar_som(SONS["clique"])
	
	# Melhorias da partida (nome, nível e efeito atual) para as cartas da pausa
	var melhorias: Array = []
	for id in player.upgrades.keys():
		var up = GameData.get_upgrade(id)
		var nv: int = int(player.upgrades[id])
		if not up.is_empty() and nv > 0:
			melhorias.append({"icone": up["icone"], "nome": up["nome"], "nivel": nv,
				"efeito": up["stats"][clamp(nv - 1, 0, up["stats"].size() - 1)]})
	# O rótulo "Página N / 8" (criado depois dos menus) ficaria por cima
	if label_pagina:
		label_pagina.visible = false
	menu_pausa.visible = true
	tela_pausa.mostrar({"cap": capitulo_atual, "pagina": max(1, wave_manager.pagina_atual),
		"total_paginas": GameData.PAGINAS.size(), "vidas": player.vidas, "vidas_max": player.vidas_max,
		"tinta_partida": tinta_partida, "melhorias": melhorias,
		"som": SaveManager.dados.get("som_ativo", true), "vibracao": SaveManager.dados.get("vibracao_ativa", true)})
	get_tree().paused = true

func _criar_menu_pausa() -> void:
	menu_pausa = Control.new()
	menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.visible = false
	menu_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(menu_pausa)
	tela_pausa = Control.new()
	tela_pausa.set_script(preload("res://TelaPausa.gd"))
	menu_pausa.add_child(tela_pausa)
	tela_pausa.continuar.connect(_on_retomar_pausa_pressed)
	tela_pausa.abandonar.connect(func():
		SaveManager.limpar_run_snapshot() # Saída deliberada: abandona a run
		get_tree().paused = false
		get_tree().change_scene_to_file("res://hub.tscn"))
	# Som e vibração: os mesmos ajustes das Configurações do hub
	tela_pausa.ajuste_alterado.connect(func(chave: String, ligado: bool):
		SaveManager.dados[chave] = ligado
		SaveManager.salvar()
		_tocar_som(SONS["clique"]))

func _criar_label_contagem() -> void:
	label_contagem = Label.new()
	label_contagem.process_mode = Node.PROCESS_MODE_ALWAYS
	label_contagem.visible = false
	label_contagem.add_theme_font_override("font", FONTE_NUMEROS)
	label_contagem.add_theme_font_size_override("font_size", 140)
	label_contagem.add_theme_color_override("font_color", Color("002867")) # Azul BIC
	label_contagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_contagem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_contagem.position = Vector2(0, 800)
	label_contagem.size = Vector2(1080, 300)
	label_contagem.pivot_offset = Vector2(540, 150)
	$HUD.add_child(label_contagem)

func _on_retomar_pausa_pressed() -> void:
	menu_pausa.visible = false
	if label_pagina:
		label_pagina.visible = true
	
	# Som de clique
	_tocar_som(SONS["clique"])
	
	label_contagem.visible = true
	
	# Sequência: 3, 2, 1, JÁ!
	var seq = [
		{"texto": "3", "freq": 440.0},
		{"texto": "2", "freq": 440.0},
		{"texto": "1", "freq": 440.0},
		{"texto": "JÁ!", "freq": 880.0}
	]
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	for etapa in seq:
		tween.tween_callback(func():
			label_contagem.text = etapa["texto"]
			label_contagem.scale = Vector2.ZERO
			var bipe = _gerar_som_procedural(etapa["freq"], 0.12, "sin")
			_tocar_som(bipe)
		)
		tween.tween_property(label_contagem, "scale", Vector2(1.3, 1.3), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label_contagem, "scale", Vector2.ZERO, 0.25).set_delay(0.4)
		tween.tween_interval(0.1)
		
	tween.finished.connect(func():
		label_contagem.visible = false
		get_tree().paused = false
	)
