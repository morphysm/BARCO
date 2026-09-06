## Resultado de um risco avaliado. SPEC.md §4.2 e §5.
##
## `firmeza` viaja com o `trabalho` pelo ciclo inteiro (GLOSSARY.md).
## `firmeza` nao e pontuacao: e a qualidade do traco, 0–100.
class_name RiscoResultado
extends RefCounted

var firmeza: int = 0

## Componentes crus, antes dos pesos. Uteis para tuning contra playtest;
## os pesos da formula nao mudam (SPEC.md §4.2).
var accuracy: float = 0.0
var order: float = 0.0
var continuity: float = 0.0

## firmeza antes do modificador de `face_indefinida`.
var firmeza_bruta: int = 0

## Slug da entidade cuja `assinatura` foi reconhecida. Vazio quando
## `indefinida` ou `abandonado`.
var entidade_slug: String = ""

## O risco foi inteiro, mas nao pousou em assinatura nenhuma. E o traco
## instintivo: a mao foi ate ao fim sem se prender a uma forma. Dentro da
## `hora_asmodeica` vale muito (SPEC.md §5.3).
var indefinida: bool = false

## O risco foi deixado a meio: ha tracos do `ponto` que nunca chegaram a
## ser riscados. Um ponto riscado e abandonado nao vale nada, e nao recebe
## nada da `hora_asmodeica`.
##
## E o que separa o instinto do desistir. Sem esta distincao, parar cedo
## seria o caminho mais curto para a firmeza mais alta da madrugada.
var abandonado: bool = false

## Fracao dos tracos do `ponto` que receberam traco. 1.0 = ponto inteiro.
var cobertura: float = 0.0

## Distancia media do traco a cada `assinatura` da `irmandade`, na ordem
## em que as entidades aparecem nela.
var distancias: PackedFloat32Array = PackedFloat32Array()
var slugs: PackedStringArray = PackedStringArray()

## Quantas vezes o dedo foi levantado no meio de um segmento.
var breaks: int = 0

## Segmentos da `assinatura` reconhecida que nao receberam nenhum traco.
var segmentos_ausentes: int = 0

## Verdadeiro quando o risco foi avaliado dentro da `hora_asmodeica`.
## O cliente NAO decide isto — vem do servidor (SPEC.md §6.2).
var hora_asmodeica: bool = false

func _to_string() -> String:
	var quem := entidade_slug
	if abandonado:
		quem = "abandonado"
	elif indefinida:
		quem = "face_indefinida"
	return "RiscoResultado(firmeza=%d, %s, acc=%.2f ord=%.2f cont=%.2f cob=%.2f)" % [
		firmeza, quem, accuracy, order, continuity, cobertura
	]
