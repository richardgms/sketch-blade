extends Control
## Selo redondo de carimbo da tela de vitória: dois anéis, "CAPÍTULO N" em
## arco no alto, nome do chefe em arco embaixo e faixa "DERROTADO" no meio.

const FONTE = preload("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
const COR := Color("c62828")
const PAPEL := Color(0.99, 0.97, 0.9, 0.5) # deixa o chefe aparecer por baixo

var capitulo: int = 1
var nome_chefe: String = ""

func configurar(cap: int, nome: String) -> void:
	capitulo = cap
	nome_chefe = nome.to_upper()
	queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r: float = min(size.x, size.y) / 2.0 - 6.0
	# Fundo de papel para ler por cima do desenho
	draw_circle(c, r, PAPEL)
	# Anéis: grosso por fora, fino por dentro
	draw_arc(c, r - 5.0, 0.0, TAU, 128, COR, 10.0, true)
	draw_arc(c, r - 46.0, 0.0, TAU, 128, COR, 4.0, true)
	# Textos em arco entre os anéis
	var r_texto: float = r - 25.0
	_texto_curvo("CAPÍTULO %d" % capitulo, c, r_texto, 30, true)
	_texto_curvo(nome_chefe, c, r_texto, 28 if nome_chefe.length() <= 14 else 24, false)
	# Pontinhos separando os dois arcos
	draw_circle(c + Vector2(-r_texto, 0.0), 6.0, COR)
	draw_circle(c + Vector2(r_texto, 0.0), 6.0, COR)
	# Faixa central com "DERROTADO", mais larga que o anel interno
	var tam := 60
	var largura_txt: float = FONTE.get_string_size("DERROTADO", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var faixa := Rect2(c.x - largura_txt / 2.0 - 26.0, c.y - 44.0, largura_txt + 52.0, 88.0)
	draw_rect(faixa, Color(PAPEL.r, PAPEL.g, PAPEL.b, 1.0))
	draw_rect(faixa, COR, false, 6.0)
	draw_string(FONTE, Vector2(faixa.position.x + 26.0, c.y + tam * 0.36), "DERROTADO",
		HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COR)

## Escreve o texto letra a letra num arco. No alto lê da esquerda para a
## direita por fora; embaixo, de pé, também da esquerda para a direita.
func _texto_curvo(texto: String, c: Vector2, raio: float, tam: int, no_alto: bool) -> void:
	var larguras: Array[float] = []
	var total := 0.0
	for ch in texto:
		var w: float = FONTE.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 2.0
		larguras.append(w)
		total += w
	var acumulado := 0.0
	for i in texto.length():
		var w: float = larguras[i]
		var meio: float = (acumulado + w / 2.0 - total / 2.0) / raio
		var ang: float
		var giro: float
		if no_alto:
			ang = -PI / 2.0 + meio
			giro = ang + PI / 2.0
		else:
			ang = PI / 2.0 - meio
			giro = ang - PI / 2.0
		var pos := c + Vector2(cos(ang), sin(ang)) * raio
		draw_set_transform(pos, giro)
		draw_string(FONTE, Vector2(-w / 2.0 + 1.0, tam * 0.36), texto[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COR)
		acumulado += w
	draw_set_transform(Vector2.ZERO, 0.0)
