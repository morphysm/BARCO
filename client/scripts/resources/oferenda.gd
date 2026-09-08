## Uma `oferenda` que pode ser deposta no `assentamento`.
##
## O catalogo e dado, nao codigo: acrescentar uma oferenda e escrever um
## .tres, nunca recompilar (AGENTS.md).
##
## Depor e irreversivel. Nao ha aqui — e nao deve haver em lado nenhum —
## como tirar uma `oferenda` de um `assentamento`: `depositos` e
## append-only (SPEC.md §3.3, GDD §2).
class_name Oferenda
extends Resource

@export var slug: String = ""
@export var nome: String = ""

## bebida | fumo | botanica | objeto | luz | sangue
@export var tipo: String = "objeto"

@export_file("*.glb") var modelo: String = ""

## Maior dimensao, em metros, ja no `assentamento`.
@export var tamanho: float = 0.15

## Se e uma vela: passa a ser luz assim que e deposta. Acender e o que
## revela o `assentamento` (SPEC.md §8.1).
@export var e_vela: bool = false
## Verdadeiro quando o MODELO nao traz chama acesa e ela tem de ser
## desenhada por cima (grupo `sem_chama`).
##
## O `vela_branca.glb` e o `vela_preta.glb` trazem um material emissivo; o
## `vela_vermlha.glb` nao traz nada. Isto vive aqui e nao num no marcado a
## mao na cena porque tambem tem de valer para as velas DEPOSTAS, que
## nascem em tempo de execucao e nao existem em cena nenhuma para serem
## marcadas.
@export var sem_chama: bool = false

## Custo em cafes (SPEC.md §10.1). Zero enquanto nao ha pagamento.
@export var cafes: int = 0
