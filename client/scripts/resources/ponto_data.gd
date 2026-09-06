## Geometria de referencia de um `ponto_riscado`. SPEC.md §4.
##
## O `ponto_riscado` e input, nao decoracao. Esta resource guarda apenas a
## referencia contra a qual o traco do usuario e comparado; o desenho na tela
## e feito pelo traco do proprio usuario (SPEC.md §4.1: marcas de inicio de
## segmento sao mostradas, o caminho nao).
class_name PontoData
extends Resource

## Resolucao de referencia. Todo traco e normalizado para este espaco antes
## de qualquer comparacao.
@export var referencia: Vector2 = Vector2(1000, 1000)

## Segmentos da base, na ordem obrigatoria de traçado.
@export var segmentos: Array[Curve2D] = []

## TOLERANCE_PX na escala de referencia. SPEC.md §4.2.
@export var tolerancia_px: float = 40.0

## Retorna o ponto inicial de cada segmento — as unicas marcas visiveis
## antes do traco.
func marcas_de_inicio() -> PackedVector2Array:
	var marcas := PackedVector2Array()
	for c in segmentos:
		if c != null and c.point_count > 0:
			marcas.append(c.get_point_position(0))
	return marcas
