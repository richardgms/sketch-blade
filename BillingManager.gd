extends Node
## Autoload de compras no app (Google Play Billing).
##
## MODO SIMULADO: fora do Android (editor/desktop) a compra é simulada, para
## todo o fluxo ser testável sem a loja. No Android usa o plugin oficial
## GodotGooglePlayBilling (addons/GodotGooglePlayBilling).
##
## Regra de segurança: o item só é entregue depois que o Google confirma a
## compra. O token de cada compra entregue fica gravado no save, para que uma
## compra interrompida (app fechado antes de consumir) seja entregue uma única
## vez e depois consumida.

signal compra_concluida(chave: String)
signal compra_falhou(chave: String, motivo: String)
signal precos_atualizados

const BillingClientScript = preload("res://addons/GodotGooglePlayBilling/BillingClient.gd")

## chave interna -> produto cadastrado no Play Console (INAPP, consumível)
const PRODUTOS: Dictionary = {
	"clipes": {"id": "clipes_100", "campo": "clipes_ouro", "quantidade": 100,
		"nome": "100 Clipes de Ouro", "preco_simulado": "R$ 4,90"},
	"tinta": {"id": "tinta_5000", "campo": "tinta", "quantidade": 5000,
		"nome": "5.000 Gotas de Tinta", "preco_simulado": "R$ 4,90"},
}
const MAX_TOKENS_GUARDADOS: int = 50
const ESPERA_RECONECTAR: float = 5.0

var _client: Node = null
var _conectado: bool = false
var _simulado: bool = true
var _precos: Dictionary = {} # chave -> preço formatado pela loja
var _compra_em_andamento: String = ""

func _ready() -> void:
	_simulado = OS.get_name() != "Android"
	if _simulado:
		return
	_client = BillingClientScript.new()
	add_child(_client)
	_client.connected.connect(_on_connected)
	_client.disconnected.connect(_on_disconnected)
	_client.connect_error.connect(_on_connect_error)
	_client.query_product_details_response.connect(_on_query_product_details_response)
	_client.query_purchases_response.connect(_on_query_purchases_response)
	_client.on_purchase_updated.connect(_on_purchase_updated)
	_client.consume_purchase_response.connect(_on_consume_purchase_response)
	_client.start_connection()

# ------------------------------------------------------------------
# API para a UI
# ------------------------------------------------------------------
## Preço para exibir. Vazio no Android enquanto a loja não respondeu.
func preco(chave: String) -> String:
	if _simulado:
		return PRODUTOS[chave]["preco_simulado"]
	return _precos.get(chave, "")

func disponivel(chave: String) -> bool:
	return _simulado or (_conectado and _precos.has(chave))

func nome(chave: String) -> String:
	return PRODUTOS[chave]["nome"]

func comprar(chave: String) -> void:
	if not PRODUTOS.has(chave) or _compra_em_andamento != "":
		return
	_compra_em_andamento = chave

	if _simulado:
		await get_tree().create_timer(0.6).timeout
		_entregar(chave)
		_compra_em_andamento = ""
		compra_concluida.emit(chave)
		return

	if not disponivel(chave):
		_falhar(chave, "Loja indisponível no momento. Tente de novo em instantes.")
		_client.start_connection()
		return
	var r: Dictionary = _client.purchase(PRODUTOS[chave]["id"])
	if r.get("response_code", -1) != BillingClientScript.BillingResponseCode.OK:
		_falhar(chave, "Não foi possível abrir a compra (código %s)." % str(r.get("response_code", "?")))

# ------------------------------------------------------------------
# Plugin: conexão e consultas
# ------------------------------------------------------------------
func _on_connected() -> void:
	_conectado = true
	var ids := PackedStringArray()
	for chave in PRODUTOS:
		ids.append(PRODUTOS[chave]["id"])
	_client.query_product_details(ids, BillingClientScript.ProductType.INAPP)
	# Recupera compras que ficaram sem consumir (app fechado no meio, etc.)
	_client.query_purchases(BillingClientScript.ProductType.INAPP)

func _on_disconnected() -> void:
	_conectado = false
	await get_tree().create_timer(ESPERA_RECONECTAR).timeout
	if not _conectado:
		_client.start_connection()

func _on_connect_error(response_code: int, debug_message: String) -> void:
	_conectado = false
	push_warning("[BillingManager] Falha ao conectar (%d): %s" % [response_code, debug_message])

func _on_query_product_details_response(resposta: Dictionary) -> void:
	if resposta.get("response_code", -1) != BillingClientScript.BillingResponseCode.OK:
		push_warning("[BillingManager] Consulta de produtos falhou: %s" % str(resposta.get("debug_message", "")))
		return
	for detalhe in resposta.get("product_details", []):
		var chave := _chave_por_id(str(detalhe.get("product_id", "")))
		var ofertas = detalhe.get("one_time_purchase_offer_details_list", null)
		if chave != "" and ofertas is Array and not ofertas.is_empty():
			_precos[chave] = str(ofertas[0].get("formatted_price", ""))
	precos_atualizados.emit()

func _on_query_purchases_response(resposta: Dictionary) -> void:
	if resposta.get("response_code", -1) != BillingClientScript.BillingResponseCode.OK:
		return
	for compra in resposta.get("purchases", []):
		_processar_compra(compra)

func _on_purchase_updated(resposta: Dictionary) -> void:
	var codigo: int = resposta.get("response_code", -1)
	if codigo == BillingClientScript.BillingResponseCode.OK:
		for compra in resposta.get("purchases", []):
			_processar_compra(compra)
		return
	var chave := _compra_em_andamento
	if codigo == BillingClientScript.BillingResponseCode.USER_CANCELED:
		_falhar(chave, "cancelada")
	elif codigo == BillingClientScript.BillingResponseCode.ITEM_ALREADY_OWNED:
		# Compra anterior ainda não consumida: recupera e entrega.
		_client.query_purchases(BillingClientScript.ProductType.INAPP)
	else:
		_falhar(chave, "A compra não foi concluída (código %d)." % codigo)

func _on_consume_purchase_response(resposta: Dictionary) -> void:
	if resposta.get("response_code", -1) != BillingClientScript.BillingResponseCode.OK:
		# A compra continua pendente no Google e será retomada na próxima abertura.
		push_warning("[BillingManager] Consumo falhou: %s" % str(resposta.get("debug_message", "")))

# ------------------------------------------------------------------
# Entrega
# ------------------------------------------------------------------
## Entrega o item (uma vez por token) e depois consome a compra.
func _processar_compra(compra: Dictionary) -> void:
	var token: String = str(compra.get("purchase_token", ""))
	if token == "":
		return
	var estado: int = compra.get("purchase_state", 0)
	for id in compra.get("product_ids", PackedStringArray()):
		var chave := _chave_por_id(str(id))
		if chave == "":
			continue
		if estado == BillingClientScript.PurchaseState.PENDING:
			if chave == _compra_em_andamento:
				_falhar(chave, "Pagamento pendente. Os itens chegam quando for aprovado.")
			continue
		if estado != BillingClientScript.PurchaseState.PURCHASED:
			continue

		var tokens: Array = SaveManager.dados["compras_tokens"]
		var nova: bool = not tokens.has(token)
		if nova:
			_entregar(chave)
			tokens.append(token)
			while tokens.size() > MAX_TOKENS_GUARDADOS:
				tokens.pop_front()
			SaveManager.salvar()
		_consumir(token)
		if nova:
			if chave == _compra_em_andamento:
				_compra_em_andamento = ""
			compra_concluida.emit(chave)

func _entregar(chave: String) -> void:
	var p: Dictionary = PRODUTOS[chave]
	SaveManager.dados[p["campo"]] += p["quantidade"]
	SaveManager.salvar()

func _consumir(token: String) -> void:
	if _client:
		_client.consume_purchase(token)

func _chave_por_id(id: String) -> String:
	for chave in PRODUTOS:
		if PRODUTOS[chave]["id"] == id:
			return chave
	return ""

func _falhar(chave: String, motivo: String) -> void:
	_compra_em_andamento = ""
	compra_falhou.emit(chave, motivo)
