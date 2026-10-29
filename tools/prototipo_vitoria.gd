extends SceneTree
## Protótipos da nova tela de vitória (29/10/2026), montados por cima da
## vitória real do jogo, sem mexer no Main.gd. Gera prints 1080x1920.
## Uso: Godot --path . -s tools/prototipo_vitoria.gd -- <pasta>
## (faça backup do save do PC antes, como no capturar_telas)

const FONTE := preload("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
const NUM := preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")
const AZUL := Color("0047ab")
const AZUL_ESCURO := Color("002867")
const TEXTO := Color(0.1, 0.1, 0.15)
const VERDE := Color("2e7d32")
const CAP := 5

var _sv: SubViewport
var _saida := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_saida = args[0] if args.size() > 0 else "C:/Users/joalh/Documentos/Sketch Blade - design/vitoria-nova"
	DirAccess.make_dir_recursive_absolute(_saida)
	_rodar()

func _save() -> void:
	var d: Dictionary = root.get_node("SaveManager").dados
	d["tinta"] = 640; d["nivel_conta"] = 6; d["xp_conta"] = 340
	d["capitulo_desbloqueado"] = CAP; d["capitulo_selecionado"] = CAP
	d["tutorial_visto"] = true; d["run_snapshot"] = {"ativa": false}

func _abrir_vitoria() -> Node:
	_save()
	_sv = SubViewport.new(); _sv.size = Vector2i(1080, 1920)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_sv)
	var m: Node = load("res://main.tscn").instantiate(); _sv.add_child(m)
	await create_timer(1.0).timeout
	m.player.invencivel = true
	m.jogo_iniciado = true; m.menu_iniciar.visible = false
	m.capitulo_atual = CAP
	m.tinta_partida = 420; m.monstros_derrotados_partida = 40; m.boss_derrotado_partida = true
	m._processar_fim_de_jogo(true); m.menu_vitoria.visible = true
	await create_timer(0.3).timeout
	return m

func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	_sv.get_texture().get_image().save_png("%s/%s.png" % [_saida, nome])
	print("[prototipo_vitoria] ", nome)

func _fechar() -> void:
	paused = false
	_sv.queue_free(); await process_frame; await process_frame

## Camada nova por cima de tudo, com o papel quadriculado da fase.
func _camada(m: Node) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	m.menu_vitoria.add_child(c)
	var papel := ColorRect.new()
	papel.set_script(preload("res://Paper.gd"))
	papel.desenhar_margem = false
	c.add_child(papel)
	papel.configurar_para_capitulo(CAP)
	return c

func _txt(pai: Control, t: String, tam: int, cor: Color, y0: float, y1: float, fonte: Font = FONTE,
		x0: float = 0.0, x1: float = 1080.0, alinh := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_constant_override("line_spacing", -18)
	l.horizontal_alignment = alinh
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(x0, y0)
	l.size = Vector2(x1 - x0, y1 - y0)
	pai.add_child(l)
	return l

func _linha(pai: Control, x0: float, x1: float, y: float, cor: Color, esp := 3.0) -> void:
	var c := Control.new()
	c.position = Vector2.ZERO
	c.size = Vector2(1080, 1920)
	c.draw.connect(func():
		var pts: PackedVector2Array = []
		for i in range(21):
			var t := float(i) / 20.0
			pts.append(Vector2(lerp(x0, x1, t), y + sin(i * 1.9 + y) * 1.2))
		c.draw_polyline(pts, cor, esp, true))
	pai.add_child(c)

func _chefe(pai: Control, rect: Rect2, cinza: float) -> TextureRect:
	var arte := TextureRect.new()
	arte.texture = load("res://assets/inimigos/chefe_%d.png" % CAP)
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arte.position = rect.position
	arte.size = rect.size
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float cinza : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(g), cinza);
	c.rgb = mix(c.rgb, vec3(0.97, 0.95, 0.9), cinza * 0.35);
	COLOR = c;
}"""
	var mat := ShaderMaterial.new(); mat.shader = sh
	mat.set_shader_parameter("cinza", cinza)
	arte.material = mat
	pai.add_child(arte)
	return arte

func _selo(pai: Control, centro: Vector2, escala: float, giro: float) -> void:
	var s := Control.new()
	s.set_script(preload("res://SeloDerrotado.gd"))
	s.size = Vector2(360, 360)
	s.pivot_offset = Vector2(180, 180)
	s.position = centro - Vector2(180, 180)
	s.scale = Vector2(escala, escala)
	s.rotation_degrees = giro
	pai.add_child(s)
	s.configurar(CAP, "Compasso")

func _botao_cheio(pai: Control, t: String, rect: Rect2, tam := 60) -> void:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", FONTE)
	b.add_theme_font_size_override("font_size", tam)
	for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(e, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(AZUL_ESCURO, 0.6))
	b.add_theme_constant_override("outline_size", 6)
	var st := StyleBoxTexture.new()
	st.texture = load("res://assets/ui/botao_riscado.png")
	st.texture_margin_left = 48; st.texture_margin_right = 48
	st.texture_margin_top = 36; st.texture_margin_bottom = 36
	for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		st.set_content_margin(lado, 6.0)
	for e in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(e, st)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.position = rect.position; b.size = rect.size
	pai.add_child(b)

func _botao_contorno(pai: Control, t: String, rect: Rect2, icone: String = "", tam := 48) -> void:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", FONTE)
	b.add_theme_font_size_override("font_size", tam)
	for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(e, AZUL)
	for e in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(e, AZUL)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(14)
	sb.content_margin_top = 8.0
	if icone != "":
		sb.content_margin_left = 84.0 # texto anda 42 px para dar lugar ao ícone
	for e in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(e, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.position = rect.position; b.size = rect.size
	b.draw.connect(func():
		var r := 22.0; var mm := -6.0; var w := b.size.x; var h := b.size.y
		var cantos := [[Vector2(w - mm - r, mm + r), -PI / 2.0], [Vector2(w - mm - r, h - mm - r), 0.0],
			[Vector2(mm + r, h - mm - r), PI / 2.0], [Vector2(mm + r, mm + r), PI]]
		var pts: PackedVector2Array = []
		var idx := 0
		for c in cantos:
			for i in range(9):
				var a: float = c[1] + float(i) / 8.0 * PI / 2.0
				pts.append(c[0] + Vector2(cos(a), sin(a)) * r + Vector2(3, 3) + Vector2(sin(idx * 7.31), cos(idx * 5.17)) * 1.2)
				idx += 1
		pts.append(pts[0] + Vector2(-14, -1.5))
		b.draw_polyline(pts, Color(AZUL_ESCURO, 0.9), 3.5, true))
	pai.add_child(b)
	if icone != "":
		# Ícone colado no texto, os dois centrados juntos no botão
		var tw: float = FONTE.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var ic := TextureRect.new()
		ic.texture = load(icone)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.modulate = AZUL
		ic.size = Vector2(64, 64)
		ic.position = Vector2((rect.size.x - tw) / 2.0 + 42.0 - 84.0, (rect.size.y - 64.0) / 2.0 + 4.0)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)

func _marca_texto(pai: Control, t: String, y: float) -> void:
	var w: float = FONTE.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 50).x + 60.0
	var faixa := ColorRect.new()
	faixa.color = Color(1.0, 0.92, 0.35, 0.75)
	faixa.position = Vector2(540 - w / 2.0, y + 6)
	faixa.size = Vector2(w, 66)
	faixa.rotation_degrees = -1.0
	pai.add_child(faixa)
	_txt(pai, t, 50, AZUL_ESCURO, y, y + 78)

func _trilha_cheia(pai: Control, y: float) -> void:
	var c := Control.new()
	c.position = Vector2(100, y); c.size = Vector2(880, 100)
	var tex: Texture2D = load("res://assets/inimigos/chefe_%d.png" % CAP)
	c.draw.connect(func():
		var cy := 50.0; var rp := 21.0; var rc := 40.0
		var xc := c.size.x - rc - 6.0
		var passo := (xc - rc - rp - 34.0 - 30.0) / 6.0
		var xs: Array = []
		for i in range(7): xs.append(30.0 + passo * i)
		xs.append(xc)
		for i in range(7):
			c.draw_line(Vector2(xs[i] + rp, cy), Vector2(xs[i + 1] - (rc if i == 6 else rp), cy), AZUL_ESCURO, 3.0, true)
		for i in range(7):
			c.draw_circle(Vector2(xs[i], cy), rp, AZUL)
			c.draw_arc(Vector2(xs[i], cy), rp, 0, TAU, 40, AZUL_ESCURO, 3.0, true)
		c.draw_circle(Vector2(xc, cy), rc, Color.WHITE)
		var lado := rc * 1.9
		c.draw_texture_rect(tex, Rect2(Vector2(xc, cy) - Vector2(lado, lado) / 2.0, Vector2(lado, lado)), false)
		c.draw_arc(Vector2(xc, cy), rc, 0, TAU, 48, AZUL_ESCURO, 4.0, true)
		var cv := Vector2(xc, cy) + Vector2(rc * 0.72, rc * 0.72)
		c.draw_circle(cv, 17.0, Color("2e9e44"))
		c.draw_polyline(PackedVector2Array([cv + Vector2(-8, 0), cv + Vector2(-2, 7), cv + Vector2(9, -7)]), Color.WHITE, 4.0, true))
	pai.add_child(c)

# ------------------------------------------------------------
## Versão do conselho: chefe colorido com selo pequeno no canto, um número
## herói, uma linha de detalhe, barra de XP, trilha cheia, DOBRAR com
## contorno e o botão principal embaixo (polegar).
func _versao_conselho(m: Node) -> void:
	var c := _camada(m)
	_chefe(c, Rect2(190, 110, 700, 640), 0.0)
	_selo(c, Vector2(800, 650), 0.52, -12.0)
	_txt(c, "O Compasso foi derrotado!", 50, TEXTO, 770, 840)
	_txt(c, "+1058 tinta", 150, AZUL, 860, 1040, NUM)
	_txt(c, "420 coletada  +  638 de bônus", 40, AZUL_ESCURO, 1040, 1095)
	# Barra de XP (nível 6, 340 → 450 de 5500)
	var barra := Control.new()
	barra.position = Vector2(240, 1120); barra.size = Vector2(600, 60)
	barra.draw.connect(func():
		var r := Rect2(90, 14, 420, 30)
		barra.draw_rect(r, Color.WHITE)
		barra.draw_rect(Rect2(r.position, Vector2(r.size.x * 450.0 / 5500.0 + 40.0, r.size.y)), AZUL)
		barra.draw_rect(r, AZUL_ESCURO, false, 3.0)
		barra.draw_string(NUM, Vector2(0, 42), "Nv. 6", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, AZUL_ESCURO)
		barra.draw_string(NUM, Vector2(522, 42), "+110 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, AZUL_ESCURO))
	c.add_child(barra)
	_trilha_cheia(c, 1200)
	_marca_texto(c, "Capítulo 6 desbloqueado!", 1330)
	_botao_contorno(c, "Ver anúncio: +1058 tinta", Rect2(170, 1470, 740, 110), "res://assets/ads.svg", 46)
	_botao_cheio(c, "IR PARA O CAPÍTULO 6", Rect2(150, 1630, 780, 130), 60)

## Versão inspirada no rascunho do amigo, sem os excessos: sem "Capítulo 5 ·
## Compasso" no topo, sem "Assistir anúncio", marca-texto sem tracinhos.
## Chefe colorido que fica P&B quando o selo bate (selo maior, mais para a
## esquerda e para cima, cobrindo um pouco da perna).
func _versao_amigo(m: Node, carimbado: bool) -> void:
	var c := _camada(m)
	_txt(c, "CAPÍTULO\nCONCLUÍDO!", 90, VERDE, 50, 290)
	_linha(c, 270, 810, 296, Color(VERDE, 0.85), 5.0)
	_chefe(c, Rect2(150, 315, 780, 650), 1.0 if carimbado else 0.0)
	if carimbado:
		_selo(c, Vector2(745, 765), 0.72, -14.0)
	_txt(c, "Você derrotou o Compasso!", 52, AZUL_ESCURO, 975, 1045)
	_linha(c, 230, 850, 1053, Color(AZUL_ESCURO, 0.6), 2.5)
	var linhas := [["Tinta coletada", "+420"], ["Bônus de vidas", "+336"], ["Bônus do capítulo", "+302"]]
	for i in linhas.size():
		var y := 1068.0 + i * 62.0
		_txt(c, linhas[i][0], 44, AZUL_ESCURO, y, y + 60, FONTE, 210, 700, HORIZONTAL_ALIGNMENT_LEFT)
		_txt(c, linhas[i][1], 48, AZUL_ESCURO, y, y + 60, NUM, 700, 870, HORIZONTAL_ALIGNMENT_RIGHT)
	_linha(c, 190, 890, 1263, AZUL, 3.5)
	var gota := TextureRect.new()
	gota.texture = load("res://assets/ink.svg")
	gota.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gota.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gota.position = Vector2(215, 1288); gota.size = Vector2(110, 110)
	c.add_child(gota)
	_txt(c, "+1.058 tinta", 140, AZUL, 1273, 1413, NUM, 330, 900)
	_linha(c, 300, 440, 1448, Color(AZUL_ESCURO, 0.5), 2.5)
	_linha(c, 640, 780, 1448, Color(AZUL_ESCURO, 0.5), 2.5)
	_txt(c, "+110 XP", 44, AZUL_ESCURO, 1418, 1478, NUM)
	_marca_texto(c, "Capítulo 6 desbloqueado!", 1490)
	_botao_cheio(c, "VOLTAR AO CADERNO", Rect2(130, 1608, 820, 125), 60)
	_botao_contorno(c, "DOBRAR TINTA", Rect2(150, 1768, 780, 100), "res://assets/ads.svg", 48)

## Chefe com dessaturação PARCIAL: tira ~50% da cor do corpo, preserva os
## vermelhos (olhos) e não clareia nem deixa transparente.
func _chefe_parcial(pai: Control, rect: Rect2, desat: float) -> TextureRect:
	var arte := _chefe(pai, rect, 0.0)
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float desat : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	// vermelho forte (olhos, detalhes) fica intacto
	float vermelho = clamp((c.r - max(c.g, c.b)) * 3.0, 0.0, 1.0);
	vec3 suave = mix(c.rgb, vec3(g), 0.5 * desat);
	c.rgb = mix(suave, c.rgb, vermelho);
	COLOR = c;
}"""
	var mat := ShaderMaterial.new(); mat.shader = sh
	mat.set_shader_parameter("desat", desat)
	arte.material = mat
	return arte

## Botão de anúncio: vídeo + "Ver anúncio ·" + gota + "+1.058".
func _botao_anuncio(pai: Control, rect: Rect2, recebido: bool) -> void:
	_botao_contorno(pai, "", rect)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 14)
	linha.position = rect.position + Vector2(0, 6)
	linha.size = rect.size
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(linha)
	var cor := Color("2e9e44") if recebido else AZUL
	var partes: Array = [["res://assets/ads.svg", ""], ["", "Ver anúncio ·"], ["res://assets/ink.svg", ""], ["", "+1.058"]]
	if recebido:
		partes = [["", "Bônus recebido  ✓"]]
	for p in partes:
		if p[0] != "":
			var ic := TextureRect.new()
			ic.texture = load(p[0])
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.custom_minimum_size = Vector2(58, 58)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if p[0].ends_with("ads.svg"):
				ic.modulate = AZUL
			linha.add_child(ic)
		else:
			var l := Label.new()
			l.text = p[1]
			l.add_theme_font_override("font", NUM if p[1].begins_with("+") else FONTE)
			l.add_theme_font_size_override("font_size", 58 if p[1].begins_with("+") else 46)
			l.add_theme_color_override("font_color", cor)
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			linha.add_child(l)

## Versão combinada (pedido de 29/10): estrutura do amigo + barra de XP do
## conselho. estado: "colorido" (antes do carimbo), "final", "bonus", "repetida".
func _versao_mista(m: Node, estado: String) -> void:
	var c := _camada(m)
	var carimbado := estado != "colorido"
	_txt(c, "CAPÍTULO CONCLUÍDO!", 74, VERDE, 70, 170)
	_linha(c, 170, 910, 180, Color(VERDE, 0.85), 5.0)
	_chefe_parcial(c, Rect2(190, 215, 700, 640), 1.0 if carimbado else 0.0)
	if carimbado:
		_selo(c, Vector2(800, 760), 0.5, -10.0)
	var com_bonus := estado == "bonus"
	_txt(c, "Tinta conquistada (com anúncio)" if com_bonus else "Tinta conquistada", 36, Color(AZUL_ESCURO, 0.8), 885, 930)
	var total := "+2.116 tinta" if com_bonus else "+1.058 tinta"
	var tw: float = NUM.get_string_size(total, HORIZONTAL_ALIGNMENT_LEFT, -1, 130).x
	var gota := TextureRect.new()
	gota.texture = load("res://assets/ink.svg")
	gota.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gota.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gota.size = Vector2(96, 96)
	gota.position = Vector2(540 - (tw + 110) / 2.0, 952)
	c.add_child(gota)
	_txt(c, total, 130, AZUL, 925, 1075, NUM, 540 - (tw + 110) / 2.0 + 110, 540 + (tw + 110) / 2.0 + 20, HORIZONTAL_ALIGNMENT_LEFT)
	var linhas := [["Tinta coletada", "+420"], ["Bônus de vidas", "+336"], ["Bônus do capítulo", "+302"]]
	if com_bonus:
		linhas.append(["Bônus do anúncio", "+1.058"])
	for i in linhas.size():
		var y := 1090.0 + i * 58.0
		_txt(c, linhas[i][0], 42, AZUL_ESCURO, y, y + 56, FONTE, 220, 700, HORIZONTAL_ALIGNMENT_LEFT)
		_txt(c, linhas[i][1], 46, AZUL_ESCURO, y, y + 56, NUM, 700, 860, HORIZONTAL_ALIGNMENT_RIGHT)
	var y_xp := 1090.0 + linhas.size() * 58.0 + 30.0
	_linha(c, 200, 880, y_xp - 12.0, Color(AZUL_ESCURO, 0.45), 2.5)
	# Barra de XP: nível 6, 340 + 110 = 450 de 5500 (preenchimento real)
	var barra := Control.new()
	barra.position = Vector2(200, y_xp); barra.size = Vector2(680, 60)
	barra.draw.connect(func():
		var r := Rect2(100, 14, 400, 30)
		barra.draw_rect(r, Color.WHITE)
		barra.draw_rect(Rect2(r.position, Vector2(r.size.x * 450.0 / 5500.0, r.size.y)), AZUL)
		barra.draw_rect(r, AZUL_ESCURO, false, 3.0)
		barra.draw_string(NUM, Vector2(0, 43), "Nv. 6", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, AZUL_ESCURO)
		barra.draw_string(NUM, Vector2(518, 43), "+110 XP", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, AZUL_ESCURO))
	c.add_child(barra)
	# Desbloqueio num espaço fixo: na vitória repetida some sem mexer nos botões
	if estado != "repetida":
		_marca_texto(c, "Capítulo 6 desbloqueado!", 1450)
	_botao_cheio(c, "VOLTAR AO CADERNO", Rect2(130, 1580, 820, 125), 60)
	_botao_anuncio(c, Rect2(150, 1740, 780, 100), com_bonus)

func _rodar() -> void:
	await process_frame
	for estado in ["colorido", "final", "bonus", "repetida"]:
		var m = await _abrir_vitoria()
		_versao_mista(m, estado); await create_timer(0.4).timeout
		await _foto("4-mista-" + estado); await _fechar()
	quit()
