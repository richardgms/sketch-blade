extends "res://TelaEstojo.gd"
## Loja no estilo caderno (versão A aprovada em 30/10/2026): abas
## CANETAS | PACOTES, fichas de etiqueta em lista (irmã do Estojo).
## Fica dentro do Hub (aba Loja), como o Estojo: papel, cabeçalho e barra de
## abas são do Hub. Reaproveita as peças do Estojo (card da roleta, etiqueta,
## botões riscados por estado).
## O Hub chama mostrar(montar_dados(save) + pacotes + aba) e compra nos
## sinais; "comprado" = id pulsa a ficha e trava os botões um instante.
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

var _ids: Array = [] # id da caneta de cada ficha (para pulsar/tremer)

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

static func icone_pacote(chave: String) -> String:
	for p in PACOTES:
		if p["chave"] == chave:
			return p["icone"]
	return ""

func mostrar(d: Dictionary) -> void:
	_dados = d
	for f in _bloco.get_children():
		_bloco.remove_child(f)
		f.queue_free()
	_btns.clear()
	_fichas_atuais.clear()
	_ids.clear()
	_abas(d.get("aba", "canetas"))
	if d.get("aba", "canetas") == "pacotes":
		_pacotes_fichas(d["pacotes"])
		return
	_canetas_fichas(d["canetas"])
	var comprado: String = d.get("comprado", "")
	if comprado in _ids:
		_animar_compra(_fichas_atuais[_ids.find(comprado)])

## Sem saldo: a ficha treme (o Hub oferece o pacote em seguida).
func negar(id: String) -> void:
	var k := _ids.find(id)
	if k < 0 or not is_instance_valid(_fichas_atuais[k]):
		return
	var c: Control = _fichas_atuais[k]
	var x0: float = c.position.x
	var t := create_tween()
	t.tween_property(c, "position:x", x0 - 15, 0.05)
	t.tween_property(c, "position:x", x0 + 15, 0.05)
	t.tween_property(c, "position:x", x0, 0.05)

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
# Fichas
# ------------------------------------------------------------
func _canetas_fichas(canetas: Array) -> void:
	var alt := 216.0
	var y := 470.0
	for k in range(canetas.size()):
		var it: Dictionary = canetas[k]
		var c := _carta(Rect2(50, y, 980, alt))
		_fichas_atuais.append(c)
		_ids.append(it["id"])
		_etiqueta(c)
		_icone_inclinado(c, it["icone"], Rect2(92, 28, 150, 150))
		_txt(c, it["nome"], 50, AZUL_ESCURO, 12, 76, FONTE, 262, 690, HORIZONTAL_ALIGNMENT_LEFT)
		_efeito_rico(c, it["efeito"], Rect2(262, 78, 430, 110), 40)
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
# Peças
# ------------------------------------------------------------
## Ação da caneta pelo estado: EM USO (verde, sem toque), EQUIPAR (contorno),
## COMPRAR (azul riscado com a moeda em branco) ou falta (riscado clarinho).
func _acao_caneta(pai: Control, it: Dictionary, r: Rect2) -> void:
	var id: String = it["id"]
	match it["estado"]:
		"uso":
			var selo := Panel.new()
			selo.add_theme_stylebox_override("panel", _estilo_riscado(BOTAO_MAXIMO))
			selo.position = r.position
			selo.size = r.size
			selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pai.add_child(selo)
			var l := _txt(selo, "EM USO ✓", 40, Color.WHITE, 4, r.size.y, FONTE, 0, r.size.x)
			l.add_theme_color_override("font_outline_color", Color(VERDE, 0.6))
			l.add_theme_constant_override("outline_size", 6)
		"equipar":
			var b := _botao_contorno(r)
			b.reparent(pai, false)
			b.position = r.position
			var l := _lbl("EQUIPAR", FONTE, 46, AZUL)
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
			var cont := VBoxContainer.new()
			cont.alignment = BoxContainer.ALIGNMENT_CENTER
			cont.add_theme_constant_override("separation", -8)
			cont.set_anchors_preset(Control.PRESET_FULL_RECT)
			cont.offset_top = 4.0
			cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(cont)
			if pode:
				var l := _lbl("COMPRAR", FONTE, 40, Color.WHITE)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cont.add_child(l)
			cont.add_child(_preco_moeda(it, pode))
			if not pode:
				var f := _lbl("faltam %s" % _milhar(int(it["falta"])), NUM, 42, AZUL_ESCURO)
				f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cont.add_child(f)
			b.pressed.connect(func(): caneta.emit(id))
			_btns.append(b)

## Moeda + custo; no azul a moeda vai em caneta branca.
func _preco_moeda(it: Dictionary, pode: bool) -> HBoxContainer:
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
	var ic := _icone(caminho, 48)
	if not pode:
		ic.modulate = Color(1, 1, 1, 0.5)
	h.add_child(ic)
	h.add_child(_lbl(_milhar(int(it["custo"])), NUM, 52,
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
	if b.disabled:
		b.modulate = Color(1, 1, 1, 0.5)
	var chave: String = p["chave"]
	b.pressed.connect(func(): pacote.emit(chave))
	_btns.append(b)

func _nota(y: float) -> void:
	var n := _txt(_bloco, "Pagamento pela Google Play.\nOs itens entram na hora.", 40, Color(AZUL_ESCURO, 0.7), y, y + 110)
	n.add_theme_constant_override("line_spacing", -6)

## Desenho da caneta (os SVGs vêm deitados): um pouco inclinado, como na mesa.
func _icone_inclinado(pai: Control, caminho: String, r: Rect2) -> TextureRect:
	var ic := _icone(caminho, r.size.x)
	ic.position = r.position
	ic.size = r.size
	ic.pivot_offset = r.size / 2.0
	pai.add_child(ic)
	return ic

## Efeito da caneta: bônus em azul, penalidade em vermelho, números em Caveat.
func _efeito_rico(pai: Control, texto: String, r: Rect2, tam: int) -> void:
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
	rt.text = "\n".join(linhas)
	pai.add_child(rt)
