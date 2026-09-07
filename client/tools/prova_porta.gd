## Prova o caminho: tres `pontos`, um de cada vez, e a porta em cada um.
##   godot --headless --path client --script res://tools/prova_porta.gd
##
## Os tracos sao fatias exatas do proprio desenho. Nao mede a pontaria de
## ninguem: mede a porta e o empurrao para o seguinte.
extends SceneTree

func _initialize() -> void:
	var irm: Irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	Passagem.esquecer()
	print("porta: cobertura >= %.2f" % Passagem.COBERTURA_PARA_PASSAR)
	print("")

	# 1) o primeiro ponto, mal riscado: nao passa, e nao avanca
	var e := Passagem.proximo(irm)
	print("a frente: %s" % e.slug)
	print("  riscado 50%%  cobertura %.2f  ->  %s" % [
		_medir(e, 0.50), "passa" if _medir(e, 0.50) >= Passagem.COBERTURA_PARA_PASSAR else "AINDA NAO"])
	print("  a frente continua: %s" % Passagem.proximo(irm).slug)
	print("")

	# 2) agora bem riscado, um a um, ate acabarem
	var passo := 1
	while true:
		var actual := Passagem.proximo(irm)
		if actual == null:
			break
		var c := _medir(actual, 0.90)
		var pode: bool = c >= Passagem.COBERTURA_PARA_PASSAR
		print("%d. %-14s riscado 90%%  cobertura %.2f  ->  %s" % [
			passo, actual.slug, c, "passa" if pode else "AINDA NAO"])
		if not pode:
			break
		Passagem.passar(actual.slug)
		var seguinte := Passagem.proximo(irm)
		print("     o guia poe: %s" % (seguinte.nome if seguinte != null else "-- eclipse --"))
		passo += 1
	print("")
	print("completa: ", Passagem.completa(irm), "   passados: ", Passagem.passados())
	Passagem.esquecer()
	quit()


func _medir(e: Entidade, fatia: float) -> float:
	var segs := e.ponto_riscado.segmentos
	var t: Array[PackedVector2Array] = []
	for i in int(round(segs.size() * fatia)):
		t.append(Polilinha.da_curva(segs[i], 48))
	return RiscoScoring.medir(t, e.ponto_riscado).get("cobertura", 0.0)
