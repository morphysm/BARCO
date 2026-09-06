## Poe uma imagem PNG no `assentamento`, como uma estampa de pe ou uma
## fotografia pousada no chao.
##
## A imagem tem de estar DENTRO do projeto e importada. Um PNG que esteja
## noutra pasta qualquer nao serve: o Godot so ve o que importou.
##
##   cp a_minha.png client/resources/imagens/
##   godot --headless --path client --import
##   godot --headless --path client --script res://tools/por_imagem.gd -- \
##         --cena cenario resources/imagens/a_minha.png 0.20 0 0.10 0.12 -30
##
## Argumentos: FICHEIRO x y z altura giro
##   x y z    onde assenta — o pe da imagem, nao o centro
##   altura   quanto mede ao alto, em metros. A largura sai da propria
##            imagem, para nao a esticar
##   giro     graus a rodar sobre si mesma
##
## Opcoes:
##   --cena cenario|fundamento   qual das duas cenas (por omissao, o
##                               fundamento, que esta travado)
##   --nome NO                   nome do no; por omissao, o do ficheiro
##   --deitada                   pousada no chao em vez de ao alto
##   --inclinar G                graus tombada para tras (so em pe)
##   --acesa                     nao recebe luz: le-se sempre igual, mesmo
##                               sem vela nenhuma acesa. Sem isto a imagem
##                               vive da luz das velas, como o resto
##   --tirar                     tira o no com este nome
##
## A textura vai no material da PROPRIA malha e nao em `material_override`:
## o `assentamento` limpa os overrides a cada passagem, e a imagem
## desaparecia.
extends SceneTree

const FUNDAMENTO := "res://scenes/assentamento.tscn"
const CENARIO := "res://scenes/assentamento_cenario.tscn"

var _cena := FUNDAMENTO


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	a.erase("--destravar")

	var deitada := a.has("--deitada")
	a.erase("--deitada")
	var acesa := a.has("--acesa")
	a.erase("--acesa")
	var tirar := a.has("--tirar")
	a.erase("--tirar")

	var nome := ""
	var i := a.find("--nome")
	if i != -1:
		if i + 1 >= a.size():
			printerr("--nome precisa de um nome")
			quit(1)
			return
		nome = a[i + 1]
		a.remove_at(i + 1)
		a.remove_at(i)

	var inclinacao := 0.0
	i = a.find("--inclinar")
	if i != -1:
		if i + 1 >= a.size():
			printerr("--inclinar precisa de graus")
			quit(1)
			return
		inclinacao = float(a[i + 1])
		a.remove_at(i + 1)
		a.remove_at(i)

	i = a.find("--cena")
	if i != -1:
		if i + 1 >= a.size():
			printerr("--cena precisa de um nome: fundamento | cenario")
			quit(1)
			return
		match a[i + 1]:
			"cenario": _cena = CENARIO
			"fundamento": _cena = FUNDAMENTO
			_:
				printerr("cena desconhecida: ", a[i + 1], " (fundamento | cenario)")
				quit(1)
				return
		a.remove_at(i + 1)
		a.remove_at(i)

	# O fundamento e autoral e esta travado. O cenario e uma copia para
	# levar para outro sitio: mexer nela nao altera o `assentamento`.
	if _cena == FUNDAMENTO and not OS.get_cmdline_user_args().has("--destravar"):
		printerr("RECUSADO: o fundamento esta travado (ver scenes/assentamento.travado)")
		printerr("  para alterar mesmo assim: acrescentar  -- --destravar")
		printerr("  depois de alterar: python3 tools/verificar_fundamento.py --regravar")
		printerr("  para mexer so na copia de cenario:  -- --cena cenario ...")
		quit(1)
		return

	if tirar:
		_tirar(nome if nome != "" else (a[0].get_file().get_basename() if a.size() > 0 else ""))
		return

	if a.size() < 6:
		printerr("uso: [--cena cenario] [--nome NO] [--deitada] [--acesa]")
		printerr("     [--inclinar G] FICHEIRO.png x y z altura giro")
		quit(1)
		return

	var caminho := a[0]
	if not caminho.begins_with("res://"):
		caminho = "res://" + caminho.trim_prefix("./")
	if nome == "":
		nome = caminho.get_file().get_basename()

	if not ResourceLoader.exists(caminho):
		printerr("nao ha imagem importada em: ", caminho)
		printerr("  o ficheiro tem de estar dentro de client/ e ja importado:")
		printerr("    cp A.png client/resources/imagens/")
		printerr("    godot --headless --path client --import")
		quit(1)
		return
	var textura: Texture2D = load(caminho)
	if textura == null:
		printerr("isto nao carregou como imagem: ", caminho)
		quit(1)
		return

	var onde := Vector3(float(a[1]), float(a[2]), float(a[3]))
	var altura := float(a[4])
	var giro := float(a[5])

	# A largura sai da imagem. Dar as duas medidas a mao era a maneira
	# certa de a esticar sem dar por isso.
	var proporcao := float(textura.get_width()) / maxf(float(textura.get_height()), 1.0)
	var largura := altura * proporcao

	var raiz: Node3D = load(_cena).instantiate()
	root.add_child(raiz)

	var antiga := raiz.get_node_or_null(NodePath(nome))
	if antiga != null:
		raiz.remove_child(antiga)
		antiga.free()

	var no := MeshInstance3D.new()
	no.name = nome
	var quad := QuadMesh.new()
	quad.size = Vector2(largura, altura)

	var m := StandardMaterial3D.new()
	m.albedo_texture = textura
	# Um PNG traz canal alfa quase sempre; sem isto o fundo transparente
	# saia preto chapado.
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Vista pelos dois lados: uma estampa fina nao tem costas.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	m.metallic = 0.0
	if acesa:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = m           # na malha, nao em material_override
	no.mesh = quad

	raiz.add_child(no)
	no.owner = raiz

	if deitada:
		# Deitada de costas para cima, e um fio acima do chao para nao
		# lutar com ele pelo mesmo plano.
		no.rotation_degrees = Vector3(-90, giro, 0)
		no.position = onde + Vector3(0, 0.0008, 0)
	else:
		no.rotation_degrees = Vector3(-inclinacao, giro, 0)
		# `onde` e o pe da imagem: sobe-se meia altura para ela assentar
		# em vez de ficar enterrada ate ao meio.
		no.position = onde + Vector3(0, cos(deg_to_rad(inclinacao)) * altura * 0.5, 0)

	var empacotada := PackedScene.new()
	assert(empacotada.pack(raiz) == OK)
	assert(ResourceSaver.save(empacotada, _cena) == OK)
	print("posta %s  %.3f x %.3f m  em (%.2f, %.2f, %.2f)  ->  %s" % [
		nome, largura, altura, onde.x, onde.y, onde.z, _cena.get_file()])
	raiz.free()
	quit()


func _tirar(nome: String) -> void:
	var raiz: Node3D = load(_cena).instantiate()
	root.add_child(raiz)
	var no := raiz.get_node_or_null(NodePath(nome))
	if no == null:
		printerr("nao ha no chamado: ", nome)
		quit(1)
		return
	raiz.remove_child(no)
	no.free()
	var e := PackedScene.new()
	assert(e.pack(raiz) == OK)
	assert(ResourceSaver.save(e, _cena) == OK)
	print("tirada de %s: %s" % [_cena.get_file(), nome])
	raiz.free()
	quit()
