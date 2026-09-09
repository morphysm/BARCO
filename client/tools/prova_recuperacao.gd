extends SceneTree

class ContaFalsa extends "res://scripts/ritual/conta.gd":
	var resposta: Dictionary = {}
	var chamadas: Array[String] = []
	func _ready() -> void:
		pass
	func _guardar() -> void:
		pass
	func _http(caminho: String, _corpo: Dictionary,
			_metodo := HTTPClient.METHOD_POST, _autenticado := false) -> Dictionary:
		chamadas.append(caminho)
		return resposta.duplicate(true)

var falhas := 0

func _initialize() -> void:
	call_deferred("_correr")

func _correr() -> void:
	var c := ContaFalsa.new()
	root.add_child(c)
	var servidor := Servidor.new()
	servidor.url = "https://teste.invalid"
	servidor.vende = true
	servidor.vende_na_web = true
	c._servidor = servidor
	c._id = "conta-original"
	c._renovar = "refresh-original"
	c._expira = 0
	await c.entrar()
	checar("refresh falhado preserva identidade", c.id() == "conta-original")
	checar("refresh falhado nao cria outra conta", not c.chamadas.has("/auth/v1/signup"))
	checar("token expirado nao e sessao utilizavel", not c.ha())
	c.resposta = {"_ok": true}
	checar("envio OTP aceite", await c.enviar_codigo("alguem@example.com"))
	checar("envio OTP nao confirma identidade", not c.recuperavel())
	checar("OTP sem sessao nao entra", not await c.confirmar_codigo("123456"))
	c.resposta = {"_ok": true, "access_token": "teste", "refresh_token": "teste-refresh",
		"expires_in": 3600, "user": {"id": "recuperada", "email": "alguem@example.com",
		"email_confirmed_at": "2026-09-08T00:00:00Z", "is_anonymous": false}}
	checar("OTP confirmado recupera identidade", await c.confirmar_codigo("123456"))
	checar("compras pertencem ao mesmo id recuperado", c.id() == "recuperada")
	c._email_otp = "alguem@example.com"
	c._dono_otp = "outra-conta"
	checar("linking nunca troca o dono", not await c.confirmar_codigo("123456"))
	checar("sessao preservada apos linking errado", c.id() == "recuperada")
	c.free()
	quit(1 if falhas else 0)

func checar(nome: String, ok: bool) -> void:
	print("%s: %s" % ["ok" if ok else "FALHA", nome])
	if not ok:
		falhas += 1
