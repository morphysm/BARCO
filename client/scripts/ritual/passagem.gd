## O que ja foi riscado, e se a passagem para o `assentamento` esta aberta.
##
## Primeira fase (SPEC.md §1.1): riscar as tres `assinaturas` da
## `irmandade`. Enquanto faltar uma, o `assentamento` nao existe para
## quem esta a jogar — nao esta trancado, nao esta la.
##
## Conta o risco que NOMEIA a entidade. Uma `face_indefinida` nao conta,
## e um `ponto` `abandonado` muito menos: a fase pede as tres assinaturas,
## nao tres tentativas.
##
## Isto vive no aparelho e e provisorio. O `caderno` e o registo a serio e
## e do servidor (AGENTS.md, SPEC.md §3.3); quando ele existir, isto passa
## a ser so a copia local.
class_name Passagem
extends RefCounted

const REGISTO := "user://passagem.json"

## `firmeza` minima para um `ponto` contar. ZERO por enquanto: basta
## nomear a entidade. Quanto tem de ser esta por decidir (SPEC.md §1.1) e
## e decisao de A.C., nao minha.
const FIRMEZA_MINIMA := 0


static func riscados() -> Array:
	if not FileAccess.file_exists(REGISTO):
		return []
	var f := FileAccess.open(REGISTO, FileAccess.READ)
	if f == null:
		return []
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY or not d.has("riscados"):
		return []
	return d["riscados"]


## Regista que uma entidade foi nomeada. Devolve `true` se e a primeira
## vez — e o que faz a fase avancar.
##
## Nao se desmarca. Como tudo o resto aqui, so cresce (GDD §2).
static func marcar(slug: String, firmeza: int) -> bool:
	if slug == "" or firmeza < FIRMEZA_MINIMA:
		return false
	var lista := riscados()
	if lista.has(slug):
		return false
	lista.append(slug)
	var f := FileAccess.open(REGISTO, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"riscados": lista}))
	f.close()
	return true


## Faltam quantas assinaturas desta `irmandade`.
static func faltam(irm: Irmandade) -> int:
	if irm == null:
		return 0
	var lista := riscados()
	var n := 0
	for e in irm.entidades:
		if e != null and not lista.has(e.slug):
			n += 1
	return n


static func aberta(irm: Irmandade) -> bool:
	return faltam(irm) == 0


## So para provas: apaga o progresso. Nao ha caminho nenhum para isto a
## partir do app — a fase nao se desfaz.
static func esquecer() -> void:
	if FileAccess.file_exists(REGISTO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(REGISTO))
