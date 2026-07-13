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

## Registra um respingo permanente de tinta na posição (global) da morte.
func adicionar_mancha(pos_global: Vector2, cor: Color, raio_base: float = 20.0) -> void:
	var pos_local = get_global_transform().affine_inverse() * pos_global
	manchas.append({
		"pos": pos_local,
		"cor": Color(cor.r, cor.g, cor.b, 0.16),
		"raio": raio_base * randf_range(0.7, 1.3),
		"seed": randi(),
	})
	if manchas.size() > MAX_MANCHAS:
		manchas.pop_front()
	queue_redraw()

func limpar_manchas() -> void:
	manchas.clear()
	queue_redraw()

func configurar_para_capitulo(capitulo: int) -> void:
	# Define cores e estilos procedurais com base no capítulo
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
	elif capitulo == 10:
		# Papel Milimetrado de Desenho Técnico (Clímax!)
		color = Color("fdfaf4")
		cor_da_linha = Color("e07a5f", 0.5) # Laranja técnico principal
		cor_da_margem = Color("e07a5f", 0.6)
		tipo_pauta = "milimetrado"
	queue_redraw()

func _draw() -> void:
	var limite_y = pauta_limite_y if pauta_limite_y != null else 1440.0
	
	# 1. Desenha as linhas horizontais da pauta
	var y = espacamento_linhas
	while y < size.y:
		# Se desenhar_margem for ativo e for a linha limite, desenha tracejada (picotada do caderno)
		if desenhar_margem and abs(y - limite_y) < 1.0:
			draw_dashed_line(Vector2(0, y), Vector2(size.x, y), Color("444444", 0.7) if color.v > 0.5 else Color("cccccc", 0.7), espessura_linha * 2.5, 12.0)
		else:
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

	# 3. Desenha a linha vertical da margem e os marcadores apenas se desenhar_margem for ativo
	if desenhar_margem:
		if tipo_pauta != "quadriculado" and tipo_pauta != "milimetrado":
			draw_line(Vector2(margem_esquerda, 0), Vector2(margem_esquerda, size.y), cor_da_margem, espessura_linha * 1.5)
		
		if abs(limite_y) > 0:
			var cor_marcador = Color("444444", 0.7) if color.v > 0.5 else Color("cccccc", 0.7)
			# Pequeno marcador (> e <) indicando a barreira de movimento na margem
			draw_line(Vector2(margem_esquerda - 25, limite_y - 12), Vector2(margem_esquerda - 10, limite_y), cor_marcador, 2.0)
			draw_line(Vector2(margem_esquerda - 25, limite_y + 12), Vector2(margem_esquerda - 10, limite_y), cor_marcador, 2.0)

	# 4. Manchas de tinta das batalhas (seed fixa por mancha: redraw estável)
	for m in manchas:
		var rng = RandomNumberGenerator.new()
		rng.seed = m["seed"]
		draw_circle(m["pos"], m["raio"], m["cor"])
		for i in range(4):
			var offset = Vector2(rng.randf_range(-m["raio"], m["raio"]), rng.randf_range(-m["raio"], m["raio"]))
			draw_circle(m["pos"] + offset, m["raio"] * rng.randf_range(0.25, 0.5), m["cor"])
