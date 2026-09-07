## Prova o gesto de depor sem dedo: pega numa `oferenda`, arrasta-a e
## larga-a, como se alguem o fizesse.
##
## Rodar:
##   godot --path client --script res://tools/prova_gesto.gd --resolution 700x800
extends SceneTree

var r: Node3D
var q := 0
var fase := 0

func _initialize() -> void:
	# Provas nunca escrevem nos dados a serio: um `pedido` de prova ficava
	# espetado no tridente de quem usa o app, a arder sete dias reais.
	Pedido.REGISTO = "user://prova_pedidos.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Pedido.REGISTO))
	var _ecra := load("res://scripts/ui/assentamento_screen.gd")
	_ecra.REGISTO = "user://prova_depositos.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_ecra.REGISTO))

	r = load("res://scenes/assentamento.tscn").instantiate()
	root.add_child(r)

func _process(_d: float) -> bool:
	q += 1
	if q < 20:
		return false
	match fase:
		0:
			var antes: int = r.get("_depositos").size()
			var o: Oferenda = load("res://resources/oferendas/vela_branca.tres")
			r.call("_comecar_a_depor", o)
			print("na mao: %s" % (r.get("_na_mao") != null))
			# arrastar ate um sitio livre a frente do caldeirao
			r.call("_assentar", r.get("_na_mao"), Vector2(-0.30, 0.34))
			r.call("_largar", Vector2(-0.30, 0.34))
			var depois: int = r.get("_depositos").size()
			print("depositos: %d -> %d" % [antes, depois])
			print("na mao depois de largar: %s" % (r.get("_na_mao") != null))
			fase = 1
			q = 0
		1:
			# largar fora do assentamento nao depoe nada
			var antes2: int = r.get("_depositos").size()
			var o2: Oferenda = load("res://resources/oferendas/pimenta.tres")
			r.call("_comecar_a_depor", o2)
			r.call("_largar", null)
			print("largar fora: depositos %d -> %d" % [antes2, r.get("_depositos").size()])
			fase = 2
			q = 0
		2:
			DirAccess.make_dir_recursive_absolute("res://../capturas")
			root.get_texture().get_image().save_png("res://../capturas/gesto_depor.png")
			print("salvo")
			return true
	return false
