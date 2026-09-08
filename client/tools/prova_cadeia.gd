## Metade em Godot da prova da cadeia inteira. Ver `server/prova/cadeia.sh`.
##
## Dois modos, porque entre eles tem de acontecer uma coisa que nao e do
## cliente: o webhook do Ko-fi a entregar o pagamento.
##
##   codigo    -- identidade + cesto, e escreve o codigo no ecra
##   verificar -- le os creditos, gasta um, e le outra vez
extends Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		print("uso: -- URL CHAVE modo")
		get_tree().quit(1)
		return
	var s := Servidor.new()
	s.url = args[0]
	s.chave_publica = args[1]
	var modo := args[2]

	# A sessao vive num ficheiro de lado, partilhado pelas duas corridas:
	# o cesto e os creditos tem de ser da MESMA pessoa.
	Conta.set("REGISTO", "user://prova_cadeia_conta.json")
	Conta.set("_a_falar", false)
	Conta.set("_servidor", s)
	Creditos.set("_servidor", s)
	if modo == "codigo":
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path("user://prova_cadeia_conta.json"))
		for campo in ["_id", "_token", "_renovar"]:
			Conta.set(campo, "")
		Conta.set("_expira", 0.0)
	else:
		Conta.call("_ler")

	await Conta.entrar()
	if not Conta.ha():
		print("SEM IDENTIDADE")
		get_tree().quit(1)
		return

	if modo == "codigo":
		var cod: String = await Creditos.pedir_codigo({"pimenta": 2, "sangue": 1})
		print("ID=%s" % Conta.id())
		print("CODIGO=%s" % cod)
	else:
		await Creditos.actualizar()
		print("CREDITOS_ANTES=%s" % JSON.stringify(Creditos.tudo()))
		var deu: bool = await Creditos.gastar("pimenta")
		print("GASTOU_PIMENTA=%s" % deu)
		await Creditos.actualizar()
		print("CREDITOS_DEPOIS=%s" % JSON.stringify(Creditos.tudo()))
		var outra: bool = await Creditos.gastar("navalha")
		print("GASTOU_NAVALHA=%s  (nao comprada: tem de ser false)" % outra)
	get_tree().quit()
