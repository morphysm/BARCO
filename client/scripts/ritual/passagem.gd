## O caminho ate ao `assentamento` (SPEC.md §1.1).
##
## Tres `pontos` primeiro, um de cada vez, sempre com o guia por baixo; a
## `fornalha` a seguir, uma vez so.
## Risca-se o
## que esta a frente e pergunta-se ao guia: posso passar? Se o desenho
## estiver riscado o suficiente, o guia poe o seguinte; senao diz que
## ainda nao.
##
## Riscado o terceiro, o eclipse, e depois o `assentamento`. Atravessa-se
## uma vez: dai em diante o app abre no `assentamento`.
##
## A ordem e a da `irmandade`, e nao ha escolha nenhuma pelo caminho —
## nao ha menu, ha o ponto que esta a frente.
##
## Isto vive no aparelho e e provisorio. O `caderno` e o registo a serio e
## e do servidor (AGENTS.md, SPEC.md §3.3).
class_name Passagem
extends RefCounted

## Onde o progresso fica.
##
## Nao e `const` para as provas poderem apontar para outro sitio. Uma
## prova que escreva aqui mexe no progresso de quem esta a usar o app —
## ja aconteceu com os `pedidos`, e voltou a acontecer aqui.
static var REGISTO := "user://passagem.json"

## A iris que fecha na `fornalha` tem de abrir no `assentamento`. Vive so
## na memoria e so entre as duas cenas: nao se guarda, porque nao e
## estado do ritual — e o corte entre dois planos.
static var iris_a_abrir := false

## Quanto de um `ponto` tem de estar riscado para se passar ao seguinte.
##
## Nao tem numero proprio: e o limiar do `abandonado` (SPEC.md §5.3), para
## a porta nao poder discordar da nota. Quem abandona nao entra.
const COBERTURA_PARA_PASSAR := RiscoScoring.COBERTURA_MINIMA


## Os `pontos` ja riscados, por slug, pela ordem em que caíram.
static func passados() -> Array:
	return _ler().get("passados", [])


## O `ponto` que esta a frente, ou `null` se ja se riscaram os tres.
static func proximo(irm: Irmandade) -> Entidade:
	if irm == null:
		return null
	var feitos := passados()
	for e in irm.entidades:
		if e != null and not feitos.has(e.slug):
			return e
	return null


## Regista um `ponto` riscado. Nao se desfaz (GDD §2).
static func passar(slug: String) -> void:
	if slug == "":
		return
	var d := _ler()
	var lista: Array = d.get("passados", [])
	if lista.has(slug):
		return
	lista.append(slug)
	d["passados"] = lista
	_guardar(d)


## Riscaram-se os tres?
##
## Sem `irmandade` a resposta e NAO, e nao "sim". Nao saber quais sao os
## `pontos` nao e o mesmo que te-los riscado todos — e o `proximo()`
## devolve nulo nos dois casos, portanto a diferenca tem de ser feita
## aqui. Foi por faltar isto que uma `irmandade` por carregar mandava
## alguem direito ao `assentamento`.
static func completa(irm: Irmandade) -> bool:
	if irm == null:
		return false
	return proximo(irm) == null


## Ja se atravessou a Porta? E a pergunta da entrada, antes de tudo o
## resto (SPEC.md §1.1). Quem entrou nao volta a ser perguntado; quem
## desistiu fechou o app sem entrar, e a Porta continua fechada.
static func atravessou() -> bool:
	return _ler().get("atravessou_a_porta", false)


static func atravessar() -> void:
	var d := _ler()
	d["atravessou_a_porta"] = true
	_guardar(d)


## Ja se queimou o passado na `fornalha`? Atravessa-se uma vez.
static func queimou() -> bool:
	return _ler().get("queimou", false)


static func queimar() -> void:
	var d := _ler()
	d["queimou"] = true
	_guardar(d)


static func _ler() -> Dictionary:
	if not FileAccess.file_exists(REGISTO):
		return {}
	var f := FileAccess.open(REGISTO, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d if typeof(d) == TYPE_DICTIONARY else {}


static func _guardar(d: Dictionary) -> void:
	var f := FileAccess.open(REGISTO, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()


## So para provas. Nao ha caminho nenhum para isto a partir do app.
static func esquecer() -> void:
	if FileAccess.file_exists(REGISTO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(REGISTO))
