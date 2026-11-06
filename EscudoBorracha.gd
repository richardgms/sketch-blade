class_name EscudoBorracha
## Desenho do Escudo de Borracha em volta da caneta: uma pílula (como a
## borracha de apagar caneta), em 3 estilos para escolher:
##   A = pílula tracejada à caneta (traços correm devagar pelo contorno)
##   B = borracha bicolor: contorno azul em cima e vermelho embaixo
##   C = contorno à caneta com hachura curtinha por dentro
## Recarregando, o contorno volta a ser desenhado (dá para ler o tempo).

const CENTRO := Vector2(0, -12)
const MEIA_LARGURA: float = 62.0
const MEIA_ALTURA: float = 145.0
const AZUL := Color("0047ab")
const AZUL_BORRACHA := Color("3456a8")
const VERMELHO_BORRACHA := Color("c8473f")
const TRACOS: int = 20

static var estilo: String = "A"

static func perimetro(w: float, h: float) -> float:
	return 4.0 * (h - w) + TAU * w

## Ponto do contorno a "s" px do topo, no sentido horário, com tremor de caneta.
static func ponto(s: float, w: float, h: float, tremor: float = 1.0) -> Vector2:
	var p := perimetro(w, h)
	var u := fposmod(s, p)
	var lh := h - w
	var pos: Vector2
	var n: Vector2
	var arcq := PI * w / 2.0
	if u < arcq:
		n = Vector2.from_angle(-PI / 2.0 + u / w)
		pos = Vector2(0, -lh) + n * w
	elif u < arcq + 2.0 * lh:
		n = Vector2.RIGHT
		pos = Vector2(w, -lh + (u - arcq))
	elif u < arcq + 2.0 * lh + PI * w:
		n = Vector2.from_angle((u - arcq - 2.0 * lh) / w)
		pos = Vector2(0, lh) + n * w
	elif u < arcq + 4.0 * lh + PI * w:
		n = Vector2.LEFT
		pos = Vector2(-w, lh - (u - arcq - 2.0 * lh - PI * w))
	else:
		n = Vector2.from_angle(PI + (u - arcq - 4.0 * lh - PI * w) / w)
		pos = Vector2(0, -lh) + n * w
	var off: float = (sin(u * 0.045 + 1.3) * 2.6 + sin(u * 0.13) * 1.2) * tremor
	return CENTRO + pos + n * off

static func _trecho(s0: float, s1: float, w: float, h: float, desloc: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var passos: int = maxi(2, int((s1 - s0) / 8.0))
	for k in passos + 1:
		var s: float = lerpf(s0, s1, float(k) / passos)
		pts.append(ponto(s, w, h) + Vector2(desloc, desloc * 0.5))
	return pts

static func _cor_b(s: float, w: float, h: float) -> Color:
	return AZUL_BORRACHA if ponto(s, w, h, 0.0).y < CENTRO.y else VERMELHO_BORRACHA

## progresso: 0..1 da recarga (1 = ativo). pop: 0..1 logo que volta.
static func desenhar(ci: CanvasItem, progresso: float, ativo: bool, t: float, pop: float) -> void:
	var k: float = 1.0 + 0.015 * sin(t * 3.0) + 0.14 * pop
	var w := MEIA_LARGURA * k
	var h := MEIA_ALTURA * k
	var p := perimetro(w, h)
	match estilo:
		"A":
			var corre: float = t * 28.0
			var cheios: int = TRACOS if ativo else int(TRACOS * progresso)
			for i in TRACOS:
				var s0: float = corre + p * i / TRACOS
				var pts := _trecho(s0, s0 + p / TRACOS * 0.55, w, h)
				if i < cheios:
					ci.draw_polyline(pts, AZUL, 5.0 if ativo else 3.5, true)
				else:
					ci.draw_polyline(pts, Color(AZUL, 0.15), 3.0, true)
		"B":
			var feito: float = p if ativo else p * progresso
			# Fundo clarinho nas duas cores (só ativo)
			if ativo:
				var poli := _trecho(0.0, p, w, h)
				var meio := CENTRO.y
				var cima := Geometry2D.intersect_polygons(poli, PackedVector2Array([Vector2(-200, meio - 400), Vector2(200, meio - 400), Vector2(200, meio), Vector2(-200, meio)]))
				var baixo := Geometry2D.intersect_polygons(poli, PackedVector2Array([Vector2(-200, meio), Vector2(200, meio), Vector2(200, meio + 400), Vector2(-200, meio + 400)]))
				for pc in cima:
					ci.draw_colored_polygon(pc, Color(AZUL_BORRACHA, 0.10))
				for pc in baixo:
					ci.draw_colored_polygon(pc, Color(VERMELHO_BORRACHA, 0.10))
			ci.draw_polyline(_trecho(0.0, p, w, h), Color(AZUL, 0.12), 3.0, true)
			var seg: float = 10.0
			var s: float = 0.0
			while s < feito:
				var s1: float = minf(s + seg, feito)
				var c := _cor_b(s, w, h)
				ci.draw_polyline(_trecho(s, s1 + 1.0, w, h), c, 5.0, true)
				ci.draw_polyline(_trecho(s, s1 + 1.0, w, h, 2.5), Color(c, 0.45), 2.0, true)
				s = s1
		_:
			var feito: float = p if ativo else p * progresso
			ci.draw_polyline(_trecho(0.0, p, w, h), Color(AZUL, 0.12), 3.0, true)
			if feito > 1.0:
				ci.draw_polyline(_trecho(0.0, feito, w, h), AZUL, 4.0, true)
				ci.draw_polyline(_trecho(0.0, feito, w, h, 2.5), Color(AZUL, 0.45), 2.0, true)
			if ativo:
				var s: float = 6.0
				while s < p:
					var a := ponto(s, w, h, 0.0)
					var b := ponto(s + 1.0, w, h, 0.0)
					var tangente := (b - a).normalized()
					var dentro := Vector2(-tangente.y, tangente.x) # vira para dentro (sentido horário)
					var d := dentro.rotated(0.55)
					ci.draw_line(a + dentro * 4.0, a + dentro * 4.0 + d * 13.0, Color(AZUL, 0.5), 2.0, true)
					s += 13.0

## Pedaços do contorno para voar na quebra: [pontos (em volta do centro), cor, largura].
static func pedacos(t: float) -> Array:
	var w := MEIA_LARGURA
	var h := MEIA_ALTURA
	var p := perimetro(w, h)
	var lista: Array = []
	var desloc: float = t * 28.0 if estilo == "A" else 0.0
	for i in TRACOS:
		var s0: float = desloc + p * i / TRACOS
		var s1: float = s0 + p / TRACOS * (0.55 if estilo == "A" else 0.9)
		var pts := _trecho(s0, s1, w, h)
		for j in pts.size():
			pts[j] -= CENTRO
		var cor: Color = _cor_b(s0, w, h) if estilo == "B" else AZUL
		lista.append([pts, cor, 5.0 if estilo != "C" else 4.0])
	return lista
