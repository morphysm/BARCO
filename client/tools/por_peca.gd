## Acrescenta uma peca ao `assentamento` sem refazer a cena.
##
## Rodar:
##   godot --headless --path client --script res://tools/por_peca.gd -- MODELO x y z tamanho giro [vela]
##
## Ao contrario de `gerar_cena_assentamento.gd`, que escreve a cena do
## zero, este carrega a que la esta e so lhe junta um no. E o que permite
## acrescentar uma peca depois de a nganga ja ter sido arrumada a mao no
## editor, sem deitar esse trabalho fora.
extends SceneTree

const CENA := "res://scenes/assentamento.tscn"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 6:
		printerr("uso: -- MODELO x y z tamanho giro [vela]")
		quit(1)
		return
	var modelo := a[0]
	var onde := Vector3(float(a[1]), float(a[2]), float(a[3]))
	var tamanho := float(a[4])
	var giro := float(a[5])
	var e_vela := a.size() > 6 and a[6] == "vela"

	var raiz: Node3D = load(CENA).instantiate()
	root.add_child(raiz)

	# Se a peca ja la estiver, sai e volta a entrar no sitio novo. Assim o
	# mesmo comando serve para acrescentar e para mudar de lugar.
	var antiga := raiz.get_node_or_null(NodePath(modelo))
	if antiga != null:
		raiz.remove_child(antiga)
		antiga.free()

	var no: Node3D = load("res://resources/modelos/%s.glb" % modelo).instantiate()
	no.name = modelo
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
	assert(ResourceSaver.save(empacotada, CENA) == OK)
	print("acrescentado %s em (%.2f, %.2f, %.2f), tamanho %.2f" % [
		modelo, onde.x, onde.y, onde.z, tamanho])
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
