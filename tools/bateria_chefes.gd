extends SceneTree
## Bateria de equilíbrio dos chefes: um robô joga cada chefe (sem tela, acelerado).
## Resumo: python tools/resumo_bateria.py <pasta com esquiva/segue/parado.jsonl>
## Uso: Godot --headless --fixed-fps 60 --path . -s tools/bateria_chefes.gd -- <saida.jsonl> <bot> <seeds>
## bot: esquiva | segue | parado

const CENARIOS: Dictionary = {
	"zerado": {1: [1, 1, 1], 2: [1, 1, 1], 3: [1, 1, 1], 4: [1, 1, 1], 5: [1, 1, 1],
		6: [1, 1, 1], 7: [1, 1, 1], 8: [1, 1, 1], 9: [1, 1, 1], 10: [1, 1, 1]},
	# níveis D/H/C na vitória de cada capítulo (tools/sim_economia.py, tabela B)
	"progressao": {1: [3, 2, 3], 2: [3, 3, 3], 3: [4, 3, 4], 4: [5, 4, 5], 5: [5, 5, 6],
		6: [7, 6, 7], 7: [7, 7, 7], 8: [8, 8, 9], 9: [9, 8, 9], 10: [10, 9, 10]},
}
const LIMITE_LUTA: float = 150.0
const Y_CANETA: float = 1700.0

var _saida := ""
var _bot := "esquiva"
var _seeds: int = 3
var _caps: Array = range(1, 11)
var m
var boss
var _arquivo: FileAccess
var _pos_antes: Dictionary = {} # inimigo -> x na decisão anterior (para antecipar)

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_saida = a[0]
	_bot = a[1]
	_seeds = int(a[2])
	if a.size() > 3:
		_caps = Array(a[3].split(",")).map(func(v): return int(v))
	_arquivo = FileAccess.open(_saida, FileAccess.WRITE)
	_rodar()

func _rodar() -> void:
	await process_frame
	for cen in CENARIOS.keys():
		for cap in _caps:
			for s in _seeds:
				var r: Dictionary = await _luta(cen, cap, s)
				_arquivo.store_line(JSON.stringify(r))
				_arquivo.flush()
				print(JSON.stringify(r))
	_arquivo.close()
	quit()

func _luta(cen: String, cap: int, s: int) -> Dictionary:
	seed(1000 * cap + 17 * s + (0 if cen == "zerado" else 7))
	var niv: Array = CENARIOS[cen][cap]
	var sm = root.get_node("SaveManager")
	var d: Dictionary = sm.dados
	d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}
	d["nivel_dano"] = niv[0]; d["nivel_hp"] = niv[1]; d["nivel_cadencia"] = niv[2]
	d["caneta_equipada"] = "bic_azul"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 5: await process_frame
	var vidas_max: int = m.player.vidas_max
	m.player.vidas = 9999
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.capitulo_atual = cap
	m.player.position = Vector2(540, Y_CANETA)
	m.player.mover_para(Vector2(540, Y_CANETA))
	m.player.attack_timer.start()
	m.wave_manager.iniciar_fase_na_pagina(cap, root.get_node("GameData").PAGINAS.size())
	boss = null
	var morto := [false]
	while boss == null:
		await process_frame
		for n in m.get_children():
			if n.has_method("dano_compartilhado"):
				boss = n
	boss.morreu.connect(func(): morto[0] = true)
	var hp_max: int = boss.hp_max
	while is_instance_valid(boss) and not boss.entrada_concluida:
		await process_frame
	var t: float = 0.0
	var decide_t: float = 0.0
	var alvo_x: float = 540.0
	var tempo_atirando: float = 0.0
	while not morto[0] and t < LIMITE_LUTA:
		await process_frame
		var dt: float = 1.0 / 60.0
		t += dt
		decide_t -= dt
		if decide_t <= 0.0:
			decide_t = 0.12 # tempo de reação
			alvo_x = _decidir(alvo_x)
			m.player.mover_para(Vector2(alvo_x, Y_CANETA))
		if m.player.position.distance_to(m.player.posicao_alvo) < 28.0 or m.player._tempo_alvo_estatico > 0.08:
			tempo_atirando += dt
	var dano: int = 9999 - m.player.vidas
	var hp_rest: int = boss.hp if is_instance_valid(boss) else 0
	var r := {
		"cen": cen, "cap": cap, "seed": s, "bot": _bot,
		"ttk": snappedf(t, 0.1), "matou": morto[0], "dano": dano, "vidas": vidas_max,
		"hp_boss": hp_max, "hp_rest": hp_rest, "dano_caneta": m.player.dano,
		"intervalo": snappedf(m.player.intervalo_ataque, 0.01),
		"atirando_pct": int(100.0 * tempo_atirando / maxf(t, 0.01)),
		# dano causado ÷ dano que a caneta faria acertando todo tiro
		"aproveitamento": int(100.0 * (hp_max - hp_rest) / maxf(t * m.player.dano / m.player.intervalo_ataque, 1.0)),
	}
	m.queue_free()
	for i in 5: await process_frame
	return r

# --- robôs -------------------------------------------------------------------

func _decidir(atual: float) -> float:
	match _bot:
		"parado":
			return 540.0
		"segue":
			return clampf(_x_alvo_chefe(), 60.0, 1020.0)
	# esquiva: menor perigo; desempate por ficar embaixo do chefe e mexer pouco
	var px: float = m.player.position.x
	var alvo_chefe: float = _x_alvo_chefe()
	var melhor: float = px
	var melhor_nota: float = INF
	var x: float = 60.0
	while x <= 1020.0:
		var nota: float = _perigo(x) * 100.0 + absf(x - alvo_chefe) * 0.02 + absf(x - px) * 0.01
		if nota < melhor_nota:
			melhor_nota = nota
			melhor = x
		x += 20.0
	# não fica trocando por pouco
	if absf(melhor - atual) < 25.0:
		return atual
	return melhor

## Chefe a mirar: o verdadeiro (o robô "vê" a sombra); na Mancha, o pedaço
## mais perto; no Fantasma também acerta cópias se estiverem perto.
## Antecipa: mira onde o alvo vai estar quando o tiro chegar (como uma pessoa).
func _x_alvo_chefe() -> float:
	var px: float = m.player.position.x
	var melhor := 540.0
	var menor := INF
	var novos: Dictionary = {}
	for e in m.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.global_position.y > 1300.0:
			continue
		var ex: float = e.global_position.x
		var vx: float = (ex - _pos_antes[e]) / 0.12 if _pos_antes.has(e) else 0.0
		novos[e] = ex
		var voo: float = (Y_CANETA - 100.0 - e.global_position.y) / 900.0
		var previsto: float = ex + vx * voo
		var peso: float = absf(previsto - px) * (0.5 if e == boss else 1.0)
		if peso < menor:
			menor = peso
			melhor = previsto
	_pos_antes = novos
	return melhor

func _perigo(x: float) -> float:
	var p: float = 0.0
	# tiros: prevê 1 s à frente
	for proj in m.get_tree().get_nodes_in_group("enemy_projectiles"):
		if not proj.visible:
			continue
		var r: float = 8.0 * proj.scale.x + 26.0
		var tt: float = 0.0
		while tt <= 1.0:
			var q: Vector2 = proj.position + proj.direcao * proj.velocidade * tt
			if q.y > 1590.0 and q.y < 1730.0 and absf(q.x - x) < r:
				p += 1.2 - tt
			tt += 0.1
	for n in m.get_children():
		var sc = n.get_script()
		if sc == null:
			continue
		var caminho: String = sc.resource_path
		if caminho.ends_with("ZonaGrade.gd") and not n._explodiu:
			for col in n.colunas:
				var x0: float = col * 180.0
				if x > x0 - 25.0 and x < x0 + 205.0:
					p += 3.0
		elif caminho.ends_with("ZonaBomba.gd") and not n._explodiu:
			if absf(x - n.alvo_x) < 105.0 + 30.0:
				p += 3.0
		elif caminho.ends_with("ParedeTinta.gd"):
			if n.y > 700.0 and n.y < 1760.0 and absf(x - n.fresta_x) > n.largura_fresta / 2.0 - 30.0:
				p += 3.0 if n._caindo else 1.0
		elif caminho.ends_with("FolhaFantasma.gd"):
			if n.position.y > 900.0 and absf(x - n.position.x) < 100.0:
				p += 3.0
		elif caminho.ends_with("AvisoTiro.gd") and not n.atras_do_atirador:
			for dir in n.direcoes:
				var dd: Vector2 = (dir as Vector2).normalized()
				if dd.y > 0.3:
					var xa: float = n.position.x + dd.x / dd.y * (1660.0 - n.position.y)
					if absf(x - xa) < 160.0:
						p += 3.0
	# corpos que descem (mergulhos, lacaios)
	for e in m.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.y > 1000.0 and absf(e.global_position.x - x) < 150.0:
			p += 3.0
	return p
