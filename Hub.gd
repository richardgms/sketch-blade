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
var item_sendo_comprado: String = "clipes" # "clipes" ou "tinta"

# Áudio procedural
var audio_click_sucesso: AudioStreamWAV
var audio_click_erro: AudioStreamWAV

func _adicionar_sublinhado(parent: Control, y_top: float, meio_largura: float) -> void:
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
	_adicionar_sublinhado(tela_loja,   448.0, 300.0)

	# Conteúdo do Estojo desce para abrir espaço após o sublinhado
	var shift := 80.0
	for c in [container_dano, container_hp, container_cadencia]:
		c.offset_top  += shift
		c.offset_bottom += shift

	# Conteúdo da TelaLutar desce para abrir espaço após o sublinhado
	var shift_lutar := 70.0
	for label_node in [$HUD/TelaLutar/NomeCapitulo, $HUD/TelaLutar/DificuldadeLabel]:
		label_node.offset_top    += shift_lutar
		label_node.offset_bottom += shift_lutar

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
	xp_bar_tex.tint_progress = Color("0549b4")
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
	lbl_xp_texto.add_theme_font_size_override("font_size", 28)
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
	botao_comprar_tinta.pressed.connect(func(): _abrir_popup_compra("tinta"))
	botao_comprar_clipes.pressed.connect(func(): _abrir_popup_compra("clipes"))
	botao_confirmar_compra.pressed.connect(_on_confirmar_compra_pressed)
	botao_cancelar_compra.pressed.connect(_on_cancelar_compra_pressed)
	
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
	
	# Aplica visual do caderno dinamicamente no Hub
	if has_node("Paper"):
		$Paper.configurar_para_capitulo(cap_sel)

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

# Lógica IAP Sandbox
func _abrir_popup_compra(tipo: String) -> void:
	item_sendo_comprado = tipo
	_tocar_som(audio_click_sucesso)
	
	if tipo == "clipes":
		popup_titulo.text = "Comprar Clipes"
		popup_descricao.text = "Deseja comprar 100 Clipes de Ouro por R$ 4,90 para apoiar o desenvolvimento do Sketch Blade?"
	else:
		popup_titulo.text = "Comprar Tintas"
		popup_descricao.text = "Deseja comprar 5.000 Gotas de Tinta por R$ 4,90 para dar carga rápida no seu estojo?"
		
	popup_compra.visible = true
	if desenho_hub:
		desenho_hub.queue_redraw()

func _on_confirmar_compra_pressed() -> void:
	_tocar_som(audio_click_sucesso)
	
	if item_sendo_comprado == "clipes":
		dados_save["clipes_ouro"] += 100
	else:
		dados_save["tinta"] += 5000

	_salvar_dados()
	_atualizar_ui_upgrades() # Tinta nova pode liberar botões do Estojo
	popup_compra.visible = false
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
	lbl_falta.add_theme_font_size_override("font_size", 26)

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

	var cap: int = clamp(int(snap.get("capitulo", 1)), 1, nomes_capitulos.size() - 1)
	var pagina: int = int(snap.get("pagina", 1))
	var total_paginas: int = GameData.PAGINAS.size()

	var overlay = Control.new()
	overlay.name = "PromptRetomarRun"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	$HUD.add_child(overlay)

	var fundo = ColorRect.new()
	fundo.color = Color(0.98, 0.965, 0.93, 0.96)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fundo)

	var fonte_texto = load("res://assets/fonts/ArchitectsDaughter-Regular.ttf")

	var titulo = Label.new()
	titulo.text = "✏️ RUN EM ANDAMENTO"
	titulo.add_theme_font_override("font", fonte_texto)
	titulo.add_theme_font_size_override("font_size", 60)
	titulo.add_theme_color_override("font_color", Color("002867"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 560)
	titulo.size = Vector2(1080, 120)
	overlay.add_child(titulo)

	var sub = Label.new()
	sub.text = "Você parou no Capítulo %d — Página %d/%d.\nDeseja continuar de onde parou?" % [cap, pagina, total_paginas]
	sub.add_theme_font_override("font", fonte_texto)
	sub.add_theme_font_size_override("font_size", 36)
	sub.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 700)
	sub.size = Vector2(1080, 140)
	overlay.add_child(sub)

	var btn_continuar = Button.new()
	btn_continuar.text = "[ CONTINUAR RUN ]"
	btn_continuar.add_theme_font_override("font", fonte_texto)
	btn_continuar.add_theme_font_size_override("font_size", 52)
	btn_continuar.add_theme_color_override("font_color", Color("2e7d32"))
	btn_continuar.add_theme_color_override("font_hover_color", Color("43a047"))
	btn_continuar.flat = true
	btn_continuar.position = Vector2(240, 900)
	btn_continuar.size = Vector2(600, 90)
	overlay.add_child(btn_continuar)
	btn_continuar.pressed.connect(func():
		_tocar_som(audio_click_sucesso)
		SaveManager.retomar_run_pendente = true
		get_tree().change_scene_to_file("res://main.tscn")
	)

	var btn_descartar = Button.new()
	btn_descartar.text = "[ DESCARTAR ]"
	btn_descartar.add_theme_font_override("font", fonte_texto)
	btn_descartar.add_theme_font_size_override("font_size", 36)
	btn_descartar.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	btn_descartar.add_theme_color_override("font_hover_color", Color(0.85, 0.1, 0.1))
	btn_descartar.flat = true
	btn_descartar.position = Vector2(340, 1050)
	btn_descartar.size = Vector2(400, 80)
	overlay.add_child(btn_descartar)
	btn_descartar.pressed.connect(func():
		_tocar_som(audio_click_erro)
		SaveManager.limpar_run_snapshot()
		overlay.queue_free()
	)

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
	tela_loja.add_child(container_loja)
	_atualizar_loja()

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
		rich.add_theme_font_size_override("normal_font_size", 27)
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
	btn_coletar.add_theme_color_override("font_hover_color", Color("0044cc"))
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
		var callback = func(placement: String):
			if placement == "diaria_dobro":
				dados_save["tinta"] += recompensa["tinta"] * 2
				dados_save["clipes_ouro"] += recompensa["clipes"] * 2
				_salvar_dados()
				_tocar_som(audio_click_sucesso)
				overlay.queue_free()
		AdsManager.recompensa_concedida.connect(callback, CONNECT_ONE_SHOT)
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
	var cor := Color("0549b4", 0.9)
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
		lbl_num.add_theme_color_override("font_color", Color("0549b4"))
		lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Nudge à direita: os algarismos da Caveat têm bearing esquerdo largo
		# que desloca o glifo do centro óptico do círculo.
		lbl_num.position = circulo_num.position + Vector2(-4, 0)
		lbl_num.size = circulo_num.size
		painel_missoes.add_child(lbl_num)

		# Título centralizado no card (rect 150..930 tem o mesmo centro do
		# card de fundo, x = 540). RichTextLabel para os números da frase
		# saírem em Caveat (ver _bbcode_numeros).
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

		var progresso = _progresso_missao(missao)
		var completa = progresso >= def["alvo"]

		# Moldura manuscrita em volta da barra (geometria simples: código;
		# só a textura orgânica do rabisco vem de asset)
		# Grupo barra (500) + gap + contador "x/x" (~60) centrado no card:
		# largura total ~580 → barra começa em x = 540 - 290 = 250
		var moldura = Control.new()
		moldura.position = Vector2(242, y_base + 52)
		moldura.size = Vector2(516, 46)
		moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moldura.draw.connect(func(): _desenhar_moldura_manuscrita(moldura))
		painel_missoes.add_child(moldura)

		# Mesmo rabisco da barra de XP do header (texture_progress.svg é uma
		# máscara branca tintável): trilha cinza por baixo, preenchimento azul
		# enquanto anda e verde quando a missão está completa.
		var barra = TextureProgressBar.new()
		barra.texture_under = load("res://assets/texture_progress.svg")
		barra.texture_progress = load("res://assets/texture_progress.svg")
		barra.tint_under = Color(0.63, 0.63, 0.66, 0.5)
		barra.tint_progress = Color("2e7d32") if completa else Color("0549b4")
		barra.nine_patch_stretch = true
		barra.max_value = def["alvo"]
		barra.value = progresso
		barra.position = Vector2(250, y_base + 60)
		barra.size = Vector2(500, 30)
		painel_missoes.add_child(barra)

		var lbl_prog = Label.new()
		lbl_prog.text = "%d / %d" % [progresso, def["alvo"]]
		lbl_prog.add_theme_font_override("font", FONTE_NUMEROS)
		lbl_prog.add_theme_font_size_override("font_size", 28)
		lbl_prog.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		lbl_prog.position = Vector2(770, y_base + 55)
		lbl_prog.size = Vector2(150, 40)
		painel_missoes.add_child(lbl_prog)

		# Carimbo de check no canto inferior direito quando a missão foi
		# concluída (SVG quadrado 144×144, escala sem distorção).
		if completa:
			var check = TextureRect.new()
			check.texture = load("res://assets/check.svg")
			check.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			check.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			check.position = Vector2(840, y_base + 68)
			check.size = Vector2(90, 90)
			check.mouse_filter = Control.MOUSE_FILTER_IGNORE
			painel_missoes.add_child(check)

		var recompensa_txt = ""
		if def["tinta"] > 0:
			recompensa_txt = "+%d tinta" % def["tinta"]
		if def["clipes"] > 0:
			recompensa_txt += " +%d clipes" % def["clipes"]

		var btn_missao = Button.new()
		btn_missao.add_theme_font_override("font", FONTE_NUMEROS)
		btn_missao.add_theme_font_size_override("font_size", 30)
		btn_missao.flat = true
		# Centrado no card como o resto da coluna (texto de Button flat já
		# centraliza dentro do próprio rect)
		btn_missao.position = Vector2(290, y_base + 105)
		btn_missao.size = Vector2(500, 55)

		if missao["coletada"]:
			btn_missao.text = "[ RECEBIDO ✓ ]"
			btn_missao.disabled = true
			btn_missao.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
		elif completa:
			btn_missao.text = "[ COLETAR %s ]" % recompensa_txt
			btn_missao.add_theme_color_override("font_color", Color("2e7d32"))
			btn_missao.add_theme_color_override("font_hover_color", Color("43a047"))
			var indice = i
			btn_missao.pressed.connect(func(): _coletar_missao(indice))
		else:
			btn_missao.text = "Recompensa: %s" % recompensa_txt
			btn_missao.disabled = true
			btn_missao.add_theme_color_override("font_disabled_color", Color(0.55, 0.5, 0.35))

		painel_missoes.add_child(btn_missao)

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
	btn_som.add_theme_color_override("font_hover_color", Color("0044cc"))
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
	btn_vibracao.add_theme_color_override("font_hover_color", Color("0044cc"))
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
	btn_stats.add_theme_color_override("font_hover_color", Color("0044cc"))
	btn_stats.flat = true
	btn_stats.custom_minimum_size = Vector2(500, 80)
	btn_stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn_stats)
	btn_stats.pressed.connect(_abrir_painel_stats)

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
	papel.size = Vector2(820, 900)
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
		_salvar_dados()
		_tocar_som(audio_click_sucesso)
		overlay.queue_free()
		_abrir_painel_stats()
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
