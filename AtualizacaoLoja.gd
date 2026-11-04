extends Node
## Resultado zero = sem atualização confirmada. Nunca infere disponibilidade do JSON.
signal consultada(codigo: int)
const PRAZO_SEG := 8.0

func consultar(plugin: Object = null) -> void:
	if plugin == null and Engine.has_singleton("SketchBladePlayUpdate"):
		plugin = Engine.get_singleton("SketchBladePlayUpdate")
	if plugin == null:
		consultada.emit(0)
		return
	plugin.query_update()
	var inicio := Time.get_ticks_msec()
	while is_inside_tree() and plugin.get_update_state() == 0:
		if Time.get_ticks_msec() - inicio >= PRAZO_SEG * 1000.0:
			consultada.emit(0)
			return
		await get_tree().create_timer(0.2).timeout
	if is_inside_tree():
		consultada.emit(plugin.get_available_version_code() if plugin.get_update_state() == 2 else 0)
