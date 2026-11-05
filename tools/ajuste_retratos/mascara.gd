@tool
extends Node2D
## Só desenha a área que recorta o Sprite2D filho, inclusive no editor 2D.
func _draw() -> void:
	draw_circle(Vector2.ZERO, 100.0, Color.WHITE, true, -1.0, true)
