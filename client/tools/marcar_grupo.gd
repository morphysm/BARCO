## Poe (ou tira) um no da cena do `assentamento` num grupo, sem tocar em
## mais nada.
##
## Rodar:
##   godot --headless --path client --script res://tools/marcar_grupo.gd -- NO GRUPO [tirar]
##
## Serve para `sem_chama`: as velas cujo modelo nao traz pavio aceso.
extends SceneTree

const CENA := "res://scenes/assentamento.tscn"

func _initialize() -> void:
	# O fundamento esta TRAVADO. A cena e autoral: e o vaso que faz este
	# `assentamento` ser o daquela entidade, e nao se mexe por engano.
	# Quem depoe acrescenta por `depor()`; isto aqui altera o fundamento.
	if not OS.get_cmdline_user_args().has("--destravar"):
		printerr("RECUSADO: o fundamento esta travado (ver scenes/assentamento.travado)")
		printerr("  para alterar mesmo assim: acrescentar  -- --destravar")
		printerr("  depois de alterar: python3 tools/verificar_fundamento.py --regravar")
		quit(1)
		return

	var a := OS.get_cmdline_user_args()
	if a.size() < 2:
		printerr("uso: -- NO GRUPO [tirar]")
		quit(1)
		return
	var raiz: Node3D = load(CENA).instantiate()
	root.add_child(raiz)
	var no := raiz.get_node_or_null(NodePath(a[0]))
	if no == null:
		printerr("nao ha no chamado: ", a[0])
		quit(1)
		return
	if a.size() > 2 and a[2] == "tirar":
		no.remove_from_group(a[1])
		print("%s sai do grupo %s" % [a[0], a[1]])
	else:
		no.add_to_group(a[1], true)
		print("%s entra no grupo %s" % [a[0], a[1]])
	var e := PackedScene.new()
	assert(e.pack(raiz) == OK)
	assert(ResourceSaver.save(e, CENA) == OK)
	raiz.free()
	quit()
