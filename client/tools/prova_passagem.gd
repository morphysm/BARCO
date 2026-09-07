## Prova a primeira fase: marca as tres assinaturas uma a uma e confirma
## que so a terceira abre a passagem.
##   godot --headless --path client --script res://tools/prova_passagem.gd
extends SceneTree

func _initialize() -> void:
	var irm: Irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	Passagem.esquecer()
	print("entidades: ", irm.entidades.size())
	print("de inicio faltam %d, aberta=%s" % [Passagem.faltam(irm), Passagem.aberta(irm)])
	for e in irm.entidades:
		var novo := Passagem.marcar(e.slug, 70)
		print("  %-14s novo=%s  faltam=%d  aberta=%s" % [
			e.slug, novo, Passagem.faltam(irm), Passagem.aberta(irm)])
	print("repetir uma nao conta: ", Passagem.marcar(irm.entidades[0].slug, 99))
	print("riscados: ", Passagem.riscados())
	Passagem.esquecer()
	print("depois de esquecer, faltam ", Passagem.faltam(irm))
	quit()
