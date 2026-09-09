## Identidade Supabase; email com OTP permite recuperar compras.
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
var _email := ""
var _confirmada := false
var _email_otp := ""
var _tipo_otp := "email"
var _dono_otp := ""
var erro := ""


func recuperavel() -> bool:
	return ha() and _confirmada


func email() -> String:
	return _email


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
	return _id != "" and _token != "" and Time.get_unix_time_from_system() < _expira


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
	# Nao se vende nada: nao ha pagamento nenhum para ligar a ninguem, e
	# entao nao ha identidade nenhuma para criar.
	#
	# Isto e o `Servidor.vende` a fechar a ULTIMA porta, e e a que se via
	# de fora: com o balcao fechado mas isto aberto, cada pessoa que
	# abrisse a pagina deixava uma linha permanente em `auth.users` do
	# projecto a serio — uma identidade criada para servir um pagamento
	# que nao pode acontecer. Numa pagina publica isso e lixo a crescer
	# sozinho, e sao dados de pessoas guardados sem nada em troca.
	#
	# Fica AQUI, e nao em cada sitio que chama `entrar`, por ser o unico
	# sitio por onde uma identidade nasce.
	if not _servidor.vende_aqui():
		return
	if ha() and Time.get_unix_time_from_system() < _expira - MARGEM_DE_RENOVACAO:
		return
	_a_falar = true
	if _renovar != "":
		await _pedir("/auth/v1/token?grant_type=refresh_token",
			{"refresh_token": _renovar})
	elif _id == "" and not OS.has_feature("web"):
		await _pedir("/auth/v1/signup", {})
	# Preserva a identidade e o refresh token quando a rede falha.
	_a_falar = false


## Sem redirects: o jogador escreve no app o codigo recebido por email.
func enviar_codigo(endereco: String, ligar := false) -> bool:
	if _a_falar:
		return false
	var limpo := endereco.strip_edges().to_lower()
	if not limpo.contains("@"):
		erro = "verifica o email"
		return false
	if ligar:
		await entrar()
		if not ha():
			erro = "não foi possível abrir a sessão deste aparelho"
			return false
	_a_falar = true
	var d: Dictionary
	if ligar:
		d = await _http("/auth/v1/user", {"email": limpo}, HTTPClient.METHOD_PUT, true)
	else:
		d = await _http("/auth/v1/otp", {"email": limpo, "create_user": true})
	_a_falar = false
	if not d.get("_ok", false):
		return false
	_email_otp = limpo
	_tipo_otp = "email_change" if ligar else "email"
	_dono_otp = _id if ligar else ""
	return true


func confirmar_codigo(codigo: String) -> bool:
	if _a_falar or _email_otp == "" or codigo.strip_edges() == "":
		return false
	_a_falar = true
	var d := await _http("/auth/v1/verify",
		{"email": _email_otp, "token": codigo.strip_edges(), "type": _tipo_otp})
	var certo := false
	if d.get("_ok", false):
		var u: Dictionary = d.get("user", {})
		if _dono_otp == "" or str(u.get("id", "")) == _dono_otp:
			certo = _aceitar_sessao(d)
		else:
			erro = "a confirmação não corresponde à conta deste aparelho"
	_a_falar = false
	if certo:
		_email_otp = ""
	return certo and recuperavel()


func ligar_email(endereco: String) -> bool:
	return await enviar_codigo(endereco, true)


func _http(caminho: String, corpo: Dictionary,
		metodo := HTTPClient.METHOD_POST, autenticado := false) -> Dictionary:
	erro = ""
	if _servidor == null or _servidor.url == "":
		erro = "servidor indisponível"
		return {}
	var pedido := HTTPRequest.new()
	# Godot 4.7 Web falha a descomprimir algumas respostas gzip do
	# Supabase e entrega um corpo vazio ao JSON. Pedir a resposta sem
	# compressao conserva exactamente os mesmos dados.
	pedido.accept_gzip = false
	pedido.timeout = 20.0
	add_child(pedido)
	var headers := PackedStringArray([
		"apikey: " + _servidor.chave_publica, "Content-Type: application/json"])
	if autenticado:
		headers.append("Authorization: Bearer " + _token)
	var e := pedido.request(_servidor.url + caminho, headers, metodo, JSON.stringify(corpo))
	if e != OK:
		pedido.queue_free()
		erro = "sem ligação — tenta novamente"
		return {}
	var r: Array = await pedido.request_completed
	pedido.queue_free()
	if int(r[1]) < 200 or int(r[1]) >= 300:
		erro = "não foi possível confirmar — verifica o email ou código"
		if int(r[1]) == 429:
			erro = "aguarda antes de pedir outro código"
		elif int(r[1]) == 0:
			erro = "sem ligação — tenta novamente"
		return {}
	var d = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	if not d is Dictionary:
		d = {}
	d["_ok"] = true
	return d


func _pedir(caminho: String, corpo: Dictionary) -> void:
	_aceitar_sessao(await _http(caminho, corpo))


func _aceitar_sessao(d: Dictionary) -> bool:
	var u: Dictionary = d.get("user", {})
	if str(d.get("access_token", "")) == "" or str(u.get("id", "")) == "":
		return false
	_id = str(u["id"])
	_token = str(d["access_token"])
	_renovar = str(d.get("refresh_token", ""))
	_expira = Time.get_unix_time_from_system() + float(d.get("expires_in", 3600))
	_email = str(u.get("email", ""))
	_confirmada = u.get("email_confirmed_at") != null and not u.get("is_anonymous", true)
	_guardar()
	entrou.emit(_id)
	return true


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
	# Revalida no servidor apos cada arranque.
	_expira = 0.0


func _guardar() -> void:
	var f := FileAccess.open(REGISTO, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"id": _id, "token": _token, "renovar": _renovar, "expira": _expira,
	}))
	f.close()
