extends SceneTree
## Abre o hub sem tela por alguns quadros e troca de aba/capítulo, para pegar erro
## de script nos sons do hub (estojo, loja, capítulo). Faça backup do save antes.
## Uso: Godot --headless --path . -s tools/teste_abrir_hub.gd

func _initialize() -> void:
	_rodar()

func _rodar() -> void:
	var h = load("res://hub.tscn").instantiate()
	root.add_child(h)
	for i in 10:
		await process_frame
	for aba in ["estojo", "loja", "lutar"]:
		h._alterar_aba(aba)
		await process_frame
	h._mudar_capitulo(1)
	await process_frame
	h._mudar_capitulo(-1)
	for i in 10:
		await process_frame
	print("HUB OK")
	quit()
