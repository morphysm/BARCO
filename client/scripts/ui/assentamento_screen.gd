## O `assentamento`. GLOSSARY.md, GDD §8, SPEC.md §8.1.
##
## Nao e um quarto iluminado. E um plano escuro visto de um so ponto, sem
## paredes e sem camara que gire — uma chapa, nao um mundo. SPEC.md §11:
## a presenca indica-se por `ponto`, luz, fumo e movimento de objeto.
##
## A vela e a unica luz. Enquanto arde, ve-se; quando acaba, o
## `assentamento` fica no escuro. A vela ja e cronometrada pelo servidor
## (SPEC.md §8.1) — aqui ela deixa de ser um relogio e passa a ser a razao
## pela qual ha alguma coisa visivel.
extends Node3D

const COR_TINTA := Color(0.937, 0.925, 0.882)

## Altura, em metros, a que cada modelo e normalizado. Os .glb vem em
## escalas diferentes; sem isto o caldeirao e a vela nao se falam.
const ALTURA_CALDEIRAO := 0.42
const ALTURA_VELA := 0.26

var _gravura: Shader
var _luz: Vector3
var _chama: MeshInstance3D
var _energia_base := 1.0
var _tempo := 0.0


func _ready() -> void:
	_gravura = load("res://shaders/gravura.gdshader")
	_montar_camara()
	_montar_chao()

	var caldeirao := _pousar("res://resources/modelos/cauldron.glb",
		Vector3(0, 0, 0), ALTURA_CALDEIRAO)
	var vela := _pousar("res://resources/modelos/vela_preta.glb",
		Vector3(0.24, 0, 0.07), ALTURA_VELA)

	# A chama fica no topo da vela, e e de la que vem toda a luz.
	var topo := _caixa_mundo(vela)
	_luz = Vector3(topo.get_center().x, topo.end.y + 0.015, topo.get_center().z)
	_montar_chama()
	set_process(true)


func _process(delta: float) -> void:
	# Uma vela nao arde estavel. O bruxulear e lento e pequeno: se for
	# depressa demais le-se como luz de discoteca, nao como cera.
	_tempo += delta
	var bruxuleio := 1.0 + 0.06 * sin(_tempo * 3.1) + 0.04 * sin(_tempo * 7.7 + 1.3)
	_aplicar_luz(_energia_base * bruxuleio)
	if _chama != null:
		_chama.scale = Vector3.ONE * (1.0 + 0.08 * sin(_tempo * 9.0))


# --- cena --------------------------------------------------------------

func _montar_camara() -> void:
	var c := Camera3D.new()
	# Ortogonal de proposito: sem fuga de perspetiva, a imagem le-se como
	# uma pagina impressa e nao como um espaco jogavel (SPEC.md §11).
	c.projection = Camera3D.PROJECTION_ORTHOGONAL
	c.size = 1.15
	c.position = Vector3(0.10, 0.78, 0.95)
	c.rotation_degrees = Vector3(-38, 0, 0)
	add_child(c)


func _montar_chao() -> void:
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	# Bem maior que o alcance da vela: assim a borda do plano cai sempre no
	# escuro e nunca se ve onde o chao acaba.
	plano.size = Vector2(3.0, 3.0)
	# Subdividir: a hachura precisa de normais e o sombreado varia com a
	# distancia a chama.
	plano.subdivide_width = 64
	plano.subdivide_depth = 64
	chao.mesh = plano
	chao.material_override = _material()
	add_child(chao)


func _montar_chama() -> void:
	_chama = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.012
	esfera.height = 0.03
	_chama.mesh = esfera
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = COR_TINTA
	_chama.material_override = m
	_chama.position = _luz
	add_child(_chama)


## Instancia um modelo, normaliza a altura e assenta-o no chao.
func _pousar(caminho: String, onde: Vector3, altura: float) -> Node3D:
	var cena: PackedScene = load(caminho)
	var no: Node3D = cena.instantiate()
	add_child(no)

	# Medir em espaco de mundo, sempre. Os modelos vem de fontes
	# diferentes, uns de pe em Y outros em Z, e com escalas proprias; so
	# a caixa em mundo diz qual e a altura de facto.
	var caixa := _caixa_mundo(no)
	if caixa.size.y > 0.0:
		no.scale = Vector3.ONE * (altura / caixa.size.y)
		caixa = _caixa_mundo(no)          # escalar move tudo: medir de novo
	# Assentar: o fundo do modelo toca o chao, o centro fica onde se pede.
	var centro := caixa.get_center()
	no.position += onde - Vector3(centro.x, caixa.position.y, centro.z)

	for malha in _malhas(no):
		malha.material_override = _material()
	return no


func _material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _gravura
	m.set_shader_parameter("cor_tinta", COR_TINTA)
	return m


func _aplicar_luz(energia: float) -> void:
	for malha in _malhas(self):
		var m := malha.material_override
		if m is ShaderMaterial:
			m.set_shader_parameter("luz_pos", _luz)
			m.set_shader_parameter("luz_energia", energia)


# --- utilitarios -------------------------------------------------------

func _malhas(raiz: Node) -> Array[MeshInstance3D]:
	var saida: Array[MeshInstance3D] = []
	if raiz is MeshInstance3D and raiz != _chama:
		saida.append(raiz)
	for filho in raiz.get_children():
		saida.append_array(_malhas(filho))
	return saida


## Caixa envolvente de um modelo, em espaco de mundo.
##
## Em mundo e nao em local: em local a caixa vem nas unidades cruas do
## ficheiro — centenas — e sem a escala do proprio no. Foi assim que a
## chama foi parar a 374 metros de altura e o `assentamento` ficou todo
## preto.
func _caixa_mundo(no: Node3D) -> AABB:
	var total := AABB()
	var primeiro := true
	for malha in _malhas(no):
		if malha.mesh == null:
			continue
		var caixa: AABB = malha.global_transform * malha.mesh.get_aabb()
		if primeiro:
			total = caixa
			primeiro = false
		else:
			total = total.merge(caixa)
	return total
