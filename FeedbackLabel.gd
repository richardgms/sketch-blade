extends Marker2D

const FONTE_NUMEROS = preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")

@onready var label: Label = $Label

## subir = false: o texto foi posto embaixo do alvo e desce, para não voltar por cima dele.
func setup(texto: String, tipo_timing: String, subir: bool = true) -> void:
	# Força a inicialização rápida do nó se ele ainda não estiver no ready
	if not is_node_ready():
		await ready

	label.add_theme_font_override("font", FONTE_NUMEROS)
	label.text = texto
	
	# Cores de caneta com contorno escuro (como os números de dano): legível
	# sobre o papel e sobre monstro/explosão. A cor vai na fonte, não no
	# modulate, para o contorno continuar escuro.
	var cor: Color
	match tipo_timing:
		"perfect":
			cor = Color("ffad33") # dourado/laranja de caneta gel
		"good":
			cor = Color("4d8dff") # azul BIC clareado para ler com contorno
		"miss":
			cor = Color("ff6b5e") # vermelho de correção
		_:
			cor = Color.WHITE
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_outline_color", Color("1a1a2e"))
	label.add_theme_constant_override("outline_size", 12)
			
	# Animação dinâmica com Tween
	var tween = create_tween().set_parallel(true)
	
	# 1. Efeito de Escala (Surge pequeno, dá um pulso/pop e estabiliza)
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Rotação Aleatória de Leve (efeito "escrito à mão" torto)
	rotation = randf_range(-0.18, 0.18)
	
	# 3. Flutuar para cima (perda de gravidade do feedback)
	var pos_alvo = position + (Vector2(0, -100) if subir else Vector2(0, 60))
	tween.tween_property(self, "position", pos_alvo, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 4. Desaparecimento gradual (Fade out) começando após a metade do tempo
	var fade_tween = create_tween()
	fade_tween.set_parallel(false)
	fade_tween.tween_interval(0.4)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Se auto-destrói quando o movimento principal terminar
	tween.finished.connect(queue_free)
