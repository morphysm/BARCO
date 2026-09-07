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

## A cruz esta NA CENA, no no `Cruz` — posicao, giro e tamanho arrumam-se
## no editor como qualquer outra peca. Aqui so se diz quanto ela mede.
@export_range(0.1, 2.0) var tamanho_da_cruz := 0.55
## Onde a cruz fica quando esta na mao, relativo a camara.
@export var cruz_na_mao := Vector3(0.26, -0.30, -0.85)

## Ferro enferrujado por cima da fornalha. Desligar mostra os materiais
## que o modelo traz de fabrica.
@export var ferro_enferrujado := true:
	set(valor):
		ferro_enferrujado = valor
		if is_inside_tree():
			_vestir_a_fornalha()
@export_range(0.0, 1.0) var ferrugem := 0.62

## Quanto tempo uma forma leva a sair do fumo, e quanto a seguinte
## espera. Nao saem todas ao mesmo tempo: juntas leem-se como um
## interruptor.
@export_range(0.2, 6.0) var demora_a_surgir := 1.8
@export_range(0.0, 2.0) var espera_entre_formas := 0.35

## As formas dancantes estao NA CENA, em `Dancantes`, uma por figura.
## Cor, brilho, contorno, faisca, bruma, ritmo e tamanho sao `@export` de
## cada uma e veem-se no editor — `FormaDancante` e `@tool`. Aqui nao ha
## nada para regular.

## A musica. A iris so abre quando ela acabar — nao ha duracao escrita a
## mao: troca-se o ficheiro e o compasso vai atras.
@export var musica: AudioStream

## O que se le quando a musica acaba, antes de a iris fechar.
## TODO(CONTENT.pt.md): texto de A.C.
@export var boas_vindas := "Bem-vindo de volta ao lar!"
@export_range(0.5, 10.0) var demora_das_boas_vindas := 4.2
## Quanto tempo a frase leva a ser escrita, letra a letra.
@export_range(0.2, 6.0) var demora_a_escrever := 1.9
## Tamanho da letra das boas-vindas. Grande: quem le esta longe.
@export_range(20, 200) var tamanho_das_boas_vindas := 74
## O cursor que pisca a frente do que ainda nao foi escrito. Vazio tira-o.
@export var cursor := "_"
## Onde a frase assenta, em fraccao da altura do ecra a contar de cima.
@export_range(0.1, 0.95) var altura_das_boas_vindas := 0.62

## Quanto a iris demora a fechar, depois das boas-vindas. Fecha aqui e
## volta a abrir no `assentamento`: a iris atravessa as duas cenas.
@export_range(0.2, 8.0) var fecho_da_iris := 0.8

## O no do modelo que e a boca do forno. A cruz vai para onde ele esta —
## a posicao sai do proprio modelo e nao de um numero escrito a mao, para
## nao se desencontrarem quando a fornalha se mexer na cena.
@export var no_da_boca := "Bay2_MouthInterior"
## Usada so se o no acima nao aparecer.
@export var boca := Vector3(-1.62, 1.30, 0.30)
## A que distancia da MIRA, em pixeis, a boca do forno tem de estar para
## se poder atirar. No ecra e nao em metros: aponta-se com a cabeca.
@export_range(20.0, 400.0) var alcance_da_boca := 190.0
## O mesmo, para apanhar a cruz.
@export_range(20.0, 400.0) var alcance_da_cruz := 260.0
## Ou entao basta estar perto dela, em metros. A mira sozinha era exigente
## de mais: de pe ao lado da cruz, ela cai muito abaixo do centro do ecra
## e nunca entrava no raio.
@export_range(0.3, 4.0) var perto_da_cruz := 1.7

## Quanta luz ha na sala antes de o fogo pegar.
@export_range(0.0, 1.5) var luz_da_sala := 0.62

const COR_TINTA := Color(0.937, 0.925, 0.882)
const COR_BRASA := Color(1.0, 0.42, 0.12)

enum { PERGUNTA, CRUZ_POUSADA, CRUZ_NA_MAO, A_ARDER, A_SAUDAR, A_FECHAR, IDO }

var _fase := PERGUNTA
var _cruz: Node3D
var _fogo: MeshInstance3D
var _formas: Array[FormaDancante] = []
var _esperas: Array[float] = []
var _luz_do_fogo: OmniLight3D
var _tocador: AudioStreamPlayer
var _iris: ColorRect
var _painel: CanvasLayer
var _dito: Label
var _mira: Label
var _saudacao: Label
var _tempo := 0.0
var _crescimento := 0.0
var _tempo_do_fogo := 0.0


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

	# A mira. Sem ela nao se sabe para onde se esta a apontar, e apontar e
	# o unico gesto que ha aqui.
	_mira = Pagina.texto("+", 26)
	_mira.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mira.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mira.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mira.modulate = Color(1, 1, 1, 0.55)
	_mira.visible = false
	_painel.add_child(_mira)

	# As boas-vindas tem rotulo proprio: grande, em baixo, e escritas a
	# tinta de fogo. O `_dito` e letra pequena no alto, boa para uma
	# instrucao e ma para isto.
	_saudacao = Pagina.texto("", tamanho_das_boas_vindas)
	# Letra de maquina: mono, para as letras cairem em coluna como num
	# terminal. A serifa da `Pagina` e para papel impresso, nao para isto.
	var mono := load("res://resources/fonts/DejaVuSansMono-Bold.ttf")
	if mono != null:
		_saudacao.add_theme_font_override("font", mono)
	_saudacao.set_anchors_preset(Control.PRESET_FULL_RECT)
	_saudacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_saudacao.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_saudacao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tinta := ShaderMaterial.new()
	tinta.shader = load("res://shaders/fosforo.gdshader")
	_saudacao.material = tinta
	_saudacao.visible = false
	_painel.add_child(_saudacao)

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
	_dito.text = "W para andar · duplo clique pegue a cruz"
	_por_a_cruz()
	# So agora se anda. Durante a pergunta o rato e para responder, e uma
	# sala que se pode percorrer antes de responder convida a adiar.
	var j := get_node_or_null("Jogador")
	if j != null:
		j.solto = true
		# A cruz fecha o caminho de volta assim que se passa por ela.
		j.set("barreira", _cruz)
	if _mira != null:
		_mira.visible = true


# --- a cruz ------------------------------------------------------------

## Mostrar a cruz que ja esta na cena, e dar-lhe o tamanho pedido.
##
## O no `Cruz` e da cena e nao daqui: posicao e giro arrumam-se no editor.
## O que se faz em codigo e so acender e medir.
func _por_a_cruz() -> void:
	_cruz = get_node_or_null("Cruz")
	if _cruz == null:
		push_warning("nao ha no `Cruz` na cena — nao ha nada para pegar")
		return
	_cruz.visible = true

	var modelo := _cruz.get_node_or_null("Modelo")
	if modelo == null:
		return
	# A caixa MEDE-SE EM MUNDO e nao com `malha.transform`. O transform de
	# um `MeshInstance3D` e so o dele relativo ao pai, e num modelo do
	# Sketchfab a malha esta aninhada sob nos que carregam a escala toda:
	# medir sem eles deu uma cruz de 2617 x 874 x 5500 metros, a volta da
	# camara, e o que se via era nada.
	var caixa := _caixa_em(modelo, _cruz)
	var maior: float = maxf(caixa.size.x, maxf(caixa.size.y, caixa.size.z))
	if maior > 0.0:
		var factor := tamanho_da_cruz / maior
		modelo.scale *= factor
		modelo.position -= caixa.get_center() * factor


## Caixa envolvente de `no`, no espaco de `referencia`. Em mundo e depois
## trazida para o referencial pedido — nunca com transforms locais.
func _caixa_em(no: Node3D, referencia: Node3D) -> AABB:
	var para_dentro := referencia.global_transform.affine_inverse()
	var total := AABB()
	var primeiro := true
	for malha in _malhas(no):
		if malha.mesh == null or not malha.is_inside_tree():
			continue
		var c: AABB = (para_dentro * malha.global_transform) * malha.mesh.get_aabb()
		total = c if primeiro else total.merge(c)
		primeiro = false
	return total


## Aponta-se com o PONTEIRO quando se esta parado, e com a mira quando se
## anda. Duplo clique na cruz pega nela; duplo clique no forno atira-a la
## para dentro.
func _input(evento: InputEvent) -> void:
	if Engine.is_editor_hint() or _fase == PERGUNTA or _fase >= A_ARDER:
		return
	if not (evento is InputEventMouseButton):
		return
	var e := evento as InputEventMouseButton
	if not e.pressed or e.button_index != MOUSE_BUTTON_LEFT:
		return
	# Depois de largar o rato com ESC, o primeiro clique so o volta a
	# prender — nao age no mundo.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if not e.double_click:
		return

	# Aponta-se com a MIRA: o rato esta preso a olhar em volta, entao o
	# ponteiro nao existe.
	var onde: Vector2 = get_viewport().get_visible_rect().size * 0.5

	if _fase == CRUZ_POUSADA:
		# Na mira OU ao alcance do braco. So a mira nao chegava: anda-se
		# em frente, passa-se a cruz, e ela fica ATRAS — e o que esta
		# atras nunca entra na mira.
		var cam := get_viewport().get_camera_3d()
		var encostado: bool = (cam != null
			and cam.global_position.distance_to(_cruz.global_position) <= perto_da_cruz)
		if encostado or _perto_no_ecra(_cruz.global_position, onde, alcance_da_cruz):
			_pegar_a_cruz()
	elif _fase == CRUZ_NA_MAO:
		if _perto_no_ecra(boca, onde, alcance_da_boca):
			_atirar()
		else:
			# TODO(CONTENT.pt.md): texto autoral. Este e estrutural.
			_dito.text = "duplo clique no forno"


## Este ponto do mundo esta a menos de `raio` pixeis de `onde`?
func _perto_no_ecra(mundo: Vector3, onde: Vector2, raio: float) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam.is_position_behind(mundo):
		return false
	return cam.unproject_position(mundo).distance_to(onde) <= raio


## A cruz passa para a mao: fica agarrada a camara e vai com quem anda.
func _pegar_a_cruz() -> void:
	_fase = CRUZ_NA_MAO
	# A cruz deixa de ser barreira: na mao anda connosco, e uma barreira
	# que anda connosco prendia-nos no sitio. O recuo ja apertado fica.
	var j := get_node_or_null("Jogador")
	if j != null:
		j.set("barreira", null)
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_cruz.reparent(cam, true)
		_cruz.position = cruz_na_mao
		_cruz.rotation = Vector3(0, 0, 0)
	# TODO(CONTENT.pt.md): texto autoral. Este e estrutural.
	_dito.text = "duplo clique atire no fogo"


# --- o fogo ------------------------------------------------------------

func _atirar() -> void:
	_fase = A_ARDER
	# Marca-se ao ATIRAR e nao no fim: quem fechar o app a meio do fogo
	# ja queimou o que tinha a queimar, e nao volta a ser perguntado.
	Passagem.queimar()
	_cruz.queue_free()
	_cruz = null
	_dito.text = ""
	if _mira != null:
		_mira.visible = false

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

	# O sopro do forno: arrasta para tras e tranca o andar.
	var j := get_node_or_null("Jogador")
	if j != null:
		j.call("soprar")

	if musica != null:
		_tocador = AudioStreamPlayer.new()
		_tocador.stream = musica
		add_child(_tocador)
		_tocador.finished.connect(_musica_acabou)
		_tocador.play()
	else:
		# Sem musica nao se fica preso: espera-se um pouco e segue.
		get_tree().create_timer(6.0).timeout.connect(_musica_acabou)


## As formas ja estao na cena, em `Dancantes`. Aqui so se lhes da vida.
##
## So aparecem com o fogo, e uma de cada vez: cada uma tem a sua espera,
## para nao acenderem todas juntas como um interruptor.
func _por_as_formas() -> void:
	var grupo := get_node_or_null("Dancantes")
	if grupo == null:
		return
	var i := 0
	for f in grupo.get_children():
		if f is FormaDancante:
			_formas.append(f)
			_esperas.append(float(i) * espera_entre_formas)
			i += 1


func _musica_acabou() -> void:
	if _fase != A_ARDER:
		return
	_fase = A_SAUDAR
	_tempo = 0.0
	_dito.text = ""
	var alto := get_viewport().get_visible_rect().size.y
	_saudacao.offset_top = alto * altura_das_boas_vindas
	_saudacao.text = ""
	_saudacao.visible = true


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_tempo += delta

	if _fase == CRUZ_NA_MAO and _cruz != null:
		# Vai agarrada a camara: anda com quem a leva. So se mexe um
		# pouco, para nao parecer colada ao ecra.
		_cruz.rotation.z = sin(_tempo * 2.4) * 0.05
		_cruz.position = cruz_na_mao + Vector3(0, sin(_tempo * 1.7) * 0.012, 0)

	if _fase >= A_ARDER:
		_tempo_do_fogo += delta
	if _fase >= A_ARDER and _fogo != null:
		# A bola cresce depressa no principio e depois assenta.
		_crescimento = minf(_crescimento + delta * 0.5, 1.0)
		var r: float = 0.25 + 1.15 * sqrt(_crescimento)
		var pulsar := 1.0 + 0.045 * sin(_tempo * 7.3) + 0.03 * sin(_tempo * 13.1)
		_fogo.scale = Vector3(r * pulsar, r * 1.25 * pulsar, r * pulsar)
		_fogo.material_override.set_shader_parameter("crescimento", _crescimento)
		_luz_do_fogo.light_energy = 6.5 * _crescimento * pulsar
		# As formas entram com o fogo, nao antes: primeiro o fumo, depois
		# elas por dentro dele.
		for i in _formas.size():
			var desde: float = _tempo_do_fogo - _esperas[i]
			_formas[i].surgir = clampf(desde / maxf(demora_a_surgir, 0.001), 0.0, 1.0)
			_formas[i].vigor = _formas[i].surgir

	if _fase == A_SAUDAR and _saudacao != null:
		# Letra a letra. Corta-se o TEXTO e nao o `visible_ratio`: assim o
		# cursor anda com a ultima letra escrita, como num terminal, em vez
		# de ficar parado no fim da frase inteira.
		var quantas := int(boas_vindas.length() * clampf(
			_tempo / maxf(demora_a_escrever, 0.001), 0.0, 1.0))
		var pisca: bool = fmod(_tempo, 0.9) < 0.55
		_saudacao.text = boas_vindas.substr(0, quantas) + (cursor if pisca else "")

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
