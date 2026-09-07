## A porta entre riscar e o `assentamento` (SPEC.md §1.1).
##
## Uma so pergunta: chegou-se ao fim do desenho? Quem abandonou nao
## entra — e o mesmo limiar que faz um `ponto` ser `abandonado`.
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

## Quem abandona nao entra (decisao de A.C.). E por isso que a porta nao
## tem numero proprio: e o mesmo limiar do `abandonado`, e um `ponto`
## abandonado vale zero a qualquer hora (SPEC.md §5.3).
##
## Dois numeros diferentes davam um risco que passava a porta e valia
## zero. Um so nao pode discordar de si mesmo. Se o limiar do abandono
## mudar, a porta acompanha.
const COBERTURA_PARA_PASSAR := RiscoScoring.COBERTURA_MINIMA


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
