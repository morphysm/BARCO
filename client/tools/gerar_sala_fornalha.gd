## Monta a sala da `fornalha` com nos a serio, para tudo se poder arrastar
## no editor depois.
##
##   godot --headless --path client --script res://tools/gerar_sala_fornalha.gd -- --refazer
##
## PEDE `--refazer` de proposito: escreve a cena do zero e deita fora o
## que estiver la arrumado a mao. Ja aconteceu uma vez, num assentamento.
##
## Nada disto e feito por codigo em tempo de execucao. As paredes, as
## bandeiras, o sigilo, a imagem e os lugares das formas sao nos com
## transformacao propria: abre-se a cena e mexe-se.
extends SceneTree

const CENA := "res://scenes/fornalha.tscn"

const REDSKIN := "res://resources/imagens/mmorph REDskin_para_as_paredes.png"
const SIGILO_CHAO := "res://resources/imagens/MORPHISTIC SIGIL_para o chão.jpg"
const SIGILO_PANO := "res://resources/imagens/morphysm sigil STONE.png"
const BAPHOMET := "res://resources/imagens/BAPHOMET777SUBLIMINALL.jpg"
const FORNALHA := "res://resources/modelos/fornalha.glb"
const MUSICA := "res://resources/audio/Entrego Minha Alma.ogg"

## A sala. A fornalha ocupa a frente; as paredes fecham os lados.
const LARGURA := 9.0      # de parede a parede
const FUNDO := 9.0        # da fornalha ate atras da camara
const ALTURA := 5.4

var raiz: Node3D


func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--refazer"):
		printerr("RECUSADO: isto reescreve %s de raiz." % CENA)
		printerr("  o que estiver arrumado a mao no editor perde-se.")
		printerr("  para o fazer mesmo assim: acrescentar  -- --refazer")
		quit(1)
		return

	raiz = Node3D.new()
	raiz.name = "Fornalha"
	raiz.set_script(load("res://scripts/ui/fornalha_screen.gd"))

	_camara()
	_chao()
	_paredes()
	_fornalha()
	_baphomet()
	_bandeiras()
	_lugares_das_formas()

	raiz.set("musica", load(MUSICA))
	raiz.set("cruz", load("res://resources/modelos/cruz_pro_fogo.glb"))

	var e := PackedScene.new()
	assert(e.pack(raiz) == OK)
	assert(ResourceSaver.save(e, CENA) == OK)
	print("sala montada: %d nos" % _contar(raiz))
	quit()


func _contar(n: Node) -> int:
	var t := 1
	for f in n.get_children():
		t += _contar(f)
	return t


func _por(no: Node3D, nome: String, onde: Vector3) -> Node3D:
	no.name = nome
	no.position = onde
	raiz.add_child(no)
	no.owner = raiz
	return no


func _camara() -> void:
	var c := Camera3D.new()
	c.fov = 58.0
	c.current = true
	# De pe, a olhar para a boca do forno, ligeiramente de cima.
	c.rotation_degrees = Vector3(-5.5, 0.0, 0.0)
	_por(c, "Camara", Vector3(-1.5, 2.15, 7.4))


func _chao() -> void:
	var chao := MeshInstance3D.new()
	var m := PlaneMesh.new()
	m.size = Vector2(LARGURA, FUNDO)
	chao.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.055, 0.05, 0.048)
	mat.roughness = 1.0
	chao.material_override = mat
	_por(chao, "Chao", Vector3(-1.5, 0.0, FUNDO * 0.5 - 1.2))

	# O sigilo no chao, deitado. Ligeiramente acima do plano para nao
	# lutarem pelo mesmo sitio.
	var sig := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2.4, 2.28)
	q.material = _material_de_imagem(SIGILO_CHAO, false)
	sig.mesh = q
	sig.rotation_degrees = Vector3(-90, 0, 0)
	_por(sig, "SigiloDoChao", Vector3(-1.5, 0.006, 2.6))


## Duas paredes de lado e uma atras da fornalha — a fornalha e a terceira,
## a nossa frente. A de tras tapa os arcos vazios das bocas que nao vieram.
func _paredes() -> void:
	var esq := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(FUNDO, ALTURA)
	q.material = _material_de_imagem(REDSKIN, false)
	esq.mesh = q
	esq.rotation_degrees = Vector3(0, 90, 0)
	_por(esq, "ParedeEsquerda", Vector3(-1.5 - LARGURA * 0.5, ALTURA * 0.5, FUNDO * 0.5 - 1.2))

	var dir := MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(FUNDO, ALTURA)
	q2.material = _material_de_imagem(REDSKIN, false)
	dir.mesh = q2
	dir.rotation_degrees = Vector3(0, -90, 0)
	_por(dir, "ParedeDireita", Vector3(-1.5 + LARGURA * 0.5, ALTURA * 0.5, FUNDO * 0.5 - 1.2))

	var atras := MeshInstance3D.new()
	var q3 := QuadMesh.new()
	q3.size = Vector2(LARGURA, ALTURA)
	q3.material = _material_de_imagem(REDSKIN, false)
	atras.mesh = q3
	_por(atras, "ParedeAtras", Vector3(-1.5, ALTURA * 0.5, -0.9))


func _fornalha() -> void:
	var f: Node3D = load(FORNALHA).instantiate()
	_por(f, "fornalha", Vector3.ZERO)


func _baphomet() -> void:
	var b := MeshInstance3D.new()
	var t: Texture2D = load(BAPHOMET)
	var q := QuadMesh.new()
	var proporcao := float(t.get_width()) / float(t.get_height())
	var altura := 2.7
	q.size = Vector2(altura * proporcao, altura)
	q.material = _material_de_imagem(BAPHOMET, false)
	b.mesh = q
	_por(b, "Baphomet", Vector3(-1.5, 3.75, 0.05))


## Tres panos compridos pendurados de uma travessa no topo de um mastro.
func _bandeiras() -> void:
	var grupo := Node3D.new()
	_por(grupo, "Bandeiras", Vector3.ZERO)
	# O ecra e ao alto e estreito: a camara so ve cerca de 4.6 m de
	# largura ao pe da fornalha, e tudo o que passava disso caía fora do
	# enquadramento. Estas sao posicoes DENTRO do cone visivel — pontos de
	# partida, que e no editor que se arrumam.
	var lugares := [
		Vector3(-3.6, 0.0, 0.4),
		Vector3(0.6, 0.0, 0.4),
		Vector3(-3.5, 0.0, 2.2),
	]
	var giros := [24.0, -24.0, 12.0]
	for i in lugares.size():
		var b := _uma_bandeira(i + 1)
		b.position = lugares[i]
		b.rotation_degrees = Vector3(0, giros[i], 0)
		grupo.add_child(b)
		_dono(b, raiz)


func _uma_bandeira(n: int) -> Node3D:
	var alt_mastro := 3.5
	var larg_pano := 0.78
	var alt_pano := 2.05

	var b := Node3D.new()
	b.name = "Bandeira%d" % n

	var ferro := ShaderMaterial.new()
	ferro.shader = load("res://shaders/ferro.gdshader")

	# Mastro
	var mastro := MeshInstance3D.new()
	mastro.name = "Mastro"
	var cil := CylinderMesh.new()
	cil.top_radius = 0.045
	cil.bottom_radius = 0.06
	cil.height = alt_mastro
	cil.radial_segments = 10
	mastro.mesh = cil
	mastro.material_override = ferro
	mastro.position = Vector3(0, alt_mastro * 0.5, 0)
	b.add_child(mastro)

	# Travessa, no topo do mastro
	var travessa := MeshInstance3D.new()
	travessa.name = "Travessa"
	var cil2 := CylinderMesh.new()
	cil2.top_radius = 0.032
	cil2.bottom_radius = 0.032
	cil2.height = larg_pano + 0.22
	cil2.radial_segments = 8
	travessa.mesh = cil2
	travessa.material_override = ferro
	travessa.rotation_degrees = Vector3(0, 0, 90)
	travessa.position = Vector3(0, alt_mastro - 0.06, 0)
	b.add_child(travessa)

	# O pano, preso pela borda de cima
	var pano := MeshInstance3D.new()
	pano.name = "Pano"
	var q := QuadMesh.new()
	q.size = Vector2(larg_pano, alt_pano)
	q.material = _material_de_imagem(SIGILO_PANO, true)
	pano.mesh = q
	pano.position = Vector3(0, alt_mastro - 0.10 - alt_pano * 0.5, 0.02)
	b.add_child(pano)

	return b


func _dono(n: Node, d: Node) -> void:
	n.owner = d
	for f in n.get_children():
		_dono(f, d)


## Onde as formas dancantes aparecem. So marcas: os corpos sao feitos em
## tempo de execucao (ver `FormaDancante`).
func _lugares_das_formas() -> void:
	var grupo := Node3D.new()
	_por(grupo, "Dancantes", Vector3.ZERO)
	# Dentro do cone visivel, entre a camara e o fogo: dancam diante dele.
	#
	# Encostadas as margens de proposito. Ao meio tapavam a boca do forno,
	# que e o unico sitio para onde se tem de olhar.
	var lugares := [
		Vector3(-2.6, 0.0, 1.1), Vector3(-0.4, 0.0, 1.1),
		Vector3(-3.0, 0.0, 1.9), Vector3(0.0, 0.0, 1.9),
		Vector3(-2.92, 0.0, 2.7), Vector3(-0.08, 0.0, 2.7),
	]
	for i in lugares.size():
		var m := Marker3D.new()
		m.name = "Lugar%d" % (i + 1)
		m.position = lugares[i]
		m.rotation_degrees = Vector3(0, randf_range(-40.0, 40.0), 0)
		grupo.add_child(m)
		m.owner = raiz


func _material_de_imagem(caminho: String, dos_dois_lados: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(caminho)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 1.0
	m.metallic = 0.0
	if dos_dois_lados:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
