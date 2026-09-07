## Apagar o que o app guardou no aparelho.
##
## ISTO SO EXISTE EM DEBUG. Num build de release nao apaga nada, e nao ha
## botao nenhum que lhe chegue.
##
## O app a serio nao tem volta: `depor` e irreversivel, o `caderno` e
## append-only, e um `pedido` arde os sete dias que tem para arder
## (AGENTS.md — Irreversibilidade, GDD §2). Nada disto e um "undo": e a
## bancada de quem esta a construir, e a bancada nao vai no barco.
##
## O unico caminho para apagar no app a serio continua a ser apagar a
## conta inteira (GDPR), que e outra coisa e ainda esta por construir.
class_name Dados
extends RefCounted

## Os ficheiros que o app escreve no aparelho.
const FICHEIROS := [
	"user://passagem.json",     # que pontos ja foram riscados
	"user://depositos.json",    # o que foi deposto no assentamento
	"user://pedidos.json",      # os pedidos a arder
]


## Ha bancada? Falso num build de release, e ai nada disto funciona.
static func em_debug() -> bool:
	return OS.is_debug_build()


## Apaga tudo. Devolve quantos ficheiros existiam e foram apagados, ou -1
## se nao ha bancada — e nao ha maneira de forçar.
static func apagar_tudo() -> int:
	if not em_debug():
		push_warning("Dados.apagar_tudo() so funciona em debug. Nada foi apagado.")
		return -1
	var n := 0
	for caminho in FICHEIROS:
		if FileAccess.file_exists(caminho):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
			n += 1
	return n
