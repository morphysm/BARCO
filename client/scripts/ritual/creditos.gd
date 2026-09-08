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


func _ready() -> void:
	_servidor = load("res://resources/servidor/supabase.tres")


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
	if not Conta.ha():
		await Conta.entrar()
		if not Conta.ha():
			return
	_a_ler = true
	var pedido := HTTPRequest.new()
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
	if not Conta.ha():
		await Conta.entrar()
		if not Conta.ha():
			return ""
	var itens: Array = []
	for slug in cesto:
		if int(cesto[slug]) > 0:
			itens.append({"ato_slug": slug, "quantidade": int(cesto[slug])})
	if itens.is_empty():
		return ""

	var pedido := HTTPRequest.new()
	add_child(pedido)
	var erro := pedido.request(
		_servidor.url + "/rest/v1/rpc/pedir_codigo",
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
