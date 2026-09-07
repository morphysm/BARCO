## Apaga o que o app guardou no aparelho — pontos riscados, depositos,
## pedidos. Bancada, nao mecanica: ver `Dados`.
##
##   godot --headless --path client --script res://tools/limpar_dados.gd
extends SceneTree

func _initialize() -> void:
	for caminho in Dados.FICHEIROS:
		print("  %-28s %s" % [
			caminho, "existe" if FileAccess.file_exists(caminho) else "-"])
	var n := Dados.apagar_tudo()
	if n < 0:
		printerr("nao e um build de debug — nada foi apagado")
		quit(1)
		return
	print("apagados: %d" % n)
	quit()
