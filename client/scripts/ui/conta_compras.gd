## Rotulos estruturais de autenticacao; sem texto ritual.
class_name ContaCompras
extends VBoxContainer

signal autenticou
var _email: LineEdit
var _codigo: LineEdit
var _mensagem: Label
var _enviar: Button
var _ligar: Button
var _confirmar: Button
var _ocupada := false


func _ready() -> void:
	add_child(Pagina.texto("entrar / recuperar compras", 20))
	_email = LineEdit.new()
	_email.placeholder_text = "email para recuperar as compras"
	add_child(_email)
	var linha := HBoxContainer.new()
	add_child(linha)
	_enviar = Pagina.botao("enviar código por email", 18)
	_enviar.pressed.connect(_pedir.bind(false))
	linha.add_child(_enviar)
	_ligar = Pagina.botao("ligar compras deste aparelho", 18)
	_ligar.pressed.connect(_pedir.bind(true))
	linha.add_child(_ligar)
	_codigo = LineEdit.new()
	_codigo.placeholder_text = "código recebido por email"
	add_child(_codigo)
	_confirmar = Pagina.botao("confirmar email", 18)
	_confirmar.pressed.connect(_verificar)
	add_child(_confirmar)
	_mensagem = Pagina.texto("", 17)
	add_child(_mensagem)
	_actualizar()


func _actualizar() -> void:
	_enviar.disabled = _ocupada
	_ligar.disabled = _ocupada
	_confirmar.disabled = _ocupada
	_ligar.visible = Conta.ha() and not Conta.recuperavel()
	_email.visible = not Conta.recuperavel()
	_codigo.visible = not Conta.recuperavel()
	_enviar.visible = not Conta.recuperavel()
	_confirmar.visible = not Conta.recuperavel()
	if Conta.recuperavel():
		_mensagem.text = "sessão: " + Conta.email()


func _pedir(ligar: bool) -> void:
	if _ocupada:
		return
	_ocupada = true
	_actualizar()
	var ok: bool = await Conta.enviar_codigo(_email.text, ligar)
	_ocupada = false
	_actualizar()
	_mensagem.text = "introduz o código recebido por email" if ok else Conta.erro


func _verificar() -> void:
	if _ocupada:
		return
	_ocupada = true
	_actualizar()
	var ok: bool = await Conta.confirmar_codigo(_codigo.text)
	_ocupada = false
	_actualizar()
	if ok:
		_codigo.text = ""
		autenticou.emit()
	else:
		_mensagem.text = Conta.erro if Conta.erro != "" else "email ainda não confirmado"
