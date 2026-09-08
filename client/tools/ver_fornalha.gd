## Volta a entrar na `fornalha`, do principio: a cruz, o fogo, as formas
## a dancar, a musica e a iris.
##
##   godot --path client --script res://tools/ver_fornalha.gd
##
## ISTO NAO E UMA PORTA NO APP. A lei nao muda: quem instala o app renega
## o passado UMA vez (SPEC.md §1.1, §2). Nao ha, nem passa a haver,
## caminho nenhum para aqui de dentro do app — isto e um script em
## `tools/`, do mesmo estatuto do `Passagem.esquecer()`, que existe e nao
## se alcanca a partir de nenhuma tela.
##
## O que faz e apontar o registo para OUTRO ficheiro antes de abrir a
## cena. A `fornalha` marca `queimar()` no instante em que a cruz e
## atirada, e essa marca vai para o ficheiro de lado: o
## `user://passagem.json` de quem esta a usar o app nao e tocado, e quem
## ja atravessou continua a ter atravessado uma vez so.
##
## Ao fim da musica a cena segue o seu caminho e abre o `assentamento`,
## como abriria a serio. E a `fornalha` inteira, nao um passeio por ela.
extends SceneTree

const DE_LADO := "user://ver_fornalha.json"


func _initialize() -> void:
	Passagem.REGISTO = DE_LADO
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DE_LADO))
	root.add_child(load("res://scenes/fornalha.tscn").instantiate())
	print("fornalha aberta. o registo desta visita fica em %s," % DE_LADO)
	print("e o `passagem.json` a serio nao e tocado.")
