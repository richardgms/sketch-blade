class_name Vibracao
## Vibração do celular por momento do jogo, sempre respeitando a chave
## "Vibração" das Configurações. Cada padrão é uma lista de [ms, força 0..1,
## pausa até o próximo em ms]. Força só vale no Android 8+; antes disso o
## aparelho usa a força padrão. Fora do celular não faz nada.
## Mapa e intensidades: docs/vibracao.md.

const PADROES := {
	"coracao": [[28, 0.35, 0]],                             # a cada batida com 1 coração
	"dano": [[100, 1.0, 0]],
	"escudo": [[45, 0.7, 70], [25, 0.4, 0]],                # a borracha racha
	"elite": [[40, 0.55, 0]],
	"carta": [[22, 0.4, 0]],                                # upgrade escolhido
	"ja": [[45, 0.6, 0]],                                   # "JÁ!" da contagem
	"chefe_surge": [[90, 0.8, 140], [90, 0.8, 140], [220, 1.0, 0]],
	"chefe_derrotado": [[240, 1.0, 120], [70, 0.6, 90], [45, 0.4, 0]],
	"reviver": [[60, 0.6, 110], [60, 0.8, 0]],
	"vitoria": [[50, 0.6, 90], [50, 0.7, 90], [160, 0.9, 0]],
	"derrota": [[320, 0.6, 0]],
	"compra": [[35, 0.5, 70], [35, 0.5, 0]],
	"coleta": [[30, 0.45, 0]],                              # missão / recompensa diária
}

static func tocar(nome: String) -> void:
	if not SaveManager.dados.get("vibracao_ativa", true):
		return
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return
	var arvore := Engine.get_main_loop() as SceneTree
	if arvore == null or not PADROES.has(nome):
		return
	var espera := 0.0
	for passo in PADROES[nome]:
		if espera <= 0.0:
			Input.vibrate_handheld(int(passo[0]), float(passo[1]))
		else:
			var t := arvore.create_timer(espera / 1000.0, true, false, true)
			t.timeout.connect(Input.vibrate_handheld.bind(int(passo[0]), float(passo[1])))
		espera += float(passo[0]) + float(passo[2])
