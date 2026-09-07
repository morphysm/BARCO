## Capta o eclipse em varios instantes, para se ver a travessia sem a
## esperar.
##   godot --path client --script res://tools/ver_eclipse.gd --resolution 720x900
extends SceneTree
var r: Node2D
var q := 0
var i := 0
const FASES := [0.0, 0.25, 0.45, 0.58, 0.70, 0.80, 0.90]

func _initialize() -> void:
	r = load("res://scenes/eclipse.tscn").instantiate()
	root.add_child(r)

func _process(_d: float) -> bool:
	q += 1
	if q < 12:
		return false
	if i >= FASES.size():
		return true
	r.set_process(false)
	r.get("_material").set_shader_parameter("fase", FASES[i])
	if q < 14:
		return false
	root.get_texture().get_image().save_png("/tmp/claude-1000/-home-kadaver-Documents-BARCO/32451f68-0717-464f-9901-83ca574324b6/scratchpad/eclipse_%d.png" % int(FASES[i] * 100))
	i += 1
	q = 12
	return false
