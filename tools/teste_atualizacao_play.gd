extends SceneTree
var falhas := 0

class PlaySimulada extends RefCounted:
	var estado := 2
	var codigo := 999
	func query_update() -> void: pass
	func get_update_state() -> int: return estado
	func get_available_version_code() -> int: return codigo

func _initialize() -> void:
	_rodar()

func checar(nome: String, ok: bool) -> void:
	print(("OK " if ok else "FALHA ") + nome)
	if not ok: falhas += 1

func avisos(h: Node) -> Array:
	return h.get_node("HUD").get_children().filter(func(n): return n.get_script() == load("res://JanelaAtualizacao.gd"))

func limpar(h: Node) -> void:
	for n in avisos(h):
		n.free()
	h._aviso_atualizacao_visto = false

func _rodar() -> void:
	await process_frame
	var consulta = load("res://AtualizacaoLoja.gd").new()
	root.add_child(consulta)
	var resultado := [0]
	consulta.consultada.connect(func(c): resultado[0] = c)
	var play := PlaySimulada.new()
	consulta.consultar(play)
	checar("Play informa versão disponível", resultado[0] == 999)
	play.estado = 1
	consulta.consultar(play)
	checar("Play sem atualização", resultado[0] == 0)
	play.estado = -1
	consulta.consultar(play)
	checar("erro da Play não anuncia versão", resultado[0] == 0)
	consulta.consultar()
	checar("PC sem plugin não anuncia versão", resultado[0] == 0)
	play.estado = 0
	create_timer(0.4).timeout.connect(func(): play.estado = 2)
	await consulta.consultar(play)
	checar("consulta assíncrona recebe resposta", resultado[0] == 999)
	play.estado = 0
	await consulta.consultar(play)
	checar("consulta sem resposta termina sem aviso", resultado[0] == 0)
	var h = load("res://hub.tscn").instantiate()
	root.add_child(h)
	await process_frame
	if is_instance_valid(h._janela_recompensa): h._janela_recompensa.free()
	limpar(h)
	var codigo: int = root.get_node("GameData").VERSAO_CODIGO + 1
	var texto := JSON.stringify({"codigo": codigo, "versao": "9.9.9", "novidades": ["Novidade da versão."]})
	h._tratar_versao(texto)
	checar("JSON sozinho não confirma disponibilidade", avisos(h).is_empty())
	h._codigo_atualizacao_loja = codigo
	h._tratar_versao(texto)
	checar("Play confirmada abre mesma notinha", avisos(h).size() == 1)
	checar("metadados da mesma versão usados", avisos(h)[0]._dados["versao"] == "9.9.9")
	h._tratar_versao(texto)
	checar("não duplica aviso", avisos(h).size() == 1)
	limpar(h)
	h._janela_recompensa = Control.new()
	h.add_child(h._janela_recompensa)
	h._tratar_versao(texto)
	h._tratar_versao(texto)
	checar("aguarda recompensa sem abrir aviso", avisos(h).is_empty())
	h._janela_recompensa.queue_free()
	await process_frame
	await process_frame
	checar("abre uma única notinha após recompensa", avisos(h).size() == 1)
	limpar(h)
	h._tratar_versao('{"codigo": 1, "versao": "antiga", "novidades": ["Texto antigo"]}')
	checar("JSON antigo não impede aviso", avisos(h).size() == 1)
	checar("não mostra notas de outra versão", avisos(h)[0]._dados["versao"] == "" and avisos(h)[0]._dados["novidades"] == ["Confira as novidades na Play Store."])
	limpar(h)
	h._tratar_versao("inválido")
	checar("JSON inválido usa aviso genérico", avisos(h).size() == 1)
	limpar(h)
	h._codigo_atualizacao_loja = root.get_node("GameData").VERSAO_CODIGO
	h._tratar_versao(texto)
	checar("versão instalada não abre aviso", avisos(h).is_empty())
	h.queue_free()
	consulta.queue_free()
	await process_frame
	print("RESULTADO: %d falha(s)" % falhas)
	quit(1 if falhas else 0)
