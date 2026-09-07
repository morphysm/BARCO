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
	_corredor()
	_chao()
	_paredes()
	_teto()
	_fornalha()
	_baphomet()
	_bandeiras()
	_lugar_da_cruz()
	_formas()

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


## Quem anda. A camara vai nele, a altura dos olhos.
func _camara() -> void:
	var j := CharacterBody3D.new()
	j.set_script(load("res://scripts/ui/jogador.gd"))
	_por(j, "Jogador", Vector3(-1.5, 0.0, 6.2))

	var forma := CollisionShape3D.new()
	forma.name = "Corpo"
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.32
	capsula.height = 1.7
	forma.shape = capsula
	forma.position = Vector3(0, 0.85, 0)
	j.add_child(forma)
	forma.owner = raiz

	var c := Camera3D.new()
	c.name = "Camara"
	c.fov = 58.0
	c.current = true
	c.position = Vector3(0, 1.62, 0)
	j.add_child(c)
	c.owner = raiz


## O corredor. Caixas a serio, que se veem e se arrastam no editor.
##
## Estreito de proposito: da para olhar em volta e nao da para passear.
## Quatro muros invisiveis a formar uma faixa da entrada ate a fornalha.
func _corredor() -> void:
	var grupo := Node3D.new()
	_por(grupo, "Corredor", Vector3.ZERO)
	# nome, centro, tamanho
	var muros := [
		# O chao. Sem ele o jogador cai — e a cair passa POR BAIXO dos
		# muros, que e como saía do corredor sem os tocar.
		["Chao", Vector3(-1.5, -0.15, 3.6), Vector3(5.0, 0.3, 8.0)],
		["Esquerda", Vector3(-3.5, 1.2, 3.6), Vector3(0.3, 2.4, 8.0)],
		["Direita", Vector3(0.5, 1.2, 3.6), Vector3(0.3, 2.4, 8.0)],
		# Nao ate a boca: encostado ao forno perde-se a sala inteira, e a
		# sala e para se ver. Fica-se a uns dois metros e meio.
		["Fundo", Vector3(-1.5, 1.2, 2.3), Vector3(4.3, 2.4, 0.3)],
		["Atras", Vector3(-1.5, 1.2, 7.4), Vector3(4.3, 2.4, 0.3)],
	]
	for m in muros:
		var corpo := StaticBody3D.new()
		corpo.name = m[0]
		grupo.add_child(corpo)
		corpo.owner = raiz
		corpo.position = m[1]
		var f := CollisionShape3D.new()
		f.name = "Forma"
		var caixa := BoxShape3D.new()
		caixa.size = m[2]
		f.shape = caixa
		corpo.add_child(f)
		f.owner = raiz


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


## O teto: o buraco negro e as estrelas negras de Carcosa.
##
## E um quad virado para baixo com o `buraco_negro.gdshader`. Os valores
## todos — horizonte, anel, rotacao, arrasto, densidade, nevoa, cores —
## estao no material e mexem-se no inspetor.
func _teto() -> void:
	var t := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(LARGURA, FUNDO)
	t.mesh = q
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/buraco_negro.gdshader")
	t.material_override = m
	t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Virado para baixo: um quad olha para +z, e rodar 90 em x poe-lhe a
	# cara em -y.
	t.rotation_degrees = Vector3(90, 0, 0)
	_por(t, "Teto", Vector3(-1.5, ALTURA, FUNDO * 0.5 - 1.2))


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


## Onde a cruz nasce, e virada para onde. E um no a serio: abre-se a cena,
## roda-se, e fica. O modelo vem dentro dele, escondido ate se dizer SIM.
func _lugar_da_cruz() -> void:
	var c := Node3D.new()
	c.visible = false
	_por(c, "Cruz", Vector3(-1.5, 1.30, 4.3))
	var modelo: Node3D = load("res://resources/modelos/cruz_pro_fogo.glb").instantiate()
	modelo.name = "Modelo"
	# De pe: o modelo vem deitado, com o braco comprido em z.
	modelo.rotation_degrees = Vector3(-90, 0, 0)
	c.add_child(modelo)
	# So o no do modelo leva dono. Dar dono aos filhos INTERNOS de um
	# `.glb` marca-os como filhos editaveis e o Godot grava-os outra vez
	# por cima da instancia — ficavam duas malhas com o mesmo nome, uma
	# delas fora da arvore.
	modelo.owner = raiz


## As formas dancantes. NOS A SERIO, um por figura — cor, brilho,
## contorno, faisca e bruma sao todos `@export` e veem-se no editor,
## porque `FormaDancante` e `@tool`.
func _formas() -> void:
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
		var f := FormaDancante.new()
		f.name = "Forma%d" % (i + 1)
		f.position = lugares[i]
		f.rotation_degrees = Vector3(0, randf_range(-40.0, 40.0), 0)
		# Cada uma com os seus valores: nao se sincronizam.
		f.semente = float(i) * 2.7 + 0.83
		f.ritmo = 0.72 + fmod(float(i) * 0.37, 0.55)
		f.tamanho = 0.92 + fmod(float(i) * 0.23, 0.26)
		f.espelhar = (i % 2) == 1
		f.eco = 0.022 + fmod(float(i) * 0.011, 0.02)
		grupo.add_child(f)
		f.owner = raiz


func _material_de_imagem(caminho: String, dos_dois_lados: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(caminho)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 1.0
	m.metallic = 0.0
	if dos_dois_lados:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
