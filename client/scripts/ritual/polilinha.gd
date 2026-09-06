## Operacoes de polilinha usadas na captura e na avaliacao do
## `ponto_riscado`. Geometria pura, sem vocabulario de dominio.
class_name Polilinha
extends RefCounted

## Numero de amostras usado em toda comparacao. Reamostrar por comprimento
## de arco torna a medida independente da taxa de amostragem do dedo, e
## mantem o custo da Frechet discreta (O(n*m)) fixo.
const AMOSTRAS := 48

static func comprimento(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	return total

## Reamostra em `n` pontos igualmente espacados por comprimento de arco.
static func reamostrar(pts: PackedVector2Array, n: int = AMOSTRAS) -> PackedVector2Array:
	var saida := PackedVector2Array()
	var total_pts := pts.size()
	if total_pts == 0 or n <= 0:
		return saida
	if total_pts == 1:
		saida.resize(n)
		saida.fill(pts[0])
		return saida

	var acum := PackedFloat32Array()
	acum.resize(total_pts)
	acum[0] = 0.0
	for i in range(1, total_pts):
		acum[i] = acum[i - 1] + pts[i - 1].distance_to(pts[i])
	var comp := acum[total_pts - 1]
	if comp <= 0.0:
		saida.resize(n)
		saida.fill(pts[0])
		return saida

	saida.resize(n)
	var j := 1
	for k in n:
		var alvo := comp * float(k) / float(n - 1)
		while j < total_pts - 1 and acum[j] < alvo:
			j += 1
		var d0 := acum[j - 1]
		var d1 := acum[j]
		var t := 0.0 if is_equal_approx(d1, d0) else (alvo - d0) / (d1 - d0)
		saida[k] = pts[j - 1].lerp(pts[j], clampf(t, 0.0, 1.0))
	return saida

## Media movel por distancia, preservando as pontas.
##
## A janela e um raio em pixels de referencia, nao um numero de amostras.
## Isto importa: o dedo entrega centenas de pontos, uma curva de referencia
## entrega dezenas, e uma janela contada em amostras arredondaria os cantos
## do `ponto` em vez de limpar o tremor da mao — punindo justamente o traco
## bem feito. Contada em distancia, a suavizacao so age onde ha amostras
## densas o bastante para haver ruido.
##
## Condicionamento de entrada, nao indulgencia: a Frechet e uma metrica de
## pior ponto, e um unico pico de amostragem domina a distancia inteira.
static func suavizar(pts: PackedVector2Array, raio_px: float = 8.0) -> PackedVector2Array:
	var n := pts.size()
	if n < 3 or raio_px <= 0.0:
		return pts

	var acum := PackedFloat32Array()
	acum.resize(n)
	acum[0] = 0.0
	for i in range(1, n):
		acum[i] = acum[i - 1] + pts[i - 1].distance_to(pts[i])

	var saida := PackedVector2Array()
	saida.resize(n)
	saida[0] = pts[0]
	saida[n - 1] = pts[n - 1]
	var esq := 0
	var dir := 0
	for i in range(1, n - 1):
		while acum[i] - acum[esq] > raio_px:
			esq += 1
		dir = maxi(dir, i)
		while dir + 1 < n and acum[dir + 1] - acum[i] <= raio_px:
			dir += 1
		var soma := Vector2.ZERO
		for k in range(esq, dir + 1):
			soma += pts[k]
		saida[i] = soma / float(dir - esq + 1)
	return saida

## Caixa envolvente de uma polilinha.
static func caixa(pts: PackedVector2Array) -> Rect2:
	if pts.is_empty():
		return Rect2()
	var r := Rect2(pts[0], Vector2.ZERO)
	for i in range(1, pts.size()):
		r = r.expand(pts[i])
	return r


## Menor distancia possivel entre duas caixas; zero se elas se tocam.
##
## Limite inferior barato para `distancia_media_ate`: se as caixas estao a
## 300 px uma da outra, nenhum ponto de uma esta a menos de 300 px da
## outra, e nao ha por que medir ponto a ponto. Num `ponto` fiel ao
## desenho, com mais de cem tracos, e a diferenca entre avaliar num piscar
## e avaliar em minutos.
static func distancia_entre_caixas(a: Rect2, b: Rect2) -> float:
	var dx := maxf(0.0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
	var dy := maxf(0.0, maxf(a.position.y - b.end.y, b.position.y - a.end.y))
	return sqrt(dx * dx + dy * dy)


## Distancia de um ponto ao segmento [a, b].
static func ponto_ate_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var comp2 := ab.length_squared()
	if comp2 <= 0.0:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / comp2, 0.0, 1.0)
	return p.distance_to(a + ab * t)

## Distancia media, em mao unica, de `a` ate a polilinha `b`.
##
## Ao contrario da Frechet, isto nao pune `a` por cobrir so um pedaco de
## `b`. E o que permite reconhecer a qual segmento pertence um traco
## interrompido: meia radial esta sobre a radial inteira, distancia ~0,
## enquanto a Frechet entre as duas mede o pedaco que faltou.
static func distancia_media_ate(a: PackedVector2Array, b: PackedVector2Array) -> float:
	if a.is_empty() or b.is_empty():
		return INF
	if b.size() == 1:
		var soma_um := 0.0
		for p in a:
			soma_um += p.distance_to(b[0])
		return soma_um / float(a.size())
	var soma := 0.0
	for p in a:
		var melhor := INF
		for i in range(1, b.size()):
			melhor = minf(melhor, ponto_ate_segmento(p, b[i - 1], b[i]))
		soma += melhor
	return soma / float(a.size())

## Densidade em que o traco e filtrado antes de virar amostra.
const DENSO := 240

## Prepara uma polilinha para comparacao: densifica, suaviza, reamostra.
##
## Tem de passar por aqui TANTO o traco do dedo QUANTO a curva de
## referencia. Suavizar so um dos lados desloca a comparacao: um `ponto`
## com cantos vivos — o pentagrama do pe, por exemplo — teria os cantos
## arredondados no traco e vivos na referencia, e um risco perfeito
## perderia firmeza por um defeito do filtro, nao do risco.
static func condicionar(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() < 2:
		return reamostrar(pts)
	return reamostrar(suavizar(reamostrar(pts, DENSO)), AMOSTRAS)

## Converte um Curve2D em polilinha densa e reamostrada.
static func da_curva(c: Curve2D, n: int = AMOSTRAS) -> PackedVector2Array:
	if c == null or c.point_count == 0:
		return PackedVector2Array()
	var t := c.tessellate(5, 2.0)
	# Uma reta vira 2 pontos no tessellate; reamostrar densifica para que
	# comparacoes ponto a ponto tenham do que se agarrar.
	return reamostrar(t, n)
