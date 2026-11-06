class_name EscudoBorracha
## Desenho do Escudo de Borracha em volta da caneta: a borracha de apagar
## caneta vista de cima (bloco com pontas chanfradas), com a face de cima e a
## borda chanfrada desenhadas à caneta. Azul em cima (~35%) e vermelho embaixo
## (~65%), como a borracha de verdade; hachura de sombra na borda direita.
## Recarregando, o contorno volta a ser desenhado (dá para ler o tempo).

const CENTRO := Vector2(0, -12)
const MEIA_LARGURA: float = 62.0
const MEIA_ALTURA: float = 148.0
const CHANFRO: float = 30.0
const BORDA: float = 13.0          # largura da borda chanfrada (face de cima fica dentro)
const FRACAO_AZUL: float = 0.35
const AZUL := Color("3456a8")
const VERMELHO := Color("c8473f")
const TINTA := Color("1d2a5c")     # traço escuro da caneta nos detalhes

## Vértices do bloco chanfrado (sentido horário, começando no topo esquerdo).
static func _vertices(w: float, h: float, c: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-w + c, -h), Vector2(w - c, -h), Vector2(w, -h + c), Vector2(w, h - c),
		Vector2(w - c, h), Vector2(-w + c, h), Vector2(-w, h - c), Vector2(-w, -h + c)])

static func perimetro(v: PackedVector2Array) -> float:
	var p := 0.0
	for i in v.size():
		p += v[i].distance_to(v[(i + 1) % v.size()])
	return p

## Ponto do contorno a "s" px do primeiro vértice, com tremor de caneta.
static func ponto(v: PackedVector2Array, s: float, tremor: float = 1.0) -> Vector2:
	var p := perimetro(v)
	var u := fposmod(s, p)
	for i in v.size():
		var a := v[i]
		var b := v[(i + 1) % v.size()]
		var l := a.distance_to(b)
		if u <= l or i == v.size() - 1:
			var dir := (b - a) / maxf(l, 0.001)
			var normal := Vector2(dir.y, -dir.x)
			var off: float = (sin(u * 0.05 + i * 1.7) * 1.1 + sin(u * 0.17 + i) * 0.5) * tremor
			return CENTRO + a + dir * minf(u, l) + normal * off
		u -= l
	return CENTRO + v[0]

static func _trecho(v: PackedVector2Array, s0: float, s1: float, desloc: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var passos: int = maxi(2, int((s1 - s0) / 7.0))
	for k in passos + 1:
		pts.append(ponto(v, lerpf(s0, s1, float(k) / passos)) + Vector2(desloc, desloc * 0.5))
	return pts

static func _y_divisa(h: float) -> float:
	return CENTRO.y - h + 2.0 * h * FRACAO_AZUL

static func _cor_em(p: Vector2, h: float) -> Color:
	return AZUL if p.y < _y_divisa(h) else VERMELHO

static func _recorte(poli: PackedVector2Array, y0: float, y1: float) -> Array:
	return Geometry2D.intersect_polygons(poli, PackedVector2Array([
		Vector2(-300, y0), Vector2(300, y0), Vector2(300, y1), Vector2(-300, y1)]))

static func _deslocar(v: PackedVector2Array) -> PackedVector2Array:
	var r := PackedVector2Array()
	for q in v:
		r.append(q + CENTRO)
	return r

## progresso: 0..1 da recarga (1 = ativo). pop: 0..1 logo que volta.
## frente = false desenha o miolo (por baixo da caneta); true, o contorno.
static func desenhar(ci: CanvasItem, progresso: float, ativo: bool, t: float, pop: float, frente: bool = true) -> void:
	var k: float = 1.0 + 0.012 * sin(t * 3.0) + 0.12 * pop
	var w := MEIA_LARGURA * k
	var h := MEIA_ALTURA * k
	var fora := _vertices(w, h, CHANFRO * k)
	var dentro := _vertices(w - BORDA, h - BORDA, (CHANFRO - BORDA * 0.45) * k)
	var p := perimetro(fora)
	var yd := _y_divisa(h)
	if ativo and not frente:
		# Preenchimento clarinho nas duas cores; borda um tom mais forte que a face
		var poli_fora := _deslocar(fora)
		var poli_dentro := _deslocar(dentro)
		for pc in _recorte(poli_fora, -999, yd):
			ci.draw_colored_polygon(pc, Color(AZUL, 0.20))
		for pc in _recorte(poli_fora, yd, 999):
			ci.draw_colored_polygon(pc, Color(VERMELHO, 0.20))
		for pc in _recorte(poli_dentro, -999, yd):
			ci.draw_colored_polygon(pc, Color(1, 1, 1, 0.35))
		for pc in _recorte(poli_dentro, yd, 999):
			ci.draw_colored_polygon(pc, Color(1, 1, 1, 0.35))
		# Hachura de sombra na borda direita (traços diagonais curtos)
		var y := CENTRO.y - h + CHANFRO
		while y < CENTRO.y + h - CHANFRO:
			var x0 := CENTRO.x + w - BORDA + 2.0
			var cor_h := Color(AZUL if y < yd else VERMELHO, 0.55)
			ci.draw_line(Vector2(x0, y + 6.0), Vector2(x0 + BORDA - 4.0, y), cor_h, 1.6, true)
			y += 9.0
		# Face de cima: contorno interno fino e as quinas da borda chanfrada
		ci.draw_polyline(_trecho(dentro, 0.0, perimetro(dentro) + 0.5), Color(TINTA, 0.55), 2.0, true)
		for i in fora.size():
			ci.draw_line(CENTRO + fora[i], CENTRO + dentro[i], Color(TINTA, 0.55), 2.0, true)
		# Divisa azul/vermelho atravessando a face e a borda
		ci.draw_line(Vector2(CENTRO.x - w + 1.0, yd), Vector2(CENTRO.x + w - 1.0, yd + 1.5), Color(TINTA, 0.6), 2.2, true)
		# Faixa branca da borracha, perto da ponta vermelha
		var yb := CENTRO.y + h - CHANFRO - 10.0
		ci.draw_line(Vector2(CENTRO.x - w + BORDA, yb), Vector2(CENTRO.x + w - BORDA, yb + 1.0), Color(1, 1, 1, 0.9), 5.0, true)
		ci.draw_line(Vector2(CENTRO.x - w + BORDA, yb + 4.0), Vector2(CENTRO.x + w - BORDA, yb + 5.0), Color(TINTA, 0.35), 1.5, true)
	if not frente:
		return
	# Contorno de fora: inteiro quando ativo; recarregando, sendo desenhado
	ci.draw_polyline(_trecho(fora, 0.0, p + 0.5), Color(TINTA, 0.10), 3.0, true)
	var feito: float = p if ativo else p * progresso
	var s := 0.0
	while s < feito:
		var s1: float = minf(s + 9.0, feito)
		var c := _cor_em(ponto(fora, s, 0.0), h)
		ci.draw_polyline(_trecho(fora, s, s1 + 1.0), c, 5.0, true)
		ci.draw_polyline(_trecho(fora, s, s1 + 1.0, 2.2), Color(c, 0.45), 2.0, true)
		s = s1
