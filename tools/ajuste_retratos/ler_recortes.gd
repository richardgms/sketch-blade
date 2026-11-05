extends SceneTree
## Lê os transforms salvos na cena; não escreve em Hub.gd nem no save.
func _initialize() -> void:
	var cena: Node = load("res://tools/ajuste_retratos/ajuste_retratos.tscn").instantiate()
	var recortes := {}
	for cap in range(1, 11):
		var rosto: Sprite2D = cena.get_node("Chefe%02d/Rosto" % cap)
		if absf(rosto.scale.x - rosto.scale.y) > 0.00001 or rosto.scale.x <= 0.0 or not is_zero_approx(rosto.rotation):
			push_error("Chefe %d: mantenha escala X = Y, positiva, e rotação zero." % cap)
			cena.free()
			quit(1)
			return
		var dimensoes := rosto.texture.get_size()
		var centro := Vector2(0.5, 0.5) - rosto.position / (dimensoes * rosto.scale)
		var tamanho := Vector2(200, 200) / (dimensoes * rosto.scale)
		recortes[cap] = Rect2(centro - tamanho * 0.5, tamanho)
	print("const ROSTOS_TRILHA := {")
	for cap in recortes:
		var r: Rect2 = recortes[cap]
		print("\t%d: Rect2(%.8f, %.8f, %.8f, %.8f)," % [cap, r.position.x, r.position.y, r.size.x, r.size.y])
	print("}")
	cena.free()
	quit()
