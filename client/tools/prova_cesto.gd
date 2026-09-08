## Prova o cesto e os creditos contra o servidor A SERIO, so de leitura e
## de emissao de codigo — nao paga nada e nao credita nada.
##
##   godot --path client --headless res://tools/prova_cesto.tscn
##
## E uma cena e nao um `--script`: com `--script` nada fica dentro da
## arvore e o `HTTPRequest` recusa-se a trabalhar.
extends Node


func _ready() -> void:
	Conta.set("REGISTO", "user://prova_cesto_conta.json")
	DirAccess.remove_absolute(
		ProjectSettings.globalize_path("user://prova_cesto_conta.json"))
	Conta.set("_a_falar", false)
	for campo in ["_id", "_token", "_renovar"]:
		Conta.set(campo, "")
	Conta.set("_expira", 0.0)

	print("1. identidade")
	await Conta.entrar()
	print("   ha=%s  id=%s" % [Conta.ha(), Conta.id().substr(0, 8)])
	if not Conta.ha():
		get_tree().quit(1)
		return

	print("")
	print("2. creditos por gastar (identidade nova: zero)")
	await Creditos.actualizar()
	print("   %s" % Creditos.tudo())

	print("")
	print("3. pedir um cesto: 3 pimentas + 1 marafo")
	var cod: String = await Creditos.pedir_codigo({"pimenta": 3, "marafo": 1})
	print("   codigo: %s" % (cod if cod != "" else "(falhou)"))

	print("")
	print("4. cesto vazio nao emite codigo")
	var vazio: String = await Creditos.pedir_codigo({})
	print("   codigo: %s" % ("'" + vazio + "'" if vazio == "" else vazio))

	print("")
	print("5. um acto que nao existe nao passa")
	var mau: String = await Creditos.pedir_codigo({"nao_existe": 1})
	print("   codigo: %s" % ("'" + mau + "'" if mau == "" else mau))
	get_tree().quit()
