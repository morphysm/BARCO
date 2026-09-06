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

## A nganga: o que esta no `assentamento`, onde, e de que tamanho.
##
## `tamanho` e em metros e normaliza o modelo pela MAIOR dimensao — nao
## pela altura. Uma faca deitada quase nao tem altura: normaliza-la por Y
## dava-lhe metros de comprimento. `onde` poe a BASE do objeto naquele
## ponto, entao um y acima de zero e o que faz um galho sair de dentro do
## caldeirao em vez de assentar no chao.
##
## Ordem: os que sao velas entram como luz (ver `_e_vela`).
const NGANGA := [
	{"m": "cauldron",           "onde": Vector3(0.00, 0.000, 0.00),  "tamanho": 0.40, "giro": 0.0},
	{"m": "galhos",             "onde": Vector3(-0.03, 0.240, 0.00), "tamanho": 0.36, "giro": 25.0},
	{"m": "horse_bone",         "onde": Vector3(0.06, 0.200, 0.02),  "tamanho": 0.26, "giro": -40.0},
	{"m": "rusty_chains",       "onde": Vector3(0.00, 0.000, 0.05),  "tamanho": 0.34, "giro": 15.0},
	{"m": "skull_para_caveira", "onde": Vector3(-0.30, 0.000, 0.10), "tamanho": 0.15, "giro": 30.0},
	{"m": "vela_preta",         "onde": Vector3(0.26, 0.000, 0.09),  "tamanho": 0.24, "giro": 0.0},
	{"m": "vela_vermlha",       "onde": Vector3(-0.27, 0.000, -0.10),"tamanho": 0.22, "giro": 0.0},
	{"m": "vela_branca",        "onde": Vector3(0.22, 0.000, -0.16), "tamanho": 0.22, "giro": 0.0},
	{"m": "knife",              "onde": Vector3(-0.16, 0.000, 0.26), "tamanho": 0.20, "giro": 70.0},
	{"m": "black_rose",         "onde": Vector3(0.14, 0.000, 0.27),  "tamanho": 0.13, "giro": -20.0},
	{"m": "chili_pepper",       "onde": Vector3(-0.05, 0.000, 0.30), "tamanho": 0.09, "giro": 45.0},
	{"m": "bottle_to_paloo",    "onde": Vector3(0.36, 0.000, 0.26),  "tamanho": 0.18, "giro": 10.0},
]

var _gravura: Shader
var _luzes: Array[Vector3] = []
var _chamas: Array[MeshInstance3D] = []
var _energia_base := 0.55
var _tempo := 0.0


func _ready() -> void:
	_gravura = load("res://shaders/gravura.gdshader")
	_montar_camara()
	_montar_chao()

	for peca in NGANGA:
		var no := _pousar("res://resources/modelos/%s.glb" % peca["m"],
			peca["onde"], peca["tamanho"], peca["giro"])
		if _e_vela(peca["m"]):
			# A chama fica no topo da vela, e e de la que vem a luz.
			var caixa := _caixa_mundo(no)
			_luzes.append(Vector3(
				caixa.get_center().x, caixa.end.y + 0.012, caixa.get_center().z))
	_montar_chamas()
	set_process(true)


func _e_vela(nome: String) -> bool:
	return nome.begins_with("vela_")


func _process(delta: float) -> void:
	# Uma vela nao arde estavel. O bruxulear e lento e pequeno: se for
	# depressa demais le-se como luz de discoteca, nao como cera.
	_tempo += delta
	# Cada chama bruxuleia por sua conta; se todas pulsassem juntas leria-se
	# como um unico interruptor a piscar.
	var energias := PackedFloat32Array()
	for i in _luzes.size():
		var f := float(i) * 2.3
		energias.append(_energia_base * (1.0
			+ 0.06 * sin(_tempo * 3.1 + f)
			+ 0.04 * sin(_tempo * 7.7 + f * 1.7)))
		if i < _chamas.size():
			_chamas[i].scale = Vector3.ONE * (1.0 + 0.08 * sin(_tempo * 9.0 + f))
	_aplicar_luz(energias)


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
	var m := _material()
	m.set_shader_parameter("resposta", 0.42)
	chao.material_override = m
	add_child(chao)


func _montar_chamas() -> void:
	for onde in _luzes:
		var chama := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.010
		esfera.height = 0.026
		chama.mesh = esfera
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = COR_TINTA
		chama.material_override = m
		chama.position = onde
		add_child(chama)
		_chamas.append(chama)


## Instancia um modelo, normaliza a altura e assenta-o no chao.
func _pousar(caminho: String, onde: Vector3, tamanho: float, giro := 0.0) -> Node3D:
	var cena: PackedScene = load(caminho)
	var no: Node3D = cena.instantiate()
	add_child(no)
	no.rotation_degrees = Vector3(0, giro, 0)

	# Medir em espaco de mundo, sempre. Os modelos vem de fontes
	# diferentes, uns de pe em Y outros em Z, e com escalas proprias; so
	# a caixa em mundo diz qual e a altura de facto.
	var caixa := _caixa_mundo(no)
	var maior: float = maxf(caixa.size.x, maxf(caixa.size.y, caixa.size.z))
	if maior > 0.0:
		no.scale = Vector3.ONE * (tamanho / maior)
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


func _aplicar_luz(energias: PackedFloat32Array) -> void:
	var posicoes := PackedVector3Array(_luzes)
	for malha in _malhas(self):
		var m := malha.material_override
		if m is ShaderMaterial:
			m.set_shader_parameter("luz_pos", posicoes)
			m.set_shader_parameter("luz_energia", energias)
			m.set_shader_parameter("luzes", _luzes.size())


# --- utilitarios -------------------------------------------------------

func _malhas(raiz: Node) -> Array[MeshInstance3D]:
	var saida: Array[MeshInstance3D] = []
	if raiz is MeshInstance3D and not _chamas.has(raiz):
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
