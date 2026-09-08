## Mostra o balcao, para se conferir a olho.
##
##   godot --path client res://tools/ver_comprar.tscn --resolution 1600x1000
extends Node
var _q := 0
var _c: Comprar

func _ready() -> void:
	var oferendas: Array[Oferenda] = []
	for f in ResourceLoader.list_directory("res://resources/oferendas/"):
		if f.ends_with(".tres"):
			var o: Oferenda = load("res://resources/oferendas/%s" % f)
			if o != null:
				oferendas.append(o)
	oferendas.sort_custom(func(a, b): return a.nome < b.nome)
	_c = Comprar.new(oferendas)
	add_child(_c)
	set_process(true)

func _process(_d: float) -> void:
	_q += 1
	if _q == 20:
		# Um cesto escolhido, para a fotografia mostrar a conta feita.
		_c.call("_mudar", "pimenta", 3)
		_c.call("_mudar", "marafo", 1)
		_c.call("_mudar", "sangue", 1)
	if _q == 60:
		get_viewport().get_texture().get_image().save_png("res://../capturas/comprar.png")
		if OS.get_cmdline_user_args().has("codigo"):
			_c.call("_pedir_codigo")
	if _q == 200 and OS.get_cmdline_user_args().has("codigo"):
		get_viewport().get_texture().get_image().save_png("res://../capturas/comprar_codigo.png")
		get_tree().quit()
	elif _q == 61 and not OS.get_cmdline_user_args().has("codigo"):
		get_tree().quit()
