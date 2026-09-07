## Prova o `pedido`: escreve, deita ao caldeirao, e mostra o menu.
##   godot --path client --script res://tools/prova_pedido.gd --resolution 700x1244
extends SceneTree
var r: Node3D
var q := 0
var fase := 0

func _initialize() -> void:
	# Provas nunca escrevem nos dados a serio: um `pedido` de prova ficava
	# espetado no tridente de quem usa o app, a arder sete dias reais.
	Pedido.REGISTO = "user://prova_pedidos.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Pedido.REGISTO))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://prova_depositos.json"))

	r = load("res://scenes/assentamento.tscn").instantiate()
	root.add_child(r)

func _process(_d: float) -> bool:
	q += 1
	if q < 25:
		return false
	match fase:
		0:
			for t in ["pelo que me foi tirado", "que a porta se feche", "sete dias"]:
				r.call("acender_pedido", t)
			# envelhecer dois deles, para se ver o papel a meio e quase ido
			var ps = r.get("_pedidos")
			ps[1].duracao = 100.0
			ps[1].aceso_em = Time.get_unix_time_from_system() - 45.0
			ps[2].duracao = 100.0
			ps[2].aceso_em = Time.get_unix_time_from_system() - 88.0
			fase = 1; q = 0
		1:
			root.get_texture().get_image().save_png("res://../capturas/pedidos_caldeirao.png")
			r.get("_menu").visible = true
			r.call("_actualizar_lista")
			fase = 2; q = 0
		2:
			root.get_texture().get_image().save_png("res://../capturas/pedidos_menu.png")
			print("salvo")
			return true
	return false
