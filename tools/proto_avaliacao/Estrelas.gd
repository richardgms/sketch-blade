extends Control
## Cinco estrelas à mão em giz de cera (assets/ui/estrela_giz.png), cada uma
## com leve giro e tamanho diferente, como desenhadas uma a uma.
var lado := 100.0
const GIRO := [-8.0, 5.0, -3.0, 7.0, -5.0]
const ESCALA := [0.96, 1.04, 1.0, 0.95, 1.02]
const SOBE := [3.0, -4.0, 0.0, -2.0, 4.0]
func _ready() -> void:
	var tex: Texture2D = load("res://assets/ui/estrela_giz.png")
	var passo := size.x / 5.0
	for i in 5:
		var l: float = lado * 1.2 * ESCALA[i]
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.size = Vector2(l, l)
		t.pivot_offset = t.size / 2.0
		t.position = Vector2(passo * (i + 0.5), size.y / 2.0 + SOBE[i]) - t.size / 2.0
		t.rotation_degrees = GIRO[i]
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(t)
