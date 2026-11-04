extends TextureRect
## Efeito atrás do HUD; pausa e menus nunca ficam tingidos.
var partida: Node
var tempo := 0.0

func _ready() -> void:
	texture = preload("res://assets/ui/vida_baixa_vinheta.png")
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(partida):
		return
	var p = partida.player
	var ativo: bool = partida.jogo_iniciado and not partida.fim_de_jogo_declarado \
		and not get_tree().paused and p.vidas > 0 and not partida.menu_iniciar.visible
	var limite := maxi(2, int(ceil(p.vidas_max * 0.3)))
	var baixa: bool = ativo and p.vidas <= limite
	tempo += delta if baixa else 0.0
	var intensidade := 1.0 if p.vidas == 1 else 0.65
	var alvo := intensidade * (0.58 + 0.18 * sin(tempo * TAU * 0.85)) if baixa else 0.0
	modulate.a = move_toward(modulate.a, alvo, delta * 3.0) if ativo else 0.0
