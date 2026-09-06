## Mostra um modelo sozinho e grande, com a gravura por cima, para se ver
## o que a decimacao lhe fez.
##
## Rodar:
##   godot --path client --script res://tools/ver_modelo.gd --resolution 700x700 -- black_rose
extends SceneTree

var quadro := 0
var nome := "black_rose"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		nome = args[0]

	var raiz := Node3D.new()
	root.add_child(raiz)

	var no: Node3D = load("res://resources/modelos/%s.glb" % nome).instantiate()
	raiz.add_child(no)
	var caixa := _caixa(no)
	var maior: float = maxf(caixa.size.x, maxf(caixa.size.y, caixa.size.z))
	if maior > 0.0:
		no.scale = Vector3.ONE * (0.5 / maior)
	caixa = no.transform * _caixa(no)
	no.position -= caixa.get_center()

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/gravura.gdshader")
	mat.set_shader_parameter("cor_tinta", Color(0.937, 0.925, 0.882))
	mat.set_shader_parameter("luz_pos", PackedVector3Array([Vector3(0.35, 0.35, 0.45)]))
	mat.set_shader_parameter("luz_energia", PackedFloat32Array([1.0]))
	mat.set_shader_parameter("luzes", 1)
	mat.set_shader_parameter("alcance", 1.2)
	for m in _malhas(no):
		m.material_override = mat

	var c := Camera3D.new()
	c.projection = Camera3D.PROJECTION_ORTHOGONAL
	c.size = 0.62
	c.position = Vector3(0.0, 0.18, 0.7)
	c.rotation_degrees = Vector3(-14, 0, 0)
	c.current = true
	raiz.add_child(c)

	var tris := 0
	for m in _malhas(no):
		if m.mesh:
			for i in m.mesh.get_surface_count():
				tris += m.mesh.surface_get_array_index_len(i) / 3
	print("%s — %d triangulos" % [nome, tris])

func _process(_d: float) -> bool:
	quadro += 1
	if quadro < 25:
		return false
	DirAccess.make_dir_recursive_absolute("res://../capturas")
	root.get_texture().get_image().save_png("res://../capturas/modelo_%s.png" % nome)
	print("salvo")
	return true

func _malhas(raiz: Node) -> Array[MeshInstance3D]:
	var saida: Array[MeshInstance3D] = []
	if raiz is MeshInstance3D:
		saida.append(raiz)
	for f in raiz.get_children():
		saida.append_array(_malhas(f))
	return saida

## Sem `global_transform`: num script de SceneTree ele nao se propaga e
## devolve identidade. As transformacoes sao acumuladas a mao.
func _caixa(no: Node3D) -> AABB:
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
