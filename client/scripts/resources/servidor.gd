## Onde o app fala com o servidor.
##
## Vive num `.tres` e nao em constantes dentro de um script para trocar de
## projecto ser trocar um ficheiro de dados, e nao mexer em codigo.
class_name Servidor
extends Resource

@export var url: String = ""
## A chave PUBLICA (anon). E publica por desenho: vai dentro do app,
## qualquer pessoa a consegue ler do executavel, e nao da acesso a nada —
## quem manda e o RLS, e as tabelas de dinheiro nao tem politica nenhuma.
##
## A chave de admin NUNCA entra aqui. Essa vive so nas Edge Functions, e
## e o servidor do Supabase que a injecta.
@export var chave_publica: String = ""

## A pagina do Ko-fi que se abre para pagar.
##
## Vazia enquanto nao for preenchida, e o botao de pagar diz isso em vez
## de abrir o browser numa pagina que nao existe.
@export var kofi_url: String = ""

## Vende-se, ou so se risca?
##
## FALSO fecha o balcao: nao ha `comprar`, nao ha tira de `oferendas`, nao
## ha por onde pedir um codigo, e nao se cria identidade nenhuma. Fica o
## ritual inteiro — a Porta, os tres `pontos`, o eclipse, a `fornalha`, o
## `assentamento` e os `pedidos` — que e tudo o que corre sem servidor e
## sem dinheiro.
@export var vende: bool = true

## Na web o checkout exige email confirmado, tambem no RPC do servidor.
## Este campo controla a disponibilidade; nao substitui a autenticacao.
@export var vende_na_web: bool = false


## Vende-se NESTE sitio onde o app esta a correr?
##
## A pergunta e uma so e mora aqui, e nao em cada ecra que mexe em
## dinheiro: o balcao, a tira de `oferendas`, o `abrir_balcao` e o
## nascimento da identidade perguntam todos a mesma coisa ao mesmo sitio.
func vende_aqui() -> bool:
	if not vende:
		return false
	if OS.has_feature("web"):
		return vende_na_web
	return true
