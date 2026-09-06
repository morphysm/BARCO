## Mostra o `assentamento` vazio e depois o mesmo depois de depor.
##
## Rodar:
##   godot --path client --script res://tools/prova_depositos.gd --resolution 700x800
##
## Serve para ver o que o app promete: um assentamento comeca quase nada e
## so cresce porque alguem lhe deu alguma coisa (GDD §8).
extends SceneTree

## slug da oferenda -> onde no chao
const A_DEPOR := [
	["vela_preta", Vector2(0.26, 0.09)],
	["vela_vermelha", Vector2(-0.27, -0.10)],
	["vela_branca", Vector2(0.22, -0.16)],
	["rosas_negras", Vector2(0.14, 0.27)],
	["pimenta", Vector2(-0.05, 0.30)],
	["marafo", Vector2(0.36, 0.26)],
	["navalha", Vector2(-0.16, 0.26)],
]

var raiz: Node3D
var quadro := 0
var fase := 0

func _initialize() -> void:
	raiz = load("res://scenes/assentamento.tscn").instantiate()
	root.add_child(raiz)

func _process(_d: float) -> bool:
	quadro += 1
	if quadro < 25:
		return false
	if fase == 0:
		_guardar("vazio")
		for par in A_DEPOR:
			var o: Oferenda = load("res://resources/oferendas/%s.tres" % par[0])
			if o == null:
				printerr("sem oferenda: ", par[0])
				continue
			raiz.depor(o, par[1])
		fase = 1
		quadro = 0
		return false
	_guardar("deposto")
	return true

func _guardar(nome: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://../capturas")
	root.get_texture().get_image().save_png("res://../capturas/assentamento_%s.png" % nome)
	print("salvo: ", nome)
