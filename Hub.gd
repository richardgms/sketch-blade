extends Node2D

const FONTE_NUMEROS = preload("res://assets/fonts/Caveat/static/Caveat-Bold.ttf")
const CAMINHO_FONTE_NUMEROS = "res://assets/fonts/Caveat/static/Caveat-Bold.ttf"

@onready var saldo_tinta_label: Label = $HUD/Header/SaldoTintaLabel
@onready var saldo_clipes_label: Label = $HUD/Header/SaldoClipesLabel
@onready var nivel_label: Label = $HUD/Header/NivelLabel
@onready var xp_bar: ProgressBar = $HUD/Header/XPBar

@onready var botao_jogar: Button = $HUD/TelaLutar/BotaoJogar

# Navegação de Capítulo
@onready var titulo_capitulo: Label = $HUD/TelaLutar/TituloCapitulo
@onready var botao_cap_esquerda: Button = $HUD/TelaLutar/BotaoCapituloEsquerda
@onready var botao_cap_direita: Button = $HUD/TelaLutar/BotaoCapituloDireita
@onready var nome_capitulo: Label = $HUD/TelaLutar/NomeCapitulo
@onready var boss_icon: TextureRect = $HUD/TelaLutar/BossIcon

# Contêineres de aba
@onready var tela_lutar: Control = $HUD/TelaLutar
@onready var tela_estojo: Control = $HUD/TelaEstojo
@onready var tela_loja: Control = $HUD/TelaLoja
@onready var desenho_hub: Node2D = $DesenhoHub

# Botões da Barra Inferior
@onready var botao_aba_estojo: Button = $HUD/BottomNavigation/BotaoAbaEstojo
@onready var botao_aba_lutar: Button = $HUD/BottomNavigation/BotaoAbaLutar
@onready var botao_aba_loja: Button = $HUD/BottomNavigation/BotaoAbaLoja

# Contêineres de upgrade (dentro de tela_estojo)
@onready var container_dano: Control = $HUD/TelaEstojo/Estojo/UpgradeDano
@onready var container_hp: Control = $HUD/TelaEstojo/Estojo/UpgradeHP
@onready var container_cadencia: Control = $HUD/TelaEstojo/Estojo/UpgradeCadencia

# Nós do Popup de Compra (IAP Sandbox)
@onready var popup_compra: Control = $HUD/PopupCompra
@onready var popup_titulo: Label = $HUD/PopupCompra/FundoPopup/TituloPopup
@onready var popup_descricao: Label = $HUD/PopupCompra/FundoPopup/TextoDescricao
@onready var botao_comprar_tinta: Button = $HUD/Header/BotaoComprarTinta
@onready var botao_comprar_clipes: Button = $HUD/Header/BotaoComprarClipes
@onready var botao_confirmar_compra: Button = $HUD/PopupCompra/FundoPopup/BotaoConfirmar
@onready var botao_cancelar_compra: Button = $HUD/PopupCompra/FundoPopup/BotaoCancelar

# Referência ao dicionário central do SaveManager (autoload)
var dados_save: Dictionary

var nomes_capitulos: Array = [
	"",
	"Folha de Rascunho",
	"Aviãozinho",
	"Borrão de Tinta",
	"Caderno Quadriculado",
	"Compasso",
	"Mapa do Tesouro",
	"Dobradura",
	"Página Perdida",
	"Pena de Tinta",
	"O Estojo Final"
]

var tinta_visual: float = 0.0
var clipes_visual: float = 0.0
var aba_ativa: String = "lutar"
var lbl_xp_texto: Label
var titulo_capitulo_rich: RichTextLabel
var decoracao_nivel: TextureRect
var xp_bar_tex: TextureProgressBar
var _tween_pop_nivel: Tween
var container_loja: Control
var sub_aba_loja: String = "canetas" # "canetas" ou "pacotes"
var sublinhado_loja: TextureRect
var botoes_sub_aba_loja: Dictionary = {} # "canetas"/"pacotes" -> Button
var oferta_mostrada: Dictionary = {} # moeda -> true (oferta de pacote 1x por visita ao Hub)
var item_sendo_comprado: String = "clipes" # "clipes" ou "tinta"

# Áudio procedural
var audio_click_sucesso: AudioStreamWAV
var audio_click_erro: AudioStreamWAV

func _adicionar_sublinhado(parent: Control, y_top: float, meio_largura: float) -> TextureRect:
	var tr = TextureRect.new()
	tr.texture = load("res://assets/sublinhado.svg")
	tr.layout_mode = 1
	tr.anchor_left = 0.5
	tr.anchor_right = 0.5
	tr.anchor_top = 0.0
	tr.anchor_bottom = 0.0
	tr.offset_left = -meio_largura
	tr.offset_right = meio_largura
	tr.offset_top = y_top
	tr.offset_bottom = y_top + 50.0
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = Color("002867")
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr

func _ready() -> void:
	$HUD.visibility_changed.connect(func(): $DesenhoHub.visible = $HUD.visible)
	dados_save = SaveManager.dados
	tinta_visual = dados_save["tinta"]
	clipes_visual = dados_save["clipes_ouro"]

	# Se houve uma run interrompida (app fechado no meio da partida), oferece
	# retomar. Deferido para rodar após toda a UI do Hub estar montada.
	if SaveManager.tem_run_ativa():
		call_deferred("_mostrar_prompt_retomar_run")

	# Sublinhados decorativos abaixo de cada título de página
	_adicionar_sublinhado(tela_lutar,  448.0, 220.0)
	_adicionar_sublinhado(tela_estojo, 448.0, 300.0)
	sublinhado_loja = _adicionar_sublinhado(tela_loja, 448.0, 200.0)

	# Conteúdo do Estojo desce para abrir espaço após o sublinhado
	var shift := 80.0
	for c in [container_dano, container_hp, container_cadencia]:
		c.offset_top  += shift
		c.offset_bottom += shift

	_montar_tela_capitulo()

	# Ícones inline no Header (ao lado dos labels de saldo, sem tocar no .tscn)
	_adicionar_icone_header("res://assets/ink.svg",  saldo_tinta_label)
	_adicionar_icone_header("res://assets/clip.svg", saldo_clipes_label)

	# Números do header usam Caveat (todos os números do jogo seguem esta fonte)
	nivel_label.add_theme_font_override("font", FONTE_NUMEROS)
	saldo_tinta_label.add_theme_font_override("font", FONTE_NUMEROS)
	saldo_clipes_label.add_theme_font_override("font", FONTE_NUMEROS)

	# "Capítulo N" mistura fonte de texto e de número — Label não suporta isso,
	# então o Label do .tscn fica oculto e um RichTextLabel espelha o rect dele.
	titulo_capitulo.visible = false
	titulo_capitulo_rich = RichTextLabel.new()
	titulo_capitulo_rich.name = "TituloCapituloRich"
	titulo_capitulo_rich.bbcode_enabled = true
	titulo_capitulo_rich.scroll_active = false
	titulo_capitulo_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo_capitulo_rich.add_theme_font_override("normal_font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	titulo_capitulo_rich.add_theme_font_size_override("normal_font_size", 72)
	titulo_capitulo_rich.add_theme_color_override("default_color", Color(0.1, 0.1, 0.15))
	titulo_capitulo_rich.anchor_left = titulo_capitulo.anchor_left
	titulo_capitulo_rich.anchor_right = titulo_capitulo.anchor_right
	titulo_capitulo_rich.offset_left = titulo_capitulo.offset_left
	titulo_capitulo_rich.offset_right = titulo_capitulo.offset_right
	# RichTextLabel alinha no topo (Label centrava na caixa de 100px) — o
	# offset_top compensa para o texto ficar na mesma altura visual.
	titulo_capitulo_rich.offset_top = titulo_capitulo.offset_top + 8.0
	titulo_capitulo_rich.offset_bottom = titulo_capitulo.offset_bottom
	titulo_capitulo.get_parent().add_child(titulo_capitulo_rich)

	# Decoração SVG: círculo Lv. X + moldura da barra de XP (atrás do NivelLabel e XPBar).
	# O retângulo precisa manter a proporção do SVG (606×260), senão o KEEP_ASPECT
	# desloca o desenho e o círculo/moldura descolam do label e da barra.
	# Com o rect 60..340 × 60..180: círculo centrado em (106, 119) e moldura
	# da barra em x 161..335, y 102..131 — NivelLabel e XPBar seguem esses pontos.
	decoracao_nivel = TextureRect.new()
	decoracao_nivel.name = "DecoracaoNivel"
	decoracao_nivel.texture = load("res://assets/level-and-progressbar.svg")
	decoracao_nivel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	decoracao_nivel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Rect ampliado ~12% para legibilidade mobile (proporção 2.333 mantida);
	# círculo agora centra em (112, 121) e a moldura da barra em x 174..369,
	# y 102..135 — NivelLabel e XPBar no .tscn seguem esses novos pontos.
	decoracao_nivel.offset_left = 60.0
	decoracao_nivel.offset_top = 55.0
	decoracao_nivel.offset_right = 375.0
	decoracao_nivel.offset_bottom = 190.0
	decoracao_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD/Header.add_child(decoracao_nivel)
	$HUD/Header.move_child(decoracao_nivel, 0)

	# Esconde o ProgressBar original e substitui por TextureProgressBar com SVG de fill
	xp_bar.visible = false
	xp_bar_tex = TextureProgressBar.new()
	xp_bar_tex.name = "XPBarTex"
	xp_bar_tex.texture_progress = load("res://assets/texture_progress.svg")
	# A textura do rabisco é branca com alpha de densidade de tinta (máscara
	# tintável — as missões usam o mesmo arquivo em azul/verde/cinza), então
	# a cor final vem toda do tint. Este azul é o tom original do rabisco.
	xp_bar_tex.tint_progress = Color("0047ab")
	xp_bar_tex.fill_mode = 0 # Esquerda para direita
	# Sem nine_patch_stretch a textura desenha no tamanho nativo (400×48)
	# e vaza da moldura; com ele, o rabisco estica para caber no rect da barra.
	xp_bar_tex.nine_patch_stretch = true
	xp_bar_tex.offset_left = xp_bar.offset_left
	xp_bar_tex.offset_top = xp_bar.offset_top
	xp_bar_tex.offset_right = xp_bar.offset_right
	xp_bar_tex.offset_bottom = xp_bar.offset_bottom
	xp_bar_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD/Header.add_child(xp_bar_tex)

	# Label "XP atual / XP necessário XP" abaixo da barra de progresso
	lbl_xp_texto = Label.new()
	lbl_xp_texto.name = "XPTextoLabel"
	lbl_xp_texto.add_theme_font_override("font", FONTE_NUMEROS)
	lbl_xp_texto.add_theme_font_size_override("font_size", 32)
	lbl_xp_texto.add_theme_color_override("font_color", Color("1a1a2e", 0.7))
	lbl_xp_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl_xp_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Alinhado à moldura desenhada do SVG (x=174), não ao início da tinta
	lbl_xp_texto.offset_left = 174.0
	lbl_xp_texto.offset_right = xp_bar.offset_right
	# +10 deixa o texto abaixo do traço inferior da moldura desenhada (y ≈ 131)
	lbl_xp_texto.offset_top = xp_bar.offset_bottom + 10
	lbl_xp_texto.offset_bottom = xp_bar.offset_bottom + 36
	$HUD/Header.add_child(lbl_xp_texto)

	_atualizar_ui_upgrades()
	_iniciar_ui_nivel()
	_atualizar_ui_capitulo()
	
	# Conecta botões de upgrades
	container_dano.get_node("BotaoUpar").pressed.connect(func(): _on_upar_pressed("nivel_dano", container_dano))
	container_hp.get_node("BotaoUpar").pressed.connect(func(): _on_upar_pressed("nivel_hp", container_hp))
	container_cadencia.get_node("BotaoUpar").pressed.connect(func(): _on_upar_pressed("nivel_cadencia", container_cadencia))
	
	# Conecta botão de Jogar
	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	
	# Conecta botões da barra inferior
	botao_aba_estojo.pressed.connect(func(): _alterar_aba("estojo"))
	botao_aba_lutar.pressed.connect(func(): _alterar_aba("lutar"))
	botao_aba_loja.pressed.connect(func(): _alterar_aba("loja"))
	
	# Conecta botões de capítulos
	botao_cap_esquerda.pressed.connect(func(): _mudar_capitulo(-1))
	botao_cap_direita.pressed.connect(func(): _mudar_capitulo(1))
	
	# Conecta botões de IAP/Lojinha
	# [+] do topo levam para a aba Pacotes da Loja
	botao_comprar_tinta.pressed.connect(_abrir_pacotes)
	botao_comprar_clipes.pressed.connect(_abrir_pacotes)
	botao_confirmar_compra.pressed.connect(_on_confirmar_compra_pressed)
	botao_cancelar_compra.pressed.connect(_on_cancelar_compra_pressed)
	_criar_fundo_popup_compra()
	BillingManager.compra_concluida.connect(_on_compra_concluida)
	BillingManager.compra_falhou.connect(_on_compra_falhou)
	BillingManager.precos_atualizados.connect(func():
		if popup_compra.visible:
			_atualizar_texto_popup_compra()
		if tela_loja.visible and sub_aba_loja == "pacotes":
			_atualizar_loja()
	)

	# Sons procedurais
	audio_click_sucesso = _gerar_som_procedural(880.0, 0.08, "sin")
	audio_click_erro = _gerar_som_procedural(150.0, 0.25, "square")
	
	_criar_loja_canetas()
	_atualizar_texto_saldo()
	_alterar_aba("lutar")

	# Retenção diária: renova missões e mostra recompensa do dia
	_verificar_missoes_diarias()
	_criar_botao_missoes()
	_criar_botao_config()
	_verificar_recompensa_diaria()

func _process(delta: float) -> void:
	# Efeito de contagem animada no saldo de tinta
	if abs(tinta_visual - dados_save["tinta"]) > 0.1:
		var diferenca = abs(tinta_visual - dados_save["tinta"])
		var step = max(20.0, diferenca * 6.0)
		tinta_visual = move_toward(tinta_visual, dados_save["tinta"], step * delta)
		_atualizar_texto_saldo()
		
	# Efeito de contagem animada no saldo de clipes
	if abs(clipes_visual - dados_save["clipes_ouro"]) > 0.1:
		var diferenca = abs(clipes_visual - dados_save["clipes_ouro"])
		var step = max(5.0, diferenca * 6.0)
		clipes_visual = move_toward(clipes_visual, dados_save["clipes_ouro"], step * delta)
		_atualizar_texto_saldo()

## Encolhe o label 40px pela direita e insere um TextureRect de 36×36
## no espaço liberado, alinhado verticalmente ao centro do label.
func _adicionar_icone_header(tex_path: String, label: Label, delta_y: float = 0.0) -> void:
	var icon_size: float = 40.0
	var gap: float = 4.0
	var right_original: float = label.offset_right
	label.offset_right = right_original - icon_size - gap

	var tr = TextureRect.new()
	tr.texture = load(tex_path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(icon_size, icon_size)
	tr.position = Vector2(
		right_original - icon_size,
		label.offset_top + (label.offset_bottom - label.offset_top - icon_size) / 2.0 + delta_y
	)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.get_parent().add_child(tr)

## Cria um TextureRect de 40×40 para usar inline na lista da loja.
func _icone_card(tex: Texture2D, pos: Vector2) -> TextureRect:
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = pos
	tr.size = Vector2(40, 40)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func _atualizar_texto_saldo() -> void:
	saldo_tinta_label.text = str(int(tinta_visual))
	saldo_clipes_label.text = str(int(clipes_visual))

## Ponto de entrada da UI de nível/XP, chamado uma vez em _ready(). Se o
## jogador acabou de voltar de uma run (snapshot pendente em SaveManager,
## gravado por Main.gd antes de aplicar os ganhos), anima a barra subindo do
## valor antigo até o novo. Sem snapshot (primeiro carregamento do Hub, ou
## Hub reaberto sem jogar), desenha o estado atual direto, sem animação.
func _iniciar_ui_nivel() -> void:
	var snapshot: Dictionary = SaveManager.xp_snapshot_pendente
	SaveManager.xp_snapshot_pendente = {}

	var nivel_final: int = dados_save["nivel_conta"]
	var xp_final: int = dados_save["xp_conta"]
	var nivel_anterior: int = int(snapshot.get("nivel", nivel_final))
	var xp_anterior: int = int(snapshot.get("xp", xp_final))
	var xp_ganho: int = int(snapshot.get("xp_ganho", 0))

	if snapshot.is_empty() or (nivel_anterior == nivel_final and xp_anterior == xp_final):
		_atualizar_ui_nivel()
		return

	# Mostra o estado "antes" já parado na tela por 1s antes de animar — dá
	# tempo do jogador olhar pro Hub e perceber a barra subindo, em vez de
	# começar a encher no exato frame em que a cena termina de carregar.
	_definir_xp_visual(nivel_anterior, xp_anterior, get_xp_necessario_para_nivel(nivel_anterior))

	var atraso := create_tween()
	atraso.tween_interval(1.0)
	atraso.tween_callback(func():
		_mostrar_popup_xp_ganho(xp_ganho)
		_animar_xp_ganho(nivel_anterior, xp_anterior, nivel_final, xp_final)
	)

## Desenha o estado atual do save direto na barra/label, sem animação.
func _atualizar_ui_nivel() -> void:
	var lvl: int = dados_save["nivel_conta"]
	var xp: int = dados_save["xp_conta"]
	_definir_xp_visual(lvl, xp, get_xp_necessario_para_nivel(lvl))

## "Renderer" comum da barra de XP: aplica um estado (nível, xp, xp_req) na
## barra, no fill de textura e no texto. Usado tanto para o estado estático
## quanto como callback de cada frame das animações de tween abaixo.
func _definir_xp_visual(nivel: int, xp: float, xp_req: int) -> void:
	nivel_label.text = str(nivel)
	xp_bar.max_value = xp_req
	xp_bar.value = xp
	if xp_bar_tex:
		xp_bar_tex.max_value = xp_req
		xp_bar_tex.value = xp
	if lbl_xp_texto:
		lbl_xp_texto.text = "%d / %d XP" % [int(round(xp)), xp_req]

## Anima a barra de XP subindo do estado anterior (capturado antes da run)
## até o estado final já salvo. Cada nível completo no caminho enche a barra,
## "estoura" (pop dourado + som no Lv., ver _celebrar_level_up) e reinicia
## do zero para o próximo — o clássico preenchimento de barra de RPG, na
## linguagem manuscrita do jogo. Suporta ganhar vários níveis numa run só.
func _animar_xp_ganho(nivel_anterior: int, xp_anterior: int, nivel_final: int, xp_final: int) -> void:
	var tween := create_tween()
	var nivel_corrente: int = nivel_anterior
	var xp_corrente: int = xp_anterior

	while nivel_corrente < nivel_final:
		var xp_req: int = get_xp_necessario_para_nivel(nivel_corrente)
		var nivel_capturado: int = nivel_corrente
		tween.tween_method(
			func(v: float): _definir_xp_visual(nivel_capturado, v, xp_req),
			float(xp_corrente), float(xp_req), _duracao_xp(xp_req - xp_corrente, xp_req)
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.1)

		var proximo_nivel: int = nivel_corrente + 1
		tween.tween_callback(func():
			_celebrar_level_up(proximo_nivel)
			# Reinicia a barra vazia no novo nível já aqui — garante o reset
			# visual mesmo quando este é o último nível (sem segmento final
			# depois dele, ver bloco abaixo).
			_definir_xp_visual(proximo_nivel, 0.0, get_xp_necessario_para_nivel(proximo_nivel))
		)

		nivel_corrente = proximo_nivel
		xp_corrente = 0

	var xp_req_final: int = get_xp_necessario_para_nivel(nivel_final)
	if xp_corrente != xp_final:
		tween.tween_method(
			func(v: float): _definir_xp_visual(nivel_final, v, xp_req_final),
			float(xp_corrente), float(xp_final), _duracao_xp(xp_final - xp_corrente, xp_req_final)
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Duração proporcional ao quanto da barra será preenchido neste trecho —
## ganhos pequenos animam rápido, ganhos grandes levam um pouco mais, mas
## sempre dentro de limites que mantêm o ritmo (nunca instantâneo, nunca
## arrastado a ponto de segurar o jogador na tela).
func _duracao_xp(delta: float, xp_req: int) -> float:
	if xp_req <= 0:
		return 0.6
	var fracao: float = clamp(delta / float(xp_req), 0.0, 1.0)
	return clamp(1.6 * fracao, 0.6, 1.6)

## Efeito de "estouro" de nível: som de sucesso + pop dourado no número do
## nível — mesma cor (#f39c12) usada no selo "MÁX" do Estojo, reaproveitando
## a linguagem de "conquista" do jogo em vez de inventar uma nova.
func _celebrar_level_up(novo_nivel: int) -> void:
	_tocar_som(audio_click_sucesso)
	nivel_label.pivot_offset = nivel_label.size / 2.0
	nivel_label.scale = Vector2.ONE
	nivel_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.15, 1))

	if _tween_pop_nivel and _tween_pop_nivel.is_valid():
		_tween_pop_nivel.kill()

	var cor_normal := Color(0.1, 0.1, 0.15, 1)
	var cor_celebracao := Color("f39c12")

	_tween_pop_nivel = create_tween()
	_tween_pop_nivel.set_parallel(true)
	_tween_pop_nivel.tween_property(nivel_label, "theme_override_colors/font_color", cor_celebracao, 0.08)
	_tween_pop_nivel.tween_property(nivel_label, "scale", Vector2(1.22, 1.22), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween_pop_nivel.set_parallel(false)
	_tween_pop_nivel.tween_property(nivel_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween_pop_nivel.parallel().tween_property(nivel_label, "theme_override_colors/font_color", cor_normal, 0.2)

## Toast manuscrito "+N XP" que sobe e desaparece ao lado da barra — dá ao
## jogador um número legível do ganho total da run, complementando o
## preenchimento da barra (que pode passar despercebido num relance rápido
## pro Estojo). Mesmo verde "antes → depois" usado nos upgrades do Estojo.
func _mostrar_popup_xp_ganho(xp_ganho: int) -> void:
	if xp_ganho <= 0:
		return

	var lbl := Label.new()
	lbl.text = "+%d XP" % xp_ganho
	lbl.add_theme_font_override("font", FONTE_NUMEROS)
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color("2f5d3a"))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.rotation_degrees = -3.0 # leve inclinação manuscrita, como as anotações do jogo
	lbl.position = Vector2(xp_bar.offset_left, xp_bar.offset_top - 34.0)
	lbl.size = Vector2(xp_bar.offset_right - xp_bar.offset_left, 30.0)
	lbl.pivot_offset = lbl.size / 2.0
	$HUD/Header.add_child(lbl)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 24.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(lbl.queue_free)

func get_xp_necessario_para_nivel(nivel: int) -> int:
	if nivel == 1:
		return 200
	elif nivel == 2:
		return 500
	elif nivel == 3:
		return 1200
	elif nivel == 4:
		return 2500
	else:
		return 2500 + (nivel - 4) * 1500

func _atualizar_ui_capitulo() -> void:
	var cap_sel = dados_save["capitulo_selecionado"]
	var cap_desb = dados_save["capitulo_desbloqueado"]
	
	titulo_capitulo.text = "Capítulo " + str(cap_sel)
	if titulo_capitulo_rich:
		titulo_capitulo_rich.text = "[center]" + _bbcode_numeros(titulo_capitulo.text) + "[/center]"
	
	if cap_sel >= 1 and cap_sel < nomes_capitulos.size():
		nome_capitulo.text = nomes_capitulos[cap_sel]
	
	# Carrega dinamicamente a imagem do capítulo.
	# IMPORTANTE: usar ResourceLoader.exists (não FileAccess.file_exists): num
	# build exportado os PNG viram .ctex empacotados e o .png cru não existe no
	# res://, então file_exists dava sempre false → todo capítulo caía no
	# fallback e mostrava a arte do capítulo 1 no celular.
	var caminho_svg = "res://assets/images/stage" + str(cap_sel) + ".svg"
	var caminho_imagem = "res://assets/images/stage" + str(cap_sel) + ".png"
	if ResourceLoader.exists(caminho_svg):
		boss_icon.texture = load(caminho_svg)
	elif ResourceLoader.exists(caminho_imagem):
		boss_icon.texture = load(caminho_imagem)
	else:
		boss_icon.texture = load("res://assets/images/stage1.png") # Fallback
	
	# UX/UI: Habilita/desabilita setas de navegação
	botao_cap_esquerda.disabled = (cap_sel <= 1)
	botao_cap_esquerda.modulate.a = 0.3 if botao_cap_esquerda.disabled else 1.0
	
	botao_cap_direita.disabled = (cap_sel >= cap_desb or cap_sel >= 10)
	botao_cap_direita.modulate.a = 0.3 if botao_cap_direita.disabled else 1.0
	
	if trilha_cap:
		_atualizar_estado_capitulo(cap_sel)

	# Aplica visual do caderno dinamicamente no Hub
	if has_node("Paper"):
		$Paper.configurar_para_capitulo(cap_sel)

# ============================================================
# TELA DO CAPÍTULO (rascunho do amigo designer, 29/10/2026)
# ============================================================
const COR_AZUL_CANETA := Color("0047ab")
const COR_AZUL_ESCURO := Color("002867")
const COR_TEXTO := Color(0.1, 0.1, 0.15)
## Tamanho padrão dos textos azuis das telas do capítulo (aprovado 29/10)
const TAM_TEXTO_AZUL := 42
const TAM_TEXTO_AZUL_REGRA := 40

var lbl_frase_cap: Label
var lbl_recorde_cap: RichTextLabel
var lbl_regra_cap: RichTextLabel
var trilha_cap: Control
var recorde_trilha: int = 0 # páginas pintadas na trilha (0..8)
var chefe_trilha: Texture2D # mini desenho do chefe na última casa (capítulo vencido)
var selo_hub: Control
const FICHAS_CHEFE: Dictionary = preload("res://Boss.gd").FICHAS

## Reposiciona os nós do .tscn e cria os textos/trilha novos. Layout pensado
## em 1080x1920; o botão LUTAR segue ancorado ao rodapé real.
func _montar_tela_capitulo() -> void:
	var fonte_texto: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")

	# Setas sobem para os lados do título: o centro fica livre para a arte
	for b in [botao_cap_esquerda, botao_cap_direita]:
		b.anchor_top = 0.0
		b.anchor_bottom = 0.0
		b.offset_top = 335.0
		b.offset_bottom = 445.0
	botao_cap_esquerda.offset_left = 120.0
	botao_cap_esquerda.offset_right = 230.0
	botao_cap_direita.offset_left = -230.0
	botao_cap_direita.offset_right = -120.0

	# Nome do capítulo maior e escuro; "MODO NORMAL" entre dois traços verdes
	nome_capitulo.offset_top = 490.0
	nome_capitulo.offset_bottom = 585.0
	nome_capitulo.add_theme_font_size_override("font_size", 64)
	nome_capitulo.add_theme_color_override("font_color", COR_TEXTO)
	var dif: Label = $HUD/TelaLutar/DificuldadeLabel
	dif.offset_top = 598.0
	dif.offset_bottom = 648.0
	var tracos := Control.new()
	tracos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_posicionar_centro(tracos, 594.0, 656.0, 150.0)
	tracos.draw.connect(_desenhar_tracos_modo.bind(tracos))
	tela_lutar.add_child(tracos)

	# Bloco de baixo (frase, recorde, trilha, regra) colado no botão LUTAR:
	# ancorado ao rodapé real, como o botão. Valores pensados em 1920 de altura.
	lbl_frase_cap = Label.new()
	lbl_frase_cap.add_theme_font_override("font", fonte_texto)
	lbl_frase_cap.add_theme_font_size_override("font_size", 40)
	lbl_frase_cap.add_theme_color_override("font_color", COR_TEXTO)
	lbl_frase_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_posicionar_centro(lbl_frase_cap, 1166.0, 1224.0, 480.0)
	tela_lutar.add_child(lbl_frase_cap)
	_ancorar_rodape(lbl_frase_cap)

	lbl_recorde_cap = _rich_centro(fonte_texto, TAM_TEXTO_AZUL, COR_AZUL_CANETA, 1234.0, 1290.0)
	_ancorar_rodape(lbl_recorde_cap)
	trilha_cap = Control.new()
	trilha_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_posicionar_centro(trilha_cap, 1300.0, 1400.0, 440.0)
	trilha_cap.draw.connect(_desenhar_trilha.bind(trilha_cap))
	tela_lutar.add_child(trilha_cap)
	_ancorar_rodape(trilha_cap)
	lbl_regra_cap = _rich_centro(fonte_texto, TAM_TEXTO_AZUL_REGRA, COR_AZUL_CANETA, 1412.0, 1466.0)
	_ancorar_rodape(lbl_regra_cap)

	# Ilustração maior: ocupa do "MODO NORMAL" até a frase (cresce em tela alta)
	boss_icon.offset_left = -290.0
	boss_icon.offset_right = 290.0
	boss_icon.offset_top = 672.0
	boss_icon.anchor_bottom = 1.0
	boss_icon.offset_bottom = 1160.0 - 1920.0

	# Selo redondo da vitória, pequeno no canto inferior direito do desenho
	# (só no capítulo vencido). Desenhado em 360 px e reduzido por escala.
	selo_hub = Control.new()
	selo_hub.set_script(preload("res://SeloDerrotado.gd"))
	selo_hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selo_hub.size = Vector2(360, 360)
	selo_hub.pivot_offset = Vector2(360, 360)
	selo_hub.scale = Vector2(0.52, 0.52)
	selo_hub.rotation_degrees = -12.0
	selo_hub.anchor_left = 1.0
	selo_hub.anchor_right = 1.0
	selo_hub.anchor_top = 1.0
	selo_hub.anchor_bottom = 1.0
	selo_hub.offset_left = -360.0 + 60.0
	selo_hub.offset_right = 60.0
	selo_hub.offset_top = -360.0 - 34.0
	selo_hub.offset_bottom = -34.0
	selo_hub.visible = false
	boss_icon.add_child(selo_hub)

	# Botão principal cheio: azul com letra branca e moldura de caneta
	botao_jogar.flat = false
	botao_jogar.text = "LUTAR"
	botao_jogar.offset_left = -330.0
	botao_jogar.offset_right = 330.0
	botao_jogar.offset_top = -415.0
	botao_jogar.offset_bottom = -290.0
	botao_jogar.add_theme_font_size_override("font_size", 76)
	_estilizar_botao_cheio(botao_jogar)

## Botão principal cheio: fundo azul riscado à caneta (imagem) com letra
## branca. Sem a imagem, cai num azul liso com moldura desenhada.
const CAMINHO_BOTAO_RISCADO := "res://assets/ui/botao_riscado.png"

func _estilizar_botao_cheio(b: Button) -> void:
	b.flat = false
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(estado, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(COR_AZUL_ESCURO, 0.6))
	b.add_theme_constant_override("outline_size", 6)
	var tem_textura: bool = ResourceLoader.exists(CAMINHO_BOTAO_RISCADO)
	for estado in ["normal", "hover", "focus", "pressed"]:
		var sb: StyleBox
		if tem_textura:
			var st := StyleBoxTexture.new()
			st.texture = load(CAMINHO_BOTAO_RISCADO)
			# Cantos fixos, miolo estica: serve para botões de larguras diferentes
			st.texture_margin_left = 48.0
			st.texture_margin_right = 48.0
			st.texture_margin_top = 36.0
			st.texture_margin_bottom = 36.0
			# Margem do texto pequena: senão o botão cresce para caber a borda
			for lado in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				st.set_content_margin(lado, 6.0)
			if estado == "pressed":
				st.modulate_color = Color(0.8, 0.8, 0.85)
			sb = st
		else:
			var sf := StyleBoxFlat.new()
			sf.bg_color = COR_AZUL_CANETA.darkened(0.25) if estado == "pressed" else COR_AZUL_CANETA
			sf.set_corner_radius_all(14)
			sb = sf
		if estado == "focus":
			sb = StyleBoxEmpty.new()
		b.add_theme_stylebox_override(estado, sb)
	if not tem_textura:
		b.draw.connect(_desenhar_moldura_botao.bind(b))

## Prende o controle ao rodapé (anchor 1.0), mantendo a posição em 1920.
func _ancorar_rodape(c: Control) -> void:
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_top -= 1920.0
	c.offset_bottom -= 1920.0

## Dois traços verdes de caneta, acima e abaixo do "MODO NORMAL" (sem laterais).
func _desenhar_tracos_modo(c: Control) -> void:
	var cor := Color(0.2, 0.6, 0.2, 0.9)
	for y in [2.0, c.size.y - 2.0]:
		var pts: PackedVector2Array = []
		for i in range(17):
			var t: float = float(i) / 16.0
			pts.append(Vector2(t * c.size.x, y + sin(i * 1.7 + y) * 0.8))
		c.draw_polyline(pts, cor, 2.5, true)

func _posicionar_centro(c: Control, y0: float, y1: float, meia_largura: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.offset_left = -meia_largura
	c.offset_right = meia_largura
	c.offset_top = y0
	c.offset_bottom = y1

## Texto centralizado com números na Caveat (como o resto do jogo).
func _rich_centro(fonte: Font, tamanho: int, cor: Color, y0: float, y1: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = true
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", fonte)
	r.add_theme_font_size_override("normal_font_size", tamanho)
	r.add_theme_color_override("default_color", cor)
	_posicionar_centro(r, y0, y1, 480.0)
	tela_lutar.add_child(r)
	return r

func _texto_rich_centro(r: RichTextLabel, texto: String) -> void:
	r.visible = texto != ""
	r.text = "[center]" + _bbcode_numeros(texto) + "[/center]"

## Textos e trilha conforme o estado do capítulo selecionado.
## Vencido = capítulo < capitulo_desbloqueado (o mesmo critério do jogo).
func _atualizar_estado_capitulo(cap: int) -> void:
	var total: int = GameData.PAGINAS.size()
	var vencido: bool = cap < int(dados_save["capitulo_desbloqueado"])
	var recorde: int = SaveManager.get_melhor_pagina(cap)
	selo_hub.visible = vencido
	chefe_trilha = null
	lbl_recorde_cap.add_theme_color_override("default_color", COR_AZUL_CANETA)
	lbl_regra_cap.add_theme_color_override("default_color", COR_AZUL_CANETA)
	botao_jogar.text = "LUTAR"
	botao_jogar.add_theme_font_size_override("font_size", 76)
	if vencido:
		# Concluído: o chefe no lugar do objeto, selo no canto, trilha cheia
		var ficha: Dictionary = FICHAS_CHEFE.get(cap, FICHAS_CHEFE[1])
		boss_icon.texture = load(ficha["arte"])
		chefe_trilha = boss_icon.texture
		selo_hub.configurar(cap, ficha["nome"].substr(2))
		recorde_trilha = total
		# "o Compasso" → "O Compasso foi derrotado!"; "a Mancha" → "...derrotada!"
		var nome: String = ficha["nome"]
		lbl_frase_cap.text = "%s foi derrotad%s!" % [nome.left(1).to_upper() + nome.substr(1), nome.left(1)]
		lbl_recorde_cap.add_theme_color_override("default_color", COR_TEXTO)
		_texto_rich_centro(lbl_recorde_cap, "Capítulo concluído")
		_texto_rich_centro(lbl_regra_cap, "Nova tentativa começa na página 1.")
		botao_jogar.text = "JOGAR NOVAMENTE"
		botao_jogar.add_theme_font_size_override("font_size", 60)
		trilha_cap.queue_redraw()
		return
	recorde_trilha = recorde
	lbl_frase_cap.text = "Algo se mexe nesta página..."
	if recorde <= 0:
		# Primeira vez: só a regra do capítulo, trilha vazia
		_texto_rich_centro(lbl_recorde_cap, "%d  páginas · o chefe espera na última." % total)
		_texto_rich_centro(lbl_regra_cap, "")
	else:
		if recorde >= total:
			_texto_rich_centro(lbl_recorde_cap, "Melhor tentativa: chegou ao chefe!")
		else:
			_texto_rich_centro(lbl_recorde_cap, "Melhor tentativa: página %d  de %d" % [recorde, total])
		_texto_rich_centro(lbl_regra_cap, "Nova tentativa começa na página 1.")
	trilha_cap.queue_redraw()

## Trilha de páginas: 7 casas + o chefe (círculo maior com "?").
## Casas até o recorde ficam pintadas de azul.
func _desenhar_trilha(c: Control) -> void:
	var total: int = GameData.PAGINAS.size()
	var y: float = c.size.y / 2.0
	var r_pag: float = 21.0
	var r_chefe: float = 40.0
	var x0: float = 30.0
	var x_chefe: float = c.size.x - r_chefe - 6.0
	var passo: float = (x_chefe - r_chefe - r_pag - 34.0 - x0) / float(total - 2)
	var xs: Array = []
	for i in range(total - 1):
		xs.append(x0 + passo * i)
	xs.append(x_chefe)
	# Traço que liga as casas
	for i in range(total - 1):
		var ra: float = r_pag
		var rb: float = r_chefe if i == total - 2 else r_pag
		c.draw_line(Vector2(xs[i] + ra, y), Vector2(xs[i + 1] - rb, y), COR_AZUL_ESCURO, 3.0, true)
	for i in range(total - 1):
		var centro := Vector2(xs[i], y)
		_disco(c, centro, r_pag, COR_AZUL_CANETA if i + 1 <= recorde_trilha else Color(1, 1, 1, 0.9))
		_circulo_caneta(c, centro, r_pag, COR_AZUL_ESCURO, 3.0, i)
	# Chefe: "?" até ser vencido; depois, o mini desenho dele com ✓ verde
	var cc := Vector2(x_chefe, y)
	var chegou: bool = recorde_trilha >= total
	_disco(c, cc, r_chefe, Color("dbe6f7") if chegou and chefe_trilha == null else Color(1, 1, 1, 0.95))
	if chefe_trilha:
		var lado: float = r_chefe * 1.9
		c.draw_texture_rect(chefe_trilha, Rect2(cc - Vector2(lado, lado) / 2.0, Vector2(lado, lado)), false)
	_circulo_caneta(c, cc, r_chefe, COR_AZUL_ESCURO, 4.0, 99)
	if chefe_trilha:
		var cv := cc + Vector2(r_chefe * 0.72, r_chefe * 0.72)
		_disco(c, cv, 17.0, Color("2e9e44"))
		c.draw_polyline(PackedVector2Array([cv + Vector2(-8, 0), cv + Vector2(-2, 7), cv + Vector2(9, -7)]),
			Color.WHITE, 4.0, true)
		return
	var fonte: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
	var tam: int = 56
	var w: float = fonte.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	c.draw_string(fonte, cc + Vector2(-w / 2.0, tam * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COR_AZUL_ESCURO)

func _disco(c: Control, centro: Vector2, raio: float, cor: Color) -> void:
	var pts: PackedVector2Array = []
	for i in range(48):
		var t: float = float(i) / 48.0 * TAU
		pts.append(centro + Vector2(cos(t), sin(t)) * raio)
	c.draw_colored_polygon(pts, cor)

## Círculo de caneta com leve tremor determinístico (semente = casa).
func _circulo_caneta(c: Control, centro: Vector2, raio: float, cor: Color, espessura: float, semente: int) -> void:
	var pontos: PackedVector2Array = []
	var n: int = 48
	for i in range(n + 1):
		var t: float = float(i) / n * TAU * 1.06 + semente
		var rr: float = raio + sin(i * 2.1 + semente) * 0.8
		pontos.append(centro + Vector2(cos(t), sin(t)) * rr)
	c.draw_polyline(pontos, cor, espessura, true)

## Moldura de caneta por fora do botão cheio: um contorno arredondado,
## levemente deslocado, como se o botão tivesse sido contornado à mão.
func _desenhar_moldura_botao(b: Control, cor: Color = COR_AZUL_ESCURO) -> void:
	var r: float = 22.0
	var m: float = -6.0
	var desloc := Vector2(3.0, 3.0)
	var w: float = b.size.x
	var h: float = b.size.y
	var cantos := [
		[Vector2(w - m - r, m + r), -PI / 2.0], [Vector2(w - m - r, h - m - r), 0.0],
		[Vector2(m + r, h - m - r), PI / 2.0], [Vector2(m + r, m + r), PI]]
	var pontos: PackedVector2Array = []
	var idx: int = 0
	for canto in cantos:
		for i in range(9):
			var a: float = canto[1] + float(i) / 8.0 * PI / 2.0
			pontos.append(canto[0] + Vector2(cos(a), sin(a)) * r + desloc
				+ Vector2(sin(idx * 7.31), cos(idx * 5.17)) * 1.2)
			idx += 1
	pontos.append(pontos[0] + Vector2(-14.0, -1.5))
	b.draw_polyline(pontos, Color(cor, 0.9), 3.5, true)

func _mudar_capitulo(direcao: int) -> void:
	var novo_cap = dados_save["capitulo_selecionado"] + direcao
	var cap_desb = dados_save["capitulo_desbloqueado"]
	
	if novo_cap >= 1 and novo_cap <= cap_desb and novo_cap <= 10:
		dados_save["capitulo_selecionado"] = novo_cap
		_salvar_dados()
		_atualizar_ui_capitulo()
		
		# Som procedural de folhear páginas
		var freq_som = 480.0 + (direcao * 80.0)
		var som_folha = _gerar_som_procedural(freq_som, 0.06, "sin")
		_tocar_som(som_folha)

func _alterar_aba(nova_aba: String) -> void:
	aba_ativa = nova_aba
	
	if desenho_hub:
		desenho_hub.aba_ativa = nova_aba
		desenho_hub.queue_redraw()
		
	# Ativa/Desativa visibilidade das telas
	tela_lutar.visible = (nova_aba == "lutar")
	tela_estojo.visible = (nova_aba == "estojo")
	tela_loja.visible = (nova_aba == "loja")

	# Reavalia custos/valores ao entrar no Estojo (a tinta pode ter mudado)
	if nova_aba == "estojo":
		_atualizar_ui_upgrades()
	
	# Atualiza botões da barra inferior (sem colchetes)
	_estilizar_botao_aba(botao_aba_estojo, nova_aba == "estojo", "ESTOJO")
	_estilizar_botao_aba(botao_aba_lutar, nova_aba == "lutar", "LUTAR")
	_estilizar_botao_aba(botao_aba_loja, nova_aba == "loja", "LOJA")
	
	_tocar_som(audio_click_sucesso)

func _estilizar_botao_aba(botao: Button, ativo: bool, texto_padrao: String) -> void:
	var cor_azul  = Color("0047ab")        # Azul cobalto — ativo (igual ao [LUTAR])
	var cor_cinza = Color("1a1a2e", 0.5)   # Cinza — inativo (igual à fonte)

	var label_interno: Label = null
	if botao.has_node("VBox/HBox/TextoEstojo"):
		label_interno = botao.get_node("VBox/HBox/TextoEstojo")
	elif botao.has_node("VBox/HBox/TextoLutar"):
		label_interno = botao.get_node("VBox/HBox/TextoLutar")
	elif botao.has_node("VBox/HBox/TextoLoja"):
		label_interno = botao.get_node("VBox/HBox/TextoLoja")

	var icone_rect: TextureRect = null
	if botao.has_node("VBox/HBox/IconeMochila"):
		icone_rect = botao.get_node("VBox/HBox/IconeMochila")
	elif botao.has_node("VBox/HBox/IconeLutar"):
		icone_rect = botao.get_node("VBox/HBox/IconeLutar")
	elif botao.has_node("VBox/HBox/IconeLoja"):
		icone_rect = botao.get_node("VBox/HBox/IconeLoja")

	var risco_rect: TextureRect = null
	if botao.has_node("VBox/Risco"):
		risco_rect = botao.get_node("VBox/Risco")

	# Reseta o self_modulate do botão — cores controladas individualmente abaixo
	botao.self_modulate = Color.WHITE

	if ativo:
		if icone_rect:
			icone_rect.modulate = Color.WHITE
		if label_interno:
			botao.text = ""
			label_interno.text = texto_padrao
			label_interno.add_theme_color_override("font_color", cor_azul)
			label_interno.add_theme_font_size_override("font_size", 48)
		if risco_rect:
			risco_rect.visible = true
	else:
		if icone_rect:
			icone_rect.modulate = cor_cinza
		if label_interno:
			botao.text = ""
			label_interno.text = texto_padrao
			label_interno.add_theme_color_override("font_color", cor_cinza)
			label_interno.add_theme_font_size_override("font_size", 40)
		if risco_rect:
			risco_rect.visible = false

## Fundo de papel opaco da janela de compra. Fica dentro do HUD, por cima da
## tela de capítulo (antes era desenhado no DesenhoHub, por baixo do HUD, e a
## ilustração do capítulo e as setas apareciam por cima do texto).
func _criar_fundo_popup_compra() -> void:
	var fundo_popup: Control = $HUD/PopupCompra/FundoPopup
	var painel := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.98, 0.965, 0.93, 1.0)
	estilo.border_color = Color("1a1a2e", 0.7)
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(6)
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 10
	painel.add_theme_stylebox_override("panel", estilo)
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo_popup.add_child(painel)
	fundo_popup.move_child(painel, 0)

# Compras no app (Google Play Billing, via BillingManager)
func _abrir_popup_compra(tipo: String) -> void:
	item_sendo_comprado = tipo
	_tocar_som(audio_click_sucesso)

	if tipo == "clipes":
		popup_titulo.text = "Comprar Clipes"
	else:
		popup_titulo.text = "Comprar Tintas"
	_atualizar_texto_popup_compra()
	popup_compra.visible = true
	if desenho_hub:
		desenho_hub.queue_redraw()

## Texto do popup com o preço vindo da loja. Sem preço (loja ainda não
## respondeu), o botão de confirmar fica desativado.
func _atualizar_texto_popup_compra() -> void:
	var nome_item: String = BillingManager.nome(item_sendo_comprado)
	var preco: String = BillingManager.preco(item_sendo_comprado)
	var pode_comprar: bool = BillingManager.disponivel(item_sendo_comprado)
	if pode_comprar:
		popup_descricao.text = "Deseja comprar %s por %s?" % [nome_item, preco]
	else:
		popup_descricao.text = "A loja não respondeu ainda. Tente de novo em instantes."
	botao_confirmar_compra.disabled = not pode_comprar

func _on_confirmar_compra_pressed() -> void:
	_tocar_som(audio_click_sucesso)
	botao_confirmar_compra.disabled = true
	popup_descricao.text = "Abrindo a loja..."
	BillingManager.comprar(item_sendo_comprado)

func _on_compra_concluida(_chave: String) -> void:
	_tocar_som(audio_click_sucesso)
	_atualizar_ui_upgrades() # Tinta nova pode liberar botões do Estojo
	popup_compra.visible = false
	if desenho_hub:
		desenho_hub.queue_redraw()

func _on_compra_falhou(_chave: String, motivo: String) -> void:
	_tocar_som(audio_click_erro)
	if motivo == "cancelada":
		popup_compra.visible = false
	else:
		popup_descricao.text = motivo
		botao_confirmar_compra.disabled = not BillingManager.disponivel(item_sendo_comprado)
	if desenho_hub:
		desenho_hub.queue_redraw()

func _on_cancelar_compra_pressed() -> void:
	_tocar_som(audio_click_erro)
	popup_compra.visible = false
	if desenho_hub:
		desenho_hub.queue_redraw()

func _on_upar_pressed(upgrade_key: String, container: Control) -> void:
	var nivel_atual = dados_save[upgrade_key]

	if nivel_atual >= GameData.NIVEL_MAX_ESTOJO:
		_tocar_som(audio_click_erro)
		return

	var custo = GameData.CUSTOS_ESTOJO[nivel_atual - 1]
	if dados_save["tinta"] >= custo:
		dados_save["tinta"] -= custo
		dados_save[upgrade_key] += 1
		_salvar_dados()
		_atualizar_ui_upgrades()
		
		_tocar_som(audio_click_sucesso)
		
		# Animação de pulso
		var tween = create_tween()
		tween.tween_property(container, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		_tocar_som(audio_click_erro)
		var pos_original = container.position
		var tween = create_tween()
		tween.tween_property(container, "position:x", pos_original.x - 15, 0.05)
		tween.tween_property(container, "position:x", pos_original.x + 15, 0.05)
		tween.tween_property(container, "position:x", pos_original.x, 0.05)
		tween.tween_callback(func(): _oferecer_pacote("tinta", custo - dados_save["tinta"]))

## Oferece o pacote quando o jogador tenta comprar algo sem saldo.
## No máximo uma vez por moeda a cada visita ao Hub, para não insistir.
func _oferecer_pacote(chave: String, falta: int) -> void:
	if oferta_mostrada.has(chave) or not BillingManager.disponivel(chave) or popup_compra.visible:
		return
	oferta_mostrada[chave] = true
	_abrir_popup_compra(chave)
	var moeda: String = "gotas de tinta" if chave == "tinta" else "clipes"
	popup_titulo.text = "Faltam %d %s" % [falta, moeda]
	popup_descricao.text = "Quer o pacote de %s por %s?" % [BillingManager.nome(chave), BillingManager.preco(chave)]

func _atualizar_ui_upgrades() -> void:
	_configurar_container(container_dano, "nivel_dano", "Dano da Caneta", "res://assets/upgrade1.svg")
	_configurar_container(container_hp, "nivel_hp", "Corações de HP", "res://assets/upgrade2.svg")
	_configurar_container(container_cadencia, "nivel_cadencia", "Cadência de Tiro", "res://assets/upgrade3.svg")
	if desenho_hub:
		desenho_hub.queue_redraw()

## Curva de atributo por chave de upgrade do Estojo (índice = nível).
func _atributos_estojo(upgrade_key: String) -> Array:
	match upgrade_key:
		"nivel_dano":
			return GameData.DANO_POR_NIVEL
		"nivel_hp":
			return GameData.HP_POR_NIVEL
		"nivel_cadencia":
			return GameData.CADENCIA_POR_NIVEL
	return []

## Formata o valor do atributo (cadência em segundos, o resto inteiro).
func _formatar_valor_estojo(upgrade_key: String, valor) -> String:
	if upgrade_key == "nivel_cadencia":
		return "%.2fs" % valor
	return str(valor)

func _configurar_container(container: Control, upgrade_key: String, nome_upgrade: String, icone_path: String = "") -> void:
	var nivel = dados_save[upgrade_key]
	var label_info: Label = container.get_node("InfoLabel")
	var botao_upar: Button = container.get_node("BotaoUpar")
	var atributos: Array = _atributos_estojo(upgrade_key)
	var fonte: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")

	# Card de fundo desenhado à mão (atrás dos textos e ícones), criado sob demanda
	var bg_card: TextureRect = container.get_node_or_null("CardBackground")
	if bg_card == null:
		bg_card = TextureRect.new()
		bg_card.name = "CardBackground"
		bg_card.texture = load("res://assets/card-upgrade.svg")
		bg_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bg_card.position = Vector2.ZERO
		bg_card.size = container.size
		bg_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(bg_card)
		container.move_child(bg_card, 0) # Garante que fique atrás de tudo

	# Ícone temático do upgrade à esquerda do card, criado sob demanda
	if icone_path != "":
		var icone: TextureRect = container.get_node_or_null("IconeUpgrade")
		if icone == null:
			icone = TextureRect.new()
			icone.name = "IconeUpgrade"
			icone.texture = load(icone_path)
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icone.position = Vector2(75, 48)
			icone.size = Vector2(145, 145)
			icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(icone)
			container.move_child(icone, 1) # Logo acima do fundo, atrás dos textos

	# Label de valor "atual → próximo" (criada sob demanda)
	var lbl_valor: Label = container.get_node_or_null("ValorLabel")
	if lbl_valor == null:
		lbl_valor = Label.new()
		lbl_valor.name = "ValorLabel"
		lbl_valor.add_theme_font_override("font", FONTE_NUMEROS)
		container.add_child(lbl_valor)

	# Label "faltam X" sob o botão (criada sob demanda)
	var lbl_falta: Label = container.get_node_or_null("FaltaLabel")
	if lbl_falta == null:
		lbl_falta = Label.new()
		lbl_falta.name = "FaltaLabel"
		lbl_falta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_falta.add_theme_font_override("font", FONTE_NUMEROS)
		lbl_falta.add_theme_color_override("font_color", Color("a33d3d"))
		container.add_child(lbl_falta)

	# Indicador "Nível X" em azul BIC ao lado do título (criado sob demanda)
	var lbl_nivel: RichTextLabel = container.get_node_or_null("NivelLabel")
	if lbl_nivel == null:
		lbl_nivel = RichTextLabel.new()
		lbl_nivel.name = "NivelLabel"
		lbl_nivel.bbcode_enabled = true
		lbl_nivel.scroll_active = false
		lbl_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_nivel.add_theme_font_override("normal_font", FONTE_NUMEROS)
		container.add_child(lbl_nivel)

	# Tracinhos de contagem manuscrita dentro do card (acima do fundo).
	# Ao subir de nível, o traço novo é "escrito" com uma animação em vez de
	# aparecer pronto — ver _animar_tracinho_novo().
	var tracinhos: Control = container.get_node_or_null("Tracinhos")
	if tracinhos == null:
		tracinhos = Control.new()
		tracinhos.name = "Tracinhos"
		tracinhos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tracinhos.draw.connect(func(): _desenhar_tracinhos_card(tracinhos))
		tracinhos.set_meta("nivel", nivel)
		tracinhos.set_meta("nivel_desenhado", nivel)
		tracinhos.set_meta("progress", 1.0)
		tracinhos.set_meta("anim_idx", -1)
		container.add_child(tracinhos)
		tracinhos.queue_redraw()
	else:
		var nivel_anterior: int = int(tracinhos.get_meta("nivel_desenhado", nivel))
		if nivel != nivel_anterior:
			tracinhos.set_meta("nivel_desenhado", nivel)
			if nivel == nivel_anterior + 1:
				_animar_tracinho_novo(tracinhos, nivel_anterior)
			else:
				# Salto maior que 1 nível (ex.: reset de save) — sem animação
				tracinhos.set_meta("nivel", nivel)
				tracinhos.set_meta("progress", 1.0)
				tracinhos.set_meta("anim_idx", -1)
				tracinhos.queue_redraw()

	# ---- Grade do card (840×240): ícone | conteúdo | ação ----
	# Linha 1: título + nível · Linha 2: tracinhos · Linha 3: valor
	label_info.position = Vector2(275, 30)
	label_info.size = Vector2(400, 52)
	label_info.add_theme_font_size_override("font_size", 38)

	# "Nível X" encostado no fim do título (largura medida na fonte real)
	var largura_titulo: float = fonte.get_string_size(nome_upgrade, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
	lbl_nivel.position = Vector2(275 + largura_titulo + 14, 33)
	lbl_nivel.size = Vector2(160, 48)
	lbl_nivel.add_theme_font_size_override("normal_font_size", 33)

	tracinhos.position = Vector2(275, 92)
	tracinhos.size = Vector2(220, 44)

	lbl_valor.position = Vector2(255, 143)
	lbl_valor.size = Vector2(380, 52)
	lbl_valor.add_theme_font_size_override("font_size", 40)

	# Zona de ação à direita: botão abaixo do "Nível X" + "faltam X" logo abaixo.
	# Antes (y=70) brigava visualmente com o badge de nível (y~34) — agora começa
	# em y=110, bem separado.
	botao_upar.position = Vector2(580, 112)
	botao_upar.size = Vector2(230, 85)
	botao_upar.add_theme_font_override("font", FONTE_NUMEROS)
	botao_upar.add_theme_font_size_override("font_size", 40)

	lbl_falta.position = Vector2(580, 202)
	lbl_falta.size = Vector2(230, 38)
	lbl_falta.add_theme_font_size_override("font_size", 32)

	var tex_upar: Texture2D = load("res://assets/upar.svg")
	botao_upar.icon = tex_upar
	botao_upar.add_theme_constant_override("icon_max_width", 48)

	if nivel >= GameData.NIVEL_MAX_ESTOJO:
		label_info.text = nome_upgrade
		lbl_nivel.text = "[color=#f39c12]MÁX[/color]"
		botao_upar.text = "[ MAX ]"
		botao_upar.icon = null
		botao_upar.disabled = true
		botao_upar.modulate.a = 1.0
		lbl_valor.text = _formatar_valor_estojo(upgrade_key, atributos[nivel]) + " · MÁX"
		lbl_valor.add_theme_color_override("font_color", Color("f39c12"))
		lbl_falta.visible = false
	else:
		var custo = GameData.CUSTOS_ESTOJO[nivel - 1]
		var pode_pagar: bool = dados_save["tinta"] >= custo
		label_info.text = nome_upgrade
		lbl_nivel.text = "[color=#0047ab]NV. [font_size=36]%d[/font_size][/color]" % nivel
		botao_upar.text = "[ " + str(custo) + " ]"
		botao_upar.disabled = false

		# Antes → depois do atributo em verde (mesma linguagem das passivas da loja)
		lbl_valor.text = "%s → %s" % [
			_formatar_valor_estojo(upgrade_key, atributos[nivel]),
			_formatar_valor_estojo(upgrade_key, atributos[nivel + 1])
		]
		lbl_valor.add_theme_color_override("font_color", Color("2f5d3a"))

		# Sem tinta suficiente: botão esmaecido em vermelho + quanto falta
		if pode_pagar:
			botao_upar.add_theme_color_override("font_color", Color("002867"))
			botao_upar.add_theme_color_override("icon_normal_color", Color("002867"))
			botao_upar.modulate.a = 1.0
			lbl_falta.visible = false
		else:
			botao_upar.add_theme_color_override("font_color", Color("a33d3d"))
			botao_upar.add_theme_color_override("icon_normal_color", Color("a33d3d"))
			botao_upar.modulate.a = 0.65
			lbl_falta.text = "faltam %d" % (custo - dados_save["tinta"])
			lbl_falta.visible = true

## Tracinhos de contagem escolar desenhados dentro do card: grupos de 5
## (4 riscos + corte diagonal). Níveis futuros aparecem como fantasma a lápis.
## O traço em "anim_idx" é desenhado parcialmente (0..progress) para simular
## uma caneta escrevendo-o em tempo real — ver _animar_tracinho_novo().
func _desenhar_tracinhos_card(ctrl: Control) -> void:
	var nivel: int = int(ctrl.get_meta("nivel", 0))
	var progress: float = float(ctrl.get_meta("progress", 1.0))
	var anim_idx: int = int(ctrl.get_meta("anim_idx", -1))
	var cor := Color("002867") # Azul BIC
	var cor_fantasma := Color(cor.r, cor.g, cor.b, 0.16)
	var altura: float = 30.0
	var passo: float = 17.0
	var gap_grupo: float = 30.0
	var cy: float = ctrl.size.y / 2.0

	for i in range(GameData.NIVEL_MAX_ESTOJO):
		var grupo: int = int(i / 5.0)
		var idx: int = i % 5
		var animando: bool = (i == anim_idx)
		var c: Color = cor if (i < nivel or animando) else cor_fantasma
		var base_x: float = 10.0 + grupo * (4.0 * passo + gap_grupo)

		var p_inicio: Vector2
		var p_fim: Vector2
		if idx < 4:
			# Risco vertical com leve inclinação alternada (traço de mão)
			var x = base_x + idx * passo
			var tilt: float = 2.0 if (i % 2 == 0) else -1.5
			p_inicio = Vector2(x + tilt, cy - altura / 2.0)
			p_fim = Vector2(x - tilt, cy + altura / 2.0)
		else:
			# Quinto risco: corta o grupo na diagonal
			p_inicio = Vector2(base_x - 8, cy + altura / 2.0 - 4.0)
			p_fim = Vector2(base_x + 3.0 * passo + 8.0, cy - altura / 2.0 + 4.0)

		if animando:
			p_fim = p_inicio.lerp(p_fim, progress)
		ctrl.draw_line(p_inicio, p_fim, c, 3.5, true)

## Anima o traço que marca o novo nível como se fosse escrito na hora:
## cresce de p_inicio até p_fim em ~0.22s, então assenta como traço definitivo.
func _animar_tracinho_novo(tracinhos: Control, nivel_anterior: int) -> void:
	tracinhos.set_meta("nivel", nivel_anterior)
	tracinhos.set_meta("progress", 0.0)
	tracinhos.set_meta("anim_idx", nivel_anterior) # índice 0-based do traço novo
	tracinhos.queue_redraw()

	var tween = tracinhos.create_tween()
	tween.tween_method(
		func(p: float):
			tracinhos.set_meta("progress", p)
			tracinhos.queue_redraw(),
		0.0, 1.0, 0.22
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		tracinhos.set_meta("nivel", nivel_anterior + 1)
		tracinhos.set_meta("anim_idx", -1)
		tracinhos.set_meta("progress", 1.0)
		tracinhos.queue_redraw()
	)

func _on_botao_jogar_pressed() -> void:
	# Com partida salva, LUTAR não apaga nada sem avisar: mostra o aviso de
	# retomar (só "Descartar" apaga a partida).
	if SaveManager.tem_run_ativa():
		if not $HUD.has_node("PromptRetomarRun"):
			_mostrar_prompt_retomar_run()
		return
	# Iniciar pelo botão = run nova: garante que não haja snapshot antigo e que
	# o Main não entre em modo de restauração.
	SaveManager.retomar_run_pendente = false
	SaveManager.limpar_run_snapshot()
	_tocar_som(audio_click_sucesso)
	get_tree().change_scene_to_file("res://main.tscn")

# ============================================================
# RETOMAR RUN INTERROMPIDA
# ============================================================
## Popup no estilo caderno perguntando se o jogador quer continuar a run que
## ficou salva quando o app foi fechado no meio da partida.
func _mostrar_prompt_retomar_run() -> void:
	var snap: Dictionary = SaveManager.get_run_snapshot()
	if snap.is_empty() or not snap.get("ativa", false):
		return

	var total: int = GameData.PAGINAS.size()
	var cap: int = clamp(int(snap.get("capitulo", 1)), 1, nomes_capitulos.size() - 1)
	var pagina: int = clamp(int(snap.get("pagina", 1)), 1, total)
	var coracoes: int = int(snap.get("hp", 1))
	var tinta: int = int(snap.get("tinta_partida", 0))
	var melhorias: int = 0
	var ups = snap.get("upgrades", {})
	if ups is Dictionary:
		for k in ups:
			melhorias += int(ups[k])
	var revive_usado: bool = bool(snap.get("revive_usado", false))
	var fonte: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")

	var overlay := Control.new()
	overlay.name = "PromptRetomarRun"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	$HUD.add_child(overlay)

	# Hub apagado atrás (cinza), o cartão de papel por cima
	var fundo := ColorRect.new()
	fundo.color = Color(0.35, 0.36, 0.4, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fundo)

	var cartao := Control.new()
	cartao.anchor_left = 0.5
	cartao.anchor_right = 0.5
	cartao.anchor_top = 0.5
	cartao.anchor_bottom = 0.5
	cartao.offset_left = -490.0
	cartao.offset_right = 490.0
	cartao.offset_top = -870.0
	cartao.offset_bottom = 870.0
	overlay.add_child(cartao)
	var recorte := Control.new()
	recorte.clip_contents = true
	recorte.set_anchors_preset(Control.PRESET_FULL_RECT)
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(recorte)
	var papel := ColorRect.new()
	papel.set_script(preload("res://Paper.gd"))
	papel.desenhar_margem = false
	papel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.add_child(papel)
	papel.configurar_para_capitulo(cap)
	var borda := Control.new()
	borda.set_anchors_preset(Control.PRESET_FULL_RECT)
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	borda.draw.connect(_desenhar_cartao_retomar.bind(borda))
	cartao.add_child(borda)

	_label_cartao(cartao, "PARTIDA EM\nANDAMENTO", fonte, 76, COR_AZUL_ESCURO, 40.0, 210.0)
	var sub := TextureRect.new()
	sub.texture = load("res://assets/sublinhado.svg")
	sub.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sub.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sub.modulate = COR_AZUL_CANETA
	sub.position = Vector2(190, 212)
	sub.size = Vector2(600, 40)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(sub)
	_rich_cartao(cartao, "Capítulo %d  · %s" % [cap, nomes_capitulos[cap]], fonte, 50, COR_AZUL_ESCURO, 262.0)

	var arte := TextureRect.new()
	var caminho_arte := "res://assets/images/stage%d.png" % cap
	if ResourceLoader.exists("res://assets/images/stage%d.svg" % cap):
		caminho_arte = "res://assets/images/stage%d.svg" % cap
	arte.texture = load(caminho_arte) if ResourceLoader.exists(caminho_arte) else boss_icon.texture
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arte.position = Vector2(290, 340)
	arte.size = Vector2(400, 360)
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(arte)

	_rich_cartao(cartao, "Página %d  de %d" % [pagina, total], fonte, 50, COR_TEXTO, 712.0)
	var trilha := Control.new()
	trilha.position = Vector2(70, 782)
	trilha.size = Vector2(840, 140)
	trilha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trilha.draw.connect(_desenhar_trilha_retomar.bind(trilha, pagina))
	cartao.add_child(trilha)
	_rich_cartao(cartao, "Você voltará ao início da página %d." % pagina, fonte, TAM_TEXTO_AZUL_REGRA, COR_AZUL_CANETA, 930.0)

	# Bloco "Preservado nesta partida" (entre linhas tracejadas)
	_rich_cartao(cartao, "Preservado nesta partida", fonte, TAM_TEXTO_AZUL, COR_AZUL_ESCURO, 1030.0)
	var itens := [
		["res://assets/ui/icone_coracao.png", "%d  %s" % [coracoes, "coração" if coracoes == 1 else "corações"], Vector2(50, 1110)],
		["res://assets/ink.svg", "%d  de tinta" % tinta, Vector2(505, 1110)],
		["res://assets/ui/icone_melhoria.png", "%d  %s" % [melhorias, "melhoria ativa" if melhorias == 1 else "melhorias ativas"], Vector2(50, 1200)],
		["res://assets/ui/icone_reviver.png", "Reviver já usado" if revive_usado else "Reviver disponível", Vector2(505, 1200)],
	]
	for it in itens:
		var ic := TextureRect.new()
		ic.texture = load(it[0])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.position = it[2]
		ic.size = Vector2(64, 64)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if it[0].ends_with("icone_reviver.png") and revive_usado:
			ic.modulate = Color(1, 1, 1, 0.4)
		cartao.add_child(ic)
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.scroll_active = false
		r.autowrap_mode = TextServer.AUTOWRAP_OFF
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_theme_font_override("normal_font", fonte)
		r.add_theme_font_size_override("normal_font_size", TAM_TEXTO_AZUL)
		r.add_theme_color_override("default_color", COR_TEXTO)
		r.position = it[2] + Vector2(76, 4)
		r.size = Vector2(400, 64)
		r.text = _bbcode_numeros(it[1])
		cartao.add_child(r)

	var btn_continuar := Button.new()
	btn_continuar.text = "CONTINUAR PARTIDA"
	btn_continuar.add_theme_font_override("font", fonte)
	btn_continuar.add_theme_font_size_override("font_size", 58)
	btn_continuar.position = Vector2(150, 1365)
	btn_continuar.size = Vector2(680, 125)
	_estilizar_botao_cheio(btn_continuar)
	cartao.add_child(btn_continuar)
	btn_continuar.pressed.connect(func():
		_tocar_som(audio_click_sucesso)
		SaveManager.retomar_run_pendente = true
		get_tree().change_scene_to_file("res://main.tscn")
	)

	var btn_abandonar := Button.new()
	btn_abandonar.text = "ABANDONAR PARTIDA"
	_fundo_branco_botao(btn_abandonar)
	btn_abandonar.add_theme_font_override("font", fonte)
	btn_abandonar.add_theme_font_size_override("font_size", 48)
	for estado in ["font_color", "font_hover_color", "font_focus_color"]:
		btn_abandonar.add_theme_color_override(estado, COR_VERMELHO_CANETA)
	btn_abandonar.add_theme_color_override("font_pressed_color", COR_VERMELHO_CANETA.darkened(0.3))
	btn_abandonar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn_abandonar.position = Vector2(156, 1561)
	btn_abandonar.size = Vector2(662, 100)
	btn_abandonar.draw.connect(_desenhar_moldura_botao.bind(btn_abandonar, COR_VERMELHO_CANETA))
	cartao.add_child(btn_abandonar)
	btn_abandonar.pressed.connect(func():
		_tocar_som(audio_click_erro)
		_confirmar_abandono(overlay, fonte)
	)

## Botão de contorno (vermelho) com miolo branco: o papel não aparece por trás.
func _fundo_branco_botao(b: Button) -> void:
	b.flat = false
	for estado in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.94, 0.94, 0.94) if estado == "pressed" else Color.WHITE
		sb.set_corner_radius_all(14)
		# A moldura de caneta é desenhada 3 px para baixo: o texto acompanha
		sb.content_margin_top = 8.0
		b.add_theme_stylebox_override(estado, sb)

## Segunda pergunta antes de apagar a partida salva.
func _confirmar_abandono(overlay: Control, fonte: Font) -> void:
	if overlay.has_node("ConfirmarAbandono"):
		return
	var camada := Control.new()
	camada.name = "ConfirmarAbandono"
	camada.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(camada)
	var escuro := ColorRect.new()
	escuro.color = Color(0.1, 0.1, 0.15, 0.45)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(escuro)

	var caixa := Control.new()
	caixa.anchor_left = 0.5
	caixa.anchor_right = 0.5
	caixa.anchor_top = 0.5
	caixa.anchor_bottom = 0.5
	caixa.offset_left = -430.0
	caixa.offset_right = 430.0
	caixa.offset_top = -330.0
	caixa.offset_bottom = 330.0
	caixa.draw.connect(func():
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.99, 0.985, 0.97)
		sb.set_corner_radius_all(10)
		sb.border_color = COR_VERMELHO_CANETA
		sb.set_border_width_all(5)
		caixa.draw_style_box(sb, Rect2(Vector2.ZERO, caixa.size))
		_desenhar_moldura_botao(caixa, COR_VERMELHO_CANETA)
	)
	camada.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "Abandonar a partida?"
	titulo.add_theme_font_override("font", fonte)
	titulo.add_theme_font_size_override("font_size", 58)
	titulo.add_theme_color_override("font_color", COR_VERMELHO_CANETA)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 50)
	titulo.size = Vector2(860, 80)
	caixa.add_child(titulo)
	var aviso := Label.new()
	aviso.text = "Ao abandonar, você perde os\nganhos desta partida."
	aviso.add_theme_font_override("font", fonte)
	aviso.add_theme_font_size_override("font_size", TAM_TEXTO_AZUL)
	aviso.add_theme_color_override("font_color", COR_TEXTO)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.position = Vector2(0, 150)
	aviso.size = Vector2(860, 130)
	caixa.add_child(aviso)

	var btn_voltar := Button.new()
	btn_voltar.text = "VOLTAR"
	btn_voltar.add_theme_font_override("font", fonte)
	btn_voltar.add_theme_font_size_override("font_size", 58)
	btn_voltar.position = Vector2(110, 300)
	btn_voltar.size = Vector2(640, 120)
	_estilizar_botao_cheio(btn_voltar)
	caixa.add_child(btn_voltar)
	btn_voltar.pressed.connect(func():
		_tocar_som(audio_click_sucesso)
		camada.queue_free()
	)

	var btn_sim := Button.new()
	btn_sim.text = "SIM, ABANDONAR"
	_fundo_branco_botao(btn_sim)
	btn_sim.add_theme_font_override("font", fonte)
	btn_sim.add_theme_font_size_override("font_size", TAM_TEXTO_AZUL_REGRA)
	for estado in ["font_color", "font_hover_color", "font_focus_color"]:
		btn_sim.add_theme_color_override(estado, COR_VERMELHO_CANETA)
	btn_sim.add_theme_color_override("font_pressed_color", COR_VERMELHO_CANETA.darkened(0.3))
	btn_sim.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn_sim.position = Vector2(118, 485)
	btn_sim.size = Vector2(624, 100)
	btn_sim.draw.connect(_desenhar_moldura_botao.bind(btn_sim, COR_VERMELHO_CANETA))
	caixa.add_child(btn_sim)
	btn_sim.pressed.connect(func():
		_tocar_som(audio_click_erro)
		SaveManager.limpar_run_snapshot()
		overlay.queue_free()
	)

const COR_VERMELHO_CANETA := Color("c62828")

func _label_cartao(cartao: Control, texto: String, fonte: Font, tam: int, cor: Color, y0: float, y1: float) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_constant_override("line_spacing", -14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y0)
	l.size = Vector2(980.0, y1 - y0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartao.add_child(l)

func _rich_cartao(cartao: Control, texto: String, fonte: Font, tam: int, cor: Color, y0: float) -> void:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = true
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", fonte)
	r.add_theme_font_size_override("normal_font_size", tam)
	r.add_theme_color_override("default_color", cor)
	r.position = Vector2(20, y0)
	r.size = Vector2(940, tam + 20)
	r.text = "[center]" + _bbcode_numeros(texto) + "[/center]"
	cartao.add_child(r)

## Cartão de papel com contorno azul de caneta e duas linhas tracejadas
## separando o bloco "Preservado nesta partida".
func _desenhar_cartao_retomar(c: Control) -> void:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(6)
	sb.border_color = COR_AZUL_CANETA
	sb.set_border_width_all(5)
	c.draw_style_box(sb, Rect2(Vector2.ZERO, c.size))
	_desenhar_moldura_botao(c)
	for y in [1005.0, 1300.0]:
		# linhas tracejadas entre os blocos
		c.draw_dashed_line(Vector2(40, y), Vector2(c.size.x - 40, y), Color(COR_AZUL_ESCURO, 0.45), 2.5, 12.0)

## Trilha numerada da partida salva: páginas passadas cheias, a atual com
## anel amarelo, as seguintes vazias e o chefe com "?".
func _desenhar_trilha_retomar(c: Control, pagina: int) -> void:
	var total: int = GameData.PAGINAS.size()
	var y: float = 46.0
	var r_pag: float = 22.0
	var r_chefe: float = 40.0
	var x0: float = 30.0
	var x_chefe: float = c.size.x - r_chefe - 6.0
	var passo: float = (x_chefe - r_chefe - r_pag - 34.0 - x0) / float(total - 2)
	var xs: Array = []
	for i in range(total - 1):
		xs.append(x0 + passo * i)
	xs.append(x_chefe)
	for i in range(total - 1):
		var rb: float = r_chefe if i == total - 2 else r_pag
		c.draw_line(Vector2(xs[i] + r_pag, y), Vector2(xs[i + 1] - rb, y), COR_AZUL_ESCURO, 3.0, true)
	for i in range(total):
		var n: int = i + 1
		var centro := Vector2(xs[i], y)
		var raio: float = r_chefe if n == total else r_pag
		if n == pagina:
			_disco(c, centro, raio + 14.0, Color("6fd877"))
			_disco(c, centro, raio + 3.0, Color.WHITE)
			_circulo_caneta(c, centro, raio + 3.0, COR_AZUL_CANETA, 6.0, i)
		elif n < pagina:
			_disco(c, centro, raio, COR_AZUL_CANETA)
			_circulo_caneta(c, centro, raio, COR_AZUL_ESCURO, 3.0, i)
		else:
			_disco(c, centro, raio, Color.WHITE)
			_circulo_caneta(c, centro, raio, COR_AZUL_ESCURO, 3.0 if n < total else 4.0, i)
		if n == total:
			# Mesmo "?" da trilha do hub (a Caveat é inclinada e saía torta)
			var fq: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
			var tq: int = 56
			var wq: float = fq.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, tq).x
			c.draw_string(fq, centro + Vector2(-wq / 2.0, tq * 0.36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, tq, COR_AZUL_ESCURO)
		var rotulo: String = str(n)
		var tam: int = 38
		var w: float = FONTE_NUMEROS.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		c.draw_string(FONTE_NUMEROS, Vector2(xs[i] - w / 2.0, y + r_chefe + 44.0), rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, COR_AZUL_ESCURO)

# ============================================================
# GESTO/BOTÃO VOLTAR NO HUB
# ============================================================
## Com quit_on_go_back=false, o voltar no Hub não fecha mais o app. Aqui ele
## fecha overlays abertos; sem nada aberto, mantém o jogador no Hub.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	# O prompt de retomar run é uma decisão obrigatória: voltar não o fecha.
	if $HUD.has_node("PromptRetomarRun"):
		var conf := $HUD.get_node("PromptRetomarRun").get_node_or_null("ConfirmarAbandono")
		if conf:
			conf.queue_free()
		return
	if popup_compra and popup_compra.visible:
		popup_compra.visible = false
		return
	# Sem overlays: permanece no Hub (evita fechamento acidental do jogo).

# ============================================================
# LOJA DE CANETAS
# ============================================================
func _criar_loja_canetas() -> void:
	# Esconde o aviso "[EM BREVE]" — a loja agora é real
	if tela_loja.has_node("AvisoLoja"):
		tela_loja.get_node("AvisoLoja").visible = false

	container_loja = Control.new()
	container_loja.set_anchors_preset(Control.PRESET_FULL_RECT)
	container_loja.mouse_filter = Control.MOUSE_FILTER_IGNORE # não bloquear os [+] do topo
	tela_loja.add_child(container_loja)
	_criar_sub_abas_loja()
	_atualizar_loja()

## O título "Loja de Canetas" vira duas abas: Canetas | Pacotes.
func _criar_sub_abas_loja() -> void:
	if tela_loja.has_node("TituloLoja"):
		tela_loja.get_node("TituloLoja").visible = false
	var fonte: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
	for item in [["canetas", "Canetas", 80.0], ["pacotes", "Pacotes", 560.0]]:
		var btn := Button.new()
		btn.text = item[1]
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(item[2], 340)
		btn.size = Vector2(440, 100)
		btn.add_theme_font_override("font", fonte)
		btn.add_theme_font_size_override("font_size", 72)
		tela_loja.add_child(btn)
		var chave: String = item[0]
		btn.pressed.connect(func(): _mudar_sub_aba_loja(chave))
		botoes_sub_aba_loja[chave] = btn
	_estilizar_sub_abas_loja()

func _mudar_sub_aba_loja(chave: String) -> void:
	if sub_aba_loja == chave:
		return
	sub_aba_loja = chave
	_tocar_som(audio_click_sucesso)
	_estilizar_sub_abas_loja()
	_atualizar_loja()

## Aba ativa escura e sublinhada; a outra em cinza.
func _estilizar_sub_abas_loja() -> void:
	for chave in botoes_sub_aba_loja:
		var btn: Button = botoes_sub_aba_loja[chave]
		var ativo: bool = chave == sub_aba_loja
		var cor: Color = Color(0.1, 0.1, 0.15, 1) if ativo else Color("1a1a2e", 0.4)
		for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(estado, cor)
	if sublinhado_loja:
		var centro: float = 300.0 if sub_aba_loja == "canetas" else 780.0
		sublinhado_loja.offset_left = centro - 540.0 - 200.0
		sublinhado_loja.offset_right = centro - 540.0 + 200.0

## Usado pelos [+] do topo e pela oferta de pacote.
func _abrir_pacotes() -> void:
	if aba_ativa != "loja":
		_alterar_aba("loja")
	else:
		_tocar_som(audio_click_sucesso)
	if sub_aba_loja != "pacotes":
		sub_aba_loja = "pacotes"
		_estilizar_sub_abas_loja()
		_atualizar_loja()

const PACOTES_LOJA: Array = [
	{"chave": "tinta", "icone": "res://assets/pote_tinta.png",
		"desc": "Para subir o Estojo e\ncomprar canetas", "cor": "0047ab"},
	{"chave": "clipes", "icone": "res://assets/clip.svg",
		"desc": "Para as canetas especiais", "cor": "b8860b"},
]

## Aba Pacotes: um cartão por produto da Play Store. Tocar abre a confirmação.
func _montar_pacotes(fonte: Font) -> void:
	for i in range(PACOTES_LOJA.size()):
		var p: Dictionary = PACOTES_LOJA[i]
		var chave: String = p["chave"]
		var disponivel: bool = BillingManager.disponivel(chave)

		var card := Button.new()
		card.flat = true
		card.focus_mode = Control.FOCUS_NONE
		card.position = Vector2(60, 540 + i * 420)
		card.size = Vector2(960, 365)
		card.pivot_offset = card.size / 2.0
		card.rotation_degrees = -0.6 if i == 0 else 0.5
		container_loja.add_child(card)

		var fundo := NinePatchRect.new()
		fundo.texture = load("res://assets/card-roleta.png")
		fundo.patch_margin_left = 62
		fundo.patch_margin_right = 62
		fundo.patch_margin_top = 62
		fundo.patch_margin_bottom = 62
		fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
		fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(fundo)

		var icone := TextureRect.new()
		icone.texture = load(p["icone"])
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.position = Vector2(60, 72)
		icone.size = Vector2(220, 220)
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(icone)

		card.add_child(_label_card(BillingManager.nome(chave), Vector2(310, 66),
			Vector2(610, 70), fonte, 50, Color(p["cor"])))
		card.add_child(_label_card(p["desc"], Vector2(310, 136),
			Vector2(610, 110), fonte, 34, Color("59595f")))
		var texto_preco: String = "[ %s ]" % BillingManager.preco(chave) if disponivel \
			else "carregando preço..."
		# Preço logo abaixo da descrição (1 ou 2 linhas)
		var y_preco: float = 136.0 + 52.0 * (p["desc"] as String).count("\n") + 52.0
		card.add_child(_label_card(texto_preco, Vector2(310, y_preco), Vector2(610, 80),
			FONTE_NUMEROS if disponivel else fonte, 56 if disponivel else 34,
			Color("2e7d32") if disponivel else Color("59595f")))

		card.pressed.connect(func(): _abrir_popup_compra(chave))
		card.button_down.connect(func(): _animar_toque_card(card, true))
		card.button_up.connect(func(): _animar_toque_card(card, false))

	var nota := _label_card("Pagamento pela Google Play. Os itens entram na hora.",
		Vector2(60, 1400), Vector2(960, 50), fonte, 30, Color("59595f"), true)
	container_loja.add_child(nota)

# Inclinação fixa por card (papel colado meio torto no caderno)
const ROTACOES_CARD: Array = [-0.9, 1.0, -1.1, 0.8, -0.6]

const ICONES_CANETA: Dictionary = {
	"bic_azul":     "res://assets/bic-azul.svg",
	"lapis_hb":     "res://assets/lapis-hb.svg",
	"nanquim":      "res://assets/nanquim.svg",
	"gel_vermelha": "res://assets/gel-vermelha.svg",
	"nanquim_real": "res://assets/nanquim-real.svg",
}

func _atualizar_loja() -> void:
	for child in container_loja.get_children():
		child.queue_free()

	var fonte: Font = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")

	if sub_aba_loja == "pacotes":
		_montar_pacotes(fonte)
		return

	for i in range(GameData.CANETAS.size()):
		var caneta: Dictionary = GameData.CANETAS[i]
		var col = i % 2
		var linha = i / 2

		var equipada: bool = dados_save["caneta_equipada"] == caneta["id"]
		var possuida: bool = caneta["id"] in dados_save["canetas_possuidas"]
		var usa_tinta: bool = caneta["custo_tinta"] > 0
		var custo: int = caneta["custo_tinta"] if usa_tinta else caneta["custo_clipes"]
		var saldo: int = dados_save["tinta"] if usa_tinta else dados_save["clipes_ouro"]
		var tex_moeda: Texture2D = load("res://assets/ink.svg") if usa_tinta else load("res://assets/clip.svg")
		var pode_pagar: bool = possuida or custo <= 0 or saldo >= custo

		var card = Control.new()
		card.position = Vector2(70 + col * 490, 540 + linha * 350)
		card.size = Vector2(450, 300)
		card.pivot_offset = card.size / 2.0
		if caneta["id"] == "lapis_hb" or caneta["id"] == "gel_vermelha":
			card.rotation_degrees = -1.0
		else:
			card.rotation_degrees = 0.0
		if not pode_pagar:
			# Ainda fora de alcance: card esmaecido, como esboço a lápis
			card.modulate = Color(0.84, 0.84, 0.84, 0.7)
		container_loja.add_child(card)

		if not pode_pagar and not possuida:
			var cadeado = TextureRect.new()
			cadeado.texture = load("res://assets/locked.svg")
			cadeado.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cadeado.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cadeado.size = Vector2(52, 52)
			cadeado.rotation_degrees = 12.0
			cadeado.position = Vector2(card.position.x + 450 - 52 - 8, card.position.y - 14)
			cadeado.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container_loja.add_child(cadeado)

		# Card desenhado à mão (fundo + borda + caneta + rabisco)
		var arte = ArteCardCaneta.new()
		arte.position = Vector2(0, 0)
		arte.size = Vector2(450, 300)
		arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arte.cor_corpo = Color(caneta["cor_corpo"])
		arte.cor_projetil = Color(caneta["cor_projetil"])
		if caneta["id"] in ICONES_CANETA:
			arte.textura_caneta = load(ICONES_CANETA[caneta["id"]])
		card.add_child(arte)

		# Nome da caneta
		card.add_child(_label_card(caneta["nome"], Vector2(180, 55), Vector2(272, 50),
			fonte, 38, Color("002867")))

		# Passiva com linhas coloridas (+ bônus / − penalidade)
		var rich = RichTextLabel.new()
		rich.bbcode_enabled = true
		rich.scroll_active = false
		rich.position = Vector2(36, 160)
		rich.size = Vector2(378, 160)
		rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rich.add_theme_font_override("normal_font", fonte)
		rich.add_theme_font_size_override("normal_font_size", 28)
		rich.text = _bbcode_passiva(caneta["passiva"])
		card.add_child(rich)

		# Rótulo de ação abaixo do card, fora da rotação dele
		var rx: float = 70 + col * 490
		var ry: float = 470 + linha * 350 + 300
		if equipada:
			card.add_child(_badge_equipada(fonte))
			var lbl_uso = _label_card("EM USO  ✓", Vector2(rx, ry), Vector2(450, 52),
				fonte, 30, Color("2e7d32"), true)
			container_loja.add_child(lbl_uso)
		elif possuida:
			var lbl_eq = _label_card("[ EQUIPAR ]", Vector2(rx, ry), Vector2(450, 52),
				fonte, 32, Color("002867"), true)
			container_loja.add_child(lbl_eq)
		elif pode_pagar:
			var lbl_preco = _label_card("%d" % custo,
				Vector2(rx + 30, ry), Vector2(80, 52), FONTE_NUMEROS, 30, Color(0.5, 0.4, 0.1))
			var icone_p = _icone_card(tex_moeda, Vector2(rx + 108, ry + 6))
			var lbl_cmp = _label_card("[ COMPRAR ]",
				Vector2(rx + 155, ry), Vector2(270, 52), fonte, 30, Color("002867"))
			container_loja.add_child(lbl_preco)
			container_loja.add_child(icone_p)
			container_loja.add_child(lbl_cmp)
		else:
			var lbl_preco = _label_card("%d" % custo,
				Vector2(rx + 30, ry), Vector2(80, 52), FONTE_NUMEROS, 30, Color(0.55, 0.3, 0.3))
			var icone_p = _icone_card(tex_moeda, Vector2(rx + 108, ry + 6))
			var lbl_falta = _label_card("faltam %d" % (custo - saldo),
				Vector2(rx + 155, ry), Vector2(270, 52), FONTE_NUMEROS, 26, Color("a33d3d"))
			container_loja.add_child(lbl_preco)
			container_loja.add_child(icone_p)
			container_loja.add_child(lbl_falta)

		# Botão invisível cobrindo o card inteiro (área de toque generosa)
		var btn = Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.disabled = equipada
		card.add_child(btn)
		btn.pressed.connect(func(): _on_caneta_pressed(caneta))
		btn.button_down.connect(func(): _animar_toque_card(card, true))
		btn.button_up.connect(func(): _animar_toque_card(card, false))

## Label posicionada de um card da loja.
func _label_card(texto: String, pos: Vector2, tam: Vector2, fonte: Font,
		tamanho_fonte: int, cor: Color, centrado: bool = false) -> Label:
	var lbl = Label.new()
	lbl.text = texto
	lbl.position = pos
	lbl.size = tam
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", fonte)
	lbl.add_theme_font_size_override("font_size", tamanho_fonte)
	lbl.add_theme_color_override("font_color", cor)
	if centrado:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

## Converte a passiva em BBCode: bônus em verde, penalidade em vermelho.
func _bbcode_passiva(passiva: String) -> String:
	var linhas: Array = []
	for linha in passiva.split("\n"):
		var l: String = linha.strip_edges()
		var cor := "#59595f"
		if l.begins_with("+"):
			cor = "#2f5d3a"
		elif l.begins_with("-") or l.begins_with("−"):
			cor = "#a33d3d"
		linhas.append("[color=%s]%s[/color]" % [cor, _bbcode_numeros(l)])
	return "[center]" + "\n".join(linhas) + "[/center]"

## Envolve os números de um texto (com sinal e % opcionais, ex.: "+15%") em
## bbcode [font] apontando para a Caveat — é como frases em ArchitectsDaughter
## exibem seus algarismos na fonte numérica padrão do jogo, já que Label não
## mistura fontes (só RichTextLabel via bbcode).
var _regex_numeros: RegEx

func _bbcode_numeros(texto: String) -> String:
	if _regex_numeros == null:
		_regex_numeros = RegEx.new()
		# Espaços vizinhos entram no wrap de propósito: renderizados na Caveat
		# eles ficam mais estreitos e compensam o side bearing largo dos
		# algarismos, que descentralizava o espaçamento no meio das frases.
		_regex_numeros.compile(" ?[+\\-−]?\\d+%? ?")
	var saida := ""
	var pos := 0
	for m in _regex_numeros.search_all(texto):
		saida += texto.substr(pos, m.get_start() - pos)
		saida += "[font=%s]%s[/font]" % [CAMINHO_FONTE_NUMEROS, m.get_string()]
		pos = m.get_end()
	saida += texto.substr(pos)
	return saida

## Selo verde rotacionado no canto superior direito do card equipado.
func _badge_equipada(fonte: Font) -> Label:
	var lbl = Label.new()
	lbl.text = "EQUIPADA ✓"
	lbl.position = Vector2(300, 20)
	lbl.rotation_degrees = 2.0
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", fonte)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("2e7d32")
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 3
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 2
	sb.content_margin_bottom = 4
	lbl.add_theme_stylebox_override("normal", sb)
	return lbl

## Feedback tátil de toque: o card encolhe levemente enquanto pressionado.
func _animar_toque_card(card: Control, pressionado: bool) -> void:
	var tw = card.create_tween()
	tw.tween_property(card, "scale", Vector2.ONE * (0.96 if pressionado else 1.0), 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_caneta_pressed(caneta: Dictionary) -> void:
	var id: String = caneta["id"]
	if dados_save["caneta_equipada"] == id:
		return

	if id in dados_save["canetas_possuidas"]:
		# Já possui: apenas equipa
		dados_save["caneta_equipada"] = id
		_salvar_dados()
		_tocar_som(audio_click_sucesso)
		_atualizar_loja()
		return

	# Tenta comprar
	var comprou: bool = false
	if caneta["custo_tinta"] > 0 and dados_save["tinta"] >= caneta["custo_tinta"]:
		dados_save["tinta"] -= caneta["custo_tinta"]
		comprou = true
	elif caneta["custo_clipes"] > 0 and dados_save["clipes_ouro"] >= caneta["custo_clipes"]:
		dados_save["clipes_ouro"] -= caneta["custo_clipes"]
		comprou = true

	if comprou:
		dados_save["canetas_possuidas"].append(id)
		dados_save["caneta_equipada"] = id
		_salvar_dados()
		_tocar_som(audio_click_sucesso)
		_atualizar_loja()
	else:
		_tocar_som(audio_click_erro)
		if caneta["custo_tinta"] > 0:
			_oferecer_pacote("tinta", caneta["custo_tinta"] - dados_save["tinta"])
		elif caneta["custo_clipes"] > 0:
			_oferecer_pacote("clipes", caneta["custo_clipes"] - dados_save["clipes_ouro"])

# ============================================================
# RETENÇÃO DIÁRIA — recompensa de login e missões
# ============================================================
var botao_missoes: Button
var painel_missoes: Control
var badge_missoes: Control
var _tween_badge_missoes: Tween

## "Hoje"/"ontem" em calendário LOCAL, não UTC. get_datetime_string_from_unix_time
## não tem parâmetro de fuso e sempre converte em UTC — usar isso fazia o "dia"
## do jogo virar à meia-noite UTC (21h no Brasil, UTC-3), resetando as missões
## e zerando o progresso de quem testava/jogava à noite. get_date_string_from_system
## já devolve a data no fuso local do sistema.
func _data_de_hoje() -> String:
	return Time.get_date_string_from_system()

func _data_de_ontem() -> String:
	# Trata o relógio local como se fosse UTC só para a aritmética de dia — evita
	# reintroduzir o mesmo problema de fuso ao calcular "hoje - 1 dia".
	var pseudo_utc: int = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	return Time.get_date_string_from_unix_time(pseudo_utc - 86400)

func _verificar_recompensa_diaria() -> void:
	var hoje = _data_de_hoje()
	if dados_save["ultimo_login"] == hoje:
		return # Já logou hoje

	# Streak: continua se logou ontem, senão recomeça do dia 1
	if dados_save["ultimo_login"] == _data_de_ontem():
		dados_save["dia_streak"] = (dados_save["dia_streak"] % 7) + 1
	else:
		dados_save["dia_streak"] = 1

	dados_save["ultimo_login"] = hoje
	_salvar_dados()
	_mostrar_popup_recompensa_diaria(dados_save["dia_streak"])

func _mostrar_popup_recompensa_diaria(dia: int) -> void:
	var recompensa: Dictionary = GameData.RECOMPENSAS_DIARIAS[dia - 1]

	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	$HUD.add_child(overlay)

	var fundo = ColorRect.new()
	fundo.color = Color(0.1, 0.1, 0.15, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fundo)

	var papel = ColorRect.new()
	papel.color = Color(0.98, 0.965, 0.93)
	papel.position = Vector2(140, 560)
	papel.size = Vector2(800, 720)
	overlay.add_child(papel)

	var hbox_titulo = HBoxContainer.new()
	hbox_titulo.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_titulo.add_theme_constant_override("separation", 16)
	hbox_titulo.position = Vector2(140, 610)
	hbox_titulo.size = Vector2(800, 80)
	overlay.add_child(hbox_titulo)

	var icone_gift = TextureRect.new()
	icone_gift.texture = load("res://assets/gift-box.svg")
	icone_gift.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone_gift.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone_gift.custom_minimum_size = Vector2(52, 52)
	icone_gift.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icone_gift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox_titulo.add_child(icone_gift)

	var titulo = Label.new()
	titulo.text = "RECOMPENSA DIÁRIA"
	titulo.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	titulo.add_theme_font_size_override("font_size", 52)
	titulo.add_theme_color_override("font_color", Color("002867"))
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox_titulo.add_child(titulo)

	var lbl_dia = Label.new()
	lbl_dia.text = "Dia %d de 7 da sequência" % dia
	lbl_dia.add_theme_font_override("font", FONTE_NUMEROS)
	lbl_dia.add_theme_font_size_override("font_size", 32)
	lbl_dia.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	lbl_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dia.position = Vector2(140, 700)
	lbl_dia.size = Vector2(800, 50)
	overlay.add_child(lbl_dia)

	var hbox_premio = HBoxContainer.new()
	hbox_premio.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_premio.add_theme_constant_override("separation", 20)
	hbox_premio.position = Vector2(140, 800)
	hbox_premio.size = Vector2(800, 200)
	overlay.add_child(hbox_premio)

	if recompensa["tinta"] > 0:
		var lbl_tinta = Label.new()
		lbl_tinta.text = "+%d" % recompensa["tinta"]
		lbl_tinta.add_theme_font_override("font", FONTE_NUMEROS)
		lbl_tinta.add_theme_font_size_override("font_size", 90)
		lbl_tinta.add_theme_color_override("font_color", Color("f39c12"))
		lbl_tinta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_tinta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox_premio.add_child(lbl_tinta)

		var icone_tinta = TextureRect.new()
		icone_tinta.texture = load("res://assets/ink.svg")
		icone_tinta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone_tinta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone_tinta.custom_minimum_size = Vector2(80, 80)
		icone_tinta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icone_tinta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox_premio.add_child(icone_tinta)

	if recompensa["clipes"] > 0:
		var lbl_clipes = Label.new()
		lbl_clipes.text = "+%d" % recompensa["clipes"]
		lbl_clipes.add_theme_font_override("font", FONTE_NUMEROS)
		lbl_clipes.add_theme_font_size_override("font_size", 90)
		lbl_clipes.add_theme_color_override("font_color", Color("f39c12"))
		lbl_clipes.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_clipes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox_premio.add_child(lbl_clipes)

		var icone_clipes = TextureRect.new()
		icone_clipes.texture = load("res://assets/clip.svg")
		icone_clipes.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone_clipes.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone_clipes.custom_minimum_size = Vector2(80, 80)
		icone_clipes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icone_clipes.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox_premio.add_child(icone_clipes)

	var btn_coletar = Button.new()
	btn_coletar.text = "[ COLETAR ]"
	btn_coletar.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn_coletar.add_theme_font_size_override("font_size", 44)
	btn_coletar.add_theme_color_override("font_color", Color("002867"))
	btn_coletar.add_theme_color_override("font_hover_color", Color("0047ab"))
	btn_coletar.flat = true
	btn_coletar.position = Vector2(340, 1030)
	btn_coletar.size = Vector2(400, 80)
	overlay.add_child(btn_coletar)

	# Rewarded ad: coletar o dobro assistindo um anúncio
	var btn_dobro = Button.new()
	btn_dobro.text = "[ COLETAR EM DOBRO ]"
	btn_dobro.icon = load("res://assets/ads.svg")
	btn_dobro.add_theme_constant_override("icon_max_width", 40)
	btn_dobro.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn_dobro.add_theme_font_size_override("font_size", 40)
	btn_dobro.add_theme_color_override("font_color", Color("2e7d32"))
	btn_dobro.add_theme_color_override("font_hover_color", Color("43a047"))
	btn_dobro.flat = true
	btn_dobro.position = Vector2(240, 1130)
	btn_dobro.size = Vector2(600, 80)
	overlay.add_child(btn_dobro)

	btn_coletar.pressed.connect(func():
		dados_save["tinta"] += recompensa["tinta"]
		dados_save["clipes_ouro"] += recompensa["clipes"]
		_salvar_dados()
		_tocar_som(audio_click_sucesso)
		overlay.queue_free()
	)

	btn_dobro.pressed.connect(func():
		btn_coletar.disabled = true
		btn_dobro.disabled = true
		btn_dobro.text = "[ Carregando... ]"
		# Dicionário: lambdas copiam variáveis locais, mas compartilham o dicionário
		var cb := {}
		cb["ganhar"] = func(placement: String):
			if placement != "diaria_dobro":
				return
			AdsManager.recompensa_concedida.disconnect(cb["ganhar"])
			AdsManager.anuncio_falhou.disconnect(cb["falhar"])
			dados_save["tinta"] += recompensa["tinta"] * 2
			dados_save["clipes_ouro"] += recompensa["clipes"] * 2
			_salvar_dados()
			_tocar_som(audio_click_sucesso)
			overlay.queue_free()
		cb["falhar"] = func(placement: String):
			if placement != "diaria_dobro":
				return
			AdsManager.recompensa_concedida.disconnect(cb["ganhar"])
			AdsManager.anuncio_falhou.disconnect(cb["falhar"])
			# Sem anúncio (rede/sem estoque): libera os botões de novo
			_tocar_som(audio_click_erro)
			btn_coletar.disabled = false
			btn_dobro.disabled = false
			btn_dobro.text = "[ SEM ANÚNCIO, TENTE DEPOIS ]"
		AdsManager.recompensa_concedida.connect(cb["ganhar"])
		AdsManager.anuncio_falhou.connect(cb["falhar"])
		AdsManager.mostrar_rewarded("diaria_dobro")
	)

func _verificar_missoes_diarias() -> void:
	var hoje = _data_de_hoje()
	if dados_save["data_missoes"] == hoje and dados_save["missoes_dia"].size() > 0:
		return # Missões de hoje já sorteadas

	# Sorteia 3 missões distintas do pool, guardando a baseline das stats
	var pool = GameData.POOL_MISSOES.duplicate()
	pool.shuffle()
	var novas_missoes: Array = []
	for i in range(3):
		var def: Dictionary = pool[i]
		novas_missoes.append({
			"id": def["id"],
			"base": int(dados_save["stats"].get(def["stat"], 0)),
			"coletada": false
		})
	dados_save["missoes_dia"] = novas_missoes
	dados_save["data_missoes"] = hoje
	_salvar_dados()

func _progresso_missao(missao: Dictionary) -> int:
	var def = GameData.get_missao(missao["id"])
	if def.is_empty():
		return 0
	var atual = int(dados_save["stats"].get(def["stat"], 0))
	return clamp(atual - int(missao["base"]), 0, def["alvo"])

func _tem_missao_para_coletar() -> bool:
	for missao in dados_save["missoes_dia"]:
		if not missao["coletada"]:
			var def = GameData.get_missao(missao["id"])
			if not def.is_empty() and _progresso_missao(missao) >= def["alvo"]:
				return true
	return false

func _criar_botao_missoes() -> void:
	botao_missoes = Button.new()
	botao_missoes.text = ""
	botao_missoes.flat = true
	botao_missoes.position = Vector2(900, 200)
	botao_missoes.size = Vector2(80, 80)

	var icone = TextureRect.new()
	icone.texture = load("res://assets/tasks.svg")
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	botao_missoes.add_child(icone)

	# Bolinha de notificação desenhada à mão (sem asset), no canto superior
	# direito do ícone — ver _desenhar_badge_missoes().
	badge_missoes = Control.new()
	badge_missoes.name = "Badge"
	badge_missoes.position = Vector2(52, -6)
	badge_missoes.size = Vector2(28, 28)
	badge_missoes.pivot_offset = Vector2(14, 14)
	badge_missoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_missoes.draw.connect(func(): _desenhar_badge_missoes(badge_missoes))
	botao_missoes.add_child(badge_missoes)

	$HUD.add_child(botao_missoes)
	botao_missoes.pressed.connect(_abrir_painel_missoes)
	_atualizar_badge_missoes()

## Mostra/esconde a bolinha de "tem missão pra coletar" e liga uma pulsação
## sutil enquanto ela estiver visível — chamado ao carregar o Hub e sempre
## que uma missão é coletada (_coletar_missao).
func _atualizar_badge_missoes() -> void:
	if not badge_missoes:
		return

	var tem_pendente: bool = _tem_missao_para_coletar()
	badge_missoes.visible = tem_pendente
	badge_missoes.queue_redraw()

	if _tween_badge_missoes and _tween_badge_missoes.is_valid():
		_tween_badge_missoes.kill()
	badge_missoes.scale = Vector2.ONE

	if tem_pendente:
		_tween_badge_missoes = create_tween()
		_tween_badge_missoes.set_loops()
		_tween_badge_missoes.tween_property(badge_missoes, "scale", Vector2(1.18, 1.18), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween_badge_missoes.tween_property(badge_missoes, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Desenha a bolinha vermelha com contorno de tinta, no mesmo traço à mão do
## resto da UI (ver _desenhar_tracinhos_card no Estojo) — sem precisar de
## mais um SVG para um indicador tão simples.
func _desenhar_badge_missoes(ctrl: Control) -> void:
	var centro: Vector2 = ctrl.size / 2.0
	var raio: float = centro.x - 2.0
	ctrl.draw_circle(centro, raio, Color("a33d3d"))
	ctrl.draw_arc(centro, raio, 0, TAU, 24, Color("1a1a2e", 0.85), 2.0, true)

## Retângulo com tremido de caneta contornando as barras de progresso das
## missões. Gera pontos ao longo dos 4 lados diretamente (sem superelipse),
## resultando em cantos retos. Jitter determinístico (sin/cos por índice)
## evita o "formigamento" que randf causaria a cada redraw.
func _desenhar_moldura_manuscrita(ctrl: Control) -> void:
	var cor := Color("1a1a2e", 0.8)
	var w: float = ctrl.size.x
	var h: float = ctrl.size.y
	var m: float = 3.0
	var jitter: float = 1.3
	var pontos: PackedVector2Array = []
	var n_h: int = 24
	var n_v: int = 10
	var idx: int = 0

	for i in range(n_h): # Topo: esq → dir
		var t: float = float(i) / (n_h - 1)
		pontos.append(Vector2(
			m + t * (w - 2.0 * m) + sin(idx * 7.31) * jitter,
			m + cos(idx * 5.17) * jitter))
		idx += 1

	for i in range(n_v): # Direita: cima → baixo
		var t: float = float(i) / (n_v - 1)
		pontos.append(Vector2(
			w - m + sin(idx * 7.31) * jitter,
			m + t * (h - 2.0 * m) + cos(idx * 5.17) * jitter))
		idx += 1

	for i in range(n_h): # Base: dir → esq
		var t: float = float(i) / (n_h - 1)
		pontos.append(Vector2(
			(w - m) - t * (w - 2.0 * m) + sin(idx * 7.31) * jitter,
			h - m + cos(idx * 5.17) * jitter))
		idx += 1

	for i in range(n_v): # Esquerda: baixo → cima
		var t: float = float(i) / (n_v - 1)
		pontos.append(Vector2(
			m + sin(idx * 7.31) * jitter,
			(h - m) - t * (h - 2.0 * m) + cos(idx * 5.17) * jitter))
		idx += 1

	pontos.append(pontos[0])
	ctrl.draw_polyline(pontos, cor, 3.5, true)

## Círculo de caneta azul em volta do número da missão. Dá uma volta e um
## pouco mais (1.12 × TAU) com raio levemente variável, imitando o gesto de
## circular um número à mão — jitter determinístico como nas outras molduras.
func _desenhar_circulo_numero(ctrl: Control) -> void:
	var cor := Color("0047ab", 0.9)
	var centro: Vector2 = ctrl.size / 2.0
	var raio_base: float = centro.x - 4.0
	var pontos: PackedVector2Array = []
	var n: int = 40

	for i in range(n + 1):
		var t: float = float(i) / n * TAU * 1.12 - 0.4
		var raio: float = raio_base + sin(i * 7.31) * 1.2 + float(i) / n * 1.5
		pontos.append(centro + Vector2(cos(t), sin(t)) * raio)

	ctrl.draw_polyline(pontos, cor, 3.0, true)

func _abrir_painel_missoes() -> void:
	_tocar_som(audio_click_sucesso)

	if painel_missoes:
		painel_missoes.queue_free()

	painel_missoes = Control.new()
	painel_missoes.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_missoes.z_index = 100
	$HUD.add_child(painel_missoes)

	var fundo = ColorRect.new()
	fundo.color = Color(0.1, 0.1, 0.15, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel_missoes.add_child(fundo)

	# Card geral da aba, no lugar do retângulo branco liso. Tamanho ajustado
	# para bater com a proporção nativa do SVG (538.5×662.25 ≈ 0,813:1) sem
	# distorcer o desenho — por isso não é preciso alterar o arquivo.
	var papel = TextureRect.new()
	papel.texture = load("res://assets/background-missoes.svg")
	papel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	papel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	papel.position = Vector2(90, 387)
	papel.size = Vector2(900, 1107)
	painel_missoes.add_child(papel)

	var titulo = Label.new()
	titulo.text = "📋 MISSÕES DE HOJE"
	titulo.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	titulo.add_theme_font_size_override("font_size", 52)
	titulo.add_theme_color_override("font_color", Color("002867"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(90, 490)
	titulo.size = Vector2(900, 80)
	painel_missoes.add_child(titulo)

	# Linhas das 3 missões
	for i in range(dados_save["missoes_dia"].size()):
		var missao: Dictionary = dados_save["missoes_dia"][i]
		var def: Dictionary = GameData.get_missao(missao["id"])
		if def.is_empty():
			continue

		var y_base = 630 + i * 230

		# Card de fundo desenhado à mão, um por missão, atrás de todo o
		# conteúdo da linha — ver nota de proporção ideal do SVG no final
		# da implementação (proporção nativa não bate com o card 820×210).
		var card_fundo = TextureRect.new()
		card_fundo.texture = load("res://assets/card-missoes.svg")
		card_fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_fundo.position = Vector2(130, y_base - 25)
		card_fundo.size = Vector2(820, 210)
		card_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		painel_missoes.add_child(card_fundo)

		# Círculo numerado à mão no canto esquerdo do card, identificando a
		# missão (1, 2, 3) — mesmo traço azul de caneta do resto da UI.
		var circulo_num = Control.new()
		circulo_num.position = Vector2(160, y_base - 5)
		circulo_num.size = Vector2(60, 60)
		circulo_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circulo_num.draw.connect(func(): _desenhar_circulo_numero(circulo_num))
		painel_missoes.add_child(circulo_num)

		var lbl_num = Label.new()
		lbl_num.text = str(i + 1)
		lbl_num.add_theme_font_override("font", FONTE_NUMEROS)
		lbl_num.add_theme_font_size_override("font_size", 34)
		lbl_num.add_theme_color_override("font_color", Color("0047ab"))
		lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Nudge à direita: os algarismos da Caveat têm bearing esquerdo largo
		# que desloca o glifo do centro óptico do círculo.
		lbl_num.position = circulo_num.position + Vector2(-4, 0)
		lbl_num.size = circulo_num.size
		painel_missoes.add_child(lbl_num)

		_montar_card_missao(i, missao, def, y_base, card_fundo)

	# Botão fechar
	var btn_fechar = Button.new()
	btn_fechar.text = "[ FECHAR ]"
	btn_fechar.add_theme_font_override("font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	btn_fechar.add_theme_font_size_override("font_size", 40)
	btn_fechar.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	btn_fechar.add_theme_color_override("font_hover_color", Color(0.85, 0.1, 0.1))
	btn_fechar.flat = true
	btn_fechar.position = Vector2(340, 1330)
	btn_fechar.size = Vector2(400, 80)
	painel_missoes.add_child(btn_fechar)
	btn_fechar.pressed.connect(func():
		painel_missoes.queue_free()
		painel_missoes = null
	)

## Monta o conteúdo de um card de missão (layout "limpo", escolhido em 27/10):
## em andamento mostra título, barra e recompensa; completa vira título +
## botão verde (o card inteiro também resgata); recebida mostra só o título e
## um selo vazado. O card de fundo e o número já foram criados.
func _montar_card_missao(i: int, missao: Dictionary, def: Dictionary, y_base: float, card_fundo: Control) -> void:
	var progresso: int = _progresso_missao(missao)
	var completa: bool = progresso >= def["alvo"]
	var coletada: bool = missao["coletada"]
	var recompensa_txt := ""
	if def["tinta"] > 0:
		recompensa_txt = "+%d tinta" % def["tinta"]
	if def["clipes"] > 0:
		recompensa_txt += (" " if recompensa_txt != "" else "") + "+%d clipes" % def["clipes"]

	var lbl_desc = RichTextLabel.new()
	lbl_desc.bbcode_enabled = true
	lbl_desc.scroll_active = false
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_desc.add_theme_font_override("normal_font", load("res://assets/fonts/ArchitectsDaughter-Regular.ttf"))
	lbl_desc.add_theme_font_size_override("normal_font_size", 36)
	lbl_desc.add_theme_color_override("default_color", Color(0.2, 0.2, 0.25))
	lbl_desc.text = "[center]" + _bbcode_numeros(def["desc"]) + "[/center]"
	lbl_desc.position = Vector2(150, y_base)
	lbl_desc.size = Vector2(780, 50)
	painel_missoes.add_child(lbl_desc)

	# Barra + contador só enquanto a missão está em andamento. Grupo de 580 px
	# (barra 500 + contador) centrado no card.
	if not completa:
		var moldura = Control.new()
		moldura.position = Vector2(242, y_base + 52)
		moldura.size = Vector2(516, 46)
		moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moldura.draw.connect(func(): _desenhar_moldura_manuscrita(moldura))
		painel_missoes.add_child(moldura)
		var barra = TextureProgressBar.new()
		barra.texture_under = load("res://assets/texture_progress.svg")
		barra.texture_progress = load("res://assets/texture_progress.svg")
		barra.tint_under = Color(0.63, 0.63, 0.66, 0.5)
		barra.tint_progress = Color("0047ab")
		barra.nine_patch_stretch = true
		barra.max_value = def["alvo"]
		barra.value = progresso
		barra.position = Vector2(250, y_base + 60)
		barra.size = Vector2(500, 30)
		barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		painel_missoes.add_child(barra)
		var lbl_prog = Label.new()
		lbl_prog.text = "%d / %d" % [progresso, def["alvo"]]
		lbl_prog.add_theme_font_override("font", FONTE_NUMEROS)
		lbl_prog.add_theme_font_size_override("font_size", 34)
		lbl_prog.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		lbl_prog.position = Vector2(766, y_base + 52)
		lbl_prog.size = Vector2(110, 44)
		painel_missoes.add_child(lbl_prog)

	var btn = Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", FONTE_NUMEROS)
	var cor_fundo := Color(0, 0, 0, 0)
	var cor_borda := Color(0, 0, 0, 0)
	var borda: int = 3
	if coletada:
		# Selo vazado: só o traço, fundo transparente, mais estreito que o botão
		btn.text = "✓ RECEBIDO"
		btn.disabled = true
		btn.add_theme_font_size_override("font_size", 34)
		btn.add_theme_color_override("font_disabled_color", Color(0.42, 0.42, 0.46))
		btn.position = Vector2(390, y_base + 66)
		btn.size = Vector2(300, 60)
		cor_borda = Color(0.42, 0.42, 0.46, 0.8)
		borda = 2
	elif completa:
		btn.text = "✓  COLETAR " + recompensa_txt
		btn.add_theme_font_size_override("font_size", 38)
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			btn.add_theme_color_override(c, Color.WHITE)
		btn.position = Vector2(250, y_base + 62)
		btn.size = Vector2(580, 72)
		cor_fundo = Color("2e7d32")
		cor_borda = Color("1a1a2e", 0.6)
		var indice = i
		btn.pressed.connect(func(): _coletar_missao(indice))
		var card_toque = Button.new()
		card_toque.flat = true
		card_toque.focus_mode = Control.FOCUS_NONE
		card_toque.position = card_fundo.position
		card_toque.size = card_fundo.size
		card_toque.pressed.connect(func(): _coletar_missao(indice))
		painel_missoes.add_child(card_toque)
		painel_missoes.move_child(card_toque, card_fundo.get_index() + 1)
	else:
		btn.text = "Recompensa: " + recompensa_txt
		btn.disabled = true
		btn.add_theme_font_size_override("font_size", 40)
		btn.add_theme_color_override("font_disabled_color", Color(0.48, 0.42, 0.26))
		btn.position = Vector2(250, y_base + 100)
		btn.size = Vector2(580, 58)
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = cor_fundo.darkened(0.15) if estado == "pressed" else cor_fundo
		estilo.border_color = cor_borda
		estilo.set_border_width_all(borda)
		estilo.set_corner_radius_all(16)
		btn.add_theme_stylebox_override(estado, estilo)
	painel_missoes.add_child(btn)

func _coletar_missao(indice: int) -> void:
	var missao: Dictionary = dados_save["missoes_dia"][indice]
	var def: Dictionary = GameData.get_missao(missao["id"])
	if def.is_empty() or missao["coletada"]:
		return

	dados_save["tinta"] += def["tinta"]
	dados_save["clipes_ouro"] += def["clipes"]
	missao["coletada"] = true
	_salvar_dados()
	_tocar_som(audio_click_sucesso)
	_atualizar_badge_missoes()
	_abrir_painel_missoes() # Reconstrói o painel atualizado

# ============================================================
# CONFIGURAÇÕES (som / vibração)
# ============================================================
func _criar_botao_config() -> void:
	var btn = Button.new()
	btn.text = ""
	btn.flat = true
	# Margem esquerda de 100 espelha a do botão de missões (x 900..980 → 100 da borda direita)
	btn.position = Vector2(100, 200)
	btn.size = Vector2(80, 80)

	var icone = TextureRect.new()
	icone.texture = load("res://assets/config.svg")
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icone)

	$HUD.add_child(btn)
	btn.pressed.connect(_abrir_painel_config)

func _abrir_painel_config() -> void:
	_tocar_som(audio_click_sucesso)

	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	$HUD.add_child(overlay)

	var fundo = ColorRect.new()
	fundo.color = Color(0.1, 0.1, 0.15, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fundo)

	var papel = ColorRect.new()
	papel.color = Color(0.98, 0.965, 0.93)
	papel.size = Vector2(800, 640)
	papel.set_anchors_preset(Control.PRESET_CENTER)
	papel.position = -papel.size / 2.0
	overlay.add_child(papel)

	var fonte = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")
	var tex_config2 = load("res://assets/config2.svg")
	var tex_volume  = load("res://assets/volume.svg")
	var tex_vibrate = load("res://assets/vibrate.svg")

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 40
	vbox.offset_top = 60
	vbox.offset_right = -40
	vbox.offset_bottom = -60
	vbox.add_theme_constant_override("separation", 35)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	papel.add_child(vbox)

	# Header (HBoxContainer) com Ícone + Título
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 20)
	vbox.add_child(header)

	var icone_titulo = TextureRect.new()
	icone_titulo.texture = tex_config2
	icone_titulo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone_titulo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone_titulo.custom_minimum_size = Vector2(72, 72)
	header.add_child(icone_titulo)

	var titulo = Label.new()
	titulo.text = "CONFIGURAÇÕES"
	titulo.add_theme_font_override("font", fonte)
	titulo.add_theme_font_size_override("font_size", 52)
	titulo.add_theme_color_override("font_color", Color("002867"))
	header.add_child(titulo)

	# Botão de Som
	var btn_som = Button.new()
	btn_som.icon = tex_volume
	btn_som.add_theme_font_override("font", fonte)
	btn_som.add_theme_font_size_override("font_size", 40)
	btn_som.add_theme_color_override("font_color", Color("002867"))
	btn_som.add_theme_color_override("font_hover_color", Color("0047ab"))
	btn_som.add_theme_constant_override("icon_max_width", 52)
	btn_som.flat = true
	btn_som.custom_minimum_size = Vector2(500, 80)
	btn_som.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_som)

	# Botão de Vibração
	var btn_vibracao = Button.new()
	btn_vibracao.icon = tex_vibrate
	btn_vibracao.add_theme_font_override("font", fonte)
	btn_vibracao.add_theme_font_size_override("font_size", 40)
	btn_vibracao.add_theme_color_override("font_color", Color("002867"))
	btn_vibracao.add_theme_color_override("font_hover_color", Color("0047ab"))
	btn_vibracao.add_theme_constant_override("icon_max_width", 52)
	btn_vibracao.flat = true
	btn_vibracao.custom_minimum_size = Vector2(500, 80)
	btn_vibracao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_vibracao)

	var atualizar_textos = func():
		btn_som.text = "[ SOM: %s ]" % ("LIGADO" if dados_save.get("som_ativo", true) else "DESLIGADO")
		btn_vibracao.text = "[ VIBRAÇÃO: %s ]" % ("LIGADA" if dados_save.get("vibracao_ativa", true) else "DESLIGADA")
	atualizar_textos.call()

	btn_som.pressed.connect(func():
		dados_save["som_ativo"] = not dados_save.get("som_ativo", true)
		_salvar_dados()
		_tocar_som(audio_click_sucesso)
		atualizar_textos.call()
	)

	btn_vibracao.pressed.connect(func():
		dados_save["vibracao_ativa"] = not dados_save.get("vibracao_ativa", true)
		_salvar_dados()
		_tocar_som(audio_click_sucesso)
		atualizar_textos.call()
	)

	# Botão Stats de Teste (telemetria de baseline — testadores tiram print)
	var btn_stats = Button.new()
	btn_stats.text = "[ STATS DE TESTE ]"
	btn_stats.add_theme_font_override("font", fonte)
	btn_stats.add_theme_font_size_override("font_size", 40)
	btn_stats.add_theme_color_override("font_color", Color("002867"))
	btn_stats.add_theme_color_override("font_hover_color", Color("0047ab"))
	btn_stats.flat = true
	btn_stats.custom_minimum_size = Vector2(500, 80)
	btn_stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_stats)
	btn_stats.pressed.connect(_abrir_painel_stats)
	btn_stats.visible = GameData.MODO_TESTE

	# Botão Fechar
	var btn_fechar = Button.new()
	btn_fechar.text = "[ FECHAR ]"
	btn_fechar.add_theme_font_override("font", fonte)
	btn_fechar.add_theme_font_size_override("font_size", 40)
	btn_fechar.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	btn_fechar.add_theme_color_override("font_hover_color", Color(0.85, 0.1, 0.1))
	btn_fechar.flat = true
	btn_fechar.custom_minimum_size = Vector2(300, 80)
	btn_fechar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_fechar)
	btn_fechar.pressed.connect(overlay.queue_free)

## Painel de telemetria de baseline (P0). Read-only, pensado para o testador
## tirar um print e enviar. O botão ZERAR limpa apenas os contadores de
## telemetria — nunca o progresso (tinta/nível/capítulos).
func _abrir_painel_stats() -> void:
	_tocar_som(audio_click_sucesso)

	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 101
	$HUD.add_child(overlay)

	var fundo = ColorRect.new()
	fundo.color = Color(0.1, 0.1, 0.15, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fundo)

	var papel = ColorRect.new()
	papel.color = Color(0.98, 0.965, 0.93)
	papel.size = Vector2(820, 1280)
	papel.set_anchors_preset(Control.PRESET_CENTER)
	papel.position = -papel.size / 2.0
	overlay.add_child(papel)

	var fonte = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 50
	vbox.offset_top = 55
	vbox.offset_right = -50
	vbox.offset_bottom = -55
	vbox.add_theme_constant_override("separation", 22)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	papel.add_child(vbox)

	var titulo = Label.new()
	titulo.text = "STATS DE TESTE"
	titulo.add_theme_font_override("font", fonte)
	titulo.add_theme_font_size_override("font_size", 52)
	titulo.add_theme_color_override("font_color", Color("002867"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	var sub = Label.new()
	sub.text = "Tire um print e me envie 🙏"
	sub.add_theme_font_override("font", fonte)
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	# Calcula as métricas de baseline a partir dos contadores acumulados
	var s: Dictionary = SaveManager.dados["stats"]
	var partidas: int = s.get("partidas_jogadas", 0)
	var div: int = max(1, partidas)
	var coletadas: int = s.get("gotas_coletadas", 0)
	var secas: int = s.get("gotas_secas", 0)
	var total_gotas: int = coletadas + secas
	var taxa_seca: float = (float(secas) / float(total_gotas) * 100.0) if total_gotas > 0 else 0.0

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(grid)

	# Atalho de teste: abre a partida direto no chefe do capítulo
	# Botões compactos em 2 linhas de 5 (a caixa tem altura fixa)
	var caixa_chefes = VBoxContainer.new()
	caixa_chefes.add_theme_constant_override("separation", 0)
	vbox.add_child(caixa_chefes)
	var caps: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
	for linha_i in 2:
		var linha_chefes = HBoxContainer.new()
		linha_chefes.alignment = BoxContainer.ALIGNMENT_CENTER
		linha_chefes.add_theme_constant_override("separation", 6)
		caixa_chefes.add_child(linha_chefes)
		if linha_i == 0:
			var lbl_chefe = Label.new()
			lbl_chefe.text = "Chefe:"
			lbl_chefe.add_theme_font_override("font", fonte)
			lbl_chefe.add_theme_font_size_override("font_size", 34)
			lbl_chefe.add_theme_color_override("font_color", Color("002867"))
			linha_chefes.add_child(lbl_chefe)
		for cap in caps.slice(linha_i * 5, linha_i * 5 + 5):
			var b = Button.new()
			b.text = "[%d]" % cap
			b.flat = true
			b.add_theme_font_override("font", fonte)
			b.add_theme_font_size_override("font_size", 36)
			b.add_theme_color_override("font_color", Color("c0392b"))
			linha_chefes.add_child(b)
			b.pressed.connect(func():
				SaveManager.teste_chefe = cap
				_on_botao_jogar_pressed()
			)

	var linhas = [
		["Partidas jogadas", str(partidas)],
		["Tinta / run", "%.0f" % (float(s.get("tinta_coletada_total", 0)) / div)],
		["Kills / run", "%.1f" % (float(s.get("monstros_derrotados", 0)) / div)],
		["Duração / run", "%ds" % int(float(s.get("tempo_jogado_seg", 0)) / div)],
		["Gota seca", "%.0f%%" % taxa_seca],
		["Gotas (peguei / secou)", "%d / %d" % [coletadas, secas]],
	]
	for linha in linhas:
		var lbl_nome = Label.new()
		lbl_nome.text = linha[0]
		lbl_nome.add_theme_font_override("font", fonte)
		lbl_nome.add_theme_font_size_override("font_size", 34)
		lbl_nome.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		grid.add_child(lbl_nome)

		var lbl_valor = Label.new()
		lbl_valor.text = linha[1]
		lbl_valor.add_theme_font_override("font", fonte)
		lbl_valor.add_theme_font_size_override("font_size", 34)
		lbl_valor.add_theme_color_override("font_color", Color("002867"))
		lbl_valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_valor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(lbl_valor)

	# Vitórias e derrotas por capítulo (só partidas normais; o atalho de teste
	# não conta). "chefe" = derrotas na página do chefe.
	var por_cap: Dictionary = s.get("por_capitulo", {})
	var lbl_caps = Label.new()
	if por_cap.is_empty():
		lbl_caps.text = "Por capítulo: ainda sem partidas"
	else:
		var partes: Array = []
		for cap in range(1, 11):
			if por_cap.has(str(cap)):
				var c: Array = por_cap[str(cap)]
				partes.append("C%d: %dV %dD (%d chefe)" % [cap, int(c[0]), int(c[1]), int(c[2])])
		var linhas_cap: Array = []
		for i in range(0, partes.size(), 2):
			linhas_cap.append("   ".join(partes.slice(i, i + 2)))
		lbl_caps.text = "\n".join(linhas_cap)
	lbl_caps.add_theme_font_override("font", fonte)
	lbl_caps.add_theme_font_size_override("font_size", 26)
	lbl_caps.add_theme_color_override("font_color", Color("002867"))
	lbl_caps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_caps)

	# Botão Zerar (só telemetria) — com confirmação em dois toques
	var btn_zerar = Button.new()
	btn_zerar.text = "[ ZERAR ]"
	btn_zerar.add_theme_font_override("font", fonte)
	btn_zerar.add_theme_font_size_override("font_size", 32)
	btn_zerar.add_theme_color_override("font_color", Color(0.55, 0.35, 0.1))
	btn_zerar.add_theme_color_override("font_hover_color", Color(0.8, 0.45, 0.1))
	btn_zerar.flat = true
	btn_zerar.custom_minimum_size = Vector2(400, 70)
	btn_zerar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_zerar)
	var zerar_armado := {"v": false}
	btn_zerar.pressed.connect(func():
		if not zerar_armado["v"]:
			zerar_armado["v"] = true
			btn_zerar.text = "[ TOQUE DE NOVO P/ ZERAR ]"
			return
		for chave in ["partidas_jogadas", "monstros_derrotados", "tinta_coletada_total", "gotas_coletadas", "gotas_secas", "tempo_jogado_seg"]:
			SaveManager.dados["stats"][chave] = 0
		SaveManager.dados["stats"]["por_capitulo"] = {}
		_salvar_dados()
		_tocar_som(audio_click_sucesso)
		overlay.queue_free()
		_abrir_painel_stats()
	)

	# Teste: volta Dano, Corações e Cadência do Estojo ao nível 1 (a tinta
	# gasta não volta). Também pede confirmação com um segundo toque.
	var btn_estojo = Button.new()
	btn_estojo.text = "[ ZERAR ESTOJO ]"
	btn_estojo.add_theme_font_override("font", fonte)
	btn_estojo.add_theme_font_size_override("font_size", 32)
	btn_estojo.add_theme_color_override("font_color", Color(0.55, 0.35, 0.1))
	btn_estojo.add_theme_color_override("font_hover_color", Color(0.8, 0.45, 0.1))
	btn_estojo.flat = true
	btn_estojo.custom_minimum_size = Vector2(400, 70)
	btn_estojo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_estojo)
	var estojo_armado := {"v": false}
	btn_estojo.pressed.connect(func():
		if not estojo_armado["v"]:
			estojo_armado["v"] = true
			btn_estojo.text = "[ TOQUE DE NOVO P/ ZERAR ESTOJO ]"
			return
		for chave in ["nivel_dano", "nivel_hp", "nivel_cadencia"]:
			dados_save[chave] = 1
		_salvar_dados()
		_atualizar_ui_upgrades()
		_tocar_som(audio_click_sucesso)
		btn_estojo.text = "[ ESTOJO ZERADO ✓ ]"
		btn_estojo.disabled = true
	)

	var btn_fechar = Button.new()
	btn_fechar.text = "[ FECHAR ]"
	btn_fechar.add_theme_font_override("font", fonte)
	btn_fechar.add_theme_font_size_override("font_size", 40)
	btn_fechar.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	btn_fechar.add_theme_color_override("font_hover_color", Color(0.85, 0.1, 0.1))
	btn_fechar.flat = true
	btn_fechar.custom_minimum_size = Vector2(300, 80)
	btn_fechar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_fechar)
	btn_fechar.pressed.connect(overlay.queue_free)

# Save/Load agora centralizado no autoload SaveManager
func _salvar_dados() -> void:
	SaveManager.salvar()

func _tocar_som(stream: AudioStream) -> void:
	if stream == null or not SaveManager.dados.get("som_ativo", true):
		return
	var p = AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func _gerar_som_procedural(frequencia: float, duracao: float, tipo: String = "sin") -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 44100
	wav.stereo = false
	
	var num_amostras = int(44100 * duracao)
	var dados = PackedByteArray()
	dados.resize(num_amostras * 2)
	
	for i in range(num_amostras):
		var tempo = float(i) / 44100.0
		var valor: int = 0
		
		if tipo == "sin":
			var volume = exp(-tempo * 30.0)
			var amplitude = 28000.0 * volume
			valor = int(sin(tempo * frequencia * 2.0 * PI) * amplitude)
		elif tipo == "square":
			var volume = exp(-tempo * 10.0)
			var amplitude = 12000.0 * volume
			var sin_val = sin(tempo * frequencia * 2.0 * PI)
			valor = int((1.0 if sin_val >= 0 else -1.0) * amplitude)
			
		dados.encode_s16(i * 2, valor)
		
	wav.data = dados
	return wav
