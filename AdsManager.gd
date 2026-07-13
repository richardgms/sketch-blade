extends Node
## Autoload que gerencia rewarded ads (AdMob).
##
## MODO MOCK: no editor/desktop o anúncio é simulado (1s de espera e recompensa
## concedida) para que TODO o fluxo do jogo seja testável sem SDK.
##
## Para o build Android de release:
## 1. Instalar o plugin poing-studios/godot-admob-android
## 2. Definir MODO_MOCK = false
## 3. Trocar os IDs de teste pelos IDs reais do app no AdMob

signal recompensa_concedida(placement: String)
signal anuncio_falhou(placement: String)

# Trocar para false quando o plugin AdMob estiver instalado no build Android
const MODO_MOCK: bool = true

# Limite de tempo (em segundos) para esperar o anúncio carregar/exibir.
const TEMPO_TIMEOUT: float = 6.0

# IDs de TESTE oficiais do AdMob (NUNCA publicar com estes IDs)
const ID_APP_TESTE: String = "ca-app-pub-3940256099942544~3347511713"
const ID_REWARDED_TESTE: String = "ca-app-pub-3940256099942544/5224354917"

# Controle de uso por run (revive é 1x por partida)
var revive_usado_na_run: bool = false

# Controle interno de requisição ativa
var _ad_ativo_placement: String = ""
var _ad_completado: bool = false

func nova_run() -> void:
	revive_usado_na_run = false

## Exibe um rewarded ad. Emite recompensa_concedida(placement) se o jogador
## assistir até o fim, ou anuncio_falhou(placement) caso contrário.
func mostrar_rewarded(placement: String) -> void:
	if _ad_ativo_placement != "":
		push_warning("[AdsManager] Já existe uma requisição de anúncio ativa.")
		return
		
	_ad_ativo_placement = placement
	_ad_completado = false

	# Timer de segurança contra timeouts de rede
	var timer_timeout = get_tree().create_timer(TEMPO_TIMEOUT)
	timer_timeout.timeout.connect(func():
		if not _ad_completado:
			push_warning("[AdsManager] Timeout de %.1fs atingido para o placement: %s" % [TEMPO_TIMEOUT, placement])
			_finalizar_requisicao(false)
	)

	if MODO_MOCK or OS.get_name() != "Android":
		# Simulação: pequena espera imitando a exibição do anúncio
		await get_tree().create_timer(1.0).timeout
		_finalizar_requisicao(true)
		return

	# INTEGRAÇÃO REAL COM O PLUGIN ADMOB (poing-studios/godot-admob-android)
	var admob = Engine.get_singleton("AdMob")
	if admob:
		# Conecta sinais dinamicamente para garantir a captura das respostas
		if not admob.rewarded_ad_failed_to_show.is_connected(_on_admob_failed_to_show):
			admob.rewarded_ad_failed_to_show.connect(_on_admob_failed_to_show)
		if not admob.user_earned_reward.is_connected(_on_admob_user_earned_reward):
			admob.user_earned_reward.connect(_on_admob_user_earned_reward)
		if not admob.rewarded_ad_dismissed.is_connected(_on_admob_dismissed):
			admob.rewarded_ad_dismissed.connect(_on_admob_dismissed)
			
		# Exibe o anúncio de recompensa
		admob.show_rewarded_ad()
	else:
		push_error("[AdsManager] Singleton AdMob não encontrado no Android!")
		_finalizar_requisicao(false)

func _on_admob_failed_to_show() -> void:
	_finalizar_requisicao(false)

func _on_admob_user_earned_reward(_type: String, _amount: int) -> void:
	_finalizar_requisicao(true)

func _on_admob_dismissed() -> void:
	# Pequeno atraso para garantir que user_earned_reward dispare primeiro se for o caso
	await get_tree().create_timer(0.15).timeout
	if not _ad_completado:
		_finalizar_requisicao(false)

func _finalizar_requisicao(sucesso: bool) -> void:
	if _ad_completado:
		return
	_ad_completado = true
	var placement = _ad_ativo_placement
	_ad_ativo_placement = ""
	
	if sucesso:
		recompensa_concedida.emit(placement)
	else:
		anuncio_falhou.emit(placement)
