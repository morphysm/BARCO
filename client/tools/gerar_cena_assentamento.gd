## Escreve a cena do `assentamento` a partir da tabela de arranjo, uma vez
## so, para que dai em diante ela se ajuste no editor e nao no codigo.
##
## Rodar:
##   godot --headless --path client --script res://tools/gerar_cena_assentamento.gd
##
## Depois disto a tabela deixa de mandar: quem manda e a cena. Mexer numa
## peca e arrasta-la no editor e gravar.
extends SceneTree

const CENA := "res://scenes/assentamento.tscn"

## posicao poe a BASE da peca naquele ponto; tamanho normaliza a MAIOR
## dimensao do modelo (uma faca deitada quase nao tem altura).
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


func _initialize() -> void:
	var raiz := Node3D.new()
	raiz.name = "Assentamento"
	raiz.set_script(load("res://scripts/ui/assentamento_screen.gd"))
	# Dentro da arvore antes de medir: fora dela o `global_transform` nao
	# se propaga pela cadeia de pais, e todas as caixas envolventes saem
	# erradas — as pecas ficam com a escala e a posicao trocadas.
	root.add_child(raiz)

	var camara := Camera3D.new()
	camara.name = "Camara"
	# Ortogonal de proposito: sem fuga de perspetiva, a imagem le-se como
	# uma pagina impressa e nao como um espaco jogavel (SPEC.md §11).
	camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	camara.size = 1.15
	camara.position = Vector3(0.10, 0.78, 0.95)
	camara.rotation_degrees = Vector3(-38, 0, 0)
	camara.current = true
	raiz.add_child(camara)
	camara.owner = raiz

	var chao := MeshInstance3D.new()
	chao.name = "Chao"
	var plano := PlaneMesh.new()
	# Bem maior que o alcance das velas: a borda cai sempre no escuro e
	# nunca se ve onde o chao acaba.
	plano.size = Vector2(3.0, 3.0)
	plano.subdivide_width = 64
	plano.subdivide_depth = 64
	chao.mesh = plano
	raiz.add_child(chao)
	chao.owner = raiz

	for peca in NGANGA:
		var cena: PackedScene = load("res://resources/modelos/%s.glb" % peca["m"])
		var no: Node3D = cena.instantiate()
		no.name = peca["m"]
		raiz.add_child(no)
		no.owner = raiz
		no.rotation_degrees = Vector3(0, peca["giro"], 0)

		var local := _caixa_local(no)
		var maior: float = maxf(local.size.x, maxf(local.size.y, local.size.z))
		if maior > 0.0:
			no.scale = Vector3.ONE * (peca["tamanho"] / maior)
		# `no.transform` leva a caixa local ao espaco do pai, ja com o giro
		# e a escala aplicados.
		var caixa := no.transform * local
		var centro := caixa.get_center()
		no.position += peca["onde"] - Vector3(centro.x, caixa.position.y, centro.z)

		# As velas sao a luz da cena. O grupo e como o script as encontra,
		# entao uma vela nova so precisa de entrar no grupo.
		if peca["m"].begins_with("vela_"):
			no.add_to_group("vela", true)

	var empacotada := PackedScene.new()
	assert(empacotada.pack(raiz) == OK)
	assert(ResourceSaver.save(empacotada, CENA) == OK)
	print("escrito %s — %d pecas" % [CENA, NGANGA.size()])
	raiz.free()
	quit()


## Caixa envolvente de um no, no espaco LOCAL dele — sem contar a
## transformacao do proprio no.
##
## As transformacoes sao acumuladas a mao em vez de se pedir
## `global_transform`: num script de SceneTree o global nao se propaga, e
## pedi-lo devolve identidade com um erro por cada malha. Assim a medida e
## a mesma dentro e fora da arvore.
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
