## Escreve a cena do `assentamento` DE RAIZ, a partir da tabela abaixo.
##
## DESTRUTIVO. Apaga tudo o que estiver na cena — incluindo o arranjo feito
## a mao no editor, que e o trabalho de quem monta a nganga. Por isso nao
## corre sem `--refazer`:
##
##   godot --headless --path client --script res://tools/gerar_cena_assentamento.gd -- --refazer
##
## Para acrescentar ou mudar uma peca de sitio SEM perder o resto, o que se
## usa e `por_peca.gd`, que so mexe num no.
##
## Depois da primeira escrita, quem manda e a cena e nao esta tabela.
extends SceneTree

const CENA := "res://scenes/assentamento.tscn"

## posicao poe a BASE da peca naquele ponto; tamanho normaliza a MAIOR
## dimensao do modelo (uma faca deitada quase nao tem altura).
## Só o FUNDAMENTO: o vaso e o que faz este `assentamento` ser o daquela
## entidade. As velas, a rosa, a pimenta, a navalha e a garrafa sairam
## daqui e passaram a `oferendas` — chegam por `depor()`, porque alguem as
## depos (SPEC.md §8.1, GDD §8).
##
## Um `assentamento` cheio no primeiro dia daria de graca o que o app
## inteiro cobra em tempo, gesto e dinheiro.
const NGANGA := [
	{"m": "cauldron",           "onde": Vector3(0.00, 0.000, 0.00),  "tamanho": 0.40, "giro": 0.0},
	{"m": "galhos",             "onde": Vector3(-0.03, 0.240, 0.00), "tamanho": 0.36, "giro": 25.0},
	{"m": "horse_bone",         "onde": Vector3(0.06, 0.200, 0.02),  "tamanho": 0.26, "giro": -40.0},
	{"m": "rusty_chains",       "onde": Vector3(0.00, 0.000, 0.05),  "tamanho": 0.34, "giro": 15.0},
	{"m": "skull_para_caveira", "onde": Vector3(-0.30, 0.000, 0.10), "tamanho": 0.15, "giro": 30.0},
	{"m": "baphomet_head",      "onde": Vector3(0.00, 0.260, -0.26), "tamanho": 0.22, "giro": 8.0},
]


func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--refazer"):
		var quantas := _quantas_pecas()
		printerr("RECUSADO: isto reescreve %s de raiz e apaga o arranjo que la esta"
				% CENA)
		if quantas >= 0:
			printerr("  a cena tem neste momento %d pecas, que se perderiam" % quantas)
		printerr("  para mexer numa peca sem perder o resto: tools/por_peca.gd")
		printerr("  para refazer mesmo assim: acrescentar  -- --refazer")
		quit(1)
		return

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
## Quantas pecas estao na cena que existe, para o aviso dizer o que se
## perderia. -1 se ainda nao ha cena.
func _quantas_pecas() -> int:
	if not ResourceLoader.exists(CENA):
		return -1
	var cena: PackedScene = load(CENA)
	if cena == null:
		return -1
	var estado := cena.get_state()
	var n := 0
	for i in estado.get_node_count():
		var pai := estado.get_node_path(i, true)
		if String(pai) == "." and estado.get_node_name(i) not in ["Camara", "Chao"]:
			n += 1
	return n


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
