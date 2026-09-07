## Prova que a cobertura mede o desenho e nao o numero de tracos.
##   godot --headless --path client --script res://tools/prova_cobertura.gd
##
## O caso que falhou a A.C.: riscar o `ponto` inteiro com a mao pousada,
## em poucos tracos longos e continuos, em vez de um traco por segmento.
extends SceneTree

func _initialize() -> void:
	var irm: Irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	var e: Entidade = irm.entidades[0]
	var segs := e.ponto_riscado.segmentos
	print("%s: %d segmentos, porta em %.2f" % [
		e.slug, segs.size(), Passagem.COBERTURA_PARA_PASSAR])
	print("")
	print("  como se risca                    tracos  cobertura  passa?")
	for junta in [1, 4, 8, 20]:
		for fatia in [0.5, 1.0]:
			var t := _tracos(segs, fatia, junta)
			var inicio := Time.get_ticks_msec()
			var c: float = RiscoScoring.medir(t, e.ponto_riscado).get("cobertura", 0.0)
			var ms := Time.get_ticks_msec() - inicio
			print("  %3.0f%% do desenho, %2d seg/traco   %6d  %9.2f  %s  (%d ms)" % [
				fatia * 100.0, junta, t.size(), c,
				"passa    " if c >= Passagem.COBERTURA_PARA_PASSAR else "AINDA NAO",
				ms])
	quit()


## Junta `junta` segmentos seguidos num traco so, como faz a mao pousada.
func _tracos(segs: Array, fatia: float, junta: int) -> Array[PackedVector2Array]:
	var saida: Array[PackedVector2Array] = []
	var quantos := int(round(segs.size() * fatia))
	var i := 0
	while i < quantos:
		var p := PackedVector2Array()
		for k in range(i, mini(i + junta, quantos)):
			p.append_array(Polilinha.da_curva(segs[k], 24))
		if p.size() > 1:
			saida.append(p)
		i += junta
	return saida
