## Uma face de uma entidade de duas faces. SPEC.md §3.2.
##
## `Exu Aranha` e `Rosa Negra` sao duas `faces` de uma entidade, partilhando
## um `assentamento`. A face nunca e escolhida em menu: o usuario risca e
## descobre (SPEC.md §5.2).
class_name Face
extends Resource

## Slug ASCII, sem acento. Ex.: exu_aranha, rosa_negra.
@export var slug: String = ""

## Ramo de cauda do `ponto_riscado` partilhado. E a geometria que decide
## qual face responde.
@export var continuacao: Curve2D

@export var bebida: String = ""
@export var fumo: String = ""
@export var oferendas: Array[String] = []
@export var cores: PackedColorArray = PackedColorArray()
