## Atira um balde de sangue ao chao do `assentamento` e fotografa o
## gesto: a meio do espalhar e ja assentado.
##
##   godot --path client --script res://tools/ver_sangue.gd --resolution 700x900
##
## Com `-- sem` nao atira nada: e a mesma cena sem a poca, para se ver
## por diferenca o que e que a poca poe no ecra e o que ja la estava.
##
## Escreve em registos DE LADO. Nem os `depositos` nem os `pedidos` de
## quem esta a usar o app sao tocados.
extends SceneTree

var _ecra: Node
var _relogio := 0.0
var _atirado := false
var _quadros := 0


func _initialize() -> void:
	var cena: Node = load("res://scenes/assentamento.tscn").instantiate()
	_ecra = cena
	_ecra.set("REGISTO", "user://ver_sangue_depositos.json")
	Pedido.REGISTO = "user://ver_sangue_pedidos.json"
	for r in [_ecra.get("REGISTO"), Pedido.REGISTO]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(r))
	root.add_child(cena)


func _process(d: float) -> bool:
	_relogio += d
	if not _atirado and _relogio > 1.0:
		_atirado = true
		if not OS.get_cmdline_user_args().has("sem"):
			var sangue: Oferenda = load("res://resources/oferendas/sangue.tres")
			# A frente da nganga, onde o chao se ve mesmo: a camara e ortogonal
			# e olha de +x, entao e para +x que o chao abre.
			_ecra.depor(sangue, Vector2(0.28, 0.02))
			print("balde atirado")
	if _atirado:
		_quadros += 1
		if _quadros == 14:
			root.get_texture().get_image().save_png("res://../capturas/sangue_a_cair.png")
		if _quadros == 90:
			var nome := "sangue_sem" if OS.get_cmdline_user_args().has("sem") else "sangue"
			root.get_texture().get_image().save_png("res://../capturas/%s.png" % nome)
			print("fotografado")
			return true
	return _relogio > 25.0
