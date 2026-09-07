## Prova o caminho inteiro da primeira fase, do ecra vazio ao eclipse.
##   godot --headless --path client --script res://tools/prova_primeiro_contato.gd
extends SceneTree

func _initialize() -> void:
	var irm: Irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	Passagem.esquecer()
	print("--- primeiro contato (SPEC 4.3): guiado, nao pontua ---")
	for i in 4:
		var e := Passagem.por_conhecer(irm)
		if e == null:
			print("  guia apaga-se: ja se conhecem as tres")
			break
		print("  o ecra abre em: %-14s  aberta=%s" % [e.slug, Passagem.aberta(irm)])
		Passagem.conhecer(e.slug)
	print("--- agora o risco vale ---")
	for e in irm.entidades:
		Passagem.marcar(e.slug, 55)
		print("  nomeada %-14s  faltam=%d  aberta=%s" % [
			e.slug, Passagem.faltam(irm), Passagem.aberta(irm)])
	Passagem.esquecer()
	quit()
