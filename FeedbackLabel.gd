extends Marker2D

const FONTE_NUMEROS = preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")

@onready var label: Label = $Label

func setup(texto: String, tipo_timing: String) -> void:
	# Força a inicialização rápida do nó se ele ainda não estiver no ready
	if not is_node_ready():
		await ready

	label.add_theme_font_override("font", FONTE_NUMEROS)
	label.text = texto
	
	# Define as cores baseadas em canetas reais de caderno
	match tipo_timing:
		"perfect":
			label.modulate = Color("f39c12") # Dourado/Laranja Caneta Gel especial
		"good":
			label.modulate = Color("0047ab") # Caneta Esferográfica Azul BIC
		"miss":
			label.modulate = Color("d9534f") # Vermelho Correção de Professor
		_:
			label.modulate = Color.BLACK
			
	# Animação dinâmica com Tween
	var tween = create_tween().set_parallel(true)
	
	# 1. Efeito de Escala (Surge pequeno, dá um pulso/pop e estabiliza)
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Rotação Aleatória de Leve (efeito "escrito à mão" torto)
	rotation = randf_range(-0.18, 0.18)
	
	# 3. Flutuar para cima (perda de gravidade do feedback)
	var pos_alvo = position + Vector2(0, -100)
	tween.tween_property(self, "position", pos_alvo, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 4. Desaparecimento gradual (Fade out) começando após a metade do tempo
	var fade_tween = create_tween()
	fade_tween.set_parallel(false)
	fade_tween.tween_interval(0.4)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Se auto-destrói quando o movimento principal terminar
	tween.finished.connect(queue_free)
