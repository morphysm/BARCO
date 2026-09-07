@tool
## A sala de blasfemia: onde se queima o passado (SPEC.md §1.1, fase 2).
##
## Depois do sol negro chega-se aqui. Uma imagem de Baphomet ao fundo, o
## sigilo morfista no chao, e a fornalha — um forno so, copiado sem
## alteracao da bancada do `Iovana Is DEAD` (ver
## `tools/tirar_fornalha.py`).
##
## Faz-se a pergunta. Quem diz SIM recebe uma cruz: duplo clique para a
## pegar, leva-se ate a boca do forno, outro duplo clique para a atirar
## la para dentro. Cresce uma bola de fogo, entra a musica, e quando a
## musica acaba abre-se uma iris para o `assentamento`.
##
## Nao ha "nao". A pergunta e uma so vez e a resposta e um so caminho —
## como o resto do app, o que se faz aqui nao se desfaz.
extends Node3D

## O que se pergunta. TODO(CONTENT.pt.md): texto de A.C.
@export_multiline var pergunta := "Você renega o teu passado\ne tudo falso que você serviu?"
@export var rotulo_sim := "SIM"

## A imagem ao fundo. Fica vazia ate A.C. dar a dele; sem imagem nao se
## desenha nada e a sala funciona na mesma.
##
## Poe-se o PNG em `resources/imagens/`, importa-se, e escolhe-se aqui no
## inspetor de `scenes/fornalha.tscn`.
@export var baphomet: Texture2D:
	set(valor):
		baphomet = valor
		if is_inside_tree():
			_montar_baphomet()
@export_range(0.5, 6.0) var altura_do_baphomet := 2.6
## A que altura ela fica, a contar do chao — por cima da fornalha.
@export var lugar_do_baphomet := Vector3(-1.5, 4.5, 0.15)

## O sigilo no chao.
@export var sigilo: Texture2D
@export_range(0.5, 6.0) var largura_do_sigilo := 1.8

## A musica. A iris so abre quando ela acabar — nao ha duracao escrita a
## mao: troca-se o ficheiro e o compasso vai atras.
@export var musica: AudioStream

## Quanto a iris demora a fechar, depois de a musica acabar. Fecha aqui e
## volta a abrir no `assentamento`: a iris atravessa as duas cenas.
@export_range(0.5, 8.0) var fecho_da_iris := 3.2

## O no do modelo que e a boca do forno. A cruz vai para onde ele esta —
## a posicao sai do proprio modelo e nao de um numero escrito a mao, para
## nao se desencontrarem quando a fornalha se mexer na cena.
@export var no_da_boca := "Bay2_MouthInterior"
## Usada so se o no acima nao aparecer.
@export var boca := Vector3(-1.62, 1.30, 0.30)
## A que distancia da boca, EM PIXEIS NO ECRA, a cruz pode ser atirada.
##
## No ecra e nao no mundo: a cruz arrasta-se num plano de frente para a
## camara, entao nunca fica a mesma profundidade da boca. Medir em metros
## dava uma boca onde a cruz nunca chegava, por muito que se a arrastasse
## para cima dela.
@export_range(20.0, 400.0) var alcance_da_boca := 130.0

## Quanta luz ha na sala antes de o fogo pegar.
@export_range(0.0, 1.0) var luz_da_sala := 0.32

const COR_TINTA := Color(0.937, 0.925, 0.882)
const COR_BRASA := Color(1.0, 0.42, 0.12)

enum { PERGUNTA, CRUZ_POUSADA, CRUZ_NA_MAO, A_ARDER, A_FECHAR, IDO }

var _fase := PERGUNTA
var _cruz: Node3D
var _fogo: MeshInstance3D
var _luz_do_fogo: OmniLight3D
var _tocador: AudioStreamPlayer
var _iris: ColorRect
var _painel: CanvasLayer
var _dito: Label
var _tempo := 0.0
var _crescimento := 0.0


func _ready() -> void:
	_achar_boca()
	_montar_luz()
	_montar_baphomet()
	_montar_brasa()
	if not Engine.is_editor_hint():
		_montar_painel()
	set_process(true)


# --- a sala ------------------------------------------------------------

## Onde a boca do forno esta de verdade, medida no modelo.
func _achar_boca() -> void:
	var no := _por_nome(self, no_da_boca)
	if no == null:
		push_warning("nao encontrei o no '%s' — a usar a posicao escrita a mao" % no_da_boca)
		return
	var caixa := AABB()
	var primeiro := true
	var pilha: Array = [no]
	while pilha:
		var x = pilha.pop_back()
		if x is MeshInstance3D and x.mesh != null:
			var c: AABB = (x as MeshInstance3D).global_transform * x.mesh.get_aabb()
			caixa = c if primeiro else caixa.merge(c)
			primeiro = false
		for y in x.get_children():
			pilha.append(y)
	if not primeiro:
		boca = caixa.get_center()


func _por_nome(raiz: Node, nome: String) -> Node3D:
	if raiz.name == nome and raiz is Node3D:
		return raiz
	for f in raiz.get_children():
		var achado := _por_nome(f, nome)
		if achado != null:
			return achado
	return null



## Luz de sala escura.
##
## Escura, nao apagada: antes de o fogo pegar tem de se ver a fornalha, o
## sigilo no chao e a imagem ao fundo, senao o ecra preto le-se como
## avaria e ninguem sabe onde carregar. Depois, o fogo e que manda.
func _montar_luz() -> void:
	if get_node_or_null("Ambiente") != null:
		return
	var amb := WorldEnvironment.new()
	amb.name = "Ambiente"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var f: float = luz_da_sala if not Engine.is_editor_hint() else 0.5
	env.ambient_light_color = Color(f, f * 0.9, f * 0.82)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 3.0
	amb.environment = env
	add_child(amb)


## A imagem ao fundo, por cima da fornalha. Sem textura nao se desenha
## nada: um retangulo vazio a espera de uma imagem le-se como um erro.
func _montar_baphomet() -> void:
	var ja := get_node_or_null("Baphomet")
	if baphomet == null:
		if ja != null:
			ja.queue_free()
		return
	var no: MeshInstance3D = ja if ja is MeshInstance3D else MeshInstance3D.new()
	no.name = "Baphomet"
	var quad := QuadMesh.new()
	var proporcao := float(baphomet.get_width()) / maxf(float(baphomet.get_height()), 1.0)
	quad.size = Vector2(altura_do_baphomet * proporcao, altura_do_baphomet)
	var m := StandardMaterial3D.new()
	m.albedo_texture = baphomet
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	quad.material = m
	no.mesh = quad
	no.position = lugar_do_baphomet
	if ja == null:
		add_child(no)


## A brasa que ja la esta. O forno nao se acende: esta aceso, e e por
## isso que se atira la para dentro. Tambem e a unica luz que chega ao
## chao antes do fogo — sem ela nao se via o sigilo.
func _montar_brasa() -> void:
	if get_node_or_null("Brasa") != null:
		return
	var l := OmniLight3D.new()
	l.name = "Brasa"
	l.light_color = COR_BRASA
	l.omni_range = 7.5
	l.omni_attenuation = 1.3
	l.light_energy = 1.35
	l.position = boca
	add_child(l)


# --- a pergunta --------------------------------------------------------

func _montar_painel() -> void:
	_painel = CanvasLayer.new()
	_painel.name = "Painel"
	add_child(_painel)

	_dito = Pagina.texto(pergunta, 30)
	_dito.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_dito.offset_top = 96
	_dito.offset_left = 40
	_dito.offset_right = -40
	_dito.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_painel.add_child(_dito)

	# Um botao so. Nao ha "nao": quem chegou aqui riscou os tres `pontos`
	# e atravessou o eclipse, e o app nao pergunta duas vezes.
	var sim := Pagina.botao(rotulo_sim, 26)
	sim.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sim.offset_top = -180
	sim.offset_bottom = -120
	sim.offset_left = -70
	sim.offset_right = 70
	sim.pressed.connect(_responder_sim)
	sim.name = "Sim"
	_painel.add_child(sim)

	_iris = ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/iris.gdshader")
	m.set_shader_parameter("abertura", 1.0)
	_iris.material = m
	_iris.set_anchors_preset(Control.PRESET_FULL_RECT)
	_iris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_iris.visible = false
	_painel.add_child(_iris)


func _responder_sim() -> void:
	if _fase != PERGUNTA:
		return
	_fase = CRUZ_POUSADA
	_painel.get_node("Sim").queue_free()
	# TODO(CONTENT.pt.md): texto de A.C. Este e estrutural.
	_dito.text = "duplo clique na cruz"
	_por_a_cruz()


# --- a cruz ------------------------------------------------------------

## Duas travessas de madeira, postas a frente de quem olha. Nao ha modelo
## de cruz no projeto e nao vou inventar um: isto e um lugar guardado, e
## troca-se por um `.glb` quando houver.
func _por_a_cruz() -> void:
	_cruz = Node3D.new()
	_cruz.name = "Cruz"
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color(0.20, 0.14, 0.10)
	madeira.roughness = 1.0
	for medida in [Vector3(0.055, 0.62, 0.045), Vector3(0.34, 0.055, 0.045)]:
		var b := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = medida
		caixa.material = madeira
		b.mesh = caixa
		if medida.x > medida.y:
			b.position.y = 0.12
		_cruz.add_child(b)
	# Na arvore primeiro: `global_position` num no solto nao vale nada, e
	# a cruz caía na origem da cena.
	add_child(_cruz)
	# A frente da pessoa, e nao num sitio escrito a mao: onde a camara
	# estiver, a cruz aparece a sua frente.
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_cruz.global_position = (cam.global_position
			- cam.global_transform.basis.z * 1.7
			- cam.global_transform.basis.y * 0.42)
	else:
		_cruz.position = Vector3(0.0, 0.55, 1.05)


func _input(evento: InputEvent) -> void:
	if Engine.is_editor_hint() or _fase == PERGUNTA or _fase >= A_ARDER:
		return
	if not (evento is InputEventMouseButton):
		return
	var e := evento as InputEventMouseButton
	if not (e.double_click and e.button_index == MOUSE_BUTTON_LEFT):
		return
	if _fase == CRUZ_POUSADA:
		if _sob_o_rato(e.position):
			_fase = CRUZ_NA_MAO
			# TODO(CONTENT.pt.md): texto de A.C.
			_dito.text = "leva a cruz à boca do forno e larga-a lá"
	elif _fase == CRUZ_NA_MAO:
		if _no_ecra(_cruz.global_position).distance_to(_no_ecra(boca)) <= alcance_da_boca:
			_atirar()
		else:
			# TODO(CONTENT.pt.md): texto de A.C.
			_dito.text = "em cima da boca do forno"


## A cruz esta debaixo do rato? Sem corpos de colisao: mede-se no ecra, e
## chega para um objeto so.
func _sob_o_rato(onde: Vector2) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _cruz == null:
		return false
	return cam.unproject_position(_cruz.global_position).distance_to(onde) < 90.0


## Onde o rato aponta, num plano de frente para a camara e a profundidade
## a que a cruz ja esta. A cruz anda pelo ecra, nao pelo chao.
func _no_plano(ecra: Vector2) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _cruz == null:
		return Vector3.ZERO
	var frente := -cam.global_transform.basis.z
	var plano := Plane(frente, _cruz.global_position.dot(frente))
	var p = plano.intersects_ray(cam.project_ray_origin(ecra), cam.project_ray_normal(ecra))
	return p if p != null else _cruz.global_position


func _no_ecra(mundo: Vector3) -> Vector2:
	var cam := get_viewport().get_camera_3d()
	return cam.unproject_position(mundo) if cam != null else Vector2.ZERO


# --- o fogo ------------------------------------------------------------

func _atirar() -> void:
	_fase = A_ARDER
	# Marca-se ao ATIRAR e nao no fim: quem fechar o app a meio do fogo
	# ja queimou o que tinha a queimar, e nao volta a ser perguntado.
	Passagem.queimar()
	_cruz.queue_free()
	_cruz = null
	_dito.text = ""

	_fogo = MeshInstance3D.new()
	_fogo.name = "Fogo"
	var bola := SphereMesh.new()
	bola.radius = 1.0
	bola.height = 2.0
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = COR_BRASA
	bola.material = m
	_fogo.mesh = bola
	_fogo.position = boca
	_fogo.scale = Vector3.ONE * 0.01
	add_child(_fogo)

	_luz_do_fogo = OmniLight3D.new()
	_luz_do_fogo.light_color = COR_BRASA
	_luz_do_fogo.omni_range = 6.0
	_luz_do_fogo.omni_attenuation = 1.6
	_luz_do_fogo.light_energy = 0.0
	_luz_do_fogo.position = boca
	add_child(_luz_do_fogo)

	if musica != null:
		_tocador = AudioStreamPlayer.new()
		_tocador.stream = musica
		add_child(_tocador)
		_tocador.finished.connect(_musica_acabou)
		_tocador.play()
	else:
		# Sem musica nao se fica preso: espera-se um pouco e abre.
		get_tree().create_timer(6.0).timeout.connect(_musica_acabou)


func _musica_acabou() -> void:
	if _fase != A_ARDER:
		return
	_fase = A_FECHAR
	_tempo = 0.0
	_iris.visible = true
	_iris.material.set_shader_parameter("abertura", 1.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_tempo += delta

	if _fase == CRUZ_NA_MAO and _cruz != null:
		_cruz.global_position = _no_plano(get_viewport().get_mouse_position())
		# Perto do forno a cruz avisa que ja chega, sem uma palavra.
		var perto: float = clampf(1.0 - _no_ecra(_cruz.global_position).distance_to(
			_no_ecra(boca)) / alcance_da_boca, 0.0, 1.0)
		_cruz.rotation.z = sin(_tempo * 6.0) * 0.05 * perto

	if _fase == A_ARDER and _fogo != null:
		# A bola cresce depressa no principio e depois assenta.
		_crescimento = minf(_crescimento + delta * 0.55, 1.0)
		var r: float = 0.05 + 0.62 * sqrt(_crescimento)
		var pulsar := 1.0 + 0.05 * sin(_tempo * 7.3) + 0.03 * sin(_tempo * 13.1)
		_fogo.scale = Vector3.ONE * r * pulsar
		_luz_do_fogo.light_energy = 5.5 * _crescimento * pulsar

	if _fase == A_FECHAR:
		var a: float = clampf(_tempo / maxf(fecho_da_iris, 0.001), 0.0, 1.0)
		var v := get_viewport().get_visible_rect().size
		_iris.material.set_shader_parameter("proporcao", v.x / maxf(v.y, 1.0))
		_iris.material.set_shader_parameter("abertura", 1.0 - a)
		if a >= 1.0:
			_fase = IDO
			# A iris fecha aqui e abre la: e a mesma iris, nao duas.
			Passagem.iris_a_abrir = true
			get_tree().change_scene_to_file("res://scenes/assentamento.tscn")
