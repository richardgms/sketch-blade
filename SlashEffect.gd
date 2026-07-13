extends Line2D

@export var tempo_vida: float = 0.22 # Duração rápida do traço de corte na tela

func _ready() -> void:
	# Cria uma animação de fade-out e encolhimento para sumir o traço de tinta
	var tween = create_tween().set_parallel(true)
	
	# 1. Faz a opacidade sumir suavemente
	tween.tween_property(self, "modulate:a", 0.0, tempo_vida).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 2. Faz o traço da linha afinar até sumir
	tween.tween_property(self, "width", 0.0, tempo_vida).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 3. Garante a auto-destruição ao fim da animação
	tween.finished.connect(queue_free)
