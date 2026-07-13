extends Node
## Controla a run de 8 páginas do caderno: ondas, descanso, elite e boss.
## A receita das páginas vive em GameData.PAGINAS.

signal pagina_iniciada(numero: int, total: int)
signal pagina_concluida(numero: int)
signal descanso_iniciado
signal boss_surgiu(boss_node: Node2D)
signal fase_concluida

@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
@export var boss_scene: PackedScene = preload("res://boss.tscn")

var pagina_atual: int = 0
var monstros_restantes_spawn: int = 0
var monstros_vivos: int = 0
var boss_ativo: bool = false
var capitulo_atual: int = 1
var intensidade_atual: float = 1.0
var elite_pendente: bool = false

var pagina_concluida_emitida: bool = false

var timer_spawn: Timer
var timer_pagina: Timer

func _ready() -> void:
	timer_spawn = Timer.new()
	timer_spawn.one_shot = false
	timer_spawn.timeout.connect(_on_spawn_timeout)
	add_child(timer_spawn)

	timer_pagina = Timer.new()
	timer_pagina.one_shot = true
	timer_pagina.timeout.connect(_on_timer_pagina_timeout)
	add_child(timer_pagina)

func iniciar_fase(capitulo: int) -> void:
	capitulo_atual = capitulo
	pagina_atual = 0
	monstros_vivos = 0
	boss_ativo = false
	elite_pendente = false
	_iniciar_proxima_pagina()

## Retoma a fase numa página específica (restauração de run interrompida).
## A página indicada recomeça do zero — reusa toda a lógica de _iniciar_proxima_pagina
## (onda/descanso/boss), então qualquer tipo de página é restaurado corretamente.
func iniciar_fase_na_pagina(capitulo: int, pagina: int) -> void:
	capitulo_atual = capitulo
	pagina_atual = max(0, pagina - 1) # _iniciar_proxima_pagina incrementa para 'pagina'
	monstros_vivos = 0
	boss_ativo = false
	elite_pendente = false
	_iniciar_proxima_pagina()

func _iniciar_proxima_pagina() -> void:
	pagina_atual += 1
	if pagina_atual > GameData.PAGINAS.size():
		return # Segurança: página 8 (boss) encerra via fase_concluida

	pagina_concluida_emitida = false
	var receita: Dictionary = GameData.PAGINAS[pagina_atual - 1]
	pagina_iniciada.emit(pagina_atual, GameData.PAGINAS.size())

	match receita["tipo"]:
		"onda":
			monstros_restantes_spawn = receita["quantidade"]
			intensidade_atual = receita.get("intensidade", 1.0)
			elite_pendente = receita.get("elite", false)
			timer_spawn.wait_time = receita["intervalo"]
			# Pequena pausa para a animação de virada de página respirar
			await get_tree().create_timer(1.2).timeout
			timer_spawn.start()
		"descanso":
			descanso_iniciado.emit()
		"boss":
			_preparar_boss()

func _on_spawn_timeout() -> void:
	if monstros_restantes_spawn > 0:
		monstros_restantes_spawn -= 1
		_spawnar_inimigo(false)

		# O elite entra junto com o último monstro comum da página
		if monstros_restantes_spawn <= 0 and elite_pendente:
			elite_pendente = false
			_spawnar_inimigo(true)
	else:
		timer_spawn.stop()

func _spawnar_inimigo(eh_elite: bool) -> void:
	var main_node = get_parent()
	if not main_node:
		return

	monstros_vivos += 1

	var enemy = enemy_scene.instantiate()
	var x_aleatorio = randf_range(100.0, 980.0)
	enemy.position = Vector2(x_aleatorio, -80.0)
	main_node.add_child(enemy)

	# 1. Configura tipo de monstro de acordo com capítulo e página
	var tipo_sorteado = _sortear_tipo_inimigo(capitulo_atual, pagina_atual)
	enemy.configurar_tipo(tipo_sorteado)

	# 2. Escala de capítulo × intensidade da página
	# Geométrica (1.28^cap): acompanha o crescimento composto do DPS do
	# jogador (dano × cadência do Estojo) — linear ficava para trás e o
	# jogo trivializava. Calibrada em tools/sim_economia.py.
	var mult_hp = pow(1.28, capitulo_atual - 1) * intensidade_atual
	var mult_vel = (1.0 + (capitulo_atual - 1) * 0.08) * lerp(1.0, intensidade_atual, 0.5)

	enemy.hp_max = int(enemy.hp_max * mult_hp)
	enemy.velocidade = enemy.velocidade * mult_vel

	# Se capítulos avançados (6 a 10), inimigos tanques causam 3 de dano
	if capitulo_atual >= 6 and tipo_sorteado == 3: # 3 = GUACHE/Tanque
		enemy.dano_contato = 3

	# 3. Elite: mancha gigante dourada que atira em leque
	if eh_elite:
		enemy.tornar_elite()

	enemy.hp = enemy.hp_max

	# Conexão de sinais
	enemy.morreu.connect(func(pos, cor, textura):
		main_node._on_enemy_morreu(pos, cor, textura)
		if eh_elite:
			SaveManager.incrementar_stat("elites_derrotados")
			# Elite derruba um jackpot extra de tinta e morre com mais peso
			if main_node.has_method("_spawn_drops_de_tinta"):
				main_node._spawn_drops_de_tinta(pos, 6, 8, textura)
			if main_node.has_method("_hitstop"):
				main_node._hitstop(0.09)
			if main_node.has_method("_shake_tela"):
				main_node._shake_tela(6.0)
	)

	enemy.tree_exited.connect(func():
		monstros_vivos -= 1
		_verificar_fim_da_pagina()
	)

func _sortear_tipo_inimigo(capitulo: int, pagina: int) -> int:
	# Retorna TipoInimigo (0: COMUM, 1: NANQUIM, 2: RESPINGO, 3: GUACHE)
	# A "fase" da run: início (pág 1-3), meio (5-6), fim (7)
	var fase: int = 1
	if pagina >= 7:
		fase = 3
	elif pagina >= 5:
		fase = 2

	if capitulo == 1:
		# Capítulo tutorial: comuns, com nanquins raros no fim
		return 1 if (fase == 3 and randf() < 0.2) else 0

	elif capitulo == 2 or capitulo == 3:
		var chance_nanquim = 0.2 + 0.15 * (fase - 1)
		return 1 if randf() < chance_nanquim else 0

	elif capitulo == 4 or capitulo == 5:
		if fase == 1:
			return 1 if randf() < 0.3 else 0
		elif fase == 2:
			return 2 if randf() < 0.4 else 0
		else:
			var r = randf()
			if r < 0.3:
				return 1 # Nanquim
			elif r < 0.6:
				return 2 # Respingo
			else:
				return 0 # Comum

	elif capitulo == 6 or capitulo == 7:
		if fase == 1:
			var r = randf()
			return 1 if r < 0.3 else (2 if r < 0.5 else 0)
		elif fase == 2:
			return 2 if randf() < 0.5 else 0
		else:
			var r = randf()
			if r < 0.4:
				return 3 # Guache/Tanque
			elif r < 0.7:
				return 1 # Nanquim
			else:
				return 0 # Comum

	else:
		# Capítulos 8, 9, 10: Caótico (mistura total dos 4 monstros)
		if fase == 1:
			var r = randf()
			return 1 if r < 0.3 else (2 if r < 0.6 else 0)
		elif fase == 2:
			var r = randf()
			return 2 if r < 0.4 else (3 if r < 0.7 else 0)
		else:
			var r = randf()
			if r < 0.3:
				return 3 # Guache
			elif r < 0.6:
				return 1 # Nanquim
			elif r < 0.8:
				return 2 # Respingo
			else:
				return 0 # Comum

func _verificar_fim_da_pagina() -> void:
	if pagina_concluida_emitida:
		return
	if pagina_atual < 1 or pagina_atual > GameData.PAGINAS.size():
		return
	if GameData.PAGINAS[pagina_atual - 1]["tipo"] != "onda":
		return
	if monstros_restantes_spawn <= 0 and not elite_pendente and monstros_vivos <= 0 and not boss_ativo:
		pagina_concluida_emitida = true
		pagina_concluida.emit(pagina_atual)

## Chamado pelo Main após roleta/descanso (ou direto, se a página não tem evento)
func continuar_proxima_pagina() -> void:
	timer_pagina.wait_time = 1.0
	timer_pagina.start()

func _on_timer_pagina_timeout() -> void:
	_iniciar_proxima_pagina()

func _preparar_boss() -> void:
	boss_ativo = true

	# Mensagem de BOSS na tela
	var main_node = get_parent()
	if main_node:
		main_node._spawn_feedback("CUIDADO: BOSS!", "miss", Vector2(540, 960))
		# Som de alerta do boss
		var som_boss = main_node._gerar_som_procedural(150.0, 0.4, "square")
		main_node._tocar_som(som_boss)

	# Espera 2.5s dramáticos e spawna o Boss
	await get_tree().create_timer(2.5).timeout

	if main_node:
		var boss = boss_scene.instantiate()
		boss.position = Vector2(540, -100.0)
		main_node.add_child(boss)

		# Padrão de comportamento por faixa de capítulo + escala de HP
		boss.configurar_padrao(capitulo_atual)
		# Geométrica, expoente menor que o dos comuns: a luta encurta de
		# ~35s (cap 1) até ~19s (cap 10) conforme o Estojo maxa.
		var mult_boss_hp = pow(1.26, capitulo_atual - 1)
		boss.hp_max = int(boss.hp_max * mult_boss_hp)
		boss.hp = boss.hp_max

		# Ajusta dano de contato do Boss para Capítulos altos
		if capitulo_atual >= 6:
			boss.dano_contato = 3

		# Conecta o sinal de morte do boss
		boss.morreu.connect(_on_boss_morreu)

		boss_surgiu.emit(boss)

func _on_boss_morreu() -> void:
	fase_concluida.emit()
