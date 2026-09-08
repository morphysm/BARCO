## A identidade de quem esta a usar o app.
##
## Anonima, e de proposito: nao ha registo, nao ha email, nao ha
## palavra-passe, nao ha ecra de entrar. O app pede uma identidade ao
## servidor na primeira vez que abre e guarda-a; a pessoa nunca ve nada
## disto. Pedir uma conta para riscar um `ponto` era pedir uma coisa a
## troco de nada, e o app so pede o que precisa.
##
## Serve UMA coisa: ligar um pagamento a quem o fez. Sem ela o dinheiro
## entra e o Ko-fi nao sabe a quem dar o acto — o pagamento fica na fila
## manual (SPEC.md §10.4).
##
## NUNCA TRAVA O RITUAL. Riscar os `pontos`, atravessar o eclipse, queimar
## o passado, depor oferendas e escrever `pedidos` sao tudo coisas que
## acontecem no aparelho e que tem de funcionar sem rede nenhuma. Se o
## servidor nao responder, isto falha em silencio e o app segue: so o
## pagamento e que fica por fazer, e o pagamento e a unica parte que
## precisa de servidor.
##
## O QUE ISTO NAO E: uma conta a serio. Uma identidade anonima vive no
## aparelho — quem limpar os dados do site, trocar de browser ou de
## computador fica sem ela, e sem os creditos que tinha por gastar. E o
## preco de nao pedir nada a ninguem. Ligar um email a esta identidade
## para a poder recuperar e o passo seguinte, e ainda nao existe.
extends Node

const REGISTO := "user://conta.json"
## Renova-se antes de expirar, e nao quando expira: uma resposta 401 a
## meio de um pagamento e um pagamento perdido.
const MARGEM_DE_RENOVACAO := 300.0

signal entrou(id: String)

var _servidor: Servidor
var _id := ""
var _token := ""
var _renovar := ""
var _expira := 0.0
var _a_falar := false


func _ready() -> void:
	_servidor = load("res://resources/servidor/supabase.tres")
	_ler()
	if not Engine.is_editor_hint():
		entrar()


## O identificador de quem esta a usar o app, ou "" se ainda nao ha.
func id() -> String:
	return _id


## Ha identidade utilizavel?
func ha() -> bool:
	return _id != "" and _token != ""


## Garante uma identidade. Chamar a vontade: nao repete o que ja esta
## feito e nao arranca duas conversas ao mesmo tempo.
func entrar() -> void:
	if _a_falar:
		# Ja ha uma conversa a decorrer: ESPERA-SE por ela. Devolver aqui
		# fazia com que `await Conta.entrar()` acabasse sem identidade
		# nenhuma e sem dizer porque — quem esperou ficava a achar que
		# tinha, e o proximo passo falhava mais a frente, longe da causa.
		while _a_falar:
			await get_tree().process_frame
		return
	if _servidor == null or _servidor.url == "":
		return
	if ha() and Time.get_unix_time_from_system() < _expira - MARGEM_DE_RENOVACAO:
		return
	_a_falar = true
	if _renovar != "":
		await _pedir("/auth/v1/token?grant_type=refresh_token",
			{"refresh_token": _renovar})
		# Um `refresh_token` recusado nao e um erro: e uma identidade que
		# caducou. Pede-se outra em vez de deixar a pessoa sem nenhuma.
		if not ha():
			_renovar = ""
			await _pedir("/auth/v1/signup", {})
	else:
		await _pedir("/auth/v1/signup", {})
	_a_falar = false
	if ha():
		entrou.emit(_id)


func _pedir(caminho: String, corpo: Dictionary) -> void:
	var pedido := HTTPRequest.new()
	add_child(pedido)
	var erro := pedido.request(
		_servidor.url + caminho,
		["apikey: " + _servidor.chave_publica, "Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(corpo))
	if erro != OK:
		pedido.queue_free()
		return
	var r: Array = await pedido.request_completed
	pedido.queue_free()
	if int(r[1]) < 200 or int(r[1]) >= 300:
		return
	var d = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY or not d.has("access_token"):
		return
	_token = str(d.get("access_token", ""))
	_renovar = str(d.get("refresh_token", ""))
	_expira = Time.get_unix_time_from_system() + float(d.get("expires_in", 3600))
	var u = d.get("user", {})
	if typeof(u) == TYPE_DICTIONARY:
		_id = str(u.get("id", ""))
	_guardar()


## Os cabecalhos para falar com a base em nome desta pessoa.
##
## Vazio quando nao ha identidade: quem chamar isto tem de tratar disso, e
## a alternativa — mandar o pedido sem token — era escrever em nome de
## ninguem.
func cabecalhos() -> PackedStringArray:
	if not ha():
		return PackedStringArray()
	return PackedStringArray([
		"apikey: " + _servidor.chave_publica,
		"Authorization: Bearer " + _token,
		"Content-Type: application/json",
	])


func _ler() -> void:
	if not FileAccess.file_exists(REGISTO):
		return
	var f := FileAccess.open(REGISTO, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return
	_id = str(d.get("id", ""))
	_token = str(d.get("token", ""))
	_renovar = str(d.get("renovar", ""))
	_expira = float(d.get("expira", 0.0))


func _guardar() -> void:
	var f := FileAccess.open(REGISTO, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"id": _id, "token": _token, "renovar": _renovar, "expira": _expira,
	}))
	f.close()
