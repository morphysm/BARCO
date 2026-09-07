## Prova a porta dos 70%: risca-se uma fracao do desenho e ve-se quem
## passa.
##   godot --headless --path client --script res://tools/prova_porta.gd
##
## Os tracos sao feitos a partir da propria assinatura — copia perfeita de
## uma fatia dela. Nao mede a pontaria de ninguem: mede a porta.
extends SceneTree

func _initialize() -> void:
	var irm: Irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	var e: Entidade = irm.entidades[0]
	var todos := e.ponto_riscado.segmentos
	print("assinatura de prova: %s, %d segmentos" % [e.slug, todos.size()])
	print("porta: cobertura >= %.2f" % Passagem.COBERTURA_PARA_PASSAR)
	print("")
	print("  fatia   cobertura   firmeza   passa?")
	for fatia in [0.40, 0.60, 0.69, 0.72, 0.85, 1.00]:
		var quantos := int(round(todos.size() * fatia))
		var tracos: Array[PackedVector2Array] = []
		for i in quantos:
			tracos.append(Polilinha.da_curva(todos[i], 48))
		var r := RiscoScoring.avaliar(tracos, irm, false)
		print("  %4.0f%%   %8.2f   %7d   %s" % [
			fatia * 100.0, r.cobertura, r.firmeza,
			"sim" if r.cobertura >= Passagem.COBERTURA_PARA_PASSAR else "AINDA NAO"])
	quit()
