## Prova que um RABISCO nao passa por um `ponto` riscado.
##   godot --headless --path client --script res://tools/prova_rabisco.gd
##
## O buraco: a `cobertura` pergunta "cada segmento tem tinta por cima?" e
## mais nada. Riscando a caixa inteira do `ponto` em linhas paralelas
## juntas — o gesto de quem raia uma folha, nao o de quem risca — todos
## os segmentos ficam cobertos e a porta abre com 1.00, sem que nada do
## desenho tenha sido seguido.
##
## Foi feito assim contra a pagina publicada, com o rato: 28 arrastos
## horizontais de ponta a ponta passaram os tres `pontos` seguidos.
##
## Uma medida que so soma tinta nao chega. Falta perguntar o contrario:
## quanta da tinta que se pos estava onde o `ponto` NAO esta.
extends SceneTree

## Quao juntas ficam as linhas do rabisco, em unidades de referencia.
## Mais juntas que a `tolerancia_px` do `ponto`, para que nenhum ponto de
## nenhum segmento fique longe de uma linha.
const APERTO := 30.0

var _falhas := 0


func _initialize() -> void:
	var irm: Irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	print("porta em %.2f\n" % Passagem.COBERTURA_PARA_PASSAR)
	print("  ponto            gesto            cobertura  fidelidade  passa?  devia?")
	for e in irm.entidades:
		# O risco fiel passa com QUALQUER gesto e QUALQUER tremor. Os
		# dois eixos estao aqui porque foi a mexer neles que se descobriu
		# que a `accuracy` nao servia para esta porta: ela da 0.00 a um
		# risco perfeito feito com a mao pousada, em tracos longos.
		for junta in [1, 8, 20]:
			for tremor in [0.0, 45.0]:
				_medir(e, "fiel %2d/%2d" % [junta, int(tremor)],
					_tracos_fieis(e.ponto_riscado, junta, tremor), true)
		_medir(e, "rabisco", _rabisco(e.ponto_riscado), false)
	print("")
	if _falhas > 0:
		printerr("%d caso(s) errado(s)." % _falhas)
		quit(1)
		return
	print("Todos os casos certos.")
	quit()


func _medir(e: Entidade, gesto: String, tracos: Array[PackedVector2Array],
		devia: bool) -> void:
	var m := RiscoScoring.medir(tracos, e.ponto_riscado)
	var cobertura: float = m.get("cobertura", 0.0)
	var fidelidade: float = m.get("fidelidade", -1.0)
	var passa: bool = cobertura >= Passagem.COBERTURA_PARA_PASSAR \
		and fidelidade >= RiscoScoring.FIDELIDADE_MINIMA
	if passa != devia:
		_falhas += 1
	print("  %-15s  %-14s   %8.2f    %8.2f  %s  %s   %s" % [
		e.slug, gesto, cobertura, fidelidade,
		"sim   " if passa else "nao   ",
		"sim   " if devia else "nao   ",
		"" if passa == devia else "<-- ERRADO"])


## O `ponto` riscado como foi desenhado, com dois eixos de gesto:
## `junta` segmentos por traco (1 = um traco por segmento; 20 = a mao
## pousada) e `tremor` unidades de ruido suave por cima.
func _tracos_fieis(ponto: PontoData, junta: int,
		tremor: float) -> Array[PackedVector2Array]:
	var r := RandomNumberGenerator.new()
	r.seed = 12345
	var saida: Array[PackedVector2Array] = []
	var i := 0
	while i < ponto.segmentos.size():
		var p := PackedVector2Array()
		for k in range(i, mini(i + junta, ponto.segmentos.size())):
			p.append_array(Polilinha.da_curva(ponto.segmentos[k], 24))
		if p.size() > 1:
			saida.append(_tremer(p, tremor, r))
		i += junta
	return saida


## Ruido suave, como o de uma mao: um desvio por traco mais uma ondulacao
## ao longo dele. Nao e ruido branco ponto a ponto — esse o `suavizar`
## limpava, e a prova ficava mais facil do que a realidade.
func _tremer(p: PackedVector2Array, tremor: float,
		r: RandomNumberGenerator) -> PackedVector2Array:
	if tremor <= 0.0:
		return p
	var desvio := Vector2(r.randfn(0.0, tremor * 0.5), r.randfn(0.0, tremor * 0.5))
	var saida := PackedVector2Array()
	for i in p.size():
		var fase := float(i) / float(p.size()) * TAU
		saida.append(p[i] + desvio + Vector2(
			sin(fase * 1.7) * tremor * 0.5, cos(fase * 2.3) * tremor * 0.5))
	return saida


## A caixa do `ponto` raiada em linhas horizontais juntas.
func _rabisco(ponto: PontoData) -> Array[PackedVector2Array]:
	var caixa := _caixa(ponto)
	var saida: Array[PackedVector2Array] = []
	var y := caixa.position.y
	var esquerda := true
	while y <= caixa.end.y:
		var p := PackedVector2Array()
		# Amostrado, e nao so as duas pontas: um arrasto de rato deixa
		# pontos pelo caminho, e e assim que o `condicionar` o ve.
		for k in 33:
			var t := float(k) / 32.0
			var x: float = lerpf(caixa.position.x, caixa.end.x,
				t if esquerda else 1.0 - t)
			p.append(Vector2(x, y))
		saida.append(p)
		esquerda = not esquerda
		y += APERTO
	return saida


func _caixa(ponto: PontoData) -> Rect2:
	var caixa := Rect2()
	var primeiro := true
	for c in ponto.segmentos:
		for p in Polilinha.da_curva(c, 24):
			if primeiro:
				caixa = Rect2(p, Vector2.ZERO)
				primeiro = false
			else:
				caixa = caixa.expand(p)
	return caixa
