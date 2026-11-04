extends SceneTree
## Teste da música adaptativa (Musica.gd) sem tela, em tempo real: percorre uma
## partida (páginas 1, 3, 6), a entrada do chefe com pré-entrada, a raiva, a
## pausa e o fim, conferindo volumes das camadas e posições.
## Uso: Godot --headless --path . -s tools/teste_musica.gd

var mu
var falhas: int = 0

func _initialize() -> void:
	mu = root.get_node("Musica")
	_rodar()

func _esperar(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _g(f, camada: String) -> float:
	return f.ganho[f.camadas.find(camada)]

func _checar(nome: String, ok: bool, info: String = "") -> void:
	print(("OK    " if ok else "FALHA ") + nome + ("  (" + info + ")" if info != "" else ""))
	if not ok:
		falhas += 1

func _resumo(f) -> String:
	var t := []
	for i in f.camadas.size():
		t.append("%s=%.2f" % [f.camadas[i], f.ganho[i]])
	return "pos %.2f  %s" % [f.player.get_playback_position(), ", ".join(t)]

func _rodar() -> void:
	await _esperar(0.5)
	# Página 1: começa no nível 1 com entrada suave
	mu.pagina(1)
	var p = mu._partida
	var c = mu._chefe
	await _esperar(2.5)
	var pos1: float = p.player.get_playback_position()
	_checar("partida tocando e posição andando", p.tocando and pos1 > 1.5, "pos %.2f" % pos1)
	_checar("nível 1", _g(p, "guitarras_leve") > 0.99 and _g(p, "bateria") < 0.01 and _g(p, "baixo") > 0.99, _resumo(p))
	_checar("entrada suave terminou no volume base", absf(p.player.volume_db - p.volume_base) < 0.5, "%.1f dB" % p.player.volume_db)

	# Página 3: nível 2 no próximo compasso, 1 compasso de passagem
	mu.pagina(3)
	await _esperar(4.6)
	_checar("nível 2", _g(p, "bateria_leve") > 0.99 and _g(p, "guitarras") > 0.99 and _g(p, "guitarras_leve") < 0.01, _resumo(p))

	# Página 6: nível 3
	mu.pagina(6)
	await _esperar(4.6)
	_checar("nível 3", _g(p, "bateria") > 0.99 and _g(p, "outros") > 0.99 and _g(p, "bateria_leve") < 0.01, _resumo(p))

	# Página 4 (descanso): volta ao nível 1 em 2 compassos
	mu.pagina(4)
	await _esperar(6.6)
	_checar("descanso volta ao nível 1", _g(p, "guitarras_leve") > 0.99 and _g(p, "bateria") < 0.01, _resumo(p))
	mu.pagina(7)
	await _esperar(4.6)

	# Chefe: pré-entrada e "1" no compasso da partida
	var t0 := Time.get_ticks_usec() / 1000000.0
	mu.entrar_chefe()
	var pos_ini: float = c.player.get_playback_position()
	_checar("chefe começa perto do fim do loop (pré-entrada)", c.tocando and pos_ini > c.duracao - 4.5, "pos %.2f de %.2f" % [pos_ini, c.duracao])
	# acha o "1" agendado pela rampa da bateria
	var r: Dictionary = c.rampas[c.camadas.find("bateria")]
	var um: float = r.get("t0", t0) + 0.02 - t0
	await _esperar(maxf(um - 0.6, 0.0))
	_checar("antes do 1: guitarra abafada subindo, sem bateria", _g(c, "bateria") < 0.01 and _g(c, "guitarras_leve") > 0.3, _resumo(c))
	await _esperar(1.1)
	var pos_um: float = c.player.get_playback_position()
	_checar("depois do 1: chefe deu a volta no loop (posição pequena)", pos_um < 1.0, "pos %.2f" % pos_um)
	_checar("chefe normal", _g(c, "bateria") > 0.99 and absf(_g(c, "alien") - 0.5) < 0.01 and _g(c, "guitarras_leve") > 0.99, _resumo(c))
	await _esperar(0.3)
	_checar("partida parou", not p.player.playing and not p.tocando, "playing %s" % p.player.playing)
	_checar("filtro da partida desligado de novo", not AudioServer.is_bus_effect_enabled(AudioServer.get_bus_index("MusicaPartida"), 0))

	# Raiva
	await _esperar(2.0)
	mu.raiva_chefe()
	await _esperar(4.7)
	_checar("raiva", _g(c, "guitarras") > 0.99 and _g(c, "guitarras_leve") < 0.01 and _g(c, "alien") > 0.99, _resumo(c))

	# Pausa: posição congela
	mu.pausar(true)
	var pp: float = c.player.get_playback_position()
	await _esperar(1.0)
	var pp2: float = c.player.get_playback_position()
	_checar("pausa congela a posição", absf(pp2 - pp) < 0.05, "%.2f -> %.2f" % [pp, pp2])
	mu.pausar(false)
	await _esperar(1.0)
	_checar("volta da pausa anda de novo", c.player.get_playback_position() > pp2 + 0.5, "%.2f" % c.player.get_playback_position())

	# Fim (vitória)
	mu.parar(1.0)
	await _esperar(1.5)
	_checar("parou tudo", not c.player.playing and not p.player.playing and not c.tocando)

	# Nova partida depois de sair pela pausa não começa pausada
	mu.pausar(true)
	mu.parar(0.3)
	await _esperar(0.5)
	mu.pagina(1)
	await _esperar(1.0)
	_checar("partida nova depois de sair pela pausa toca", p.player.playing and not p.player.stream_paused)
	mu.parar(0.2)
	await _esperar(0.4)

	print("RESULTADO: %d falha(s)" % falhas)
	quit(1 if falhas > 0 else 0)
