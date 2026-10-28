extends Node
## Autoload dos anúncios premiados (rewarded) via AdMob.
##
## No Android usa o plugin poing-studios (addons/admob, v5.1.0). Fora do Android
## (editor/PC) o anúncio é simulado: 1 s de espera e a recompensa é concedida,
## para todo o fluxo ser testável sem o SDK.
##
## O ID do app fica em Project Settings (admob/general/android/app_id).
## Os blocos de anúncio ficam em BLOCOS_REAIS; com USAR_BLOCOS_TESTE = true
## todos usam o bloco de teste do Google (seguro para clicar).

signal recompensa_concedida(placement: String)
signal anuncio_falhou(placement: String)

## true durante o desenvolvimento e o teste fechado. Clicar no próprio anúncio
## real conta como tráfego inválido e pode banir a conta AdMob.
## Trocar para false só antes da produção.
const USAR_BLOCOS_TESTE: bool = true

const BLOCO_TESTE: String = "ca-app-pub-3940256099942544/5224354917"
const BLOCOS_REAIS: Dictionary = {
	"revive": "ca-app-pub-8087529550411431/2117331750",
	"dobrar_tinta": "ca-app-pub-8087529550411431/9804250081",
	"diaria_dobro": "ca-app-pub-8087529550411431/2424453518",
}

## Espera máxima para o anúncio carregar quando o jogador toca e ele ainda não
## está pronto. Depois que o anúncio abre, não há limite de tempo.
const TEMPO_CARREGAR: float = 8.0

# Controle de uso por run (revive é 1x por partida)
var revive_usado_na_run: bool = false

var _real: bool = false
var _iniciado: bool = false
var _prontos: Dictionary = {}     # placement -> RewardedAd carregado
var _carregando: Dictionary = {}  # placement -> true
var _placement_ativo: String = ""
var _ganhou: bool = false
var _finalizado: bool = true

func _ready() -> void:
	# Precisa rodar com o jogo pausado (menu de revive pausa a árvore).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_real = OS.get_name() == "Android"
	if not _real:
		return
	var ao_iniciar := OnInitializationCompleteListener.new()
	ao_iniciar.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_iniciado = true
		for placement in BLOCOS_REAIS:
			_carregar(placement)
	MobileAds.initialize(ao_iniciar)

func nova_run() -> void:
	revive_usado_na_run = false

func _bloco(placement: String) -> String:
	if USAR_BLOCOS_TESTE:
		return BLOCO_TESTE
	return BLOCOS_REAIS.get(placement, BLOCO_TESTE)

## Carrega um anúncio para o placement e guarda até ser usado.
func _carregar(placement: String) -> void:
	if not _iniciado or _prontos.has(placement) or _carregando.has(placement):
		return
	_carregando[placement] = true
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_carregando.erase(placement)
		_prontos[placement] = ad
	cb.on_ad_failed_to_load = func(erro: LoadAdError) -> void:
		_carregando.erase(placement)
		push_warning("[AdsManager] Falha ao carregar %s (%d): %s" % [placement, erro.code, erro.message])
	RewardedAdLoader.new().load(_bloco(placement), AdRequest.new(), cb)

## Exibe um rewarded ad. Emite recompensa_concedida(placement) se o jogador
## assistir até o fim, ou anuncio_falhou(placement) caso contrário.
func mostrar_rewarded(placement: String) -> void:
	if not _finalizado:
		push_warning("[AdsManager] Já existe um anúncio em andamento.")
		return
	_placement_ativo = placement
	_ganhou = false
	_finalizado = false

	if not _real:
		await get_tree().create_timer(1.0).timeout
		_finalizar(true)
		return

	# Ainda não carregou: tenta agora e espera um pouco.
	if not _prontos.has(placement):
		_carregar(placement)
		var limite := Time.get_ticks_msec() + int(TEMPO_CARREGAR * 1000.0)
		while not _prontos.has(placement) and Time.get_ticks_msec() < limite:
			await get_tree().create_timer(0.25).timeout
		if not _prontos.has(placement):
			_finalizar(false)
			return

	var ad: RewardedAd = _prontos[placement]
	_prontos.erase(placement)

	var telas := FullScreenContentCallback.new()
	telas.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		# A recompensa costuma chegar antes do fechamento; espera um instante.
		await get_tree().create_timer(0.2).timeout
		_finalizar(_ganhou)
		_carregar(placement)
	telas.on_ad_failed_to_show_full_screen_content = func(erro: AdError) -> void:
		push_warning("[AdsManager] Falha ao exibir %s: %s" % [placement, erro.message])
		ad.destroy()
		_finalizar(false)
		_carregar(placement)
	ad.full_screen_content_callback = telas

	var premio := OnUserEarnedRewardListener.new()
	premio.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_ganhou = true
	ad.show(premio)

func _finalizar(sucesso: bool) -> void:
	if _finalizado:
		return
	_finalizado = true
	var placement := _placement_ativo
	_placement_ativo = ""
	if sucesso:
		recompensa_concedida.emit(placement)
	else:
		anuncio_falhou.emit(placement)
