## Distancia de Frechet discreta.
##
## Metrica de comparacao do `ponto_riscado` (SPEC.md §4.2) e da
## classificacao de `face` (SPEC.md §5.2). Ver `Polilinha` para
## reamostragem e suavizacao.
class_name Frechet
extends RefCounted

## Distancia de Frechet discreta entre duas polilinhas.
## Retorna INF se qualquer uma estiver vazia.
##
## E uma metrica de pior ponto: mede o maior afastamento inevitavel entre
## duas caminhadas que nao podem voltar atras. Por isso pune tanto o traco
## fora de ordem quanto o traco incompleto — que e exatamente o que se quer
## medir num `ponto_riscado`.
static func distancia(p: PackedVector2Array, q: PackedVector2Array) -> float:
	var n := p.size()
	var m := q.size()
	if n == 0 or m == 0:
		return INF

	var anterior := PackedFloat32Array()
	var atual := PackedFloat32Array()
	anterior.resize(m)
	atual.resize(m)

	for j in m:
		var d := p[0].distance_to(q[j])
		anterior[j] = d if j == 0 else maxf(anterior[j - 1], d)

	for i in range(1, n):
		for j in m:
			var d := p[i].distance_to(q[j])
			if j == 0:
				atual[j] = maxf(anterior[0], d)
			else:
				var menor := minf(anterior[j], minf(anterior[j - 1], atual[j - 1]))
				atual[j] = maxf(menor, d)
		var troca := anterior
		anterior = atual
		atual = troca

	return anterior[m - 1]

## Conveniencia: reamostra ambas e compara.
static func comparar(a: PackedVector2Array, b: PackedVector2Array) -> float:
	return distancia(Polilinha.reamostrar(a), Polilinha.reamostrar(b))
