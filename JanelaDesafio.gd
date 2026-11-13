extends "res://JanelaAtualizacao.gd"
## Desafio do dia ("Prova surpresa", aprovado em 13/11/2026, opção A): prova
## escolar presa na prancheta, montada com peças separadas (assets/ui/desafio/).
## As pautas são desenhadas aqui; cada linha de texto fica entre duas pautas.
## FAZER A PROVA emite `atualizar` (o Hub abre a partida do desafio).
## d: nome, data, regra, desc [2 linhas], carimbos (0–2), vencido (bool).
## Plano: docs/plano-desafio.md
const P := "res://assets/ui/desafio/"
const PAUTA := 76.0      # distância entre pautas
const Y_PAUTAS := 190.0  # primeira pauta (coordenada da folha)
const VERMELHO_PROF := Color("d32f2f")

var _folha: Control
## Fonte das linhas da prova (teste de legibilidade: d["fonte_corpo"] = caminho .ttf).
var _corpo: Font = FONTE

func _img(pai: Control, nome: String, r: Rect2, giro := 0.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(P + nome)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = r.position; t.size = r.size
	t.pivot_offset = r.size / 2.0; t.rotation_degrees = giro
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(t)
	return t

## Texto na linha n (entre a pauta n e a n+1).
func _na_linha(n: int, t: String, tam: int, cor: Color, x0 := 90.0, x1 := 770.0,
		alinh := HORIZONTAL_ALIGNMENT_LEFT, fonte: Font = null) -> void:
	var y := Y_PAUTAS + n * PAUTA
	_txt(_folha, t, tam, cor, y + 4, y + PAUTA - 2, fonte if fonte else _corpo, x0, x1, alinh)

func _folha_nova(d: Dictionary) -> void:
	if d.has("fonte_corpo"):
		var f := FontFile.new()
		f.load_dynamic_font(d["fonte_corpo"])
		_corpo = f
	var r: Rect2
	_img(_bloco, "prancheta.png", Rect2(50, 96, 980, 1728))
	r = Rect2(120, 350, 840, 1346)
	_folha = Control.new()
	_folha.position = r.position; _folha.size = r.size
	_bloco.add_child(_folha)
	_img(_folha, "papel.png", Rect2(Vector2.ZERO, r.size))
	var larg := r.size.x
	var n_pautas := 11
	var pautas := Control.new()
	pautas.draw.connect(func():
		for i in n_pautas + 1:
			var y := Y_PAUTAS + i * PAUTA
			pautas.draw_line(Vector2(66, y), Vector2(larg - 24, y), Color("8fb0e8", 0.75), 2.0))
	_folha.add_child(pautas)
	# Cabeçalho (acima das pautas)
	_txt(_folha, "PROVA SURPRESA", 52, AZUL_ESCURO, 70, 160, FONTE, 100, larg - 215, HORIZONTAL_ALIGNMENT_LEFT)
	_img(_folha, "carimbo_hoje.png", Rect2(larg - 215, 46, 185, 99), 8)
	# Linhas (uma por pauta, sem linhas vazias)
	var tam: int = d.get("tam_corpo", 46)
	_na_linha(0, "Nome: " + d["nome"], tam, AZUL_ESCURO, 90.0, larg - 280)
	_na_linha(1, "Data: " + d["data"], tam, AZUL_ESCURO)
	_na_linha(0, "Nota:", tam, AZUL_ESCURO, larg - 290, larg - 160, HORIZONTAL_ALIGNMENT_RIGHT)
	_img(_folha, "check_vermelho.png" if d.get("vencido", false) else "nota_interrogacao.png",
		Rect2(larg - 160, Y_PAUTAS - 10, 140, 140), -6)
	_na_linha(2, "Questão do dia:", tam, AZUL)
	_na_linha(3, d["regra"], 62, AZUL_ESCURO)
	_na_linha(4, d["desc"][0], tam, AZUL_ESCURO)
	_na_linha(5, d["desc"][1], tam, AZUL_ESCURO)
	_na_linha(6, "Só o chefe." if d.get("so_chefe", false) else "3 páginas + o chefe.", tam, AZUL)
	_na_linha(7, "Visto do professor:", tam, AZUL)
	var marca := "carimbo_visto.png"
	for i in 3:
		var cx := 96.0 + i * 160.0
		var cy := Y_PAUTAS + 8 * PAUTA + 4
		_img(_folha, "slot_carimbo.png", Rect2(cx, cy, 140, 140))
		if i < d["carimbos"]:
			_img(_folha, marca, Rect2(cx - 4, cy - 4, 148, 148), [-10, 6, -4][i])
	_na_linha(8, "%d vistos =" % GameData.DESAFIO_VISTOS_BONUS, tam, Color("2e7d32"), 580, larg - 20)
	_na_linha(9, "+%d clipes" % GameData.DESAFIO_CLIPES_BONUS, tam, Color("2e7d32"), 580, larg - 20)
	if d.get("vencido", false):
		_na_linha(10, "Prêmio de hoje recebido!", tam, Color("2e7d32"))
	else:
		_na_linha(10, "Prêmio: %d tinta + %d clipes" % [GameData.DESAFIO_PREMIO["tinta"], GameData.DESAFIO_PREMIO["clipes"]], tam, Color("2e7d32"))
	var yb := Y_PAUTAS + (n_pautas + 0.4) * PAUTA
	var bx := (larg - 620) / 2.0
	_botao_atualizar(Rect2(r.position.x + bx, r.position.y + yb, 620, 130))
	_btns[0].text = "REFAZER A PROVA" if d.get("vencido", false) else "FAZER A PROVA"
	_btn_fechar = _botao_fechar("Agora não", Rect2(r.position.x + bx + 70, r.position.y + yb + 142, 480, 92))
