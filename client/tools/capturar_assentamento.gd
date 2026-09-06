## Captura o `assentamento` sem aparelho. Conferencia visual do registo de
## gravura (SPEC.md §11).
##
## Rodar (precisa de display):
##   godot --path client --script res://tools/capturar_assentamento.gd --resolution 720x900
extends SceneTree

var quadro := 0

func _initialize() -> void:
	root.add_child(load("res://scenes/assentamento.tscn").instantiate())

func _process(_d: float) -> bool:
	quadro += 1
	if quadro < 30:
		return false
	DirAccess.make_dir_recursive_absolute("res://../capturas")
	root.get_texture().get_image().save_png("res://../capturas/assentamento.png")
	print("salvo")
	return true
