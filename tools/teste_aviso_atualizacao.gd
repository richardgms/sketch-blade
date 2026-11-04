extends SceneTree
## Confere o JSON público e a exibição do aviso no hub. Execute com backup do save.
## Godot --headless --path . -s tools/teste_aviso_atualizacao.gd

var falhas := 0

func _initialize() -> void:
	_rodar()

func _ok(nome: String, condicao: bool) -> void:
	print(("OK    " if condicao else "FALHA ") + nome)
	if not condicao:
		falhas += 1

func _avisos(hub: Node) -> Array:
	return hub.get_node("HUD").get_children().filter(func(no: Node):
		return no.get_script() == load("res://JanelaAtualizacao.gd"))

func _rodar() -> void:
	var h = load("res://hub.tscn").instantiate()
	root.add_child(h)
	for i in 10:
		await process_frame
	if is_instance_valid(h._janela_recompensa):
		h._janela_recompensa.queue_free()
		await process_frame
	h._aviso_atualizacao_visto = false
	var http := HTTPRequest.new()
	http.timeout = 15.0
	root.add_child(http)
	var erro := http.request(h.URL_VERSAO)
	_ok("requisição de versão iniciada", erro == OK)
	if erro != OK:
		quit(1)
		return
	var resposta: Array = await http.request_completed
	http.queue_free()
	_ok("JSON público responde HTTP 200", resposta[0] == HTTPRequest.RESULT_SUCCESS and resposta[1] == 200)
	var corpo: String = resposta[3].get_string_from_utf8()
	var info = JSON.parse_string(corpo)
	var valido: bool = info is Dictionary and int(info.get("codigo", 0)) == 15 and info.get("versao") == "1.8.0"
	_ok("arquivo público anuncia 1.8.0 (15)", valido)
	if not valido:
		quit(1)
		return
	h._tratar_versao(corpo)
	_ok("versão já instalada não abre aviso", _avisos(h).is_empty())
	h._tratar_versao("{arquivo inválido")
	_ok("JSON inválido não abre aviso", _avisos(h).is_empty())
	var proxima: Dictionary = info.duplicate(true)
	proxima["codigo"] = root.get_node("GameData").VERSAO_CODIGO + 1
	h._tratar_versao(JSON.stringify(proxima))
	_ok("código maior abre o aviso", _avisos(h).size() == 1)
	h._tratar_versao(JSON.stringify(proxima))
	_ok("aviso não se duplica na mesma abertura", _avisos(h).size() == 1)
	print("RESULTADO: %d falha(s)" % falhas)
	quit(1 if falhas > 0 else 0)
