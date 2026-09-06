## Mostra um modelo sozinho, com a luz do `assentamento` — vela alaranjada,
## fundo preto, ACES. E o que o app mostra, ao contrario de
## `ver_modelo.gd`, que usa a gravura e ja nao e o registo da cena.
##
##   godot --path client --script res://tools/ver_modelo_luz.gd --resolution 600x700 -- black_rose
extends SceneTree

var q := 0
var nome := "black_rose"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		nome = a[0]
	var raiz := Node3D.new()
	root.add_child(raiz)

	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.147, 0.134)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 3.0
	amb.environment = env
	raiz.add_child(amb)

	var no: Node3D = load("res://resources/modelos/%s.glb" % nome).instantiate()
	raiz.add_child(no)
	var caixa := _caixa(no)
	var maior: float = maxf(caixa.size.x, maxf(caixa.size.y, caixa.size.z))
	if maior > 0.0:
		no.scale = Vector3.ONE * (0.30 / maior)
	caixa = no.transform * _caixa(no)
	no.position -= Vector3(caixa.get_center().x, caixa.position.y, caixa.get_center().z)

	# Duas velas, como no assentamento: uma de cada lado.
	for onde in [Vector3(0.22, 0.20, 0.20), Vector3(-0.20, 0.16, 0.10)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.72, 0.42)
		l.omni_range = 0.6
		l.omni_attenuation = 3.0
		l.light_energy = 0.30
		l.position = onde
		raiz.add_child(l)

	var c := Camera3D.new()
	c.projection = Camera3D.PROJECTION_ORTHOGONAL
	c.size = 0.40
	c.position = Vector3(0, 0.24, 0.40)
	c.rotation_degrees = Vector3(-24, 0, 0)
	c.current = true
	raiz.add_child(c)

	var tris := 0
	for m in _malhas(no):
		if m.mesh:
			for i in m.mesh.get_surface_count():
				tris += m.mesh.surface_get_array_index_len(i) / 3
	print("%s — %d triangulos" % [nome, tris])

func _process(_d: float) -> bool:
	q += 1
	if q < 25:
		return false
	DirAccess.make_dir_recursive_absolute("res://../capturas")
	root.get_texture().get_image().save_png("res://../capturas/luz_%s.png" % nome)
	print("salvo")
	return true

func _malhas(raiz: Node) -> Array[MeshInstance3D]:
	var saida: Array[MeshInstance3D] = []
	if raiz is MeshInstance3D:
		saida.append(raiz)
	for f in raiz.get_children():
		saida.append_array(_malhas(f))
	return saida

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
