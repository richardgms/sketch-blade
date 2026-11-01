@tool
extends ColorRect

# Configurações das linhas (editáveis no painel Inspetor)
@export var cor_da_linha: Color = Color("92a8d1", 0.4) # Azul claro suave (pauta comum)
@export var espacamento_linhas: float = 90.0
@export var espessura_linha: float = 2.0
@export var margem_esquerda: float = 140.0
@export var cor_da_margem: Color = Color("ff6b6b", 0.5) # Margem vermelha clássica
@export var desenhar_margem: bool = true # Se falso, esconde a linha vermelha e o limite tracejado (ideal para Hub)
@export var pauta_limite_y: float = 1440.0 # Linha limite que a caneta do jogador não pode ultrapassar

var tipo_pauta: String = "pautado"

## Textura do papel gerada no ChatGPT (em cinza, tingida pela cor do
## capítulo): a limpa em todas as folhas; a usada (vincos, cantos gastos) nos
## cadernos quadriculados, milimetrado e amarelados.
const PAPEL_LIMPO := preload("res://assets/ui/papel_limpo.png")
const PAPEL_USADO := preload("res://assets/ui/papel_usado.png")
var textura_papel: Texture2D = PAPEL_LIMPO
## Linha até onde a caneta pode ir: tracejado à caneta com a setinha ">",
## desenhado no ChatGPT (branco com alfa, pintado de azul-caneta).
const LINHA_LIMITE := preload("res://assets/ui/linha_limite.png")
const COR_LIMITE := Color("002867", 0.7)

## Faz o papel preencher a tela inteira em runtime, independente do tipo do nó
## pai (a raiz das cenas é Node2D, onde âncoras full-rect não resolvem). As
## pautas são desenhadas até size.x/size.y, então basta manter o size = viewport.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_ajustar_ao_viewport()
	get_viewport().size_changed.connect(_ajustar_ao_viewport)

func _ajustar_ao_viewport() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT) # evita o layout sobrescrever o size
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()

# Manchas de tinta deixadas pelos monstros derrotados (limpas a cada página)
const MAX_MANCHAS: int = 120
var manchas: Array = []

## Mancha desenhada (textura branca com alfa, tingida pela cor do monstro).
func adicionar_mancha_textura(pos_global: Vector2, cor: Color, tex: Texture2D, tam: float, rot: float) -> void:
	manchas.append({
		"pos": get_global_transform().affine_inverse() * pos_global,
		"cor": cor, "tex": tex, "tam": tam, "rot": rot,
	})
	if manchas.size() > MAX_MANCHAS:
		manchas.pop_front()
	queue_redraw()

func limpar_manchas() -> void:
	manchas.clear()
	queue_redraw()

func configurar_para_capitulo(capitulo: int) -> void:
	# Define cores e estilos procedurais com base no capítulo
	textura_papel = PAPEL_LIMPO
	if capitulo >= 1 and capitulo <= 3:
		# Caderno de Rascunhos Comum
		color = Color("faf6ee")
		cor_da_linha = Color("92a8d1", 0.45)
		cor_da_margem = Color("ff6b6b", 0.5)
		tipo_pauta = "pautado"
	elif capitulo >= 4 and capitulo <= 5:
		# Caderno Quadriculado de Matemática
		color = Color("f5f5f7")
		cor_da_linha = Color("92a8d1", 0.35)
		cor_da_margem = Color("ff6b6b", 0.4)
		tipo_pauta = "quadriculado"
		textura_papel = PAPEL_USADO
	elif capitulo >= 6 and capitulo <= 7:
		# Papel Bege / Pardo Rústico
		color = Color("e5dcc6")
		cor_da_linha = Color("90826b", 0.5)
		cor_da_margem = Color("af4242", 0.5)
		tipo_pauta = "pautado"
	elif capitulo >= 8 and capitulo <= 9:
		# Caderno Antigo Amarelado Grafite
		color = Color("f7f0e1")
		cor_da_linha = Color("30303e", 0.22)
		cor_da_margem = Color("7e2424", 0.4)
		tipo_pauta = "pautado"
		textura_papel = PAPEL_USADO
	elif capitulo == 10:
		# Papel Milimetrado de Desenho Técnico (Clímax!)
		color = Color("fdfaf4")
		cor_da_linha = Color("e07a5f", 0.5) # Laranja técnico principal
		cor_da_margem = Color("e07a5f", 0.6)
		tipo_pauta = "milimetrado"
		textura_papel = PAPEL_USADO
	queue_redraw()

func _draw() -> void:
	var limite_y = pauta_limite_y if pauta_limite_y != null else 1440.0
	
	if textura_papel:
		draw_texture_rect(textura_papel, Rect2(Vector2.ZERO, size), false, color)

	# 1. Desenha as linhas horizontais da pauta
	var y = espacamento_linhas
	while y < size.y:
		# A linha-limite (com margem ligada) é desenhada no passo 3
		if not (desenhar_margem and abs(y - limite_y) < 1.0):
			draw_line(Vector2(0, y), Vector2(size.x, y), cor_da_linha, espessura_linha)
		y += espacamento_linhas

	# 2. Desenha as linhas verticais da pauta se for quadriculado ou milimetrado
	if tipo_pauta == "quadriculado" or tipo_pauta == "milimetrado":
		var x = espacamento_linhas
		while x < size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), cor_da_linha, espessura_linha)
			x += espacamento_linhas
			
	# 2.5. Desenha sub-grades milimétricas se for milimetrado
	if tipo_pauta == "milimetrado":
		var sub_divisoes = 5
		var sub_passo = espacamento_linhas / sub_divisoes
		var cor_sub_linha = Color(cor_da_linha.r, cor_da_linha.g, cor_da_linha.b, cor_da_linha.a * 0.35)
		
		# Sub-linhas horizontais
		var sy = sub_passo
		while sy < size.y:
			if fmod(sy, espacamento_linhas) > 1.0 and fmod(sy, espacamento_linhas) < espacamento_linhas - 1.0:
				draw_line(Vector2(0, sy), Vector2(size.x, sy), cor_sub_linha, 1.0)
			sy += sub_passo
			
		# Sub-linhas verticais
		var sx = sub_passo
		while sx < size.x:
			if fmod(sx, espacamento_linhas) > 1.0 and fmod(sx, espacamento_linhas) < espacamento_linhas - 1.0:
				draw_line(Vector2(sx, 0), Vector2(sx, size.y), cor_sub_linha, 1.0)
			sx += sub_passo

	# 3. Margem vermelha e linha-limite da caneta, só se desenhar_margem for ativo
	if desenhar_margem:
		if tipo_pauta != "quadriculado" and tipo_pauta != "milimetrado":
			draw_line(Vector2(margem_esquerda, 0), Vector2(margem_esquerda, size.y), cor_da_margem, espessura_linha * 1.5)
		
		if abs(limite_y) > 0:
			var h: float = size.x * LINHA_LIMITE.get_height() / LINHA_LIMITE.get_width()
			draw_texture_rect(LINHA_LIMITE, Rect2(0, limite_y - h / 2.0, size.x, h), false, COR_LIMITE)

	# 4. Manchas de tinta das batalhas (respingos na cor do monstro)
	for m in manchas:
		draw_set_transform(m["pos"], m["rot"], Vector2.ONE)
		var t: float = m["tam"]
		draw_texture_rect(m["tex"], Rect2(-t / 2.0, -t / 2.0, t, t), false, m["cor"])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
