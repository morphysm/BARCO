## A porta entre riscar e o `assentamento` (SPEC.md §1.1).
##
## Uma so pergunta: riscou-se o suficiente do desenho? Setenta por cento
## chega. Abaixo disso nao — risca mais.
##
## Nao ha contagem de assinaturas, nao ha sequencia de primeiros
## contatos, nao ha nada a desbloquear por partes. Risca-se, pergunta-se,
## passa-se ou nao.
##
## Atravessa-se uma vez. Depois disso o app abre no `assentamento`.
##
## Isto vive no aparelho e e provisorio. O `caderno` e o registo a serio e
## e do servidor (AGENTS.md, SPEC.md §3.3).
class_name Passagem
extends RefCounted

const REGISTO := "user://passagem.json"

## Quanto do desenho tem de estar riscado para se passar. Decisao de A.C.
##
## ATENCAO: `RiscoScoring.COBERTURA_MINIMA` e 0.75 e serve para outra
## coisa — abaixo dela o risco conta como `abandonado` (SPEC.md §5.3).
## Sendo este limiar mais baixo, um risco entre 0.70 e 0.75 passa a porta
## e mesmo assim vale zero de `firmeza`. Os dois numeros tem de se
## encontrar, e qual deles cede e decisao de A.C.
const COBERTURA_PARA_PASSAR := 0.70


static func passou() -> bool:
	return _ler().get("passou", false)


## Regista a passagem. Nao se desfaz — como tudo aqui, so cresce (GDD §2).
static func passar() -> void:
	var d := _ler()
	d["passou"] = true
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
