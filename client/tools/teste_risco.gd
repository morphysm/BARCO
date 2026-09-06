## Teste sem GUI do reconhecimento de `assinatura`.
##
## Rodar:
##   godot --headless --path client --script res://tools/teste_risco.gd
##
## Sintetiza tracos e verifica SPEC.md §4.2 e §5. Nao substitui playtest —
## TOLERANCE_PX so se tuna com dedo de verdade.
extends SceneTree

const ScoringS := preload("res://scripts/ritual/risco_scoring.gd")

## Um dedo a 60-120 Hz entrega centenas de pontos por traco.
const AMOSTRAS_DE_DEDO := 240

var falhas := 0
var irmandade: Irmandade


func _initialize() -> void:
	irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	print("irmandade %s — %d assinaturas\n" % [irmandade.slug, irmandade.entidades.size()])

	# --- cada assinatura riscada limpa e reconhecida ---------------------
	for e in irmandade.entidades:
		var r := ScoringS.avaliar(_assinatura(e), irmandade, false)
		_checar("risco limpo reconhece %s" % e.slug,
			r.entidade_slug == e.slug and not r.indefinida, r)
		_checar("risco limpo de %s da firmeza 100" % e.slug, r.firmeza == 100, r)

	# --- mao tremida ainda reconhece -------------------------------------
	for e in irmandade.entidades:
		var r := ScoringS.avaliar(_tremer(_assinatura(e), 14.0), irmandade, false)
		_checar("mao tremida ainda reconhece %s" % e.slug, r.entidade_slug == e.slug, r)
		_checar("mao tremida em %s perde firmeza" % e.slug, r.firmeza < 100, r)

	var caveira := irmandade.entidade_por_slug("exu_caveira")
	var rosa := irmandade.entidade_por_slug("rosa_negra")
	var aranha := irmandade.entidade_por_slug("exu_aranha")

	# --- ordem trocada e dedo levantado ----------------------------------
	var invertida := _assinatura(rosa)
	invertida.reverse()
	var r_ordem := ScoringS.avaliar(invertida, irmandade, false)
	_checar("ordem trocada reduz order", r_ordem.order < 1.0, r_ordem)

	var r_quebra := ScoringS.avaliar(_partir_primeiro(_assinatura(caveira)), irmandade, false)
	_checar("levantar o dedo conta como break", r_quebra.breaks >= 1, r_quebra)
	_checar("break reduz continuity", r_quebra.continuity < 1.0, r_quebra)

	# --- SPEC §5.3: abandonar nao e o mesmo que hesitar ------------------
	# Um ponto riscado e abandonado nao vale nada.
	var metade := _assinatura(rosa)
	metade.resize(metade.size() / 2)
	for hora in [false, true]:
		var r_ab := ScoringS.avaliar(metade, irmandade, hora)
		_checar("ponto abandonado nao vale nada (hora=%s)" % hora,
			r_ab.abandonado and r_ab.firmeza == 0 and r_ab.entidade_slug == "", r_ab)
		_checar("abandonado nao e face_indefinida (hora=%s)" % hora,
			not r_ab.indefinida, r_ab)

	# --- assinatura vacilante -> face_indefinida -------------------------
	# As formas estao la, mas o traco nao se compromete com nenhuma.
	var meio := _tremer(_assinatura(rosa), 240.0, 0.75)
	var r_meio := ScoringS.avaliar(meio, irmandade, false)
	_checar("assinatura vacilante e face_indefinida", r_meio.indefinida, r_meio)
	_checar("vacilante nao e abandono: o ponto foi inteiro",
		not r_meio.abandonado and r_meio.cobertura >= 0.75, r_meio)
	_checar("indefinida nao nomeia entidade", r_meio.entidade_slug == "", r_meio)

	# --- SPEC §5.3: a inversao da hora_asmodeica -------------------------
	var fora := ScoringS.avaliar(meio, irmandade, false)
	var dentro := ScoringS.avaliar(meio, irmandade, true)
	_checar("fora da hora, indefinida penaliza (x0.6)",
		fora.firmeza == int(round(float(fora.firmeza_bruta) * 0.6)), fora)
	# Dentro da hora o que pesa e o ato, nao a pontaria: a `cobertura`
	# ocupa a casa da `accuracy`, e so entao vem o x1.25.
	var instinto := 100.0 * (
		ScoringS.PESO_ACCURACY * dentro.cobertura
		+ ScoringS.PESO_ORDER * dentro.order
		+ ScoringS.PESO_CONTINUITY * dentro.continuity)
	_checar("dentro da hora, o instinto e medido pelo ato (x1.25, teto 100)",
		dentro.firmeza == mini(100, int(round(instinto * 1.25))), dentro)
	_checar("dentro da hora, indefinida > fora da hora", dentro.firmeza > fora.firmeza, dentro)

	# SPEC.md §5.3: dentro da hora, a `face_indefinida` tem de superar
	# qualquer assinatura isolada riscada com a mesma qualidade de mao.
	# So se sustenta porque o nucleo bem riscado segura a accuracy.
	var mao := 14.0
	var indef := ScoringS.avaliar(_tremer(_assinatura(rosa), 240.0, 0.75), irmandade, true)
	var rosa_tremida := ScoringS.avaliar(_tremer(_assinatura(rosa), mao), irmandade, true)
	var cav_tremida := ScoringS.avaliar(_tremer(_assinatura(caveira), mao), irmandade, true)
	print("    (rosa %d | caveira %d | instintivo %d — dentro da hora)" % [
		rosa_tremida.firmeza, cav_tremida.firmeza, indef.firmeza])
	var fora_da_hora := ScoringS.avaliar(_tremer(_assinatura(rosa), 240.0, 0.75), irmandade, false)
	var abandonado := ScoringS.avaliar(metade, irmandade, true)
	print("    (instintivo fora da hora %d | abandonado %d)" % [
		fora_da_hora.firmeza, abandonado.firmeza])
	_checar("instintivo na hora supera o mesmo traco fora dela",
		indef.firmeza > fora_da_hora.firmeza, indef)
	_checar("instintivo na hora supera de longe o abandono",
		indef.firmeza > abandonado.firmeza, indef)
	# SPEC.md §5.3 / GDD §3.4: dentro da hora o traco instintivo e o mais
	# forte da entidade, acima de qualquer assinatura isolada.
	_checar("instintivo na hora supera rosa_negra riscada",
		indef.firmeza > rosa_tremida.firmeza, indef)
	_checar("instintivo na hora supera exu_caveira riscado",
		indef.firmeza > cav_tremida.firmeza, indef)
	var r_aranha := ScoringS.avaliar(_assinatura(aranha), irmandade, false)
	print("\n    distancias da assinatura, num risco limpo de exu_aranha:")
	for i in r_aranha.slugs.size():
		print("      %-12s %.1f" % [r_aranha.slugs[i], r_aranha.distancias[i]])

	print("")
	if falhas == 0:
		print("todos os testes passaram")
	else:
		print("%d teste(s) falharam" % falhas)
	quit(1 if falhas > 0 else 0)


# --- helpers ----------------------------------------------------------

## O risco inteiro de uma entidade: a assinatura dela, e so ela.
func _assinatura(e: Entidade) -> Array:
	var saida: Array = []
	for c in e.ponto_riscado.segmentos:
		saida.append(Polilinha.da_curva(c, AMOSTRAS_DE_DEDO))
	return saida

## Deriva de mao, nao ruido branco: um dedo oscila devagar, e oscila em
## proporcao ao gesto. Ninguem erra catorze pixeis a desenhar um pingo de
## chuva de cinco — a mao vagueia ao longo de um traco longo, nao ao longo
## de uma marca minuscula. Um tremor fixo aplicado a um `ponto` fiel ao
## desenho testaria a destruicao das marcas pequenas, nao a mao tremida.
func _tremer_um(pts: PackedVector2Array, teto: float, fracao := 0.06) -> PackedVector2Array:
	var amplitude: float = clampf(Polilinha.comprimento(pts) * fracao, 1.0, teto)
	var n := pts.size()
	var saida := PackedVector2Array()
	for i in n:
		var t := float(i) / float(maxi(1, n - 1))
		var dx := sin(t * TAU * 2.3 + 0.7) * 0.6 + sin(t * TAU * 5.1 + 2.1) * 0.4
		var dy := cos(t * TAU * 1.9 + 1.3) * 0.6 + cos(t * TAU * 4.4 + 0.4) * 0.4
		saida.append(pts[i] + Vector2(dx, dy) * amplitude)
	return saida

func _tremer(tracos: Array, teto: float, fracao := 0.06) -> Array:
	var saida: Array = []
	for t in tracos:
		saida.append(_tremer_um(t, teto, fracao))
	return saida

## Levanta o dedo no meio do primeiro traco.
func _partir_primeiro(tracos: Array) -> Array:
	var saida: Array = []
	var primeiro: PackedVector2Array = tracos[0]
	var meio := primeiro.size() / 2
	saida.append(primeiro.slice(0, meio))
	saida.append(primeiro.slice(meio))
	for i in range(1, tracos.size()):
		saida.append(tracos[i])
	return saida

func _checar(nome: String, condicao: bool, r: RiscoResultado) -> void:
	if condicao:
		print("  ok    %s" % nome)
	else:
		falhas += 1
		print("  FALHA %s  -> %s" % [nome, r])
