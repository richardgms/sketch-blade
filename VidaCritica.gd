extends Node
## Coordena heartbeat, impacto de pressão e mistura da música sem depender dos menus.
const CICLO := 0.85
const SEGUNDO_ATAQUE := 0.16
var partida: Node
var zumbido := AudioStreamPlayer.new()
var _em_critico := false
var _viu_combate := false
var _coracao_ligado := false
var _ganho := 0.0
var pulso := 0.0
var _ultimo_quadro := 0.0
var _pos_anterior := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ultimo_quadro = Time.get_ticks_usec() / 1000000.0
	zumbido.stream = preload("res://assets/sons/zumbido_critico.ogg")
	zumbido.volume_db = -3.0
	add_child(zumbido)
	partida._coracao_player.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var agora := Time.get_ticks_usec() / 1000000.0
	atualizar(maxf(0.0, agora - _ultimo_quadro))
	_ultimo_quadro = agora

func atualizar(delta: float) -> void:
	var combate: bool = partida.jogo_iniciado and not partida.fim_de_jogo_declarado and partida.player.vidas > 0
	var critico: bool = combate and partida.player.vidas == 1
	var suspenso: bool = get_tree().paused or partida.menu_iniciar.visible
	var som: bool = SaveManager.dados.get("som_ativo", true)
	var coracao: AudioStreamPlayer = partida._coracao_player
	if critico and not _em_critico and _viu_combate and not suspenso and som:
		zumbido.play()
	_em_critico = critico
	_viu_combate = combate
	if not combate or not som:
		coracao.stop()
		zumbido.stop()
		_coracao_ligado = false
		_ganho = 0.0
		pulso = 0.0
		Musica.vida_critica(false, true)
		return
	coracao.stream_paused = suspenso
	zumbido.stream_paused = suspenso
	Musica.vida_critica(critico and not suspenso, suspenso)
	if suspenso:
		pulso = 0.0
		return
	if critico and not _coracao_ligado:
		coracao.play()
		_coracao_ligado = true
	_ganho = move_toward(_ganho, 1.0 if critico else 0.0, delta / (0.12 if critico else 0.9))
	coracao.volume_db = linear_to_db(_ganho) if _ganho > 0.0001 else -80.0
	if not critico:
		# O impacto não continua depois da cura; cauda é retirada em poucos quadros.
		zumbido.volume_db = move_toward(zumbido.volume_db, -60.0, delta * 90.0)
		if _ganho <= 0.0:
			coracao.stop()
			zumbido.stop()
			_coracao_ligado = false
	else:
		zumbido.volume_db = -3.0
	var pos := fmod(maxf(0.0, coracao.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()), CICLO)
	# Volta do ciclo = nova batida: vibração leve junto (sente-se mesmo com o volume baixo)
	if critico and _ganho > 0.5 and pos < _pos_anterior:
		Vibracao.tocar("coracao")
	_pos_anterior = pos
	pulso = (exp(-pos / 0.11) + (0.65 * exp(-(pos - SEGUNDO_ATAQUE) / 0.09) if pos >= SEGUNDO_ATAQUE else 0.0)) * _ganho

func _exit_tree() -> void:
	Musica.vida_critica(false, true)
