## Captura a sala da `fornalha` sem aparelho. Conferencia visual da boca
## (SPEC.md §2): a porta aberta e a orla do vao.
##
## Rodar (precisa de display):
##   godot --path client --script res://tools/capturar_fornalha.gd --resolution 720x900
extends SceneTree

var quadro := 0

func _initialize() -> void:
	root.add_child(load("res://fornalha.tscn").instantiate())

func _process(_d: float) -> bool:
	quadro += 1
	if quadro < 90:
		return false
	DirAccess.make_dir_recursive_absolute("res://../capturas")
	root.get_texture().get_image().save_png("res://../capturas/fornalha.png")
	print("salvo")
	return true
