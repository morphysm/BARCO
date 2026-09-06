## Uma `irmandade`: entidades que partilham identidades e comportamentos, e
## que respondem no mesmo `assentamento`.
##
## Cada entidade da `irmandade` tem a sua `assinatura`: o `ponto_riscado`
## inteiro, tal como foi desenhado. Assinaturas NAO se compoem umas com as
## outras e nao partilham geometria — o ponto de cada entidade e o dela.
##
## O usuario nao escolhe em menu: risca uma assinatura e descobre quem
## atendeu. Quando o traco nao chega a nenhuma, ou fica entre duas, o
## resultado e `face_indefinida`.
class_name Irmandade
extends Resource

@export var slug: String = ""
@export var nome: String = ""

## O `reino` onde esta `irmandade` responde.
@export var reino: String = ""

## Quem reina nesta `irmandade`. `Exu Caveira` e o rei do cemiterio.
## Doutrina, nao mecanica: nao altera a avaliacao do risco.
@export var rei: String = ""

## As entidades que assinam nesta `irmandade`.
@export var entidades: Array[Entidade] = []

func entidade_por_slug(s: String) -> Entidade:
	for e in entidades:
		if e != null and e.slug == s:
			return e
	return null
