shader_type canvas_item;
// Pisca o desenho em branco ao levar dano (0 = normal, 1 = todo branco).
// Funciona em tinta escura, onde multiplicar a cor (modulate) quase não aparece.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
