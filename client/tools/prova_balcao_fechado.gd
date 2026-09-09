## Prova que `Servidor.vende = false` fecha o balcao por todas as portas.
##   godot --path client --headless res://tools/prova_balcao_fechado.tscn
##
## E uma cena e nao um `--script`: o `Creditos` e um autoload, e com
## `--script` os autoloads nao existem.
##
## Nao e uma preferencia de interface: `vende` e a chave operacional que
## fecha todas as entradas do pagamento ao mesmo tempo, sem fechar o ritual
## gratuito. Ver `resources/servidor.gd`.
##
## O que se prova e que nao ha uma segunda porta esquecida: nem o botao,
## nem a tira de `oferendas`, nem o `abrir_balcao` chamado a mao pelo
## portao do arrasto.
extends Node

var _falhas := 0


func _ready() -> void:
	var s: Servidor = load("res://resources/servidor/supabase.tres")
	print("supabase.tres: vende = %s, vende_na_web = %s  ->  aqui: %s"
		% [s.vende, s.vende_na_web, s.vende_aqui()])
	print("a correr na web: %s\n" % OS.has_feature("web"))

	# Um par possivel: vende no executavel, nao vende na pagina.
	var so_desktop := Servidor.new()
	so_desktop.url = "https://exemplo.invalido"
	so_desktop.vende = true
	so_desktop.vende_na_web = false
	_checar("executavel vende, pagina nao: aqui da %s"
		% so_desktop.vende_aqui(), so_desktop.vende_aqui() != OS.has_feature("web"))
	var nem_uma := Servidor.new()
	nem_uma.vende = false
	nem_uma.vende_na_web = true
	_checar("`vende = false` manda em tudo, mesmo na web",
		not nem_uma.vende_aqui())
	print("")

	await _com(false)
	await _com(true)

	print("")
	if _falhas > 0:
		printerr("%d caso(s) errado(s)." % _falhas)
		get_tree().quit(1)
		return
	print("Todos os casos certos.")
	get_tree().quit()


func _com(vende: bool) -> void:
	# Um `Servidor` so para a prova: nao se mexe no que vai no jogo.
	var s := Servidor.new()
	s.url = "https://exemplo.invalido"
	# `vende_aqui()` e que decide; aqui poe-se o par que da nesta
	# plataforma o resultado que se quer provar.
	s.vende = vende
	s.vende_na_web = vende
	Creditos.set("_servidor", s)

	_checar("vende=%s: Creditos.vende()" % vende, Creditos.vende() == vende)

	var ecra: Node = load("res://scenes/assentamento.tscn").instantiate()
	add_child(ecra)
	# Um quadro para o `_ready` e o `_montar_tira` correrem.
	await get_tree().process_frame
	await get_tree().process_frame

	var comprar := _achar_botao(ecra, "comprar")
	var pedido := _achar_botao(ecra, "escrever um pedido · grátis")
	var precos := _quantos_botoes_com_preco(ecra)

	_checar("vende=%s: botao `comprar` %s" % [vende, "existe" if vende else "nao existe"],
		(comprar != null) == vende)
	_checar("vende=%s: tira de oferendas %s" % [vende, "tem precos" if vende else "vazia"],
		(precos > 0) == vende)
	# O `pedido` e gratis e NUNCA depende disto: e a metade que corre sem
	# servidor nenhum, e e ela que fica quando o balcao fecha.
	_checar("vende=%s: o pedido gratis fica sempre" % vende, pedido != null)

	# A ULTIMA porta, e a que se via de fora: sem venda nao nasce
	# identidade nenhuma. Com o balcao fechado mas esta aberta, cada
	# pessoa que abrisse a pagina publica deixava uma linha permanente
	# em `auth.users` do projecto a serio.
	Conta.set("_servidor", s)
	for campo in ["_id", "_token", "_renovar"]:
		Conta.set(campo, "")
	Conta.set("_a_falar", false)
	await Conta.entrar()
	# So se prova a metade NEGATIVA, e de proposito: que com o balcao
	# fechado nao nasce identidade nenhuma. A positiva — que com venda
	# nasce mesmo — nao se prova aqui, porque precisa de um servidor a
	# responder; quem a prova e o `prova_cesto.tscn`, contra o a serio.
	if not vende:
		_checar("vende=false: nenhuma conta foi criada", not Conta.ha())

	# A porta de tras: o portao do arrasto chama isto a mao.
	ecra.abrir_balcao()
	await get_tree().process_frame
	var balcao: Variant = ecra.get("_balcao")
	_checar("vende=%s: abrir_balcao() %s" % [vende, "abre" if vende else "nao abre"],
		(balcao != null and is_instance_valid(balcao)) == vende)

	ecra.queue_free()
	await get_tree().process_frame


func _achar_botao(no: Node, texto: String) -> Button:
	if no is Button and (no as Button).text == texto:
		return no
	for f in no.get_children():
		var achado: Button = _achar_botao(f, texto)
		if achado != null:
			return achado
	return null


## Botoes cujo rotulo traz um preco: sao as `oferendas` a venda.
func _quantos_botoes_com_preco(no: Node) -> int:
	var n := 0
	if no is Button and (no as Button).text.contains("US$"):
		n += 1
	for f in no.get_children():
		n += _quantos_botoes_com_preco(f)
	return n


func _checar(nome: String, certo: bool) -> void:
	if not certo:
		_falhas += 1
	print("  %s  %s" % ["ok   " if certo else "FALHA", nome])
