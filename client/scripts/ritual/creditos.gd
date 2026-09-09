## Os creditos: o que foi comprado e ainda nao foi gasto.
##
## Um credito e NOMEADO — uma pimenta, um marafo — e fica preso ao acto
## com que foi emitido. Nao ha conversao, nem soma, nem saldo: quem pagou
## uma pimenta tem uma pimenta. E de propósito, e esta escrito no
## `AGENTS.md` que nao pode ser de outra maneira.
##
## Isto so LE. Quem escreve creditos e o webhook, com a chave de admin —
## o cliente nao tem politica de escrita nenhuma sobre a tabela, e se
## tentasse levava 42501.
extends Node

signal mudaram

## Quantos de cada acto ha por gastar, por slug.
var _por_gastar: Dictionary = {}
var _servidor: Servidor
var _a_ler := false
var _dono := ""


func _ready() -> void:
	_servidor = load("res://resources/servidor/supabase.tres")
	Conta.entrou.connect(_sessao)


func _sessao(dono: String) -> void:
	if _dono != dono:
		_dono = dono
		_por_gastar.clear()
		mudaram.emit()


## Vende-se nesta build? Ver `Servidor.vende`.
##
## Uma pergunta so, e feita em todo o lado onde o dinheiro aparece: o
## botao de `comprar`, a tira de `oferendas`, o balcao. Estando num sitio
## so, fechar o balcao e mudar um campo de um `.tres` — nao e ir procurar
## os tres ecras onde o dinheiro assoma e esperar nao ter falhado nenhum.
##
## Falso quando nao ha `Servidor` nenhum: sem servidor nao ha pagamento,
## e um balcao que nao pode cobrar nao se abre.
func vende() -> bool:
	return _servidor != null and _servidor.vende_aqui()


## Quantos creditos de `slug` estao por gastar.
func quantos(slug: String) -> int:
	return int(_por_gastar.get(slug, 0))


## Ha algum credito por gastar, seja de que acto for?
func algum() -> bool:
	for n in _por_gastar.values():
		if int(n) > 0:
			return true
	return false


func tudo() -> Dictionary:
	return _por_gastar.duplicate()


## Vai buscar ao servidor o que esta por gastar.
##
## Silencioso quando falha: sem rede nao ha creditos para mostrar, e isso
## nao pode impedir nada do resto do app de funcionar.
func actualizar() -> void:
	if _a_ler or _servidor == null or _servidor.url == "":
		return
	await Conta.entrar()
	if not Conta.ha():
		return
	var dono := Conta.id()
	_a_ler = true
	var pedido := HTTPRequest.new()
	pedido.timeout = 20.0
	add_child(pedido)
	var erro := pedido.request(
		_servidor.url + "/rest/v1/creditos?select=ato_slug&spent_at=is.null",
		Conta.cabecalhos(), HTTPClient.METHOD_GET)
	if erro != OK:
		pedido.queue_free()
		_a_ler = false
		return
	var r: Array = await pedido.request_completed
	pedido.queue_free()
	_a_ler = false
	if dono != Conta.id():
		return
	if int(r[1]) < 200 or int(r[1]) >= 300:
		return
	var d = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	if typeof(d) != TYPE_ARRAY:
		return
	var novo: Dictionary = {}
	for linha in d:
		if typeof(linha) != TYPE_DICTIONARY:
			continue
		var s := str(linha.get("ato_slug", ""))
		if s != "":
			novo[s] = int(novo.get(s, 0)) + 1
	if novo != _por_gastar:
		_por_gastar = novo
		mudaram.emit()


## Pede um codigo para um cesto. Devolve o codigo, ou "" se nao deu.
##
## O cesto vem como `{slug: quantidade}`. Quem decide o preco, o codigo e
## o total e o SERVIDOR — aqui so se diz o que se quer.
func pedir_codigo(cesto: Dictionary) -> String:
	if _servidor == null or cesto.is_empty():
		return ""
	await Conta.entrar()
	if not Conta.ha():
		return ""
	if OS.has_feature("web") and not Conta.recuperavel():
		return ""
	var itens: Array = []
	for slug in cesto:
		if int(cesto[slug]) > 0:
			itens.append({"ato_slug": slug, "quantidade": int(cesto[slug])})
	if itens.is_empty():
		return ""

	var pedido := HTTPRequest.new()
	pedido.timeout = 20.0
	add_child(pedido)
	var erro := pedido.request(
		_servidor.url + "/rest/v1/rpc/" + ("pedir_codigo_recuperavel" if OS.has_feature("web") else "pedir_codigo"),
		Conta.cabecalhos(), HTTPClient.METHOD_POST,
		JSON.stringify({"p_itens": itens}))
	if erro != OK:
		pedido.queue_free()
		return ""
	var r: Array = await pedido.request_completed
	pedido.queue_free()
	if int(r[1]) < 200 or int(r[1]) >= 300:
		return ""
	var d = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	return str(d) if typeof(d) == TYPE_STRING else ""


## Estado da encomenda, sem expor o payload do pagamento.
func estado_codigo(codigo: String) -> Dictionary:
	if _servidor == null or codigo == "":
		return {}
	await Conta.entrar()
	if not Conta.ha():
		return {}
	var pedido := HTTPRequest.new()
	pedido.timeout = 15.0
	add_child(pedido)
	var erro := pedido.request(
		_servidor.url + "/rest/v1/rpc/estado_codigo",
		Conta.cabecalhos(), HTTPClient.METHOD_POST,
		JSON.stringify({"p_codigo": codigo}))
	if erro != OK:
		pedido.queue_free()
		return {}
	var r: Array = await pedido.request_completed
	pedido.queue_free()
	if int(r[1]) < 200 or int(r[1]) >= 300:
		return {}
	var d = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	return d if d is Dictionary else {}


func ultima_encomenda() -> Dictionary:
	var r := await consultar("/rest/v1/codigos?select=codigo,codigo_itens(ato_slug,quantidade)&usado_em=is.null&order=created_at.desc&limit=1")
	if r.get("dados") is Array and not r["dados"].is_empty():
		return r["dados"][0]
	return {}


func depor(oferenda: String, onde: Vector2, operacao: String) -> Dictionary:
	var r := await consultar("/rest/v1/rpc/depor_oferenda",
		{"p_operacao": operacao, "p_ato_slug": oferenda, "p_x": onde.x, "p_y": onde.y},
		HTTPClient.METHOD_POST)
	if r.get("dados") is Dictionary:
		await actualizar()
		return r["dados"]
	if r.get("status", 0) == 400:
		return {"recusado": true}
	return {}


func depositos() -> Dictionary:
	# Pagina explicitamente para nao perder registos alem do limite REST.
	var linhas: Array = []
	var inicio := 0
	var dono := Conta.id()
	while true:
		var r := await consultar("/rest/v1/depositos?select=*&order=created_at,id&limit=100&offset=%d" % inicio)
		if dono != Conta.id() or not r.get("dados") is Array:
			return {}
		var pagina: Array = r["dados"]
		linhas.append_array(pagina)
		if pagina.size() < 100:
			return {"dados": linhas}
		inicio += pagina.size()
	return {}


## Transporte comum: renova a sessao e rejeita respostas de outra identidade.
func consultar(caminho: String, corpo: Dictionary = {}, metodo := HTTPClient.METHOD_GET) -> Dictionary:
	await Conta.entrar()
	if _servidor == null or not Conta.ha():
		return {}
	var dono := Conta.id()
	var pedido := HTTPRequest.new()
	pedido.timeout = 20.0
	add_child(pedido)
	var e := pedido.request(_servidor.url + caminho, Conta.cabecalhos(), metodo,
		"" if metodo == HTTPClient.METHOD_GET else JSON.stringify(corpo))
	if e != OK:
		pedido.queue_free()
		return {}
	var r: Array = await pedido.request_completed
	pedido.queue_free()
	if dono != Conta.id():
		return {}
	if int(r[1]) < 200 or int(r[1]) >= 300:
		return {"status": int(r[1])}
	return {"dados": JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())}


## Gasta um credito de `slug`. Devolve se conseguiu.
##
## Quem marca e o SERVIDOR: o cliente nao tem politica de escrita sobre
## `creditos`, e nao pode ter. Se pudesse marcar um credito como gasto,
## podia marca-lo como por gastar.
##
## Falha quando nao ha credito, quando nao ha sessao, e quando nao ha
## rede. Nos tres casos nao se depoe nada — dar a oferenda sem gastar o
## credito era da-la de graca, e recusar depois de ela estar pousada era
## pior.
func gastar(slug: String) -> bool:
	if _servidor == null or slug == "":
		return false
	if not Conta.ha():
		await Conta.entrar()
		if not Conta.ha():
			return false

	var pedido := HTTPRequest.new()
	add_child(pedido)
	var erro := pedido.request(
		_servidor.url + "/rest/v1/rpc/gastar_credito",
		Conta.cabecalhos(), HTTPClient.METHOD_POST,
		JSON.stringify({"p_ato_slug": slug}))
	if erro != OK:
		pedido.queue_free()
		return false
	var r: Array = await pedido.request_completed
	pedido.queue_free()
	if int(r[1]) < 200 or int(r[1]) >= 300:
		return false
	var d = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	if d != true:
		return false
	# A conta local acompanha, para a tira nao continuar a mostrar um
	# credito que ja foi gasto ate a proxima leitura do servidor.
	var n: int = int(_por_gastar.get(slug, 0)) - 1
	if n > 0:
		_por_gastar[slug] = n
	else:
		_por_gastar.erase(slug)
	mudaram.emit()
	return true
