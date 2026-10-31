extends SceneTree
## Mede saltos de posição do chefe (teleporte) quadro a quadro, sem tela.
## Uso: Godot --headless --fixed-fps 60 --path . -s tools/teste_salto_chefes.gd -- [caps 1,2,..]

var _caps: Array = range(1, 11)

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_caps = Array(a[0].split(",")).map(func(v): return int(v))
	_rodar()

func _rodar() -> void:
	await process_frame
	for cap in _caps:
		seed(cap)
		var d: Dictionary = root.get_node("SaveManager").dados
		d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}
		var m = load("res://main.tscn").instantiate()
		root.add_child(m)
		for i in 5: await process_frame
		m.player.vidas = 9999
		m.player.attack_timer.stop()
		m.jogo_iniciado = true; m.menu_iniciar.visible = false
		m.wave_manager.iniciar_fase_na_pagina(cap, root.get_node("GameData").PAGINAS.size())
		var boss = null
		while boss == null:
			await physics_frame
			for n in m.get_children():
				if n.has_signal("morreu") and "entrada_concluida" in n and n.has_method("dano_compartilhado"):
					boss = n
		var antes: Vector2 = boss.position
		var pior := 0.0
		var onde := ""
		var t := 0.0
		var x_fim_entrada := -1.0
		while t < 25.0 and is_instance_valid(boss):
			await physics_frame
			t += 1.0 / 60.0
			if not is_instance_valid(boss):
				break
			var p: Vector2 = boss.position
			if x_fim_entrada < 0.0 and boss.entrada_concluida:
				x_fim_entrada = p.x
			var na_tela: bool = antes.y > 0.0 and p.y > 0.0 and antes.x > 0.0 and antes.x < 1080.0 and p.x > 0.0 and p.x < 1080.0
			var dx: float = absf(p.x - antes.x)
			if na_tela and dx > pior:
				pior = dx
				onde = "t=%.1f x %.0f -> %.0f" % [t, antes.x, p.x]
			antes = p
		print("[salto] cap %d: maior salto %.0f px/quadro (%s); x ao fim da entrada %.0f" % [cap, pior, onde, x_fim_entrada])
		m.queue_free()
		await process_frame
	quit()
