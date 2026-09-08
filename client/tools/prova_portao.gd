## Prova o portao: sem credito, o arrasto NAO comeca.
##
##   godot --path client res://tools/prova_portao.tscn --resolution 1600x1000
extends Node
var _e: Node
var _q := 0

func _ready() -> void:
	Pedido.REGISTO = "user://pp2_ped.json"
	_e = load("res://scenes/assentamento.tscn").instantiate()
	_e.set("REGISTO", "user://pp2_dep.json")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://pp2_dep.json"))
	add_child(_e)
	set_process(true)

func _process(_d: float) -> void:
	_q += 1
	if _q != 40:
		return
	set_process(false)
	var pimenta: Oferenda = load("res://resources/oferendas/pimenta.tres")

	print("1. sem credito nenhum")
	print("   Creditos.quantos('pimenta') = %d" % Creditos.quantos("pimenta"))
	_e.call("_comecar_a_depor", pimenta)
	var na_mao = _e.get("_na_mao")
	print("   o arrasto comecou? %s   (tem de ser falso)" % (na_mao != null))
	var balcao = _e.get("_balcao")
	print("   o balcao abriu?     %s   (tem de ser verdadeiro)" % (balcao != null))

	print("")
	print("2. com um credito fingido, o arrasto comeca")
	Creditos.set("_por_gastar", {"pimenta": 1})
	_e.call("_comecar_a_depor", pimenta)
	print("   o arrasto comecou? %s" % (_e.get("_na_mao") != null))

	print("")
	print("3. e um deposito ja gravado repoe-se sem cobrar nada")
	var antes := Creditos.quantos("pimenta")
	_e.call("depor", pimenta, Vector2(0.1, 0.1))
	print("   creditos antes=%d depois=%d  (repor nao gasta)" % [
		antes, Creditos.quantos("pimenta")])
	get_tree().quit()
