extends "res://TelaEstojo.gd"
## Loja no estilo caderno (protótipo de 30/10/2026): abas Canetas | Pacotes.
## Fica dentro do Hub (aba Loja), como o Estojo: papel, cabeçalho e barra de
## abas são do Hub. Reaproveita as peças do Estojo (card da roleta, etiqueta,
## botões riscados por estado).
## Versões: "A" = fichas de etiqueta em lista (irmã do Estojo);
##          "B" = vitrine (uma caneta grande, miniaturas e um botão só).
## Sinais: sub_aba(chave), caneta(id) (equipar ou comprar) e pacote(chave).

signal sub_aba(chave: String)
signal caneta(id: String)
signal pacote(chave: String)

const ICONES_CANETA := {
	"bic_azul": "res://assets/bic-azul.svg",
	"lapis_hb": "res://assets/lapis-hb.svg",
	"nanquim": "res://assets/nanquim.svg",
	"gel_vermelha": "res://assets/gel-vermelha.svg",
	"nanquim_real": "res://assets/nanquim-real.svg",
}
## Texto da passiva que não cabe na ficha (o resto vem do GameData).
const EFEITO_CURTO := {"bic_azul": "A clássica do estojo.\nSem bônus."}
const PACOTES := [
	{"chave": "tinta", "icone": "res://assets/pote_tinta.png",
		"desc": "Para subir o Estojo\ne comprar canetas."},
	{"chave": "clipes", "icone": "res://assets/clip.svg",
		"desc": "Para as canetas\nespeciais."},
]
const CLIPE_BRANCO := "res://assets/ui/clipe_branco.png"
const GOTA_BRANCA := "res://assets/ui/gota_branca.png"
const VEU := Color("e3edfc")

var versao := "A"
var _sel := "" # vitrine: caneta mostrada em destaque

## Monta canetas (estado, preço, falta) e pacotes a partir do save.
static func montar_dados(save: Dictionary) -> Dictionary:
	var canetas: Array = []
	for c in GameData.CANETAS:
		var id: String = c["id"]
		var usa_tinta: bool = int(c["custo_tinta"]) > 0
		var custo: int = int(c["custo_tinta"]) if usa_tinta else int(c["custo_clipes"])
		var saldo: int = int(save["tinta"]) if usa_tinta else int(save["clipes_ouro"])
		var estado := "comprar"
		if save["caneta_equipada"] == id:
			estado = "uso"
		elif id in save["canetas_possuidas"] or custo <= 0:
			estado = "equipar"
		elif saldo < custo:
			estado = "falta"
		canetas.append({"id": id, "nome": c["nome"], "icone": ICONES_CANETA.get(id, ""),
			"efeito": EFEITO_CURTO.get(id, c["passiva"]), "estado": estado,
			"moeda": "tinta" if usa_tinta else "clipes", "custo": custo, "falta": max(0, custo - saldo)})
	return {"canetas": canetas, "aba": "canetas"}

## Pacotes com nome e preço da Play Store (sem preço: "carregando...").
func montar_pacotes() -> Array:
	var lista: Array = []
	for p in PACOTES:
		var d: Dictionary = p.duplicate()
		d["nome"] = BillingManager.nome(p["chave"])
		d["preco"] = BillingManager.preco(p["chave"])
		d["disponivel"] = BillingManager.disponivel(p["chave"])
		lista.append(d)
	return lista

func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	_btns.clear()
	_abas(d.get("aba", "canetas"))
	if d.get("aba", "canetas") == "pacotes":
		if versao == "A":
			_pacotes_fichas(d["pacotes"])
		else:
			_pacotes_cartas(d["pacotes"])
	elif versao == "A":
		_canetas_fichas(d["canetas"])
	else:
		_vitrine(d["canetas"])

# ------------------------------------------------------------
# Abas Canetas | Pacotes (título da tela)
# ------------------------------------------------------------
func _abas(ativa: String) -> void:
	for item in [["canetas", "CANETAS", 60.0], ["pacotes", "PACOTES", 560.0]]:
		var on: bool = item[0] == ativa
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.text = item[1]
		b.add_theme_font_override("font", FONTE)
		b.add_theme_font_size_override("font_size", 66 if on else 54)
		var cor: Color = AZUL_ESCURO if on else Color(AZUL_ESCURO, 0.4)
		for e in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(e, cor)
		b.position = Vector2(item[2], 320)
		b.size = Vector2(460, 100)
		var chave: String = item[0]
		b.pressed.connect(func(): sub_aba.emit(chave))
		_bloco.add_child(b)
		if on:
			_traco(_bloco, item[2] + 70, item[2] + 390, 430, Color(AZUL_ESCURO, 0.85), 5.0)
	# Separador entre as abas
	var sep := Control.new()
	sep.size = Vector2(1080, 1920)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func():
		sep.draw_line(Vector2(540, 338), Vector2(538, 410), Color(AZUL_ESCURO, 0.35), 3.0, true))
	_bloco.add_child(sep)

# ------------------------------------------------------------
# Versão A: fichas de etiqueta em lista
# ------------------------------------------------------------
func _canetas_fichas(canetas: Array) -> void:
	var alt := 216.0
	var y := 470.0
	for k in range(canetas.size()):
		var it: Dictionary = canetas[k]
		var c := _carta(Rect2(50, y, 980, alt))
		_etiqueta(c)
		_icone_inclinado(c, it["icone"], Rect2(92, 28, 150, 150))
		_txt(c, it["nome"], 50, AZUL_ESCURO, 12, 76, FONTE, 262, 690, HORIZONTAL_ALIGNMENT_LEFT)
		_efeito_rico(c, it["efeito"], Rect2(262, 78, 430, 110), 40, false)
		_acao_caneta(c, it, Rect2(690, 38, 252, 132))
		y += alt + 16.0

func _pacotes_fichas(pacotes: Array) -> void:
	var y := 500.0
	for p in pacotes:
		var c := _carta(Rect2(50, y, 980, 330))
		_etiqueta(c)
		_icone_em(c, p["icone"], Rect2(92, 60, 190, 190))
		_txt(c, p["nome"], 50, AZUL_ESCURO, 34, 104, FONTE, 300, 960, HORIZONTAL_ALIGNMENT_LEFT)
		var desc := _txt(c, p["desc"], 42, AZUL, 112, 230, FONTE, 300, 700, HORIZONTAL_ALIGNMENT_LEFT)
		desc.add_theme_constant_override("line_spacing", -6)
		_botao_preco(c, p, Rect2(704, 120, 236, 132), 56)
		y += 370.0
	_nota(1300)

# ------------------------------------------------------------
# Versão B: vitrine (uma caneta grande + miniaturas + um botão)
# ------------------------------------------------------------
func _vitrine(canetas: Array) -> void:
	if _sel == "":
		for it in canetas:
			if it["estado"] == "uso":
				_sel = it["id"]
	var atual: Dictionary = canetas[0]
	for it in canetas:
		if it["id"] == _sel:
			atual = it
	var c := _carta(Rect2(70, 470, 940, 660))
	_icone_inclinado(c, atual["icone"], Rect2(320, 36, 300, 300))
	_txt(c, atual["nome"], 66, AZUL_ESCURO, 336, 426)
	_traco(c, 300, 640, 434, Color(AZUL_ESCURO, 0.6), 4.0)
	_efeito_rico(c, atual["efeito"], Rect2(60, 462, 820, 130), 46, true)
	# Miniaturas
	var larg := 176.0
	var x0 := 540.0 - (canetas.size() * larg + (canetas.size() - 1) * 14.0) / 2.0
	for k in range(canetas.size()):
		var it: Dictionary = canetas[k]
		var m := _carta(Rect2(x0 + k * (larg + 14.0), 1170, larg, 176))
		var escolhida: bool = it["id"] == _sel
		if escolhida:
			_veu(m)
		var ic := _icone_inclinado(m, it["icone"], Rect2(22, 18, 132, 132))
		if it["estado"] == "falta":
			ic.modulate = Color(1, 1, 1, 0.45)
		if it["estado"] == "uso":
			_txt(m, "✓", 54, VERDE, 96, 160, FONTE, 110, 176)
		var t := Button.new()
		t.flat = true
		t.focus_mode = Control.FOCUS_NONE
		t.size = m.size
		var id: String = it["id"]
		t.pressed.connect(func():
			_sel = id
			mostrar(_dados))
		m.add_child(t)
		if escolhida:
			# Marca de caneta embaixo da escolhida
			_traco(_bloco, m.position.x + 30, m.position.x + larg - 30, 1362, AZUL, 5.0)
	_acao_caneta(_bloco, atual, Rect2(170, 1420, 740, 136), true)

func _pacotes_cartas(pacotes: Array) -> void:
	for k in range(pacotes.size()):
		var p: Dictionary = pacotes[k]
		var c := _carta(Rect2(60 + k * 495, 480, 465, 820))
		_icone_em(c, p["icone"], Rect2(82, 50, 300, 300))
		var nome: String = (p["nome"] as String).replace(" de ", "\nde ")
		var n := _txt(c, nome, 52, AZUL_ESCURO, 360, 500, FONTE, 20, 445)
		n.add_theme_constant_override("line_spacing", -10)
		var desc := _txt(c, p["desc"], 42, AZUL, 510, 640, FONTE, 20, 445)
		desc.add_theme_constant_override("line_spacing", -6)
		_botao_preco(c, p, Rect2(50, 660, 365, 120), 64)
	_nota(1340)

# ------------------------------------------------------------
# Peças
# ------------------------------------------------------------
## Ação da caneta pelo estado: EM USO (verde, sem toque), EQUIPAR (contorno),
## COMPRAR (azul riscado com a moeda em branco) ou falta (riscado clarinho).
func _acao_caneta(pai: Control, it: Dictionary, r: Rect2, largo := false) -> void:
	var id: String = it["id"]
	match it["estado"]:
		"uso":
			var selo := Panel.new()
			selo.add_theme_stylebox_override("panel", _estilo_riscado(BOTAO_MAXIMO))
			selo.position = r.position
			selo.size = r.size
			selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pai.add_child(selo)
			var l := _txt(selo, "EM USO ✓", 50 if largo else 40, Color.WHITE, 4, r.size.y, FONTE, 0, r.size.x)
			l.add_theme_color_override("font_outline_color", Color(VERDE, 0.6))
			l.add_theme_constant_override("outline_size", 6)
		"equipar":
			var b := _botao_contorno(r)
			b.reparent(pai, false)
			b.position = r.position
			var l := _lbl("EQUIPAR", FONTE, 52 if largo else 46, AZUL)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_linha_anuncio.add_child(l)
			b.pressed.connect(func(): caneta.emit(id))
			_btns.append(b)
		_:
			var pode: bool = it["estado"] == "comprar"
			var b := _botao_cheio("", r)
			if not pode:
				var st := _estilo_riscado(BOTAO_FALTA)
				var st_p: StyleBoxTexture = st.duplicate()
				st_p.modulate_color = Color(0.85, 0.85, 0.9)
				for e in ["normal", "hover"]:
					b.add_theme_stylebox_override(e, st)
				b.add_theme_stylebox_override("pressed", st_p)
			b.reparent(pai, false)
			b.position = r.position
			var cont: BoxContainer = HBoxContainer.new() if largo else VBoxContainer.new()
			cont.alignment = BoxContainer.ALIGNMENT_CENTER
			cont.add_theme_constant_override("separation", 22 if largo else -8)
			cont.set_anchors_preset(Control.PRESET_FULL_RECT)
			cont.offset_top = 4.0
			cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(cont)
			if pode:
				var l := _lbl("COMPRAR", FONTE, 52 if largo else 40, Color.WHITE)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cont.add_child(l)
			cont.add_child(_preco_moeda(it, pode, largo))
			if not pode:
				var f := _lbl("faltam %s" % _milhar(int(it["falta"])), NUM, 46 if largo else 42, AZUL_ESCURO)
				f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cont.add_child(f)
			b.pressed.connect(func(): caneta.emit(id))
			_btns.append(b)

## Moeda + custo; no azul a moeda vai em caneta branca.
func _preco_moeda(it: Dictionary, pode: bool, largo: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tinta: bool = it["moeda"] == "tinta"
	var caminho: String
	if pode:
		caminho = GOTA_BRANCA if tinta else CLIPE_BRANCO
	else:
		caminho = "res://assets/ink.svg" if tinta else "res://assets/clip.svg"
	var ic := _icone(caminho, 54 if largo else 48)
	if not pode:
		ic.modulate = Color(1, 1, 1, 0.5)
	h.add_child(ic)
	h.add_child(_lbl(_milhar(int(it["custo"])), NUM, 60 if largo else 52,
		Color.WHITE if pode else Color(AZUL_ESCURO, 0.5)))
	return h

## Botão azul riscado com o preço da Play Store (ou "carregando...").
func _botao_preco(pai: Control, p: Dictionary, r: Rect2, tam: int) -> void:
	var b := _botao_cheio(p["preco"] if p["disponivel"] else "carregando...", r)
	b.add_theme_font_override("font", NUM if p["disponivel"] else FONTE)
	b.add_theme_font_size_override("font_size", tam if p["disponivel"] else 40)
	b.reparent(pai, false)
	b.position = r.position
	b.disabled = not p["disponivel"]
	var chave: String = p["chave"]
	b.pressed.connect(func(): pacote.emit(chave))
	_btns.append(b)

func _nota(y: float) -> void:
	var n := _txt(_bloco, "Pagamento pela Google Play.\nOs itens entram na hora.", 40, Color(AZUL_ESCURO, 0.7), y, y + 110)
	n.add_theme_constant_override("line_spacing", -6)

## Véu azul clarinho da escolhida/em uso (como a carta tocada da roleta).
func _veu(c: Control) -> void:
	var v := Control.new()
	v.size = c.size
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.draw.connect(func():
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(VEU, 0.75)
		sb.set_corner_radius_all(28)
		v.draw_style_box(sb, Rect2(Vector2(14, 12), c.size - Vector2(36, 40))))
	c.add_child(v)

## Desenho da caneta (os SVGs vêm deitados): um pouco inclinado, como na mesa.
func _icone_inclinado(pai: Control, caminho: String, r: Rect2) -> TextureRect:
	var ic := _icone(caminho, r.size.x)
	ic.position = r.position
	ic.size = r.size
	ic.pivot_offset = r.size / 2.0
	pai.add_child(ic)
	return ic

## Efeito da caneta: bônus em azul, penalidade em vermelho, números em Caveat.
func _efeito_rico(pai: Control, texto: String, r: Rect2, tam: int, centro: bool) -> void:
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.scroll_active = false
	rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rt.add_theme_font_override("normal_font", FONTE)
	rt.add_theme_font_size_override("normal_font_size", tam)
	rt.add_theme_constant_override("line_separation", -4)
	rt.position = r.position
	rt.size = r.size
	var linhas: Array = []
	var re := RegEx.new()
	re.compile("[+\\-−]?\\d+%?")
	for linha in texto.split("\n"):
		var l: String = linha.strip_edges()
		var cor := AZUL
		if l.begins_with("-") or l.begins_with("−"):
			cor = VERMELHO
		elif not l.begins_with("+"):
			cor = Color(AZUL_ESCURO, 0.8)
		var s := ""
		var pos := 0
		for m in re.search_all(l):
			s += l.substr(pos, m.get_start() - pos)
			s += "[font=%s][font_size=%d]%s[/font_size][/font]" % [NUM.resource_path, tam + 8, m.get_string()]
			pos = m.get_end()
		s += l.substr(pos)
		linhas.append("[color=#%s]%s[/color]" % [cor.to_html(false), s])
	var corpo := "\n".join(linhas)
	rt.text = "[center]%s[/center]" % corpo if centro else corpo
	pai.add_child(rt)
