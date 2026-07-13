extends CPUParticles2D

func _ready() -> void:
	# Garante que vai emitir o espirro de tinta uma única vez
	emitting = true
	# Se não estiver rodando no pool do Main, se destrói de forma convencional (evita vazamento de memória)
	if not get_parent() or not get_parent().has_method("devolver_particulas"):
		finished.connect(queue_free)
