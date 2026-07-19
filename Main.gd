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
var label_status_hp_descanso: Label
var label_status_tinta_descanso: Label
var fundo_upgrades: Node
var fundo_descanso: Node
var bg_cards_descanso: Array = []

# Rewarded ads (revive e dobrar tinta)
var menu_revive: Control
var tinta_final_ultima_run: int = 0
var botao_dobrar_vitoria: Button
var botao_dobrar_gameover: Button

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
var audio_hit: AudioStreamWAV
var audio_kill: AudioStreamWAV
var audio_dano: AudioStreamWAV
var audio_vitoria: AudioStreamWAV

# Sistema de Upgrades Roguelite
var menu_upgrades: Control
var botoes_upgrades: Array = []
var dados_cartas: Array = []
var label_dica_upgrades: Label
var menu_pausa: Control
var botao_pausa_hud: Button
var container_habilidades_pausa: HBoxContainer
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
	var lbl_detalhes_gameover = menu_game_over.get_node_or_null("DetalhesGameOver")
	if lbl_detalhes_gameover:
		lbl_detalhes_gameover.add_theme_font_override("font", FONTE_NUMEROS)

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
	
	# Gera sons procedurais
	audio_kill = _gerar_som_procedural(1450.0, 0.08, "sin")
	audio_hit = _gerar_som_procedural(950.0, 0.05, "sin")
	audio_dano = _gerar_som_procedural(200.0, 0.15, "square")
	audio_vitoria = _gerar_som_procedural(600.0, 0.6, "sin")
	
	_atualizar_hud()
	
	_criar_menu_upgrades()
	_criar_botao_pausa_hud()
	_criar_menu_pausa()
	_criar_label_contagem()
	_criar_label_pagina()
	_criar_menu_descanso()
	_criar_menu_revive()
	_criar_botoes_dobrar_tinta()

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
	# Recua o número para não sobrepor o ícone de tinta
	tinta_label.offset_right = -124.0

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
		return
	if menu_descanso and menu_descanso.visible:
		return
	# Menus de fim de partida: voltar equivale a sair para o Hub.
	if menu_game_over and menu_game_over.visible:
		_on_botao_recomecar_pressed()
		return
	if menu_vitoria and menu_vitoria.visible:
		_on_botao_continuar_pressed()
		return
	# Já pausado: voltar retoma a partida.
	if menu_pausa and menu_pausa.visible:
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
	wave_manager.iniciar_fase_na_pagina(capitulo_atual, pagina)

	# Consumido: o snapshot será regravado se o app for ao background de novo.
	SaveManager.limpar_run_snapshot()
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
		return

	_finalizar_derrota()

func _finalizar_derrota() -> void:
	fim_de_jogo_declarado = true
	SaveManager.limpar_run_snapshot() # Run encerrada: nada a retomar
	boss_hp_bar.visible = false
	_processar_fim_de_jogo(false)
	get_tree().paused = true
	menu_game_over.visible = true

# ============================================================
# REWARDED ADS — revive e dobrar tinta
# ============================================================
func _criar_menu_revive() -> void:
	menu_revive = Control.new()
	menu_revive.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_revive.visible = false
	menu_revive.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(menu_revive)

	var fundo = ColorRect.new()
	fundo.color = Color(0.98, 0.965, 0.93, 0.95)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_revive.add_child(fundo)

	var titulo = Label.new()
	titulo.text = "✏️ SEGUNDA CHANCE?"
	titulo.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", Color("002867"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 560)
	titulo.size = Vector2(1080, 120)
	menu_revive.add_child(titulo)

	var sub = Label.new()
	sub.text = "Apague os erros da página e continue\nde onde parou com 3 corações!"
	sub.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	sub.add_theme_font_size_override("font_size", 36)
	sub.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 700)
	sub.size = Vector2(1080, 120)
	menu_revive.add_child(sub)

	var btn_continuar = Button.new()
	btn_continuar.name = "BotaoContinuar"
	btn_continuar.text = "[ CONTINUAR ]"
	btn_continuar.icon = load("res://assets/ads.svg")
	btn_continuar.add_theme_constant_override("icon_max_width", 44)
	btn_continuar.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn_continuar.add_theme_font_size_override("font_size", 52)
	btn_continuar.add_theme_color_override("font_color", Color("2e7d32"))
	btn_continuar.add_theme_color_override("font_hover_color", Color("43a047"))
	btn_continuar.flat = true
	btn_continuar.position = Vector2(290, 900)
	btn_continuar.size = Vector2(500, 90)
	menu_revive.add_child(btn_continuar)
	btn_continuar.pressed.connect(func():
		btn_continuar.disabled = true
		btn_continuar.text = "[ Carregando... ]"
		AdsManager.revive_usado_na_run = true
		AdsManager.mostrar_rewarded("revive")
	)

	var btn_desistir = Button.new()
	btn_desistir.text = "[ DESISTIR ]"
	btn_desistir.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn_desistir.add_theme_font_size_override("font_size", 36)
	btn_desistir.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	btn_desistir.add_theme_color_override("font_hover_color", Color(0.85, 0.1, 0.1))
	btn_desistir.flat = true
	btn_desistir.position = Vector2(340, 1050)
	btn_desistir.size = Vector2(400, 80)
	menu_revive.add_child(btn_desistir)
	btn_desistir.pressed.connect(func():
		AdsManager.revive_usado_na_run = true
		menu_revive.visible = false
		get_tree().paused = false
		_finalizar_derrota()
	)

func _criar_botoes_dobrar_tinta() -> void:
	botao_dobrar_vitoria = _criar_botao_dobrar(menu_vitoria)
	botao_dobrar_gameover = _criar_botao_dobrar(menu_game_over)

func _criar_botao_dobrar(menu_pai: Control) -> Button:
	var btn = Button.new()
	btn.text = "[ DOBRAR TINTA ]"
	btn.icon = load("res://assets/ads.svg")
	btn.add_theme_constant_override("icon_max_width", 36)
	btn.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_color_override("font_color", Color("2e7d32"))
	btn.add_theme_color_override("font_hover_color", Color("43a047"))
	btn.flat = true
	btn.position = Vector2(290, 1560)
	btn.size = Vector2(500, 80)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pai.add_child(btn)
	btn.pressed.connect(func():
		btn.disabled = true
		btn.text = "[ Carregando... ]"
		AdsManager.mostrar_rewarded("dobrar_tinta")
	)
	return btn

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
			var btn_rev = menu_revive.get_node_or_null("BotaoContinuar") if menu_revive else null
			if btn_rev:
				btn_rev.disabled = false
				btn_rev.text = "[ CONTINUAR ]"
			AdsManager.revive_usado_na_run = false
			_spawn_feedback("SEM CONEXÃO!", "miss", player.global_position if player else Vector2(540, 960))
		"dobrar_tinta":
			for btn in [botao_dobrar_vitoria, botao_dobrar_gameover]:
				if btn and btn.disabled:
					btn.disabled = false
					btn.text = "[ DOBRAR TINTA ]"
			_spawn_feedback("FALHA DE REDE!", "miss", Vector2(540, 1500))

func _executar_revive() -> void:
	menu_revive.visible = false
	menu_revive.get_node("BotaoContinuar").disabled = false
	menu_revive.get_node("BotaoContinuar").text = "[ CONTINUAR ]"

	# Cancela a declaração de fim de jogo para permitir novas jogadas
	fim_de_jogo_declarado = false

	# Limpa as ameaças da tela (poupa Boss e Elite, que não morrem por contato)
	for inimigo in get_tree().get_nodes_in_group("enemies"):
		if inimigo.get("morre_no_contato") == true:
			inimigo.queue_free()
	for proj in get_tree().get_nodes_in_group("enemy_projectiles"):
		proj.queue_free()

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

	for btn in [botao_dobrar_vitoria, botao_dobrar_gameover]:
		if btn and btn.disabled:
			btn.text = "[ +%d RECEBIDO ✓ ]" % tinta_final_ultima_run

	_tocar_som(audio_vitoria)

func _on_boss_surgiu(boss_node: Node2D) -> void:
	boss_hp_bar.max_value = boss_node.hp_max
	boss_hp_bar.value = boss_node.hp
	boss_hp_bar.visible = true
	
	boss_node.hp_alterado.connect(func(novo_hp):
		boss_hp_bar.value = novo_hp
	)
	boss_node.morreu.connect(func():
		boss_hp_bar.visible = false
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
	
	_tocar_som(audio_vitoria)
	get_tree().paused = true
	menu_vitoria.visible = true

func _processar_fim_de_jogo(venceu: bool) -> void:
	# 1. Bônus por vidas (10% por vida)
	var bonus_vida_pct: int = player.vidas * 10
	var tinta_bonus_vida: int = int(tinta_partida * (float(bonus_vida_pct) / 100.0)) if venceu else 0
	
	# Tinta acumulada na partida antes do multiplicador do Capítulo
	var tinta_base_final = tinta_partida + tinta_bonus_vida
	
	# 2. Bônus de Capítulo (+10% por capítulo acima do 1)
	var bonus_cap_pct: int = (capitulo_atual - 1) * 10
	var tinta_bonus_cap: int = int(tinta_base_final * (float(bonus_cap_pct) / 100.0))
	var tinta_final: int = tinta_base_final + tinta_bonus_cap

	# Guarda para o botão "DOBRAR TINTA" (rewarded ad) e reabilita os botões
	tinta_final_ultima_run = tinta_final
	for btn in [botao_dobrar_vitoria, botao_dobrar_gameover]:
		if btn:
			btn.disabled = false
			btn.text = "[ DOBRAR TINTA ]"
			btn.visible = tinta_final > 0
	
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
	
	# 7. Atualiza UI dos menus
	if venceu:
		var texto_lvlup = "[ NOVO NÍVEL ALCANÇADO: Lv. %d! ] (+5 Clipes)\n" % dados_save["nivel_conta"] if subiu_nivel else ""
		label_detalhes_vitoria.text = (
			"Tinta Coletada: +%d\n" +
			"Bônus por Vidas (+%d%%): +%d\n" +
			"Bônus Capítulo %d (+%d%%): +%d\n" +
			"Tinta Ganha na Run: +%d\n" +
			"XP Ganho na Run: +%d XP\n" +
			texto_desbloqueio +
			texto_lvlup + "\n" +
			"Tinta: %d  |  Clipes: %d"
		) % [
			tinta_partida, 
			bonus_vida_pct, 
			tinta_bonus_vida, 
			capitulo_atual, 
			bonus_cap_pct, 
			tinta_bonus_cap, 
			tinta_final, 
			xp_ganho, 
			dados_save["tinta"], 
			dados_save["clipes_ouro"]
		]
	else:
		var texto_lvlup = "[ NOVO NÍVEL ALCANÇADO: Lv. %d! ] (+5 Clipes)\n" % dados_save["nivel_conta"] if subiu_nivel else ""
		var label_gameover = menu_game_over.get_node_or_null("DetalhesGameOver")
		if label_gameover:
			label_gameover.text = (
				"Tinta Coletada: +%d\n" +
				"XP Ganho na Run: +%d XP\n" +
				texto_lvlup + "\n" +
				"Tinta: %d  |  Clipes: %d"
			) % [tinta_final, xp_ganho, dados_save["tinta"], dados_save["clipes_ouro"]]

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
	print("  Duração: %ds | Kills: %d | Tinta ganha: %d" % [dur_seg, monstros_derrotados_partida, tinta_final])
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
func spawn_damage_number(quantidade: int, pos: Vector2, eh_jogador: bool, critico: bool = false) -> void:
	var lbl = Label.new()
	lbl.text = ("-" + str(quantidade)) if quantidade > 0 else "BLOQUEADO"
	if critico:
		lbl.text = str(quantidade) + "!"
	lbl.add_theme_font_override("font", FONTE_NUMEROS)
	lbl.add_theme_font_size_override("font_size", 52 if critico else 36)
	var cor = Color("d9534f") if eh_jogador else (Color("f39c12") if critico else Color("30303e"))
	lbl.add_theme_color_override("font_color", cor)
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
	
	# Fundo estilo folha de caderno da fase atual (apenas cor sólida)
	var fundo = ColorRect.new()
	fundo.color = _obter_cor_papel_capitulo(capitulo_atual)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.modulate.a = 0.96
	menu_upgrades.add_child(fundo)
	fundo_upgrades = fundo
	
	# Título
	var titulo = Label.new()
	titulo.text = "ESCOLHA UM UPGRADE"
	titulo.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	titulo.add_theme_font_size_override("font_size", 60)
	titulo.add_theme_color_override("font_color", Color("002867")) # Azul BIC
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 160)
	titulo.size = Vector2(1080, 120)
	menu_upgrades.add_child(titulo)
	
	# Dica/Status
	label_dica_upgrades = Label.new()
	label_dica_upgrades.text = "⭐ Girando a roleta de materiais... ⭐"
	label_dica_upgrades.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	label_dica_upgrades.add_theme_font_size_override("font_size", 34)
	label_dica_upgrades.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	label_dica_upgrades.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_dica_upgrades.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_dica_upgrades.position = Vector2(0, 260)
	label_dica_upgrades.size = Vector2(1080, 80)
	menu_upgrades.add_child(label_dica_upgrades)
	
	for i in range(3):
		var btn = Button.new()
		btn.size = Vector2(280, 700)
		
		# Calcula a posição X absoluta lado a lado (margem 80, largura 280, espaço 40)
		var pos_x = 80 + i * (280 + 40)
		btn.position = Vector2(pos_x, 400)
		btn.flat = true
		btn.pivot_offset = Vector2(140, 350) # Para animação de escala centralizada
		menu_upgrades.add_child(btn)
		botoes_upgrades.append(btn)
		
		# Imagem de fundo da carta (backgroundpowerup.png)
		var bg_card = TextureRect.new()
		bg_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_card.stretch_mode = TextureRect.STRETCH_SCALE
		bg_card.texture = load("res://assets/backgroundpowerup.png")
		bg_card.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(bg_card)
		
		# Área de recorte dos ícones na metade superior (centralizada: 280 - 200 = 80 / 2 = 40)
		var recorte = Control.new()
		recorte.size = Vector2(200, 200)
		recorte.position = Vector2(40, 120)
		recorte.clip_contents = true
		btn.add_child(recorte)
		
		# Carrossel de ícones rolável
		var carrossel = Control.new()
		carrossel.size = Vector2(200, 2000)
		carrossel.position = Vector2(0, -1800)
		recorte.add_child(carrossel)
		
		# Preenche o carrossel com 10 slots de imagens verticais
		var texturas_carrossel: Array = []
		for j in range(10):
			var tex = TextureRect.new()
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.size = Vector2(200, 200)
			tex.position = Vector2(0, j * 200)
			carrossel.add_child(tex)
			texturas_carrossel.append(tex)
			
		# Status "GIRANDO..." (centralizado horizontalmente e logo abaixo do ícone)
		var lbl_status = Label.new()
		lbl_status.text = "GIRANDO..."
		lbl_status.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
		lbl_status.add_theme_font_size_override("font_size", 34)
		lbl_status.add_theme_color_override("font_color", Color("002867"))
		lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_status.position = Vector2(0, 420)
		lbl_status.size = Vector2(280, 80)
		btn.add_child(lbl_status)
		
		# VBox de informações reais da habilidade
		# Ocupa da base do ícone até perto da borda inferior da carta,
		# com margens laterais simétricas (30px de cada lado)
		var vbox_info = VBoxContainer.new()
		vbox_info.name = "Info"
		vbox_info.position = Vector2(30, 340)
		vbox_info.size = Vector2(220, 280)
		vbox_info.add_theme_constant_override("separation", 12)
		vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_info.visible = false
		btn.add_child(vbox_info)
		
		# Nome do Upgrade
		var lbl_nome = Label.new()
		lbl_nome.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
		lbl_nome.add_theme_font_size_override("font_size", 28)
		lbl_nome.add_theme_color_override("font_color", Color("002867")) # Azul BIC
		lbl_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_nome.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox_info.add_child(lbl_nome)
		
		# Descrição detalhada
		var lbl_desc = Label.new()
		lbl_desc.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
		lbl_desc.add_theme_font_size_override("font_size", 18)
		lbl_desc.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox_info.add_child(lbl_desc)
		
		# Stats fora do card, abaixo da moldura
		var lbl_stats = Label.new()
		lbl_stats.add_theme_font_override("font", FONTE_NUMEROS)
		lbl_stats.add_theme_font_size_override("font_size", 28)
		lbl_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_stats.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl_stats.position = Vector2(pos_x, 1115)
		lbl_stats.size = Vector2(280, 80)
		lbl_stats.visible = false
		menu_upgrades.add_child(lbl_stats)

		# Salva a referência da carta para manipulação simples
		dados_cartas.append({
			"botao": btn,
			"bg_card": bg_card,
			"carrossel": carrossel,
			"texturas": texturas_carrossel,
			"vbox_info": vbox_info,
			"lbl_nome": lbl_nome,
			"lbl_desc": lbl_desc,
			"lbl_stats": lbl_stats,
			"lbl_status": lbl_status,
			"pos_original": btn.position
		})

# ============================================================
# FLUXO DAS PÁGINAS DO CADERNO
# ============================================================
func _on_pagina_iniciada(numero: int, total: int) -> void:
	dano_sofrido_na_pagina = false
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
	
	# Garante que o fundo esteja adaptado ao capítulo atual (apenas a cor)
	if fundo_descanso:
		fundo_descanso.color = _obter_cor_papel_capitulo(capitulo_atual)
		
	# Atualiza o modulate das cartas de descanso para o capítulo atual
	var cor_fundo_carta = _obter_cor_fundo_carta(capitulo_atual)
	for bg in bg_cards_descanso:
		if bg:
			bg.modulate = cor_fundo_carta
	
	# Oculta o HUD de gameplay poluído por trás
	hp_bar.visible = false
	hp_texto_label.visible = false
	tinta_label.visible = false
	if botao_pausa_hud:
		botao_pausa_hud.visible = false
	if label_pagina:
		label_pagina.visible = false
		
	# Atualiza informações de status no descanso
	if label_status_hp_descanso:
		label_status_hp_descanso.text = "🩸 Vida: %d / %d" % [player.vidas, player.vidas_max]
	if label_status_tinta_descanso:
		label_status_tinta_descanso.text = "Tinta: %d" % tinta_partida
		
	# Atualiza o texto do pote de tinta do descanso com o valor correto deste capítulo
	var label_desc_tinta = menu_descanso.get_node_or_null("CartaDescansoTinta/Desc")
	if label_desc_tinta:
		label_desc_tinta.text = "+%d gotas de tinta" % GameData.tinta_descanso(capitulo_atual)

	menu_descanso.visible = true
	_tocar_som(audio_vitoria)

func _criar_label_pagina() -> void:
	label_pagina = Label.new()
	label_pagina.text = ""
	label_pagina.add_theme_font_override("font", FONTE_NUMEROS)
	label_pagina.add_theme_font_size_override("font_size", 32)
	label_pagina.add_theme_color_override("font_color", Color("002867", 0.75))
	label_pagina.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_pagina.position = Vector2(0, 95)
	label_pagina.size = Vector2(1080, 40)
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
	var som_folha = _gerar_som_procedural(520.0, 0.08, "sin")
	_tocar_som(som_folha)

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

	# Fundo estilo folha de caderno da fase atual (apenas cor sólida)
	var fundo = ColorRect.new()
	fundo.color = _obter_cor_papel_capitulo(capitulo_atual)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.modulate.a = 0.96
	menu_descanso.add_child(fundo)
	fundo_descanso = fundo

	var titulo = Label.new()
	titulo.text = "🍃 PÁGINA DE DESCANSO 🍃"
	titulo.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	titulo.add_theme_font_size_override("font_size", 56)
	titulo.add_theme_color_override("font_color", Color("002867"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 200)
	titulo.size = Vector2(1080, 120)
	menu_descanso.add_child(titulo)

	var sub = Label.new()
	sub.text = "Um momento de paz no caderno.\nEscolha com sabedoria:"
	sub.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 310)
	sub.size = Vector2(1080, 100)
	menu_descanso.add_child(sub)

	# Container para status do jogador em destaque
	var container_status = HBoxContainer.new()
	container_status.alignment = BoxContainer.ALIGNMENT_CENTER
	container_status.position = Vector2(0, 435)
	container_status.size = Vector2(1080, 80)
	menu_descanso.add_child(container_status)

	label_status_hp_descanso = Label.new()
	label_status_hp_descanso.text = "🩸 Vida: - / -"
	label_status_hp_descanso.add_theme_font_override("font", FONTE_NUMEROS)
	label_status_hp_descanso.add_theme_font_size_override("font_size", 36)
	label_status_hp_descanso.add_theme_color_override("font_color", Color("d9534f"))
	container_status.add_child(label_status_hp_descanso)

	var espacador = Control.new()
	espacador.custom_minimum_size = Vector2(80, 10)
	container_status.add_child(espacador)

	label_status_tinta_descanso = Label.new()
	label_status_tinta_descanso.text = "Tinta: -"
	label_status_tinta_descanso.add_theme_font_override("font", FONTE_NUMEROS)
	label_status_tinta_descanso.add_theme_font_size_override("font_size", 36)
	label_status_tinta_descanso.add_theme_color_override("font_color", Color("002867"))
	container_status.add_child(label_status_tinta_descanso)

	# Duas cartas de escolha lado a lado
	var opcoes_descanso = [
		{"id": "curar", "titulo": "CORRETIVO\nDA SORTE", "desc": "Cura %d corações" % GameData.DESCANSO_CURA, "icone": "res://assets/corretivo.png"},
		{"id": "tinta", "titulo": "POTE DE\nTINTA", "desc": "+%d gotas de tinta" % GameData.tinta_descanso(capitulo_atual), "icone": "res://assets/pote_tinta.png"}
	]

	bg_cards_descanso.clear()
	for i in range(2):
		var op = opcoes_descanso[i]
		var btn = Button.new()
		btn.size = Vector2(360, 520)
		btn.position = Vector2(120 + i * 480, 560)
		btn.flat = true
		btn.clip_contents = true
		btn.name = "CartaDescanso" + op["id"].capitalize()
		menu_descanso.add_child(btn)

		var bg_card = TextureRect.new()
		bg_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_card.stretch_mode = TextureRect.STRETCH_SCALE
		bg_card.texture = load("res://assets/backgroundpowerup.png")
		bg_card.position = Vector2.ZERO
		bg_card.size = Vector2(360, 520)
		btn.add_child(bg_card)
		bg_cards_descanso.append(bg_card)

		var img = TextureRect.new()
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.texture = load(op["icone"])
		img.size = Vector2(180, 180)
		img.position = Vector2(90, 70)
		btn.add_child(img)

		var lbl_titulo = Label.new()
		lbl_titulo.text = op["titulo"]
		lbl_titulo.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
		lbl_titulo.add_theme_font_size_override("font_size", 36)
		lbl_titulo.add_theme_color_override("font_color", Color("002867"))
		lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_titulo.position = Vector2(30, 270)
		lbl_titulo.size = Vector2(300, 100)
		btn.add_child(lbl_titulo)

		var lbl_desc = Label.new()
		lbl_desc.name = "Desc"
		lbl_desc.text = op["desc"]
		lbl_desc.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
		lbl_desc.add_theme_font_size_override("font_size", 28)
		lbl_desc.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
		lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl_desc.position = Vector2(30, 380)
		lbl_desc.size = Vector2(300, 90)
		btn.add_child(lbl_desc)

		btn.pressed.connect(func(): _on_descanso_escolhido(op["id"]))

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
	
	# Garante que o fundo esteja adaptado ao capítulo atual (apenas a cor)
	if fundo_upgrades:
		fundo_upgrades.color = _obter_cor_papel_capitulo(capitulo_atual)
	
	# Restaura modulated e posições originais das cartas
	var cor_fundo_carta = _obter_cor_fundo_carta(capitulo_atual)
	for i in range(3):
		var carta = dados_cartas[i]
		carta["botao"].modulate = Color.WHITE
		carta["botao"].scale = Vector2.ONE
		carta["botao"].position = carta["pos_original"]
		carta["botao"].disabled = true # Desabilita cliques durante o giro
		carta["vbox_info"].visible = false
		carta["lbl_stats"].visible = false
		carta["lbl_status"].visible = true
		carta["carrossel"].position.y = -1800.0
		if carta.has("bg_card") and carta["bg_card"]:
			carta["bg_card"].modulate = cor_fundo_carta
	
	label_dica_upgrades.text = "⭐ Girando a roleta de materiais... ⭐"

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
	_tocar_som(audio_vitoria)
	
	# Inicia o giro e tremor de cada slot com delays sequenciais
	for i in range(3):
		var carta = dados_cartas[i]
		var info_final = opcoes[i]
		
		# Configura as texturas do carrossel (ícone final na posição 0, outros aleatórios)
		carta["texturas"][0].texture = load(info_final["icone"])
		for j in range(1, 10):
			var index_aleatorio = randi() % GameData.UPGRADES.size()
			carta["texturas"][j].texture = load(GameData.UPGRADES[index_aleatorio]["icone"])

		# Popula as informações de textos (stats do PRÓXIMO nível + indicador Lv)
		var nivel_atual = player.nivel_upgrade(info_final["id"])
		var nivel_alvo = nivel_atual + 1
		var idx_stats = clamp(nivel_alvo - 1, 0, info_final["stats"].size() - 1)
		var texto_stats: String = info_final["stats"][idx_stats]
		if not info_final.get("consumivel", false):
			if nivel_atual > 0:
				texto_stats += "\nLv.%d → Lv.%d" % [nivel_atual, nivel_alvo]
			else:
				texto_stats += "\nNOVO!"

		carta["lbl_nome"].text = info_final["nome"]
		carta["lbl_desc"].text = info_final["descricao"]
		carta["lbl_stats"].text = texto_stats
		carta["lbl_stats"].add_theme_color_override("font_color", Color(info_final["cor_stats"]))
		
		# Limpa e conecta os sinais de cliques
		for conn in carta["botao"].pressed.get_connections():
			carta["botao"].pressed.disconnect(conn.callable)
		carta["botao"].pressed.connect(func():
			_aplicar_upgrade(info_final["id"], i)
		)
		
		# Efeito de tremor lateral suave (tremor de máquina)
		var tween_tremor = create_tween().set_loops(int(10 + i * 8))
		tween_tremor.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var pos_org = carta["botao"].position
		tween_tremor.tween_property(carta["botao"], "position:x", pos_org.x + randf_range(-3.0, 3.0), 0.05)
		tween_tremor.tween_property(carta["botao"], "position:x", pos_org.x, 0.05)
		
		# Giro vertical usando Tween com bounce elástico no final
		var tempo_giro = 1.0 + (i * 0.4)
		var tween_giro = create_tween()
		tween_giro.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween_giro.tween_property(carta["carrossel"], "position:y", 0.0, tempo_giro).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Callback da parada da roleta
		tween_giro.finished.connect(func():
			tween_tremor.kill()
			carta["botao"].position = pos_org
			carta["lbl_status"].visible = false
			carta["vbox_info"].visible = true
			carta["lbl_stats"].visible = true
			_tocar_som_clunk()
			
			# Se for a última roleta a parar (índice 2)
			if i == 2:
				label_dica_upgrades.text = "👉 Toque em um para escolher! 👈"
				for k in range(3):
					dados_cartas[k]["botao"].disabled = false # Habilita cliques
		)

func _tocar_som_clunk() -> void:
	var som = _gerar_som_procedural(250.0, 0.08, "square")
	_tocar_som(som)

func _aplicar_upgrade(id: String, index_escolhido: int) -> void:
	# Desabilita cliques para evitar duplo clique
	for i in range(3):
		dados_cartas[i]["botao"].disabled = true
		
	# Som de seleção
	var som_sel = _gerar_som_procedural(880.0, 0.08, "sin")
	_tocar_som(som_sel)
	
	# Animação da carta escolhida: pulso de escala + brilho
	var carta_escolhida = dados_cartas[index_escolhido]
	var tween_sel = create_tween()
	tween_sel.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_sel.tween_property(carta_escolhida["botao"], "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_sel.tween_property(carta_escolhida["botao"], "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Escurece e desliza as outras cartas para fora da tela
	for i in range(3):
		if i != index_escolhido:
			var carta_outra = dados_cartas[i]
			var direcao_deslizar = -400.0 if i < index_escolhido else 400.0
			var tween_outra = create_tween().set_parallel(true)
			tween_outra.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween_outra.tween_property(carta_outra["botao"], "modulate", Color(0.2, 0.2, 0.2, 0.0), 0.5)
			tween_outra.tween_property(carta_outra["botao"], "position:x", carta_outra["botao"].position.x + direcao_deslizar, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
	# Espera concluir as animações antes de aplicar os efeitos e fechar
	await get_tree().create_timer(0.6).timeout
	
	menu_upgrades.visible = false
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
	var som_clic = _gerar_som_procedural(440.0, 0.1, "sin")
	_tocar_som(som_clic)
	
	# Preenche o histórico de upgrades do jogador
	_atualizar_habilidades_pausa()
	
	menu_pausa.visible = true
	get_tree().paused = true

func _criar_menu_pausa() -> void:
	menu_pausa = Control.new()
	menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.visible = false
	menu_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(menu_pausa)
	
	# Fundo semi-transparente estilo folha de rascunho
	var fundo = ColorRect.new()
	fundo.color = Color(0.98, 0.965, 0.93, 0.95)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_pausa.add_child(fundo)
	
	# Título
	var titulo = Label.new()
	titulo.text = "PARTIDA PAUSADA"
	titulo.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", Color("002867"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 300)
	titulo.size = Vector2(1080, 100)
	menu_pausa.add_child(titulo)
	
	# Subtítulo Habilidades
	var sub = Label.new()
	sub.text = "Habilidades nesta run:"
	sub.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 500)
	sub.size = Vector2(1080, 60)
	menu_pausa.add_child(sub)
	
	# HBoxContainer para as habilidades ativas na run
	container_habilidades_pausa = HBoxContainer.new()
	container_habilidades_pausa.position = Vector2(140, 580)
	container_habilidades_pausa.size = Vector2(800, 200)
	container_habilidades_pausa.alignment = BoxContainer.ALIGNMENT_CENTER
	container_habilidades_pausa.add_theme_constant_override("separation", 30)
	menu_pausa.add_child(container_habilidades_pausa)
	
	# Botão Retomar
	var btn_retomar = Button.new()
	btn_retomar.text = "[ RETOMAR ]"
	btn_retomar.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn_retomar.add_theme_font_size_override("font_size", 48)
	btn_retomar.add_theme_color_override("font_color", Color("002867"))
	btn_retomar.add_theme_color_override("font_hover_color", Color("0044cc"))
	btn_retomar.add_theme_color_override("font_pressed_color", Color("001a66"))
	btn_retomar.flat = true
	btn_retomar.position = Vector2(340, 950)
	btn_retomar.size = Vector2(400, 80)
	menu_pausa.add_child(btn_retomar)
	btn_retomar.pressed.connect(_on_retomar_pausa_pressed)
	
	# Botão Sair para o Hub
	var btn_sair = Button.new()
	btn_sair.text = "[ SAIR PARA O HUB ]"
	btn_sair.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn_sair.add_theme_font_size_override("font_size", 36)
	btn_sair.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	btn_sair.add_theme_color_override("font_hover_color", Color(0.85, 0.1, 0.1))
	btn_sair.add_theme_color_override("font_pressed_color", Color(0.4, 0.05, 0.05))
	btn_sair.flat = true
	btn_sair.position = Vector2(340, 1100)
	btn_sair.size = Vector2(400, 80)
	menu_pausa.add_child(btn_sair)
	btn_sair.pressed.connect(func():
		SaveManager.limpar_run_snapshot() # Saída deliberada: abandona a run
		get_tree().paused = false
		get_tree().change_scene_to_file("res://hub.tscn")
	)

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
	
	# Som de clique
	var som_clic = _gerar_som_procedural(880.0, 0.05, "sin")
	_tocar_som(som_clic)
	
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

func _atualizar_habilidades_pausa() -> void:
	for child in container_habilidades_pausa.get_children():
		child.queue_free()
		
	if not player:
		return
		
	# Lista habilidades ativas com nível: [{icone, nivel}, ...]
	var habilidades_ativas: Array = []
	for id in player.upgrades.keys():
		var up = GameData.get_upgrade(id)
		if not up.is_empty():
			habilidades_ativas.append({"icone": up["icone"], "nivel": player.upgrades[id]})

	if habilidades_ativas.size() == 0:
		var lbl_nenhuma = Label.new()
		lbl_nenhuma.text = "(Nenhuma habilidade nesta run)"
		lbl_nenhuma.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
		lbl_nenhuma.add_theme_font_size_override("font_size", 28)
		lbl_nenhuma.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		lbl_nenhuma.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container_habilidades_pausa.add_child(lbl_nenhuma)
	else:
		for habilidade in habilidades_ativas:
			var container_icone = Control.new()
			container_icone.custom_minimum_size = Vector2(140, 170)
			container_icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			container_icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			container_habilidades_pausa.add_child(container_icone)

			# Fundo: moldura fixa de 140x140 (mesmo padrão dos cards de upgrade)
			var bg = TextureRect.new()
			bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg.stretch_mode = TextureRect.STRETCH_SCALE
			bg.texture = load("res://assets/backgroundpowerup.png")
			bg.size = Vector2(140, 140)
			bg.position = Vector2.ZERO
			container_icone.add_child(bg)

			# Ícone centralizado dentro da moldura
			var img = TextureRect.new()
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.texture = load(habilidade["icone"])
			img.size = Vector2(100, 100)
			img.position = Vector2(20, 20)
			container_icone.add_child(img)

			# Nível da habilidade abaixo da moldura
			var lbl_nivel = Label.new()
			lbl_nivel.text = "Lv.%d" % habilidade["nivel"]
			lbl_nivel.add_theme_font_override("font", FONTE_NUMEROS)
			lbl_nivel.add_theme_font_size_override("font_size", 26)
			lbl_nivel.add_theme_color_override("font_color", Color("002867"))
			lbl_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_nivel.position = Vector2(0, 140)
			lbl_nivel.size = Vector2(140, 30)
			container_icone.add_child(lbl_nivel)

func _obter_cor_fundo_carta(capitulo: int) -> Color:
	if capitulo <= 2:
		# Branco total para os dois primeiros capítulos
		return Color.WHITE
	elif capitulo == 3:
		# Bege bem clarinho
		return Color("faf6ee")
	elif capitulo >= 4 and capitulo <= 5:
		# Quadriculado: azul claro/cinza suave
		return Color("e6ecf5")
	elif capitulo >= 6 and capitulo <= 7:
		# Bege / Kraft Rústico
		return Color("dccfb5")
	elif capitulo >= 8 and capitulo <= 9:
		# Caderno Antigo Amarelado
		return Color("eedfc4")
	elif capitulo == 10:
		# Papel Milimetrado Técnico
		return Color("f5ece2")
	return Color.WHITE

func _obter_cor_papel_capitulo(capitulo: int) -> Color:
	if capitulo >= 1 and capitulo <= 3:
		return Color("faf6ee")
	elif capitulo >= 4 and capitulo <= 5:
		return Color("f5f5f7")
	elif capitulo >= 6 and capitulo <= 7:
		return Color("e5dcc6")
	elif capitulo >= 8 and capitulo <= 9:
		return Color("f7f0e1")
	elif capitulo == 10:
		return Color("fdfaf4")
	return Color("faf6ee")
