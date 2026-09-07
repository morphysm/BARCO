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
@export var rotulo_nao := "NÃO"

## A cruz que se queima. Modelo de A.C.
@export var cruz: PackedScene
@export_range(0.1, 2.0) var tamanho_da_cruz := 0.55

## Ferro enferrujado por cima da fornalha. Desligar mostra os materiais
## que o modelo traz de fabrica.
@export var ferro_enferrujado := true:
	set(valor):
		ferro_enferrujado = valor
		if is_inside_tree():
			_vestir_a_fornalha()
@export_range(0.0, 1.0) var ferrugem := 0.62

## Quantas formas dancam. Os LUGARES estao na cena, em `Dancantes` — sao
## marcas que se arrastam no editor. Isto so diz quantas se usam.
@export_range(0, 12) var quantas_formas := 6
@export var cor_das_formas := Color(0.18, 0.05, 0.04, 0.86)

## A musica. A iris so abre quando ela acabar — nao ha duracao escrita a
## mao: troca-se o ficheiro e o compasso vai atras.
@export var musica: AudioStream

## O que se le quando a musica acaba, antes de a iris fechar.
## TODO(CONTENT.pt.md): texto de A.C.
@export var boas_vindas := "Bem-vindo de volta ao lar!"
@export_range(0.5, 8.0) var demora_das_boas_vindas := 3.4

## Quanto a iris demora a fechar, depois das boas-vindas. Fecha aqui e
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
@export_range(0.0, 1.5) var luz_da_sala := 0.62

const COR_TINTA := Color(0.937, 0.925, 0.882)
const COR_BRASA := Color(1.0, 0.42, 0.12)

enum { PERGUNTA, CRUZ_POUSADA, CRUZ_NA_MAO, A_ARDER, A_SAUDAR, A_FECHAR, IDO }

var _fase := PERGUNTA
var _cruz: Node3D
var _fogo: MeshInstance3D
var _formas: Array[FormaDancante] = []
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
	_vestir_a_fornalha()
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


## Ferro enferrujado por cima de tudo o que a fornalha traz.
##
## Percorre-se e poe-se `material_override`: o modelo e uma sub-cena
## instanciada e nao se lhe mexe nos materiais a partir da cena de fora.
func _vestir_a_fornalha() -> void:
	var f := get_node_or_null("fornalha")
	if f == null:
		return
	var m: ShaderMaterial = null
	if ferro_enferrujado:
		m = ShaderMaterial.new()
		m.shader = load("res://shaders/ferro.gdshader")
		m.set_shader_parameter("ferrugem", ferrugem)
	for malha in _malhas(f):
		malha.material_override = m


func _malhas(raiz: Node) -> Array[MeshInstance3D]:
	var saida: Array[MeshInstance3D] = []
	if raiz is MeshInstance3D:
		saida.append(raiz)
	for filho in raiz.get_children():
		saida.append_array(_malhas(filho))
	return saida


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

	# Duas respostas, e as duas valem. Quem diz NAO nao fica preso num
	# quarto que nao quer: o app fecha-se.
	var respostas := HBoxContainer.new()
	respostas.name = "Respostas"
	respostas.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	respostas.offset_top = -180
	respostas.offset_bottom = -120
	respostas.offset_left = -150
	respostas.offset_right = 150
	respostas.alignment = BoxContainer.ALIGNMENT_CENTER
	respostas.add_theme_constant_override("separation", 40)
	_painel.add_child(respostas)

	var sim := Pagina.botao(rotulo_sim, 26)
	sim.pressed.connect(_responder_sim)
	sim.name = "Sim"
	respostas.add_child(sim)

	var nao := Pagina.botao(rotulo_nao, 26)
	nao.pressed.connect(_responder_nao)
	nao.name = "Nao"
	respostas.add_child(nao)

	_iris = ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/iris.gdshader")
	m.set_shader_parameter("abertura", 1.0)
	_iris.material = m
	_iris.set_anchors_preset(Control.PRESET_FULL_RECT)
	_iris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_iris.visible = false
	_painel.add_child(_iris)


## Quem diz NAO sai. Nao ha ecra de despedida e nao ha volta atras dentro
## da mesma sessao: a pergunta e a serio, e uma recusa e uma recusa.
func _responder_nao() -> void:
	if _fase != PERGUNTA:
		return
	get_tree().quit()


func _responder_sim() -> void:
	if _fase != PERGUNTA:
		return
	_fase = CRUZ_POUSADA
	_painel.get_node("Respostas").queue_free()
	# TODO(CONTENT.pt.md): texto de A.C. Este e estrutural.
	_dito.text = "duplo clique na cruz"
	_por_a_cruz()


# --- a cruz ------------------------------------------------------------

## A cruz de A.C., posta a frente de quem olha.
func _por_a_cruz() -> void:
	_cruz = Node3D.new()
	_cruz.name = "Cruz"
	add_child(_cruz)

	if cruz != null:
		var modelo: Node3D = cruz.instantiate()
		_cruz.add_child(modelo)
		# Pelo maior lado, para uma cruz achatada nao sair gigante.
		var c := _caixa(modelo)
		var maior: float = maxf(c.size.x, maxf(c.size.y, c.size.z))
		if maior > 0.0:
			modelo.scale = Vector3.ONE * (tamanho_da_cruz / maior)
			modelo.position = -c.get_center() * modelo.scale.x
	else:
		push_warning("sem modelo de cruz — nada para pegar")

	# A frente da pessoa, e nao num sitio escrito a mao: onde a camara
	# estiver, a cruz aparece a sua frente.
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_cruz.global_position = (cam.global_position
			- cam.global_transform.basis.z * 1.7
			- cam.global_transform.basis.y * 0.42)
	else:
		_cruz.position = Vector3(0.0, 0.55, 1.05)


func _caixa(no: Node3D) -> AABB:
	var total := AABB()
	var primeiro := true
	for malha in _malhas(no):
		if malha.mesh == null:
			continue
		var c: AABB = malha.transform * malha.mesh.get_aabb()
		total = c if primeiro else total.merge(c)
		primeiro = false
	return total


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

	# Num quad virado a camara, nao numa esfera: ver `fogo.gdshader`.
	_fogo = MeshInstance3D.new()
	_fogo.name = "Fogo"
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.35)
	_fogo.mesh = q
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/fogo.gdshader")
	m.set_shader_parameter("crescimento", 0.0)
	_fogo.material_override = m
	_fogo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fogo)
	_fogo.global_position = boca
	_fogo.scale = Vector3.ONE * 0.05

	_luz_do_fogo = OmniLight3D.new()
	_luz_do_fogo.light_color = COR_BRASA
	_luz_do_fogo.omni_range = 9.0
	_luz_do_fogo.omni_attenuation = 1.4
	_luz_do_fogo.light_energy = 0.0
	add_child(_luz_do_fogo)
	_luz_do_fogo.global_position = boca + Vector3(0, 0.2, 0.5)

	_por_as_formas()

	if musica != null:
		_tocador = AudioStreamPlayer.new()
		_tocador.stream = musica
		add_child(_tocador)
		_tocador.finished.connect(_musica_acabou)
		_tocador.play()
	else:
		# Sem musica nao se fica preso: espera-se um pouco e segue.
		get_tree().create_timer(6.0).timeout.connect(_musica_acabou)


## As formas so aparecem com o fogo. Os lugares estao na cena, em
## `Dancantes` — marcas que se arrastam no editor.
func _por_as_formas() -> void:
	var lugares := get_node_or_null("Dancantes")
	if lugares == null:
		return
	var i := 0
	for marca in lugares.get_children():
		if i >= quantas_formas or not marca is Node3D:
			break
		var f := FormaDancante.new()
		f.name = "Forma%d" % (i + 1)
		# §16: cada figura recebe valores diferentes. Nao se sincronizam.
		f.semente = float(i) * 2.7 + 0.83
		f.ritmo = 0.72 + fmod(float(i) * 0.37, 0.55)
		f.tamanho = 0.92 + fmod(float(i) * 0.23, 0.26)
		f.espelhar = (i % 2) == 1
		f.eco = 0.022 + fmod(float(i) * 0.011, 0.02)
		f.cor = cor_das_formas
		add_child(f)
		f.global_transform = (marca as Node3D).global_transform
		_formas.append(f)
		i += 1


func _musica_acabou() -> void:
	if _fase != A_ARDER:
		return
	_fase = A_SAUDAR
	_tempo = 0.0
	_dito.text = boas_vindas


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_tempo += delta

	if _fase == CRUZ_NA_MAO and _cruz != null:
		_cruz.global_position = _no_plano(get_viewport().get_mouse_position())
		# Perto do forno a cruz avisa que ja chega, sem uma palavra.
		var perto: float = clampf(1.0 - _no_ecra(_cruz.global_position).distance_to(
			_no_ecra(boca)) / alcance_da_boca, 0.0, 1.0)
		_cruz.rotation.z = sin(_tempo * 6.0) * 0.06 * perto

	if _fase >= A_ARDER and _fogo != null:
		# A bola cresce depressa no principio e depois assenta.
		_crescimento = minf(_crescimento + delta * 0.5, 1.0)
		var r: float = 0.25 + 1.15 * sqrt(_crescimento)
		var pulsar := 1.0 + 0.045 * sin(_tempo * 7.3) + 0.03 * sin(_tempo * 13.1)
		_fogo.scale = Vector3(r * pulsar, r * 1.25 * pulsar, r * pulsar)
		_fogo.material_override.set_shader_parameter("crescimento", _crescimento)
		_luz_do_fogo.light_energy = 6.5 * _crescimento * pulsar
		# As formas entram com o fogo, nao antes.
		for f in _formas:
			f.vigor = _crescimento

	if _fase == A_SAUDAR and _tempo >= demora_das_boas_vindas:
		_fase = A_FECHAR
		_tempo = 0.0
		_iris.visible = true
		_iris.material.set_shader_parameter("abertura", 1.0)

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
