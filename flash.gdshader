shader_type canvas_item;
// Shader dos inimigos:
// - flash: pisca o desenho em branco ao levar dano (0 = normal, 1 = branco).
//   Funciona em tinta escura, onde multiplicar a cor (modulate) quase não aparece.
// - tremido: "boiling line" de desenho à mão; a imagem ondula de leve e muda
//   de forma em passos (8 por segundo), como animação desenhada quadro a quadro.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float tremido = 0.0;   // intensidade em UV (~0.004); 0 desliga
uniform float semente = 0.0;   // cada inimigo treme diferente

varying vec4 cor_vertice;

void vertex() {
	cor_vertice = COLOR;
}

void fragment() {
	vec2 uv = UV;
	if (tremido > 0.0) {
		float passo = floor(TIME * 8.0) + semente;
		uv += vec2(
			sin(UV.y * 31.0 + passo * 12.9898),
			cos(UV.x * 27.0 + passo * 78.233)
		) * tremido;
	}
	vec4 c = texture(TEXTURE, uv) * cor_vertice;
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	COLOR = c;
}
