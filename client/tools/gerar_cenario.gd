## Refaz `assentamento_cenario.tscn` a partir do `assentamento.tscn`.
##
##   godot --headless --path client --script res://tools/gerar_cenario.gd
##
## As duas cenas tem o mesmo arranjo e scripts diferentes: a oficial corre
## o ritual, a copia so veste e ilumina. Mantidas a mao, afastavam-se —
## e afastaram-se. Isto poe a copia a par, e a copia nao guarda nada de
## seu: o que se acrescentar so a ela perde-se aqui.
##
## O sentido e sempre este. O arranjo mora na cena oficial.
extends SceneTree

const OFICIAL := "res://scenes/assentamento.tscn"
const CENARIO := "res://scenes/assentamento_cenario.tscn"
const RITUAL := "res://scripts/ui/assentamento_screen.gd"
const SO_CENARIO := "res://scripts/ui/assentamento_cenario.gd"


func _initialize() -> void:
	var f := FileAccess.open(OFICIAL, FileAccess.READ)
	if f == null:
		printerr("nao ha cena em ", OFICIAL)
		quit(1)
		return
	var t := f.get_as_text()
	f.close()

	# O uid da cena e o do script mudam; o resto e igual, linha a linha.
	var uid_cenario := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(CENARIO))
	var uid_oficial := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(OFICIAL))
	if uid_cenario != "" and uid_oficial != "":
		t = t.replace(uid_oficial, uid_cenario)

	var uid_script := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(SO_CENARIO))
	var re := RegEx.new()
	re.compile('\\[ext_resource type="Script"[^\\]]*assentamento_screen\\.gd"([^\\]]*)\\]')
	var achou := re.search(t)
	if achou == null:
		printerr("a cena oficial nao tem o script do ritual — nada a fazer")
		quit(1)
		return
	t = t.replace(achou.get_string(),
		'[ext_resource type="Script" uid="%s" path="%s"%s]' % [
			uid_script, SO_CENARIO, achou.get_string(1)])

	# Exports que so o script do ritual tem: no de cenario nao existem e o
	# Godot avisa a cada abertura.
	var limpo := PackedStringArray()
	for linha in t.split("\n"):
		if linha.begins_with("dias_de_queima "):
			continue
		limpo.append(linha)
	t = "\n".join(limpo)

	var g := FileAccess.open(CENARIO, FileAccess.WRITE)
	g.store_string(t)
	g.close()
	var pecas := 0
	for linha in t.split("\n"):
		if linha.begins_with("[node name="):
			pecas += 1
	print("cenario refeito a partir da cena oficial: %d pecas" % pecas)
	quit()
