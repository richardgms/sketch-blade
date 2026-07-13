extends Node
## Autoload que centraliza todo o save/load do jogo em user://save_data.json.
## Substitui as versões duplicadas que existiam em Hub.gd e Main.gd.

const CAMINHO_SAVE: String = "user://save_data.json"
const VERSAO_SAVE_ATUAL: int = 2
const CHAVE_CRIPTOGRAFIA: String = "sketch_blade_secret_key_2026"

var dados: Dictionary = {}

## Snapshot runtime-only (não persistido) do nível/XP de conta ANTES de uma
## run aplicar seus ganhos. O Hub consome isso uma vez ao carregar para
## animar a barra de XP subindo do valor antigo até o novo — ver Hub.gd
## _animar_xp_ganho(). Fica vazio quando não há run pendente de animar.
var xp_snapshot_pendente: Dictionary = {}

## Flag runtime-only (não persistida): o Hub liga isto antes de trocar para a
## main.tscn quando o jogador escolhe CONTINUAR uma run interrompida. O Main lê
## no _ready para decidir entre restaurar o snapshot ou começar uma run nova.
var retomar_run_pendente: bool = false

# Valores padrão — todo campo novo entra aqui e é migrado automaticamente
# para saves antigos via _mesclar_com_defaults().
var _defaults: Dictionary = {
	"versao_save": VERSAO_SAVE_ATUAL,
	"tinta": 0,
	"clipes_ouro": 10,
	"nivel_conta": 1,
	"xp_conta": 0,
	"capitulo_desbloqueado": 1,
	"capitulo_selecionado": 1,
	"nivel_dano": 1,
	"nivel_hp": 1,
	"nivel_cadencia": 1,
	"equipamentos": [],
	# Loja de Canetas
	"caneta_equipada": "bic_azul",
	"canetas_possuidas": ["bic_azul"],
	# Retenção diária
	"ultimo_login": "",
	"dia_streak": 0,
	"recompensa_coletada_hoje": false,
	"missoes_dia": [],
	"data_missoes": "",
	# Estatísticas acumuladas (missões e telemetria)
	"stats": {
		"monstros_derrotados": 0,
		"bosses_derrotados": 0,
		"elites_derrotados": 0,
		"tinta_coletada_total": 0,
		"partidas_jogadas": 0,
		"capitulos_vencidos": 0,
		"paginas_perfeitas": 0,
		"descansos_usados": 0,
		# Telemetria de baseline P0 (medir antes de decidir o combo P1)
		"gotas_coletadas": 0,
		"gotas_secas": 0,
		"tempo_jogado_seg": 0
	},
	# Configurações
	"tutorial_visto": false,
	"som_ativo": true,
	"vibracao_ativa": true,
	# Snapshot de run em andamento (rede de segurança contra o app ser fechado
	# no meio da partida — gesto voltar, kill de processo pelo Android, etc).
	# Estrutura completa preenchida por Main._capturar_estado_run(); aqui só o
	# marcador de "não há run ativa".
	"run_snapshot": {"ativa": false}
}

func _ready() -> void:
	carregar()

func carregar() -> void:
	dados = _defaults.duplicate(true)

	if not FileAccess.file_exists(CAMINHO_SAVE):
		salvar()
		return

	var texto = ""
	# 1. Tenta abrir de forma criptografada
	var arquivo = FileAccess.open_encrypted_with_pass(CAMINHO_SAVE, FileAccess.READ, CHAVE_CRIPTOGRAFIA)
	if arquivo != null:
		texto = arquivo.get_as_text()
		arquivo.close()
	else:
		# 2. Se falhar (ex: save antigo sem criptografia), tenta abrir em modo texto plano como fallback
		push_warning("[SaveManager] Falha ao abrir save criptografado. Tentando modo texto plano...")
		arquivo = FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
		if arquivo != null:
			texto = arquivo.get_as_text()
			arquivo.close()
			push_warning("[SaveManager] Save antigo em texto plano importado com sucesso!")
		else:
			push_warning("[SaveManager] Falha crítica ao ler arquivo de save. Recriando defaults.")
			salvar()
			return

	var json = JSON.new()
	if json.parse(texto) != OK:
		push_warning("[SaveManager] Save corrompido, recriando com defaults.")
		salvar()
		return

	var carregado = json.get_data()
	if carregado is Dictionary:
		_mesclar_com_defaults(carregado, dados)
		# O snapshot da run tem chaves dinâmicas (upgrades variáveis) e não pode
		# passar pelo filtro de _mesclar_com_defaults, que descartaria tudo que
		# não estivesse nos defaults. Copiamos a estrutura crua inteira.
		if carregado.has("run_snapshot") and carregado["run_snapshot"] is Dictionary:
			dados["run_snapshot"] = carregado["run_snapshot"]

	dados["versao_save"] = VERSAO_SAVE_ATUAL
	salvar() # Regrava criptografado para persistir campos migrados e converter o formato do arquivo

func salvar() -> void:
	var arquivo = FileAccess.open_encrypted_with_pass(CAMINHO_SAVE, FileAccess.WRITE, CHAVE_CRIPTOGRAFIA)
	if arquivo != null:
		arquivo.store_string(JSON.stringify(dados))
		arquivo.close()
	else:
		push_error("[SaveManager] Não foi possível salvar os dados criptografados!")

## Copia valores do save carregado por cima dos defaults, respeitando o tipo
## do default (JSON devolve float para todo número — coage para int quando preciso).
func _mesclar_com_defaults(origem: Dictionary, destino: Dictionary) -> void:
	for chave in destino.keys():
		if not origem.has(chave):
			continue
		var valor = origem[chave]
		var padrao = destino[chave]

		if padrao is int and (valor is float or valor is int):
			destino[chave] = int(valor)
		elif padrao is Dictionary and valor is Dictionary:
			_mesclar_com_defaults(valor, destino[chave])
		elif typeof(padrao) == typeof(valor) or padrao is Array:
			destino[chave] = valor

## Atalho para incrementar uma estatística acumulada.
func incrementar_stat(chave: String, quantidade: int = 1) -> void:
	if dados["stats"].has(chave):
		dados["stats"][chave] += quantidade

# ============================================================
# SNAPSHOT DE RUN (retomar partida interrompida)
# ============================================================
func salvar_run_snapshot(snap: Dictionary) -> void:
	dados["run_snapshot"] = snap
	salvar()

func limpar_run_snapshot() -> void:
	dados["run_snapshot"] = {"ativa": false}
	salvar()

func tem_run_ativa() -> bool:
	var snap = dados.get("run_snapshot", {})
	return snap is Dictionary and snap.get("ativa", false)

func get_run_snapshot() -> Dictionary:
	var snap = dados.get("run_snapshot", {})
	return snap if snap is Dictionary else {}
