## Acrescenta uma peca ao `assentamento` sem refazer a cena.
##
## Rodar:
##   godot --headless --path client --script res://tools/por_peca.gd -- MODELO x y z tamanho giro [vela]
##   godot --headless --path client --script res://tools/por_peca.gd -- MODELO tirar
##
## Ao contrario de `gerar_cena_assentamento.gd`, que escreve a cena do
## zero, este carrega a que la esta e so lhe junta um no. E o que permite
## acrescentar uma peca depois de a nganga ja ter sido arrumada a mao no
## editor, sem deitar esse trabalho fora.
##
## Por omissao escreve no FUNDAMENTO, que esta travado. Para escrever na
## copia de cenario — que nao e autoral e nao esta travada:
##
##   ... -- --cena cenario MODELO x y z tamanho giro
##
## O no fica com o nome do modelo, e por isso por o mesmo modelo duas
## vezes muda a peca de sitio em vez de acrescentar outra. Para uma
## segunda copia, dar-lhe um nome:
##
##   ... -- --nome black_rose8 black_rose x y z tamanho giro
##
## As duas cenas sao independentes de proposito: a copia nao arrasta atras
## o codigo do ritual, e por isso tambem nao acompanha o fundamento
## sozinha. Uma peca que va para as duas poe-se duas vezes.
extends SceneTree

const FUNDAMENTO := "res://scenes/assentamento.tscn"
const CENARIO := "res://scenes/assentamento_cenario.tscn"

var _cena := FUNDAMENTO


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	a.erase("--destravar")

	var nome := ""
	var j := a.find("--nome")
	if j != -1:
		if j + 1 >= a.size():
			printerr("--nome precisa de um nome")
			quit(1)
			return
		nome = a[j + 1]
		a.remove_at(j + 1)
		a.remove_at(j)

	var i := a.find("--cena")
	if i != -1:
		if i + 1 >= a.size():
			printerr("--cena precisa de um nome: fundamento | cenario")
			quit(1)
			return
		match a[i + 1]:
			"cenario": _cena = CENARIO
			"fundamento": _cena = FUNDAMENTO
			_:
				printerr("cena desconhecida: ", a[i + 1], " (fundamento | cenario)")
				quit(1)
				return
		a.remove_at(i + 1)
		a.remove_at(i)

	# O fundamento esta TRAVADO. A cena e autoral: e o vaso que faz este
	# `assentamento` ser o daquela entidade, e nao se mexe por engano.
	# Quem depoe acrescenta por `depor()`; isto aqui altera o fundamento.
	#
	# O cenario nao: e uma copia para levar para outro sitio, e mexer nela
	# nao altera o `assentamento` de ninguem.
	if _cena == FUNDAMENTO and not OS.get_cmdline_user_args().has("--destravar"):
		printerr("RECUSADO: o fundamento esta travado (ver scenes/assentamento.travado)")
		printerr("  para alterar mesmo assim: acrescentar  -- --destravar")
		printerr("  depois de alterar: python3 tools/verificar_fundamento.py --regravar")
		printerr("  para mexer so na copia de cenario:  -- --cena cenario ...")
		quit(1)
		return

	if a.size() >= 2 and a[1] == "tirar":
		_tirar(nome if nome != "" else a[0])
		return
	if a.size() < 6:
		printerr("uso: [--cena fundamento|cenario] [--nome NO] MODELO x y z tamanho giro [vela]")
		printerr("     [--cena fundamento|cenario] MODELO tirar")
		quit(1)
		return
	var modelo := a[0]
	if nome == "":
		nome = modelo
	var onde := Vector3(float(a[1]), float(a[2]), float(a[3]))
	var tamanho := float(a[4])
	var giro := float(a[5])
	var e_vela := a.size() > 6 and a[6] == "vela"

	var raiz: Node3D = load(_cena).instantiate()
	root.add_child(raiz)

	# Se a peca ja la estiver, sai e volta a entrar no sitio novo. Assim o
	# mesmo comando serve para acrescentar e para mudar de lugar.
	var antiga := raiz.get_node_or_null(NodePath(nome))
	if antiga != null:
		raiz.remove_child(antiga)
		antiga.free()

	var no: Node3D = load("res://resources/modelos/%s.glb" % modelo).instantiate()
	no.name = nome
	raiz.add_child(no)
	no.owner = raiz
	no.rotation_degrees = Vector3(0, giro, 0)

	var local := _caixa_local(no)
	var maior: float = maxf(local.size.x, maxf(local.size.y, local.size.z))
	if maior > 0.0:
		no.scale = Vector3.ONE * (tamanho / maior)
	var caixa := no.transform * local
	var centro := caixa.get_center()
	no.position += onde - Vector3(centro.x, caixa.position.y, centro.z)

	if e_vela:
		no.add_to_group("vela", true)

	var empacotada := PackedScene.new()
	assert(empacotada.pack(raiz) == OK)
	assert(ResourceSaver.save(empacotada, _cena) == OK)
	print("acrescentado %s (%s) em (%.2f, %.2f, %.2f), tamanho %.2f  ->  %s" % [
		nome, modelo, onde.x, onde.y, onde.z, tamanho, _cena.get_file()])
	raiz.free()
	quit()


## Tira uma peca do fundamento. Isto e do vaso, nao dos `depositos`: o que
## alguem depoe nunca se tira (GDD §2).
func _tirar(nome: String) -> void:
	var raiz: Node3D = load(_cena).instantiate()
	root.add_child(raiz)
	var no := raiz.get_node_or_null(NodePath(nome))
	if no == null:
		printerr("nao ha no chamado: ", nome)
		quit(1)
		return
	raiz.remove_child(no)
	no.free()
	var e := PackedScene.new()
	assert(e.pack(raiz) == OK)
	assert(ResourceSaver.save(e, _cena) == OK)
	print("tirado de %s: %s" % [_cena.get_file(), nome])
	raiz.free()
	quit()


## Sem `global_transform`: num script de SceneTree ele nao se propaga.
func _caixa_local(no: Node3D) -> AABB:
	var total := AABB()
	var primeiro := true
	var pilha: Array = [[no, Transform3D.IDENTITY]]
	while pilha:
		var par = pilha.pop_back()
		var n: Node = par[0]
		var t: Transform3D = par[1]
		if n is Node3D and n != no:
			t = t * (n as Node3D).transform
		if n is MeshInstance3D and n.mesh != null:
			var caixa: AABB = t * n.mesh.get_aabb()
			if primeiro:
				total = caixa
				primeiro = false
			else:
				total = total.merge(caixa)
		for f in n.get_children():
			pilha.append([f, t])
	return total
