## Escreve o catalogo de `oferendas` e reduz a cena do `assentamento` ao
## seu fundamento.
##
## Rodar:
##   godot --headless --path client --script res://tools/gerar_oferendas.gd
##
## A divisao vem de SPEC.md §8.1 e do GDD §8: o `assentamento` acumula o
## que lhe e dado. O fundamento — o caldeirao e o que o faz ser o
## assentamento daquela entidade — e autoral e esta na cena. Tudo o resto
## chega porque alguem o depos, na posicao que escolheu, e fica.
##
## Por isso a cena de partida tem de ser quase vazia. Um `assentamento`
## cheio no primeiro dia da de graca aquilo que o app inteiro cobra em
## tempo, gesto e dinheiro.
extends SceneTree

const CENA := "res://scenes/assentamento.tscn"
const OferendaS := preload("res://scripts/resources/oferenda.gd")

## Fica na cena: o vaso, e o que o define.
## `Exu Aranha` e a teia que tece: a teia e do vaso, nao coisa que se
## ofereca.
const FUNDAMENTO := [
	"cauldron", "galhos", "horse_bone", "rusty_chains",
	"skull_para_caveira", "baphomet_head", "spider_web",
]

## Sai da cena e passa a catalogo. `cafes` segue SPEC.md §10.1.
const CATALOGO := [
	{"slug": "vela_preta", "nome": "Vela preta", "tipo": "luz",
		"modelo": "vela_preta", "tamanho": 0.24, "vela": true, "cafes": 1},
	{"slug": "vela_vermelha", "nome": "Vela vermelha", "tipo": "luz",
		"modelo": "vela_vermlha", "tamanho": 0.22, "vela": true, "cafes": 1},
	{"slug": "vela_branca", "nome": "Vela branca", "tipo": "luz",
		"modelo": "vela_branca", "tamanho": 0.22, "vela": true, "cafes": 1},
	{"slug": "rosas_negras", "nome": "Rosas negras", "tipo": "botanica",
		"modelo": "black_rose", "tamanho": 0.13, "vela": false, "cafes": 1},
	{"slug": "pimenta", "nome": "Pimenta", "tipo": "botanica",
		"modelo": "chili_pepper", "tamanho": 0.09, "vela": false, "cafes": 1},
	{"slug": "navalha", "nome": "Navalha", "tipo": "objeto",
		"modelo": "knife", "tamanho": 0.20, "vela": false, "cafes": 1},
	{"slug": "marafo", "nome": "Marafo", "tipo": "bebida",
		"modelo": "bottle_to_paloo", "tamanho": 0.18, "vela": false, "cafes": 1},
	# O `sacrificio` e simbolico: o abate real e substituido por um ato
	# digital (GDD §1, §6). O sangue e o que fica no assentamento depois.
	{"slug": "sangue", "nome": "Sangue", "tipo": "sangue",
		"modelo": "sangue", "tamanho": 0.22, "vela": false, "cafes": 7},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/oferendas")
	for o in CATALOGO:
		var r: Oferenda = OferendaS.new()
		r.slug = o["slug"]
		r.nome = o["nome"]
		r.tipo = o["tipo"]
		r.modelo = "res://resources/modelos/%s.glb" % o["modelo"]
		r.tamanho = o["tamanho"]
		r.e_vela = o["vela"]
		r.cafes = o["cafes"]
		assert(ResourceSaver.save(r, "res://resources/oferendas/%s.tres" % r.slug) == OK)

	var raiz: Node3D = load(CENA).instantiate()
	root.add_child(raiz)
	var saiu: Array[String] = []
	for filho in raiz.get_children():
		if filho is Node3D and filho.name != "Chao" and filho.name != "Camara":
			if not FUNDAMENTO.has(String(filho.name)):
				saiu.append(String(filho.name))
				raiz.remove_child(filho)
				filho.free()

	var empacotada := PackedScene.new()
	assert(empacotada.pack(raiz) == OK)
	assert(ResourceSaver.save(empacotada, CENA) == OK)
	print("catalogo: %d oferendas" % CATALOGO.size())
	print("fundamento na cena: %s" % [FUNDAMENTO])
	print("saiu da cena e passou a oferenda: %s" % [saiu])
	raiz.free()
	quit()
