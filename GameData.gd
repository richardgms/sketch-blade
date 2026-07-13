extends Node
## Autoload com definições data-driven do jogo: upgrades in-run, canetas,
## receita das páginas e curvas econômicas. Nenhum estado mutável aqui.

# ============================================================
# UPGRADES IN-RUN (roguelite) — 10 upgrades, até 3 níveis cada.
# "valores" é o dado numérico lido pelo Player/Projectile por nível.
# "consumivel" = efeito imediato, sem nível (pode repetir sempre).
# ============================================================
const UPGRADES: Array = [
	{
		"id": "tiro_duplo",
		"nome": "CANETA DE\nDUAS PORTAS",
		"descricao": "Dispara 2 projéteis\nparalelos",
		"nivel_max": 3,
		"valores": [0.85, 0.95, 1.0], # multiplicador de dano por bala
		"stats": ["Dano -15%\npor bala", "Dano -5%\npor bala", "Dano cheio\npor bala"],
		"cor_stats": "002867",
		"icone": "res://assets/2canetabic.png"
	},
	{
		"id": "tiro_perfurante",
		"nome": "GRAFITE\nAFIADO",
		"descricao": "Projéteis atravessam\ninimigos",
		"nivel_max": 3,
		"valores": [1, 2, 3], # inimigos perfurados
		"stats": ["Perfuração 1", "Perfuração 2", "Perfuração 3"],
		"cor_stats": "002867",
		"icone": "res://assets/lapisatravessando.png"
	},
	{
		"id": "escudo_borracha",
		"nome": "ESCUDO DE\nBORRACHA",
		"descricao": "Absorve 1 projétil\nou golpe",
		"nivel_max": 3,
		"valores": [8.0, 6.0, 4.0], # segundos de recarga
		"stats": ["Recarga 8s", "Recarga 6s", "Recarga 4s"],
		"cor_stats": "002867",
		"icone": "res://assets/borracha.png"
	},
	{
		"id": "corretivo_liquido",
		"nome": "CORRETIVO\nLÍQUIDO",
		"descricao": "Cura 1 coração de\nHP imediatamente",
		"nivel_max": 0, # consumível: sempre disponível
		"consumivel": true,
		"valores": [1],
		"stats": ["+1 HP"],
		"cor_stats": "d9534f",
		"icone": "res://assets/corretivo.png"
	},
	{
		"id": "apontador_rapido",
		"nome": "APONTADOR\nRÁPIDO",
		"descricao": "Mais agilidade e\nvelocidade de disparo",
		"nivel_max": 3,
		"valores": [0.15, 0.25, 0.35], # bônus percentual
		"stats": ["+15% VEL", "+25% VEL", "+35% VEL"],
		"cor_stats": "002867",
		"icone": "res://assets/raio.png"
	},
	{
		"id": "ricochete",
		"nome": "TINTA\nSALTITANTE",
		"descricao": "Projéteis quicam para\no inimigo mais próximo",
		"nivel_max": 3,
		"valores": [1, 2, 3], # quiques
		"stats": ["1 quique", "2 quiques", "3 quiques"],
		"cor_stats": "002867",
		"icone": "res://assets/ricochete.png"
	},
	{
		"id": "tinta_corrosiva",
		"nome": "TINTA\nCORROSIVA",
		"descricao": "Acertos corroem o inimigo\ncausando dano contínuo",
		"nivel_max": 3,
		"valores": [2, 4, 6], # dano por segundo (2s de duração)
		"stats": ["2 dano/s", "4 dano/s", "6 dano/s"],
		"cor_stats": "0a473a",
		"icone": "res://assets/tinta_corrosiva.png"
	},
	{
		"id": "leque",
		"nome": "LEQUE DE\nRABISCOS",
		"descricao": "+2 projéteis diagonais\nem leque",
		"nivel_max": 3,
		"valores": [0.5, 0.65, 0.8], # dano das diagonais
		"stats": ["Diagonais 50%\nde dano", "Diagonais 65%\nde dano", "Diagonais 80%\nde dano"],
		"cor_stats": "002867",
		"icone": "res://assets/leque.png"
	},
	{
		"id": "ponta_critica",
		"nome": "PONTA\nCRÍTICA",
		"descricao": "Chance de acerto\ncrítico com dano x2",
		"nivel_max": 3,
		"valores": [0.10, 0.20, 0.30], # chance de crítico
		"stats": ["10% crítico", "20% crítico", "30% crítico"],
		"cor_stats": "f39c12",
		"icone": "res://assets/ponta_critica.png"
	},
	{
		"id": "pote_tinta",
		"nome": "POTE DE\nTINTA",
		"descricao": "+50 gotas de tinta\nimediatamente",
		"nivel_max": 0, # consumível: sempre disponível
		"consumivel": true,
		"valores": [50],
		"stats": ["+50 tinta"],
		"cor_stats": "002867",
		"icone": "res://assets/pote_tinta.png"
	},
	{
		"id": "borrao_explosivo",
		"nome": "BORRÃO\nEXPLOSIVO",
		"descricao": "Inimigos mortos explodem\ne ferem os vizinhos",
		"nivel_max": 3,
		"valores": [8, 14, 20], # dano da explosão (raio 160px)
		"stats": ["8 de dano\nem área", "14 de dano\nem área", "20 de dano\nem área"],
		"cor_stats": "d9534f",
		"icone": "res://assets/borrao_explosivo.png"
	}
]

const RAIO_EXPLOSAO: float = 160.0
const DURACAO_DOT: float = 2.0
const ANGULO_LEQUE_GRAUS: float = 18.0

# ============================================================
# RECEITA DA RUN — 8 páginas do caderno por capítulo.
# "intensidade" multiplica HP/velocidade dos inimigos da página
# (por cima da escala de capítulo).
# ============================================================
const PAGINAS: Array = [
	{"tipo": "onda", "quantidade": 3, "intervalo": 2.2, "intensidade": 0.8},              # Pág 1: aquecimento
	{"tipo": "onda", "quantidade": 4, "intervalo": 2.0, "intensidade": 0.8},              # Pág 2: leve
	{"tipo": "onda", "quantidade": 5, "intervalo": 1.6, "intensidade": 1.0},              # Pág 3: pesada
	{"tipo": "descanso"},                                                                  # Pág 4: curar ou tinta
	{"tipo": "onda", "quantidade": 5, "intervalo": 1.5, "intensidade": 1.2},              # Pág 5: mista
	{"tipo": "onda", "quantidade": 4, "intervalo": 1.6, "intensidade": 1.2, "elite": true}, # Pág 6: elite!
	{"tipo": "onda", "quantidade": 7, "intervalo": 0.9, "intensidade": 1.4},              # Pág 7: horda
	{"tipo": "boss"},                                                                      # Pág 8: boss
]

# Após concluir estas páginas o jogador escolhe um upgrade na roleta
const PAGINAS_COM_UPGRADE: Array = [2, 4, 6]

# Descanso (página 4): valores da escolha
const DESCANSO_CURA: int = 2
const DESCANSO_TINTA_BASE: int = 40
const DESCANSO_TINTA_POR_CAPITULO: int = 20

# Bônus por página concluída sem tomar dano
const BONUS_PAGINA_PERFEITA_BASE: int = 10
const BONUS_PAGINA_PERFEITA_POR_CAPITULO: int = 5

func tinta_descanso(capitulo: int) -> int:
	return DESCANSO_TINTA_BASE + DESCANSO_TINTA_POR_CAPITULO * capitulo

func bonus_pagina_perfeita(capitulo: int) -> int:
	return BONUS_PAGINA_PERFEITA_BASE + BONUS_PAGINA_PERFEITA_POR_CAPITULO * capitulo

# Elite: multiplicadores sobre o inimigo base
const ELITE_MULT_HP: float = 4.0
const ELITE_MULT_ESCALA: float = 1.6
const ELITE_MULT_VELOCIDADE: float = 0.7

# ============================================================
# ESTOJO — upgrades RPG persistentes (10 níveis)
# CUSTOS_ESTOJO[n-1] = custo para subir do nível n para n+1 (curva ~1.4x)
# Arrays de atributos: índice = nível (índice 0 não usado)
# ============================================================
const NIVEL_MAX_ESTOJO: int = 10
const CUSTOS_ESTOJO: Array = [200, 280, 390, 550, 770, 1080, 1510, 2110, 2950]
const DANO_POR_NIVEL: Array = [0, 10, 14, 18, 23, 28, 34, 40, 47, 54, 62]
const HP_POR_NIVEL: Array = [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
const CADENCIA_POR_NIVEL: Array = [0.0, 0.75, 0.68, 0.62, 0.56, 0.51, 0.46, 0.42, 0.38, 0.35, 0.32]

# ============================================================
# RETENÇÃO DIÁRIA
# ============================================================
# Calendário de 7 dias (streak). Índice = dia da sequência - 1.
const RECOMPENSAS_DIARIAS: Array = [
	{"tinta": 50, "clipes": 0},
	{"tinta": 75, "clipes": 0},
	{"tinta": 100, "clipes": 0},
	{"tinta": 0, "clipes": 5},
	{"tinta": 150, "clipes": 0},
	{"tinta": 200, "clipes": 0},
	{"tinta": 0, "clipes": 15}
]

# Pool de missões diárias — progresso medido por delta das stats do SaveManager.
const POOL_MISSOES: Array = [
	{"id": "matador", "desc": "Derrote 40 monstros", "stat": "monstros_derrotados", "alvo": 40, "tinta": 50, "clipes": 0},
	{"id": "cacador_boss", "desc": "Derrote 1 Boss", "stat": "bosses_derrotados", "alvo": 1, "tinta": 40, "clipes": 0},
	{"id": "perfeccionista", "desc": "Complete 2 páginas sem tomar dano", "stat": "paginas_perfeitas", "alvo": 2, "tinta": 0, "clipes": 3},
	{"id": "colecionador", "desc": "Colete 300 gotas de tinta", "stat": "tinta_coletada_total", "alvo": 300, "tinta": 60, "clipes": 0},
	{"id": "guerreiro", "desc": "Jogue 3 partidas", "stat": "partidas_jogadas", "alvo": 3, "tinta": 50, "clipes": 0},
	{"id": "vencedor", "desc": "Vença 1 capítulo", "stat": "capitulos_vencidos", "alvo": 1, "tinta": 80, "clipes": 0},
	{"id": "elite_hunter", "desc": "Derrote 1 Elite dourado", "stat": "elites_derrotados", "alvo": 1, "tinta": 40, "clipes": 0},
	{"id": "descansado", "desc": "Use 1 página de descanso", "stat": "descansos_usados", "alvo": 1, "tinta": 30, "clipes": 0}
]

func get_missao(id: String) -> Dictionary:
	for missao in POOL_MISSOES:
		if missao["id"] == id:
			return missao
	return {}

# ============================================================
# LOJA DE CANETAS — equipamentos com passivas.
# "mods": mult_dano / mult_cadencia (multiplica o intervalo: <1 = mais rápido)
#          chance_critica / escudo_inicial
# ============================================================
const CANETAS: Array = [
	{
		"id": "bic_azul",
		"nome": "BIC Azul",
		"passiva": "A clássica de todo estojo.\nSem bônus, puro coração.",
		"custo_tinta": 0, "custo_clipes": 0,
		"cor_corpo": "0038a8",
		"cor_projetil": "002867",
		"mods": {}
	},
	{
		"id": "lapis_hb",
		"nome": "Lápis HB",
		"passiva": "+15% de chance de\nacerto crítico",
		"custo_tinta": 800, "custo_clipes": 0,
		"cor_corpo": "b8860b",
		"cor_projetil": "4a4a4a",
		"mods": {"chance_critica": 0.15}
	},
	{
		"id": "nanquim",
		"nome": "Nanquim",
		"passiva": "+20% de dano\n-10% de cadência",
		"custo_tinta": 1500, "custo_clipes": 0,
		"cor_corpo": "0d0d12",
		"cor_projetil": "000000",
		"mods": {"mult_dano": 1.2, "mult_cadencia": 1.1}
	},
	{
		"id": "gel_vermelha",
		"nome": "Gel Vermelha",
		"passiva": "+15% de cadência\nde disparo",
		"custo_tinta": 0, "custo_clipes": 25,
		"cor_corpo": "c0392b",
		"cor_projetil": "d9534f",
		"mods": {"mult_cadencia": 0.85}
	},
	{
		"id": "nanquim_real",
		"nome": "Nanquim Real",
		"passiva": "Começa toda run com\nEscudo de Borracha",
		"custo_tinta": 0, "custo_clipes": 60,
		"cor_corpo": "8e6b0a",
		"cor_projetil": "1a3a8f",
		"mods": {"escudo_inicial": true}
	}
]

## Retorna a definição de uma caneta pelo id (fallback: BIC Azul).
func get_caneta(id: String) -> Dictionary:
	for caneta in CANETAS:
		if caneta["id"] == id:
			return caneta
	return CANETAS[0]

## Retorna a definição de um upgrade pelo id (ou {} se não existir).
func get_upgrade(id: String) -> Dictionary:
	for up in UPGRADES:
		if up["id"] == id:
			return up
	return {}

## Valor numérico de um upgrade no nível dado (nível 1 = índice 0).
func valor_upgrade(id: String, nivel: int):
	var up = get_upgrade(id)
	if up.is_empty() or nivel <= 0:
		return 0
	var idx = clamp(nivel - 1, 0, up["valores"].size() - 1)
	return up["valores"][idx]
