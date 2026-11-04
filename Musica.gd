extends Node
## Música adaptativa da partida e do chefe (plano: docs/plano-musica-adaptativa.md).
## Cada música é um AudioStreamSynchronized: as camadas começam juntas e têm a
## mesma duração exata, então nunca se desencontram. A intensidade muda só no
## volume de cada camada, sempre a partir do início de um compasso.
## Quem avisa: Main (páginas, pausa, morte, vitória, saída), WaveManager (rugido
## do chefe), Boss/Mancha/Estojo (raiva).

## Chave de segurança: false = jogo exatamente como antes (sem música).
const ATIVA := true
## Volume geral da música. Sem isso o nível 3 fica a -16,9 LUFS, acima dos
## efeitos (morte -22, rugido -20, vitória -18). Ajustar de ouvido no celular.
const VOLUME_DB := -6.0
## A música do chefe é mais baixa de origem: +2,5 dB deixa o "normal" no
## volume do nível 3 da partida (medido).
const GANHO_CHEFE_DB := 2.5
const LOG := true

const DIR_PARTIDA := "res://assets/musica/partida/"
const DIR_CHEFE := "res://assets/musica/chefe/"
const CAMADAS_PARTIDA := ["baixo", "metronomo", "bateria_leve", "bateria", "guitarras_leve", "guitarras", "outros"]
const CAMADAS_CHEFE := ["baixo", "metronomo", "bateria", "guitarras_leve", "guitarras", "alien"]

## Duração exata dos loops e início de cada compasso (50 ms antes do ataque da
## bateria), medidos por tools/musica/camadas_jogo.py.
const DURACAO_PARTIDA := 48.032417 # 2305556 amostras a 48 kHz
const COMPASSOS_PARTIDA := [0.0, 2.0095, 4.0191, 6.0227, 8.0354, 10.033, 12.0357, 14.0355, 16.0353, 18.0352, 20.035, 22.0348, 24.0316, 26.0316, 28.0333, 30.0332, 32.0329, 34.0405, 36.0374, 38.0362, 40.036, 42.0358, 44.0355, 46.0374]
const DURACAO_CHEFE := 48.615896 # 2333563 amostras a 48 kHz
const COMPASSOS_CHEFE := [0.0, 2.022, 4.0479, 6.0729, 8.0997, 10.1228, 12.1506, 14.1766, 16.2026, 18.2275, 20.2624, 22.2825, 24.3044, 26.2656, 28.3533, 30.3814, 32.4103, 34.4332, 36.4593, 38.4841, 40.5191, 42.534, 44.56, 46.585]

## Volume de cada camada por nível (o que não aparece fica em 0).
const NIVEIS := {
	1: {"baixo": 1.0, "metronomo": 1.0, "guitarras_leve": 1.0},
	2: {"baixo": 1.0, "metronomo": 1.0, "bateria_leve": 1.0, "guitarras": 1.0},
	3: {"baixo": 1.0, "metronomo": 1.0, "bateria": 1.0, "guitarras": 1.0, "outros": 1.0},
}
const NIVEL_POR_PAGINA := {1: 1, 2: 1, 3: 2, 4: 1, 5: 2, 6: 3, 7: 3}
const CHEFE_NORMAL := {"baixo": 1.0, "metronomo": 1.0, "bateria": 1.0, "guitarras_leve": 1.0, "alien": 0.5}
const CHEFE_RAIVA := {"baixo": 1.0, "metronomo": 1.0, "bateria": 1.0, "guitarras": 1.0, "alien": 1.0}

## Uma música: o player, as camadas e as rampas de volume de cada camada.
class Faixa extends RefCounted:
	var nome: String
	var player: AudioStreamPlayer
	var sync: AudioStreamSynchronized
	var camadas: Array = []
	var ganho: Array = []   # volume atual de cada camada (linear)
	var rampas: Array = []  # por camada: {} ou {"para", "t0", "dur"} (tempo real, s)
	var compassos: Array = []
	var duracao: float = 0.0
	var volume_base: float = 0.0
	var tocando: bool = false  # próprio: player pausado responde playing = false

var _partida: Faixa
var _chefe: Faixa
var _filtro: AudioEffectLowPassFilter
var _bus_partida: int = -1
var _nivel: int = 0
var _raiva: bool = false
var _pausado: bool = false
var _abafado: bool = false
var _tweens: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _pode() -> bool:
	return ATIVA and SaveManager.dados.get("som_ativo", true)

func _log(t: String) -> void:
	if LOG:
		print("[Musica] ", t)

# ------------------------------------------------------------------ montagem
## Carrega as músicas só na primeira partida (o hub não paga essa memória).
func _garantir_faixas() -> void:
	if _partida != null:
		return
	_bus_partida = _criar_bus("MusicaPartida", true)
	_criar_bus("MusicaChefe", false)
	_partida = _criar_faixa("partida", DIR_PARTIDA, CAMADAS_PARTIDA, COMPASSOS_PARTIDA, DURACAO_PARTIDA, "MusicaPartida", VOLUME_DB)
	_chefe = _criar_faixa("chefe", DIR_CHEFE, CAMADAS_CHEFE, COMPASSOS_CHEFE, DURACAO_CHEFE, "MusicaChefe", VOLUME_DB + GANHO_CHEFE_DB)

func _criar_bus(nome: String, com_filtro: bool) -> int:
	var i := AudioServer.get_bus_index(nome)
	if i == -1:
		i = AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, nome)
		AudioServer.set_bus_send(i, "Master")
		if com_filtro:
			var f := AudioEffectLowPassFilter.new()
			f.cutoff_hz = 20000.0
			AudioServer.add_bus_effect(i, f)
			AudioServer.set_bus_effect_enabled(i, 0, false)
	if com_filtro:
		_filtro = AudioServer.get_bus_effect(i, 0) as AudioEffectLowPassFilter
	return i

func _criar_faixa(nome: String, dir: String, camadas: Array, compassos: Array, duracao: float, bus: String, volume_db: float) -> Faixa:
	var f := Faixa.new()
	f.nome = nome
	f.camadas = camadas
	f.compassos = compassos
	f.duracao = duracao
	f.volume_base = volume_db
	f.sync = AudioStreamSynchronized.new()
	f.sync.stream_count = camadas.size()
	for i in camadas.size():
		var s := load(dir + camadas[i] + ".ogg") as AudioStreamOggVorbis
		s.loop = true
		f.sync.set_sync_stream(i, s)
		f.sync.set_sync_stream_volume(i, -80.0)
		f.ganho.append(0.0)
		f.rampas.append({})
	f.player = AudioStreamPlayer.new()
	f.player.stream = f.sync
	f.player.bus = bus
	f.player.volume_db = volume_db
	f.player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(f.player)
	return f

# ------------------------------------------------------------- tempo e rampas
func _agora() -> float:
	return Time.get_ticks_usec() / 1000000.0

## Duração de um compasso (média do loop).
func _compasso(f: Faixa) -> float:
	return f.duracao / f.compassos.size()

## Posição atual dentro do loop (no relógio da mixagem).
func _posicao(f: Faixa) -> float:
	return fmod(f.player.get_playback_position() + AudioServer.get_time_since_last_mix(), f.duracao)

## Segundos até o próximo início de compasso que esteja pelo menos `minimo` à frente.
func _ate_compasso(f: Faixa, minimo: float) -> float:
	var pos := _posicao(f)
	for volta in [0.0, f.duracao, 2.0 * f.duracao]:
		for b in f.compassos:
			if b + volta >= pos + minimo:
				return b + volta - pos
	return minimo

func _definir(f: Faixa, i: int, g: float) -> void:
	f.ganho[i] = g
	f.sync.set_sync_stream_volume(i, linear_to_db(g) if g > 0.0001 else -80.0)

## Agenda a camada para ir até `para` começando daqui a `atraso` s, em `dur` s.
func _rampa(f: Faixa, camada: String, para: float, atraso: float, dur: float) -> void:
	var i := f.camadas.find(camada)
	if i >= 0:
		f.rampas[i] = {"para": para, "t0": _agora() + atraso, "dur": maxf(dur, 0.001)}

## Leva todas as camadas ao volume de `alvo` com a mesma duração (assim leve e
## pesada se cruzam somando sempre o mesmo volume).
func _aplicar(f: Faixa, alvo: Dictionary, atraso: float, dur: float) -> void:
	for c in f.camadas:
		_rampa(f, c, float(alvo.get(c, 0.0)), atraso, dur)

func _zerar(f: Faixa, alvo: Dictionary = {}) -> void:
	for i in f.camadas.size():
		f.rampas[i] = {}
		_definir(f, i, float(alvo.get(f.camadas[i], 0.0)))

func _process(_delta: float) -> void:
	if _partida == null:
		return
	var t := _agora()
	for f in [_partida, _chefe]:
		for i in f.rampas.size():
			var r: Dictionary = f.rampas[i]
			if r.is_empty() or t < r["t0"]:
				continue
			if not r.has("de"):
				r["de"] = f.ganho[i]
			var k := clampf((t - r["t0"]) / r["dur"], 0.0, 1.0)
			_definir(f, i, lerpf(r["de"], r["para"], k * k * (3.0 - 2.0 * k)))
			if k >= 1.0:
				f.rampas[i] = {}

func _novo_tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw

func _cancelar_tweens() -> void:
	for tw in _tweens:
		if is_instance_valid(tw):
			tw.kill()
	_tweens.clear()

## Fade do player inteiro em amplitude linear (de 0 a 1 = silêncio a volume base).
func _fade(f: Faixa, de: float, para: float, dur: float, tw: Tween = null) -> Tween:
	if tw == null:
		tw = _novo_tween()
	tw.tween_method(func(x: float): f.player.volume_db = f.volume_base + (linear_to_db(x) if x > 0.0001 else -80.0), de, para, dur)
	return tw

func _resetar_filtro() -> void:
	if _filtro:
		_filtro.cutoff_hz = 20000.0
		AudioServer.set_bus_effect_enabled(_bus_partida, 0, false)

# ------------------------------------------------------------------ partida
## Página nova: começa a música (início da partida ou partida retomada) ou
## muda o nível no próximo compasso. A página do chefe entra pelo rugido.
func pagina(numero: int) -> void:
	if not _pode() or numero >= 8:
		return
	_garantir_faixas()
	var nivel: int = NIVEL_POR_PAGINA.get(numero, 1)
	if not _partida.tocando:
		_iniciar_partida(nivel)
		return
	if nivel == _nivel:
		return
	var subir := nivel > _nivel
	_nivel = nivel
	var ate := _ate_compasso(_partida, 0.05)
	_aplicar(_partida, NIVEIS[nivel], ate, _compasso(_partida) * (1.0 if subir else 2.0))
	_log("página %d -> nível %d em %.2f s" % [numero, nivel, ate])

func _iniciar_partida(nivel: int) -> void:
	_cancelar_tweens()
	_resetar_filtro()
	_chefe.player.stop()
	_chefe.tocando = false
	_raiva = false
	_nivel = nivel
	_zerar(_partida, NIVEIS[nivel])
	_partida.player.volume_db = -80.0
	_partida.player.play(0.0)
	_partida.tocando = true
	_partida.player.stream_paused = _pausado
	_fade(_partida, 0.0, 1.0, 2.0) # entrada suave de ~2 s
	_log("partida começa no nível %d" % nivel)

# -------------------------------------------------------------------- chefe
## Rugido do chefe: a música dele começa por baixo 1 compasso antes do "1"
## (guitarra abafada subindo, baixo na metade final), a bateria cai no "1" e a
## partida vai abafando e sai logo depois.
func entrar_chefe() -> void:
	if not _pode():
		return
	_garantir_faixas()
	_cancelar_tweens()
	_raiva = false
	var c := _chefe
	_zerar(c)
	c.player.stream_paused = _pausado
	if not _partida.tocando:
		# Teste de chefe ou partida retomada na página do chefe: entra direto
		_zerar(c, CHEFE_NORMAL)
		c.player.volume_db = -80.0
		c.player.play(0.0)
		c.tocando = true
		_fade(c, 0.0, 1.0, 1.0)
		_log("chefe começa direto")
		return
	c.player.volume_db = c.volume_base
	var bp := _compasso(_partida)
	var ate := _ate_compasso(_partida, bp) # o "1" do chefe: pelo menos 1 compasso à frente
	var pre := ate - bp                    # começo da pré-entrada (>= 0)
	c.tocando = true
	c.player.play(maxf(c.duracao - ate, 0.0)) # chega ao fim do loop (que emenda no "1") no compasso da partida
	_rampa(c, "guitarras_leve", 1.0, pre, bp)
	_rampa(c, "baixo", 1.0, pre + bp * 0.5, bp * 0.5)
	for k in ["metronomo", "bateria", "alien"]:
		_rampa(c, k, CHEFE_NORMAL[k], ate - 0.02, 0.02)
	# Partida: abafa (18 kHz -> 500 Hz) e desce 6 dB na pré-entrada; some 150 ms depois do "1"
	AudioServer.set_bus_effect_enabled(_bus_partida, 0, true)
	var tf := _novo_tween()
	tf.tween_interval(pre)
	tf.tween_method(func(x: float): _filtro.cutoff_hz = exp(x), log(18000.0), log(500.0), bp)
	var tv := _novo_tween()
	tv.tween_interval(pre)
	_fade(_partida, 1.0, 0.5, bp, tv)
	_fade(_partida, 0.5, 0.0, 0.15, tv)
	_partida.tocando = false
	tv.tween_callback(func():
		_partida.player.stop()
		_resetar_filtro())
	_log("chefe: pré-entrada em %.2f s, \"1\" em %.2f s" % [pre, ate])

## Raiva do chefe (metade da vida; Mancha ao se dividir; Estojo na fase 2):
## no próximo compasso a guitarra abre e o alien sobe, em 1 compasso.
func raiva_chefe() -> void:
	if not _pode() or _chefe == null or not _chefe.tocando or _raiva:
		return
	_raiva = true
	var ate := _ate_compasso(_chefe, 0.05)
	_aplicar(_chefe, CHEFE_RAIVA, ate, _compasso(_chefe))
	_log("raiva em %.2f s" % ate)

# ------------------------------------------------------- pausa, fim e ajustes
## Sai com fade e para tudo (vitória, derrota, saída da partida).
func parar(dur: float = 0.5, manter_pausa: bool = false) -> void:
	if _partida == null:
		return
	_cancelar_tweens()
	_nivel = 0
	_raiva = false
	_abafado = false
	if not manter_pausa:
		_pausado = false # sair pela pausa não deixa a próxima partida começar pausada
	for f in [_partida, _chefe]:
		if f.tocando or f.player.playing: # partida ainda saindo na pré-entrada do chefe também
			f.tocando = false
			var tw := _fade(f, db_to_linear(f.player.volume_db - f.volume_base), 0.0, dur)
			tw.tween_callback(func():
				f.player.stop()
				f.player.stream_paused = _pausado)
		else:
			f.player.stream_paused = _pausado
	var tr := _novo_tween()
	tr.tween_interval(dur)
	tr.tween_callback(_resetar_filtro)
	_log("parar (%.1f s)" % dur)

## Menu de pausa: congela a música (volta no mesmo ponto, camadas juntas).
func pausar(sim: bool) -> void:
	_pausado = sim
	if _partida == null:
		return
	for f in [_partida, _chefe]:
		f.player.stream_paused = sim

## Tela "Segunda chance?": música 10 dB mais baixa enquanto ela está aberta.
func abafar(sim: bool) -> void:
	if _partida == null or sim == _abafado:
		return
	_abafado = sim
	for f in [_partida, _chefe]:
		if f.tocando:
			var de := db_to_linear(f.player.volume_db - f.volume_base)
			_fade(f, de, 0.32 if sim else 1.0, 0.3)

## Som ligado/desligado na pausa.
func atualizar_som(ligado: bool, pagina_atual: int, chefe_ativo: bool) -> void:
	if not ligado:
		parar(0.3, true) # desligou na pausa: continua valendo a pausa ao religar
	elif chefe_ativo:
		entrar_chefe()
	else:
		pagina(max(1, pagina_atual))
