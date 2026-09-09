## Avaliacao do `ponto_riscado`. SPEC.md §4.2, §5.
##
## Cada entidade de uma `irmandade` tem a sua `assinatura`: o
## `ponto_riscado` inteiro, tal como foi desenhado. O usuario risca; o app
## reconhece qual assinatura foi riscada, ou nenhuma.
##
## Assinaturas nao se compoem e nao partilham geometria. Nada aqui monta um
## ponto a partir de pedacos de outro.
##
## Recebe os tracos ja normalizados para o espaco de referencia da
## `irmandade`. Nao toca em tela, nao toca em relogio: funcao pura, para
## poder ser testada sem GUI e reimplementada no servidor.
class_name RiscoScoring
extends RefCounted

## Pesos da formula. Tunar TOLERANCE_PX contra playtest, manter os pesos
## (SPEC.md §4.2).
const PESO_ACCURACY := 0.50
const PESO_ORDER := 0.30
const PESO_CONTINUITY := 0.20

## SPEC.md §5.2: razao acima da qual duas assinaturas estao proximas
## demais para decidir.
const RAZAO_INDEFINIDA := 0.7

## Fracao do `ponto` que precisa de ter sido riscada para o risco contar
## como inteiro. Abaixo disto foi abandonado (SPEC.md §5.3).
##
## Nao e 1.0 de proposito: falhar um pingo de chuva de quatro pixeis nao e
## desistir. O limiar separa quem parou de quem errou.
##
## 0.70 por decisao de A.C.: e a mesma porta por onde se passa de um
## `ponto` para o seguinte. Um numero so, para a porta nao poder
## discordar da nota — quem abandona nao entra.
const COBERTURA_MINIMA := 0.70

## Fracao da TINTA que precisa de ter caido sobre o desenho.
##
## A porta tem duas folhas, e esta e a que faltava: sem ela, raiar a caixa
## do `ponto` em linhas paralelas juntas abria-a com cobertura 1.00. Ver
## `_fidelidade` e `tools/prova_rabisco.gd`.
##
## O numero saiu de medir, nao de arbitrar (`tools/prova_rabisco.gd` e o
## que ficou da medicao). Sobre os tres `pontos`, variando o gesto entre
## um traco por segmento e vinte segmentos por traco, e o tremor entre 0 e
## 45 unidades — mais do que a propria `tolerancia_px`:
##
##   riscar fiel, qualquer gesto, qualquer tremor    0.91 .. 1.00
##   raiar a caixa em linhas paralelas               0.66 .. 0.76
##
## 0.82 assenta na folga entre os dois, encostado ao lado do rabisco: um
## jogador barrado a porta fica sem jogo, e um batoteiro a passar uma fase
## gratuita nao custa nada. Entre errar para um lado e errar para o outro,
## erra-se a favor de quem esta a riscar.
##
## O que NAO serve para isto, e foi medido: a `accuracy`. Ela da 0.00 a um
## risco perfeito feito com a mao pousada, em tracos longos — o gesto de
## A.C., o mesmo que ja tinha partido a `cobertura` antiga. Poe-la a porta
## era voltar a partir o que o `_cobertura` consertou.
const FIDELIDADE_MINIMA := 0.82

## Tracos mais curtos que isto (no espaco de referencia) sao toques
## acidentais, nao tracos.
##
## Tem de ficar abaixo da menor marca real dos `pontos`: uma copia fiel do
## desenho tem pingos de chuva e bracos de cruz de quatro ou cinco pixeis,
## e um limiar alto demais os descarta em silencio — o segmento fica sem
## traco, conta como nao riscado, e a `firmeza` cai por um defeito da
## medicao e nao do risco.
const COMPRIMENTO_MINIMO := 3.0

## Um traco da assinatura que ficou por riscar custa mais que a tolerancia
## inteira: faltar e pior que errar.
const PENA_SEGMENTO_AUSENTE := 2.0

## Amostras usadas so para decidir a que segmento pertence cada traco.
## A triagem quer saber QUAL segmento, nao quao bem: 16 pontos bastam, e
## custam nove vezes menos que 48. A medida fina vem depois, so no
## segmento escolhido.
const AMOSTRAS_TRIAGEM := 16

## Quantos segmentos candidatos guardar por traco antes de emparelhar.
const CANDIDATOS := 6

## Referencias ja condicionadas, por `PontoData`. Um `ponto` fiel ao
## desenho tem mais de cem tracos; reconstruir todos a cada risco custaria
## mais do que a avaliacao inteira.
static var _cache_refs := {}


## Polilinhas de referencia de uma assinatura, prontas para comparar.
static func referencias(ponto: PontoData) -> Dictionary:
	var chave := ponto.get_instance_id()
	var guardado = _cache_refs.get(chave)
	if guardado != null and guardado["n"] == ponto.segmentos.size():
		return guardado
	var finas: Array[PackedVector2Array] = []
	var grossas: Array[PackedVector2Array] = []
	var caixas: Array[Rect2] = []
	for c in ponto.segmentos:
		var f := Polilinha.condicionar(Polilinha.da_curva(c, Polilinha.DENSO))
		finas.append(f)
		grossas.append(Polilinha.reamostrar(f, AMOSTRAS_TRIAGEM))
		caixas.append(Polilinha.caixa(f))
	var d := {"finas": finas, "grossas": grossas, "caixas": caixas,
			"n": ponto.segmentos.size()}
	_cache_refs[chave] = d
	return d


## Esquece as referencias guardadas. So e preciso se um `ponto` for
## alterado em memoria depois de ja ter sido avaliado.
static func esquecer_cache() -> void:
	_cache_refs.clear()


static func avaliar(
	tracos: Array,
	irmandade: Irmandade,
	hora_asmodeica: bool = false
) -> RiscoResultado:
	var r := RiscoResultado.new()
	r.hora_asmodeica = hora_asmodeica
	if irmandade == null or irmandade.entidades.is_empty():
		return r

	# Condicionar o traco do dedo uma vez so, e nao uma vez por
	# assinatura: o filtro e o mesmo para todas.
	var finas: Array[PackedVector2Array] = []
	var grossas: Array[PackedVector2Array] = []
	var caixas: Array[Rect2] = []
	for bruto in tracos:
		var traco: PackedVector2Array = bruto
		if Polilinha.comprimento(traco) < COMPRIMENTO_MINIMO:
			continue
		var f := Polilinha.condicionar(traco)
		finas.append(f)
		grossas.append(Polilinha.reamostrar(f, AMOSTRAS_TRIAGEM))
		caixas.append(Polilinha.caixa(f))

	var leituras: Array[Dictionary] = []
	for e in irmandade.entidades:
		if e == null or e.ponto_riscado == null or e.ponto_riscado.segmentos.is_empty():
			continue
		var leitura := _contra_assinatura(finas, grossas, caixas, e.ponto_riscado)
		leitura["slug"] = e.slug
		leituras.append(leitura)
		r.slugs.append(e.slug)
		r.distancias.append(leitura["distancia"])
	if leituras.is_empty():
		return r

	# A assinatura mais proxima, e a seguinte — SPEC.md §5.2 compara as
	# duas melhores.
	leituras.sort_custom(func(a, b): return a["distancia"] < b["distancia"])
	var melhor: Dictionary = leituras[0]

	r.accuracy = melhor["accuracy"]
	r.order = melhor["order"]
	r.continuity = melhor["continuity"]
	r.breaks = melhor["breaks"]
	r.segmentos_ausentes = melhor["ausentes"]
	r.cobertura = melhor["cobertura"]
	r.firmeza_bruta = int(round(100.0 * (
		PESO_ACCURACY * r.accuracy
		+ PESO_ORDER * r.order
		+ PESO_CONTINUITY * r.continuity
	)))
	r.firmeza = r.firmeza_bruta

	# --- veredito -------------------------------------------------------
	# O usuario nunca escolhe a entidade num menu: risca e descobre.
	var d_melhor: float = melhor["distancia"]
	var tol: float = melhor["tolerancia"]
	if r.cobertura < COBERTURA_MINIMA:
		r.abandonado = true
	elif d_melhor > tol:
		r.indefinida = true
	elif leituras.size() > 1:
		var d_segunda: float = leituras[1]["distancia"]
		if d_segunda > 0.0 and d_melhor / d_segunda > RAZAO_INDEFINIDA:
			r.indefinida = true
	if not r.indefinida and not r.abandonado:
		r.entidade_slug = melhor["slug"]

	# --- SPEC.md §5.3 ----------------------------------------------------
	# Um ponto riscado e abandonado nao vale nada. Um ponto riscado
	# inteiro, que nao se prende a assinatura nenhuma, e o traco
	# instintivo — e dentro da `hora_asmodeica` vale muito.
	#
	# Nao documentar na interface. Sem tooltip, sem conquista, sem dica, e
	# sem anunciar a hora (SPEC.md §6.2).
	if r.abandonado:
		r.firmeza = 0
	elif r.indefinida:
		if hora_asmodeica:
			# Dentro da hora a ambiguidade vale mais que a precisao, e e
			# preciso medi-la como tal: o que conta e o ato — ter ido ate
			# ao fim (`cobertura`), na ordem devida, sem parar — e nao a
			# pontaria. Os pesos de SPEC.md §4.2 ficam; o que muda e o que
			# ocupa a casa da `accuracy`.
			#
			# Sem isto o x1.25 nunca alcanca uma assinatura bem riscada, e
			# a regra promete uma coisa que a formula nao entrega.
			var instinto := 100.0 * (
				PESO_ACCURACY * r.cobertura
				+ PESO_ORDER * r.order
				+ PESO_CONTINUITY * r.continuity)
			r.firmeza = mini(100, int(round(instinto * 1.25)))
		else:
			# Fora da hora, a mesma ambiguidade e falha.
			r.firmeza = int(round(float(r.firmeza_bruta) * 0.6))

	return r


## Mede os tracos contra UMA assinatura, a que foi pedida — nao contra a
## melhor de todas.
##
## `avaliar` responde "quem atendeu?", e para isso procura. Aqui a
## pergunta e outra: "risquei o ponto que me foi posto a frente?". Nao ha
## nada a descobrir, ha um desenho a completar.
static func medir(tracos: Array, ponto: PontoData) -> Dictionary:
	var finas: Array[PackedVector2Array] = []
	var grossas: Array[PackedVector2Array] = []
	var caixas: Array[Rect2] = []
	for bruto in tracos:
		var traco: PackedVector2Array = bruto
		if Polilinha.comprimento(traco) < COMPRIMENTO_MINIMO:
			continue
		var f := Polilinha.condicionar(traco)
		finas.append(f)
		grossas.append(Polilinha.reamostrar(f, AMOSTRAS_TRIAGEM))
		caixas.append(Polilinha.caixa(f))
	if finas.is_empty() or ponto == null:
		return {"cobertura": 0.0, "fidelidade": 0.0}
	return _contra_assinatura(finas, grossas, caixas, ponto)


## Mede um conjunto de tracos ja condicionados contra uma `assinatura`.
static func _contra_assinatura(
	finas: Array[PackedVector2Array],
	grossas: Array[PackedVector2Array],
	caixas: Array[Rect2],
	ponto: PontoData
) -> Dictionary:
	var tol := ponto.tolerancia_px
	var ref := referencias(ponto)
	var r_finas: Array[PackedVector2Array] = ref["finas"]
	var r_grossas: Array[PackedVector2Array] = ref["grossas"]
	var r_caixas: Array[Rect2] = ref["caixas"]
	var n := r_finas.size()

	# --- triagem: emparelhar tracos e segmentos -------------------------
	# Por distancia media em mao unica, nao por Frechet: um traco
	# interrompido no meio de um segmento esta *sobre* o segmento certo, e
	# so a distancia em mao unica enxerga isso.
	#
	# O emparelhamento e um-para-um antes de ser um-para-muitos. Num
	# `ponto` fiel ao desenho ha dezenas de marcas pequenas e parecidas
	# lado a lado; deixar cada traco escolher o seu vizinho mais proximo
	# faz dois tracos caírem no mesmo segmento e um terceiro segmento
	# ficar vazio — e um segmento vazio conta como nao riscado.
	var melhores: Array = []
	for t in finas.size():
		var ordem: Array = []
		for i in n:
			ordem.append([Polilinha.distancia_entre_caixas(caixas[t], r_caixas[i]), i])
		ordem.sort_custom(func(a, b): return a[0] < b[0])

		# A distancia entre caixas nunca e maior que a distancia real:
		# quando ela ja passa do pior candidato guardado, o resto da lista
		# nao pode entrar.
		var lista: Array = []
		for par in ordem:
			if lista.size() >= CANDIDATOS and par[0] >= lista[CANDIDATOS - 1][0]:
				break
			lista.append([Polilinha.distancia_media_ate(grossas[t], r_grossas[par[1]]), par[1]])
			lista.sort_custom(func(a, b): return a[0] < b[0])
			if lista.size() > CANDIDATOS:
				lista.resize(CANDIDATOS)
		melhores.append(lista)

	var pares: Array = []
	for t in melhores.size():
		for par in melhores[t]:
			pares.append([par[0], t, par[1]])
	pares.sort_custom(func(a, b): return a[0] < b[0])

	var destino := {}
	var ocupado := {}
	for par in pares:
		if destino.has(par[1]) or ocupado.has(par[2]):
			continue
		destino[par[1]] = par[2]
		ocupado[par[2]] = true
	# Tracos que sobraram — o dedo levantado no meio de um segmento, por
	# exemplo — juntam-se ao segmento mais proximo, mesmo ja ocupado.
	for t in melhores.size():
		if not destino.has(t) and not melhores[t].is_empty():
			destino[t] = melhores[t][0][1]

	var por_segmento: Array[Array] = []
	for i in n:
		por_segmento.append([])
	var ordem_primeiro: Array[int] = []
	for t in finas.size():
		if not destino.has(t):
			continue
		var i: int = destino[t]
		if por_segmento[i].is_empty():
			ordem_primeiro.append(i)
		por_segmento[i].append(t)

	# --- accuracy e distancia -------------------------------------------
	var soma_acc := 0.0
	var soma_d := 0.0
	var breaks := 0
	var ausentes := 0
	for i in n:
		var partes: Array = por_segmento[i]
		if partes.is_empty():
			ausentes += 1
			soma_d += tol * PENA_SEGMENTO_AUSENTE
			continue
		# Levantar o dedo ENTRE dois tracos da assinatura nao e break.
		# Break e levantar no meio de um deles.
		breaks += partes.size() - 1
		var amostra: PackedVector2Array
		if partes.size() == 1:
			amostra = finas[partes[0]]
		else:
			var junto := PackedVector2Array()
			for t in partes:
				junto.append_array(finas[t])
			amostra = Polilinha.reamostrar(junto)
		var d := Frechet.distancia(amostra, r_finas[i])
		soma_d += d
		soma_acc += clampf(1.0 - d / tol, 0.0, 1.0)

	# --- order ----------------------------------------------------------
	# segments_started_in_sequence / total_segments: a maior subsequencia
	# de estreias que sobe. Pular um segmento custa aquele segmento, nao
	# todos os que vem depois dele.
	var order := float(_maior_subsequencia_crescente(ordem_primeiro)) / float(n)

	return {
		"cobertura": _cobertura(finas, caixas, r_finas, r_caixas,
			tol * RAIO_DA_COBERTURA),
		"fidelidade": _fidelidade(finas, caixas, r_finas, r_caixas, tol),
		"accuracy": soma_acc / float(n),
		"order": order,
		"continuity": clampf(1.0 - float(breaks) / float(n), 0.0, 1.0),
		"distancia": soma_d / float(n),
		"tolerancia": tol,
		"breaks": breaks,
		"ausentes": ausentes,
	}


## Quanto do desenho foi riscado, por cima.
##
## Mede GEOMETRIA, nao emparelhamento. A conta antiga era
## `segmentos_com_traco_atribuido / segmentos`, com o emparelhamento a ser
## um-para-um — e isso responde a outra pergunta: "fizeste um traco por
## segmento?". Quem risca o `ponto` inteiro com a mao pousada, em traços
## longos e continuos, cobria dezenas de segmentos com um so traco e via
## todos os outros contados como nao riscados. Com 143 segmentos e 25
## traços, o tecto era 17%: os 70%% eram inalcancaveis.
##
## Agora: um segmento conta como riscado se a maior parte do seu
## comprimento tem tinta por perto, venha ela de um traco ou de vinte.
static func _cobertura(
	finas: Array[PackedVector2Array],
	caixas: Array[Rect2],
	r_finas: Array[PackedVector2Array],
	r_caixas: Array[Rect2],
	tol: float
) -> float:
	var n := r_finas.size()
	if n == 0:
		return 0.0
	var feitos := 0
	for i in n:
		# So os tracos que passam perto deste segmento. A distancia entre
		# caixas nunca e maior que a real, entao isto nao deita fora
		# nenhum que contasse.
		var perto: Array[int] = []
		for t in finas.size():
			if Polilinha.distancia_entre_caixas(caixas[t], r_caixas[i]) <= tol:
				perto.append(t)
		if perto.is_empty():
			continue
		var pontos: PackedVector2Array = r_finas[i]
		var tocados := 0
		for p in pontos:
			for t in perto:
				if _perto_da_linha(p, finas[t], tol):
					tocados += 1
					break
		if float(tocados) / float(pontos.size()) >= FRACAO_DO_SEGMENTO:
			feitos += 1
	return float(feitos) / float(n)


## Quanto de um segmento precisa de ter tinta por cima para ele contar.
## Nao e 1.0: as pontas de um traco a mao ficam sempre curtas.
const FRACAO_DO_SEGMENTO := 0.6

## O raio da `cobertura`, em fraccao da `tolerancia_px`.
##
## Mais apertado que a tolerancia, e de proposito. As duas perguntas nao
## sao a mesma:
##
##   "riscaste ISTO?"        — a cobertura. Tem de ser tinta em cima.
##   "riscaste-o bem?"       — a accuracy. Ai 40 unidades e a folga justa.
##
## A folga inteira respondia a primeira por engano. Num `ponto` cujos
## segmentos vivem a menos de 40 unidades uns dos outros, riscar metade
## punha tinta a 40 da outra metade e contava-a como riscada: metade da
## `rosa_negra` dava 0.78 de cobertura e passava a porta dos 0.70. Ou
## seja, abandonar o `ponto` a meio valia tanto como acaba-lo, contra o
## SPEC.md §5.3 — e o `teste_risco` dizia-o, e falhava.
##
## A 0.75 da tolerancia, medido nos tres `pontos`:
##
##   metade dos tracos          0.54 .. 0.68   (abandonado, nao passa)
##   desenho inteiro, mao       0.98 .. 1.00   (passa)
##
## A porta dos 0.70 assenta na folga entre os dois.
const RAIO_DA_COBERTURA := 0.75


## Quanto da tinta que se pos caiu SOBRE o desenho.
##
## A `cobertura` sozinha nao chega, e o buraco nao era teorico: raiando a
## caixa do `ponto` em linhas paralelas juntas — o gesto de quem raia uma
## folha — todos os segmentos ficam com tinta por cima e a cobertura da
## 1.00, sem que o desenho tenha sido seguido em lado nenhum. Foi feito
## assim contra a pagina publicada, com o rato, nos tres `pontos`.
##
## As duas medidas sao inversas uma da outra e sao precisas as duas:
##
##   - `cobertura`  quanto do DESENHO recebeu tinta   (nao riscar de menos)
##   - `fidelidade` quanto da TINTA caiu no desenho   (nao riscar de mais)
##
## Pesada por comprimento, e nao por numero de pontos: o `condicionar`
## entrega 48 pontos por traco, seja ele de 20 unidades ou de 2000, e sem
## o peso um risco atravessado de ponta a ponta contava tanto como um
## retoque. Retocar por cima do que ja esta riscado nao custa nada — a
## tinta repetida continua a cair no desenho — e isso e de proposito:
## quem hesita e volta atras esta a riscar, nao a rabiscar.
static func _fidelidade(
	finas: Array[PackedVector2Array],
	caixas: Array[Rect2],
	r_finas: Array[PackedVector2Array],
	r_caixas: Array[Rect2],
	tol: float
) -> float:
	if finas.is_empty() or r_finas.is_empty():
		return 0.0
	var em_cima := 0.0
	var total := 0.0
	for t in finas.size():
		var comprimento := Polilinha.comprimento(finas[t])
		if comprimento <= 0.0:
			continue
		# So os segmentos que passam perto deste traco.
		var perto: Array[int] = []
		for i in r_finas.size():
			if Polilinha.distancia_entre_caixas(caixas[t], r_caixas[i]) <= tol:
				perto.append(i)
		total += comprimento
		if perto.is_empty():
			continue
		var pontos: PackedVector2Array = finas[t]
		var tocados := 0
		for p in pontos:
			for i in perto:
				if _perto_da_linha(p, r_finas[i], tol):
					tocados += 1
					break
		em_cima += comprimento * (float(tocados) / float(pontos.size()))
	if total <= 0.0:
		return 0.0
	return em_cima / total


static func _perto_da_linha(p: Vector2, linha: PackedVector2Array, tol: float) -> bool:
	var t2 := tol * tol
	for j in range(linha.size() - 1):
		if p.distance_squared_to(
				Geometry2D.get_closest_point_to_segment(p, linha[j], linha[j + 1])) <= t2:
			return true
	return false


static func _maior_subsequencia_crescente(seq: Array[int]) -> int:
	var n := seq.size()
	if n == 0:
		return 0
	var melhor := PackedInt32Array()
	melhor.resize(n)
	melhor.fill(1)
	var maximo := 1
	for i in range(1, n):
		for j in i:
			if seq[j] < seq[i]:
				melhor[i] = maxi(melhor[i], melhor[j] + 1)
		maximo = maxi(maximo, melhor[i])
	return maximo
