## Prova a identidade anonima contra um Supabase LOCAL.
##
##   npx supabase start
##   godot --path client --headless res://tools/prova_conta.tscn -- URL CHAVE
##
## E uma CENA e nao um `--script`: com `--script` nada fica dentro da
## arvore, e o `HTTPRequest` recusa-se a trabalhar fora dela. Descoberto a
## tentar, e a mensagem de erro nao dizia isso.
##
## Nao toca no projecto alojado nem no ficheiro de conta de quem usa o
## app: o `REGISTO` do `Conta` nao e `const` e aponta-se para outro sitio.
extends Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("faltam a url e a chave publica do supabase local")
		get_tree().quit(1)
		return

	var s := Servidor.new()
	s.url = args[0]
	s.chave_publica = args[1]

	Conta.set("REGISTO", "user://prova_conta.json")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://prova_conta.json"))
	_esquecer(s)

	print("1. primeira vez: nao ha nada guardado")
	print("   antes:  ha=%s" % Conta.ha())
	await Conta.entrar()
	print("   depois: ha=%s  id=%s" % [Conta.ha(), Conta.id().substr(0, 8)])
	var primeiro := Conta.id()

	print("")
	print("2. chamar outra vez nao cria outra identidade")
	await Conta.entrar()
	print("   id=%s  mesma=%s" % [Conta.id().substr(0, 8), Conta.id() == primeiro])

	print("")
	print("3. token expirado: renova, e continua a MESMA pessoa")
	Conta.set("_expira", 0.0)
	await Conta.entrar()
	print("   id=%s  mesma=%s" % [Conta.id().substr(0, 8), Conta.id() == primeiro])

	print("")
	print("4. reabrir o app: le do disco, sem falar com o servidor")
	var guardado := Conta.id()
	Conta.set("_id", "")
	Conta.set("_token", "")
	Conta.call("_ler")
	print("   id=%s  mesma=%s" % [Conta.id().substr(0, 8), Conta.id() == guardado])

	print("")
	print("5. os cabecalhos levam a chave publica E o token da pessoa")
	for h in Conta.cabecalhos():
		print("   %s..." % h.substr(0, 30))

	print("")
	print("6. servidor fora do ar: NAO trava nada")
	var mau := Servidor.new()
	mau.url = "http://127.0.0.1:1"
	mau.chave_publica = "x"
	_esquecer(mau)
	await Conta.entrar()
	print("   ha=%s   (o ritual segue na mesma)" % Conta.ha())
	get_tree().quit()


func _esquecer(s: Servidor) -> void:
	# O `_ready` do `Conta` ja arrancou uma conversa com o servidor a
	# serio quando o app abriu. Corta-se, senao a prova fica a espera
	# dela e mede o projecto alojado em vez do local.
	Conta.set("_a_falar", false)
	Conta.set("_servidor", s)
	Conta.set("_id", "")
	Conta.set("_token", "")
	Conta.set("_renovar", "")
	Conta.set("_expira", 0.0)
