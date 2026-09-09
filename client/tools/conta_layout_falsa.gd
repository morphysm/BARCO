## Autoload apenas do projecto temporario de prova visual, nunca do app.
extends "res://scripts/ritual/conta.gd"

func _ready() -> void:
	_servidor = Servidor.new()
	_servidor.vende = false

func _guardar() -> void:
	pass

func _http(_caminho: String, _corpo: Dictionary,
		_metodo := HTTPClient.METHOD_POST, _autenticado := false) -> Dictionary:
	return {}
