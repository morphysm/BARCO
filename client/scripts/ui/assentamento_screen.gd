@tool
## O `assentamento`. GLOSSARY.md, GDD §8, SPEC.md §8.1.
##
## Nao e um quarto iluminado. E um plano escuro visto de um so ponto, sem
## paredes e sem camara que gire — uma chapa, nao um mundo. SPEC.md §11:
## a presenca indica-se por `ponto`, luz, fumo e movimento de objeto.
##
## A cena tem so o FUNDAMENTO: o caldeirao e o que faz este `assentamento`
## ser o daquela entidade. Tudo o resto chega por `depor()` — porque
## alguem o depos, na posicao que escolheu (SPEC.md §8.1, GDD §8).
##
## Depor e irreversivel. Nao ha aqui como tirar nada: `depositos` e
## append-only, como o `caderno` (SPEC.md §3.3, GDD §2).
##
## As velas sao luz a serio — OmniLight3D, uma por vela. Nao ha luz
## nenhuma alem delas: acender e o que revela o `assentamento`, e quando a
## ultima se apagar fica tudo escuro.
##
## O arranjo esta na cena, nao aqui. Para mudar onde uma peca fica, abre-se
## `scenes/assentamento.tscn` e arrasta-se — e por isso que o script e
## `@tool`: a gravura e as chamas desenham-se no editor, para se ver o que
## se esta a fazer enquanto se faz.
##
## Cada peca do grupo "vela" e uma luz. Acrescentar uma vela e instanciar
## o modelo e po-lo no grupo; o script encontra-a sozinho.
extends Node3D

const COR_TINTA := Color(0.937, 0.925, 0.882)

## Cor do chao. Sem material o plano fica branco por omissao, e um branco
## de tres metros de lado devolve toda a luz das velas — foi assim que a
## nganga ficou a flutuar num lencol aceso.
@export var cor_do_chao := Color(0.06, 0.055, 0.05)

## Quanto o chao responde a luz, comparado com os objetos. Menos que eles:
## e uma extensao grande e de frente para as chamas, e com a mesma
## resposta ofusca a nganga que devia estar a mostrar.
@export_range(0.0, 1.0) var resposta_do_chao := 0.42

## Brilho de cada chama.
@export_range(0.0, 2.0) var brilho_da_vela := 0.55

## Ate onde a chama de uma vela chega. Curto de mais e cada objeto cai
## abaixo do primeiro sulco da trama e vira silhueta preta — foi assim
## que a nganga ficou ilegivel.
@export_range(0.05, 1.0) var alcance_da_vela := 0.30

## Distancia entre os sulcos da gravura. Maior = trama mais fina.
@export_range(0.03, 0.40) var trama := 0.15

## Ruido por cima da trama. Pouco: em cima da hachura le-se como
## sujidade, nao como grao de papel.
@export_range(0.0, 1.0) var grao := 0.12

## Angulo da trama do chao, em graus, contra a dos objetos. Se forem
## iguais, uma peca pousada no chao nao tem aresta que a separe dele.
##
## Angulos muito longe de zero fazem a trama bater com a grelha de pixeis
## e adensar — a trama e presa ao pixel, e isso ainda esta por resolver.
@export_range(0.0, 90.0) var angulo_do_chao := 22.0

## Trama do chao contra a dos objetos. Mais larga no chao: a diferenca de
## calibre separa tanto como a de angulo, e sem bater na grelha de pixeis.
@export_range(0.2, 1.5) var calibre_do_chao := 0.55

## Contorno nas pecas: numa gravura e o contorno que separa as coisas.
@export_range(0.0, 1.0) var contorno := 0.85

## Desliga a gravura e mostra os modelos como o Godot os mostraria — cinza
## liso, iluminado pelo ambiente do editor. Nao e como o app fica: e para
## se arrumar a nganga a ver as formas, e so depois voltar a ligar.
##
## Fora do editor nao ha ambiente nem luz de motor nenhuma, entao com isto
## desligado a cena corre preta. E um auxiliar de bancada, nao um modo.
@export var mostrar_gravura := false:
	set(valor):
		mostrar_gravura = valor
		if is_inside_tree():
			_vestir()

## Cor da chama. Cera a arder e alaranjada, nao branca.
@export var cor_da_chama := Color(1.0, 0.72, 0.42)

## Quao depressa a luz cai. Uma vela cai depressa: com queda lenta o chao
## inteiro acende e a escuridao desaparece.
@export_range(0.5, 8.0) var queda_da_luz := 3.0

## Ate onde a luz de uma vela chega, em metros.
@export_range(0.1, 3.0) var alcance_da_luz := 0.5

## Forca de cada vela.
@export_range(0.0, 8.0) var forca_da_luz := 0.26

## Luz de reserva no app, para um `assentamento` sem vela nenhuma nao ser
## um ecra preto. Visitar e sempre gratis (SPEC.md §10.1), entao tem de se
## poder ver que la esta alguma coisa — mal, mas ver.
@export_range(0.0, 0.5) var luz_de_reserva := 0.16

## Luz no EDITOR. Nada a ver com a do app: aqui e uma bancada, e uma
## bancada as escuras nao serve para arrumar coisa nenhuma. So o app fica
## no escuro a espera de que se acenda uma vela.
@export_range(0.0, 2.0) var luz_de_bancada := 0.75

## Desliga o bruxuleio. Ligado por omissao fora do editor; no editor a luz
## fica quieta, para nao pulsar enquanto se arruma a nganga.
@export var bruxulear := true

var _gravura: Shader
var _luzes: Array[Vector3] = []
var _chamas: Array[MeshInstance3D] = []
var _lampadas: Array[OmniLight3D] = []
## O que ja foi deposto. Cresce; nunca encolhe.
var _depositos: Array[Dictionary] = []
var _velas: Array[Node3D] = []

## Pedidos a arder no caldeirao. As palavras ficam no aparelho e mais
## lado nenhum (ver Pedido).
var _pedidos: Array[Pedido] = []
var _papeis: Array[Papel] = []
var _menu: CanvasLayer
var _escrita: TextEdit
var _lista: Label
var _folhas: HBoxContainer
## As folhas desenhadas no menu, para se irem queimando enquanto o menu
## esta aberto em vez de ficarem paradas no instante em que abriu.
var _folhas_vivas: Array[Dictionary] = []

## Quantos dias um `pedido` leva a arder. Sete e o que vale (SPEC.md §8.1);
## baixar isto e so para ver a queima sem esperar uma semana.
@export var dias_de_queima := 7.0

## Nome do no em que os pedidos se espetam. Como na tradicao: o papel vai
## na lanca, nao pousado no fundo da panela.
##
## O tridente e LIDO, nunca movido: e fundamento travado. Se ele mudar de
## sitio, os papeis acompanham-no sozinhos.
const LANCA := "tridente"

## O gesto de depor (GDD §5.2, SPEC.md §8.1): pega-se numa `oferenda` na
## tira de baixo e arrasta-se ate ao sitio. O que se arrasta ja e o proprio
## objeto, nao uma pre-visualizacao — larga-se e fica.
var _na_mao: Node3D
var _oferenda_na_mao: Oferenda
## Ate onde se pode depor, a contar do centro. Fora disto o gesto nao
## chegou ao `assentamento`.
const ALCANCE_DO_CHAO := 0.62
var _tempo := 0.0


func _ready() -> void:
	_gravura = load("res://shaders/gravura.gdshader")
	if not Engine.is_editor_hint():
		_carregar_depositos()
		_montar_tira()
		_montar_menu()
		_por_a_andar()
		_carregar_pedidos()
	_vestir()
	set_process(true)


## Mantem as folhas do menu a arder enquanto o menu esta aberto.
##
## Sem isto, cada folha ficava com o valor que tinha no instante em que o
## menu abriu: no caldeirao ardiam, no menu estavam paradas.
func _arder_no_menu() -> void:
	var alguma_acabou := false
	for f in _folhas_vivas:
		var papel = f["papel"]
		if papel == null or not is_instance_valid(papel):
			alguma_acabou = true
			continue
		var p: Pedido = papel.pedido
		if p.acabou():
			alguma_acabou = true
			continue
		f["material"].set_shader_parameter("consumido", p.consumido())
		var falta: float = p.duracao * (1.0 - p.consumido())
		f["quanto"].text = "%dd %dh" % [int(falta / 86400.0), int(falta / 3600.0) % 24]
	if alguma_acabou:
		_actualizar_lista()


## Poe a andar o que esta no grupo `anda`.
##
## Por adesao e nao por omissao: metade dos modelos traz uma animacao de
## fabrica — a garrafa tem um `CylinderAction`, a vela preta um
## `Take 001` — e tocar tudo o que aparece punha a garrafa a rodar sobre
## si propria em cima do `assentamento`.
##
## So fora do editor: na bancada a nganga fica quieta, para se arrumar sem
## nada a mexer.
func _por_a_andar() -> void:
	for no in get_tree().get_nodes_in_group("anda"):
		if not (no is Node3D and is_ancestor_of(no)):
			continue
		_andar(no)


func _andar(no: Node) -> void:
	for tocador in _tocadores(no):
		var lista := tocador.get_animation_list()
		if lista.is_empty():
			continue
		# Preferir um ciclo de andar; senao, a primeira que houver.
		var escolhida: String = lista[0]
		for nome in lista:
			if "walk" in String(nome).to_lower() or "ciclo" in String(nome).to_lower():
				escolhida = nome
				break
		var anim := tocador.get_animation(escolhida)
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR
		tocador.play(escolhida)


func _tocadores(raiz: Node) -> Array[AnimationPlayer]:
	var saida: Array[AnimationPlayer] = []
	if raiz is AnimationPlayer:
		saida.append(raiz)
	for f in raiz.get_children():
		saida.append_array(_tocadores(f))
	return saida


# --- pedidos ----------------------------------------------------------

func _carregar_pedidos() -> void:
	_pedidos = Pedido.ler()
	for p in _pedidos:
		_por_papel(p)


func _por_papel(p: Pedido) -> void:
	var papel := Papel.new(p)
	# Sem `owner`: os papeis nao se gravam na cena travada.
	add_child(papel)
	# Limpar os que ja arderam antes de contar: senao o proximo papel
	# entrava sempre mais abaixo, mesmo com a lanca vazia.
	_papeis = _papeis.filter(func(x): return x != null and is_instance_valid(x))
	papel.position = _na_lanca(_papeis.size())
	papel.rotation_degrees = Vector3(0, randf_range(-38.0, 38.0), randf_range(-7.0, 7.0))
	_papeis.append(papel)


## Onde espetar o enesimo papel: junto as pontas do tridente, cada um um
## pouco mais abaixo, como quem vai enfiando papeis na mesma lanca.
func _na_lanca(indice: int) -> Vector3:
	var lanca := get_node_or_null(NodePath(LANCA))
	if lanca == null or not lanca is Node3D:
		return Vector3(0.0, 0.40, 0.05)
	var caixa := _caixa_mundo(lanca)
	if caixa.size == Vector3.ZERO:
		return Vector3(0.0, 0.40, 0.05)
	var centro := caixa.get_center()
	# Abaixo das pontas, a descer com cada papel novo. Um papel tem 7,7 cm
	# de alto: descer so 3,5 cm punha-os todos no mesmo sitio, a brigarem
	# pela mesma profundidade. Descem mais, e cada um entra ligeiramente ao
	# lado, como papeis enfiados a pressa no mesmo ferro.
	var altura: float = caixa.end.y - 0.05 - float(indice) * 0.062
	var lado := Vector3(
		randf_range(-0.016, 0.016), 0.0, randf_range(-0.014, 0.014))
	return Vector3(centro.x, maxf(altura, caixa.position.y + 0.02), centro.z) + lado


## Poe um pedido a arder. Sete dias, e nao ha como o tirar de la.
func acender_pedido(texto: String) -> void:
	var limpo := texto.strip_edges()
	if limpo.is_empty():
		return
	var p := Pedido.new()
	p.texto = limpo
	p.duracao = maxf(dias_de_queima, 0.0001) * 24.0 * 60.0 * 60.0
	p.aceso_em = Time.get_unix_time_from_system()
	_pedidos.append(p)
	Pedido.guardar(_pedidos)
	_por_papel(p)


## A tira de `oferendas`. Nao e um carrinho de compras: nao se acumula,
## nao se soma, nao se confirma. Carrega-se numa e arrasta-se — o gesto e
## a decisao (GDD §2, pilar 3).
func _montar_tira() -> void:
	var folha := CanvasLayer.new()
	folha.name = "Folha"
	add_child(folha)

	var tira := HBoxContainer.new()
	tira.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tira.offset_top = -86
	tira.offset_bottom = -18
	tira.offset_left = 12
	tira.offset_right = -12
	tira.alignment = BoxContainer.ALIGNMENT_CENTER
	tira.add_theme_constant_override("separation", 8)
	folha.add_child(tira)

	# Entrada visivel para os pedidos. O ESC continua a servir, mas ninguem
	# adivinha uma tecla que nao esta escrita em lado nenhum.
	var escrever := Pagina.botao("pedido", 17)
	escrever.pressed.connect(_alternar_menu)
	tira.add_child(escrever)

	for caminho in _oferendas_disponiveis():
		var o: Oferenda = load(caminho)
		if o == null:
			continue
		var b := Pagina.botao(o.nome, 17)
		b.button_down.connect(_comecar_a_depor.bind(o))
		tira.add_child(b)


func _montar_menu() -> void:
	_menu = CanvasLayer.new()
	_menu.name = "Menu"
	_menu.visible = false
	add_child(_menu)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.86)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(fundo)

	var titulo := Pagina.texto("escreva o que tu quer", 30)
	titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 62
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(titulo)

	# O campo E o papel: cor de papel, tinta escura. Uma caixa preta e
	# vazia no meio do escuro nao diz a ninguem que se escreve ali.
	_escrita = TextEdit.new()
	_escrita.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_escrita.offset_top = 118
	_escrita.offset_bottom = 316
	_escrita.offset_left = 52
	_escrita.offset_right = -52
	_escrita.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_escrita.add_theme_font_size_override("font_size", 24)
	_escrita.add_theme_color_override("font_color", Color(0.12, 0.10, 0.09))
	_escrita.add_theme_color_override("caret_color", Color(0.12, 0.10, 0.09))
	_escrita.add_theme_color_override("font_placeholder_color", Color(0.42, 0.38, 0.34))
	_escrita.add_theme_color_override("selection_color", Color(0.62, 0.56, 0.44))
	# Diz ONDE se escreve, nunca O QUE se escreve: o app nao insinua o que
	# se pede (CONTENT_pt.md §2).
	_escrita.placeholder_text = "escreva aqui"
	var papel := StyleBoxFlat.new()
	papel.bg_color = Color(0.86, 0.82, 0.72)
	papel.border_color = Color(0.62, 0.57, 0.47)
	papel.set_border_width_all(1)
	papel.set_corner_radius_all(0)
	papel.content_margin_left = 18
	papel.content_margin_right = 18
	papel.content_margin_top = 16
	papel.content_margin_bottom = 16
	for estado in ["normal", "focus", "read_only"]:
		_escrita.add_theme_stylebox_override(estado, papel)
	_menu.add_child(_escrita)

	# Num HBox e nao por offsets: com PRESET_TOP_WIDE o offset_left conta
	# a partir da esquerda e o offset_right a partir da direita, e misturar
	# os dois punha os botoes um por cima do outro.
	var botoes := HBoxContainer.new()
	botoes.set_anchors_preset(Control.PRESET_TOP_WIDE)
	botoes.offset_top = 332
	botoes.offset_bottom = 386
	botoes.offset_left = 52
	botoes.offset_right = -52
	botoes.add_theme_constant_override("separation", 12)
	_menu.add_child(botoes)

	var deitar := Pagina.botao("deitar ao caldeirao", 22)
	deitar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deitar.pressed.connect(_deitar_ao_caldeirao)
	botoes.add_child(deitar)

	# Sair sem depender de saber que o ESC serve para isso.
	var fechar := Pagina.botao("voltar", 22)
	fechar.pressed.connect(_alternar_menu)
	botoes.add_child(fechar)

	_lista = Pagina.texto("", 19)
	_lista.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_lista.offset_top = 408
	_lista.offset_bottom = 446
	_lista.offset_left = 56
	_lista.offset_right = -56
	_lista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu.add_child(_lista)

	# As folhas, como estao agora. E para isto que o menu serve: ver o
	# papel a decompor-se, nao ler uma percentagem.
	_folhas = HBoxContainer.new()
	_folhas.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_folhas.offset_top = 452
	_folhas.offset_bottom = 700
	_folhas.offset_left = 40
	_folhas.offset_right = -40
	_folhas.alignment = BoxContainer.ALIGNMENT_CENTER
	_folhas.add_theme_constant_override("separation", 14)
	_menu.add_child(_folhas)


func _alternar_menu() -> void:
	if _menu == null:
		return
	_menu.visible = not _menu.visible
	if _menu.visible:
		_actualizar_lista()
		_escrita.grab_focus()


func _deitar_ao_caldeirao() -> void:
	acender_pedido(_escrita.text)
	_escrita.text = ""
	_actualizar_lista()


## Quanto falta a cada pedido. Diz o que esta a acontecer, nunca o que vai
## acontecer (CONTENT_pt.md §2).
func _actualizar_lista() -> void:
	if _lista == null:
		return
	var vivos := 0
	for p in _pedidos:
		if not p.acabou():
			vivos += 1
	_lista.text = "no caldeirao, a arder" if vivos > 0 else ""

	if _folhas == null:
		return
	for f in _folhas.get_children():
		f.queue_free()
	_folhas_vivas.clear()
	for papel in _papeis:
		if papel == null or not is_instance_valid(papel) or papel.pedido.acabou():
			continue
		var caixa := VBoxContainer.new()
		caixa.add_theme_constant_override("separation", 6)
		var folha := TextureRect.new()
		folha.texture = papel.escrito()
		folha.custom_minimum_size = Vector2(186, 124)
		folha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		folha.stretch_mode = TextureRect.STRETCH_SCALE
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/papel_2d.gdshader")
		m.set_shader_parameter("consumido", papel.pedido.consumido())
		folha.material = m
		caixa.add_child(folha)
		var falta: float = papel.pedido.duracao * (1.0 - papel.pedido.consumido())
		var quanto := Pagina.texto("%dd %dh" % [int(falta / 86400.0), int(falta / 3600.0) % 24], 17)
		quanto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caixa.add_child(quanto)
		_folhas.add_child(caixa)
		_folhas_vivas.append({"papel": papel, "material": m, "quanto": quanto})


func _oferendas_disponiveis() -> Array[String]:
	var saida: Array[String] = []
	var d := DirAccess.open("res://resources/oferendas")
	if d == null:
		return saida
	for f in d.get_files():
		if f.ends_with(".tres"):
			saida.append("res://resources/oferendas/%s" % f)
	saida.sort()
	return saida


func _comecar_a_depor(oferenda: Oferenda) -> void:
	if _na_mao != null:
		return
	_na_mao = _pegar(oferenda)
	if _na_mao == null:
		return
	_oferenda_na_mao = oferenda
	_assentar(_na_mao, Vector2.ZERO)


func _input(evento: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if evento.is_action_pressed("ui_cancel") and _menu != null:
		_alternar_menu()
		get_viewport().set_input_as_handled()
		return
	if _na_mao == null:
		return
	if evento is InputEventMouseMotion or evento is InputEventScreenDrag:
		var onde: Variant = _no_chao(evento.position)
		if onde != null:
			_assentar(_na_mao, onde)
	elif (evento is InputEventMouseButton and not evento.pressed) \
			or (evento is InputEventScreenTouch and not evento.pressed):
		_largar(_no_chao(evento.position))


## Larga o que esta na mao. Se chegou ao `assentamento`, fica — e fica
## para sempre. Se nao chegou, nunca chegou a ser deposto: isto nao e um
## desfazer, e um gesto que nao se completou.
func _largar(onde: Variant) -> void:
	if onde == null:
		_na_mao.queue_free()
	else:
		_assentar(_na_mao, onde)
		_registar(_oferenda_na_mao, onde)
		guardar_depositos()
		_vestir()
	_na_mao = null
	_oferenda_na_mao = null


## Onde o dedo cai no chao do `assentamento`, ou null se caiu fora.
func _no_chao(ecra: Vector2) -> Variant:
	var cam := get_node_or_null("Camara") as Camera3D
	if cam == null:
		return null
	var origem := cam.project_ray_origin(ecra)
	var dir := cam.project_ray_normal(ecra)
	if absf(dir.y) < 0.0001:
		return null
	var t := -origem.y / dir.y
	if t < 0.0:
		return null
	var p := origem + dir * t
	var onde := Vector2(p.x, p.z)
	return onde if onde.length() <= ALCANCE_DO_CHAO else null


## Depoe uma `oferenda` no `assentamento`, para sempre.
##
## `onde` e no plano do chao: `depositos` guarda duas coordenadas
## (SPEC.md §3.3), portanto o que se deposita assenta no chao e nao
## flutua.
##
## Nao existe o inverso. Se um dia aparecer um `retirar()`, alguem
## quebrou GDD §2.
func depor(oferenda: Oferenda, onde: Vector2) -> Node3D:
	var no := _pegar(oferenda)
	if no == null:
		return null
	_assentar(no, onde)
	_registar(oferenda, onde)
	_vestir()
	return no


## Poe a `oferenda` na mao: instancia o modelo e da-lhe o tamanho certo.
## Ainda nao esta deposta — enquanto esta na mao pode nao chegar a ficar.
func _pegar(oferenda: Oferenda) -> Node3D:
	if oferenda == null or oferenda.modelo == "":
		return null
	var cena: PackedScene = load(oferenda.modelo)
	if cena == null:
		push_error("oferenda sem modelo: %s" % oferenda.slug)
		return null
	var no: Node3D = cena.instantiate()
	no.name = "%s_%d" % [oferenda.slug, _depositos.size()]
	# Sem `owner`: o que se depoe nao se grava na cena. A cena e o
	# fundamento travado; os depositos vivem no registo.
	add_child(no)
	var local := _caixa_local(no)
	var maior: float = maxf(local.size.x, maxf(local.size.y, local.size.z))
	if maior > 0.0:
		no.scale = Vector3.ONE * (oferenda.tamanho / maior)
	return no


## Assenta no chao: a base toca o chao, o centro fica onde se pede.
func _assentar(no: Node3D, onde: Vector2) -> void:
	var caixa := no.transform * _caixa_local(no)
	var centro := caixa.get_center()
	no.position += Vector3(onde.x, 0.0, onde.y) - Vector3(centro.x, caixa.position.y, centro.z)


func _registar(oferenda: Oferenda, onde: Vector2) -> void:
	if oferenda.e_vela:
		var no := get_node_or_null(NodePath("%s_%d" % [oferenda.slug, _depositos.size()]))
		if no != null:
			no.add_to_group("vela", true)
	_depositos.append({"oferenda": oferenda.slug, "x": onde.x, "y": onde.y})


## Substituto local da tabela `depositos` enquanto nao ha servidor. O
## servidor e que manda (SPEC.md §3.3); isto so guarda o que ja foi deposto
## para o `assentamento` nao esquecer entre sessoes.
const REGISTO := "user://depositos.json"


func _carregar_depositos() -> void:
	if not FileAccess.file_exists(REGISTO):
		return
	var f := FileAccess.open(REGISTO, FileAccess.READ)
	var dados = JSON.parse_string(f.get_as_text())
	f.close()
	if not dados is Array:
		return
	for d in dados:
		var o: Oferenda = load("res://resources/oferendas/%s.tres" % d["oferenda"])
		if o != null:
			depor(o, Vector2(float(d["x"]), float(d["y"])))


func guardar_depositos() -> void:
	var f := FileAccess.open(REGISTO, FileAccess.WRITE)
	f.store_string(JSON.stringify(_depositos))
	f.close()


func _process(delta: float) -> void:
	var no_editor := Engine.is_editor_hint()
	if no_editor:
		# No editor a nganga muda debaixo dos pes: refazer luzes e
		# materiais todos os quadros e o que faz arrastar uma vela mover a
		# luz dela.
		_vestir()
	_tempo += delta

	if _menu != null and _menu.visible:
		_arder_no_menu()

	var energias := PackedFloat32Array()
	for i in _luzes.size():
		var e := brilho_da_vela
		if bruxulear:
			# Cada chama bruxuleia por sua conta; se todas pulsassem
			# juntas leria-se como um interruptor a piscar.
			var f := float(i) * 2.3
			e *= 1.0 + 0.06 * sin(_tempo * 3.1 + f) + 0.04 * sin(_tempo * 7.7 + f * 1.7)
			if i < _chamas.size():
				_chamas[i].scale = Vector3.ONE * (1.0 + 0.08 * sin(_tempo * 9.0 + f))
		if i < _lampadas.size():
			_lampadas[i].light_energy = forca_da_luz * (e / maxf(brilho_da_vela, 0.001))
		energias.append(e)
	_aplicar_luz(energias)


## Poe a gravura em tudo e recalcula onde estao as chamas.
func _vestir() -> void:
	_luzes.clear()
	_velas.clear()
	for vela in get_tree().get_nodes_in_group("vela"):
		if vela is Node3D and is_ancestor_of(vela):
			var caixa := _caixa_mundo(vela)
			if caixa.size != Vector3.ZERO:
				_velas.append(vela)
				_luzes.append(Vector3(
					caixa.get_center().x, caixa.end.y + 0.012, caixa.get_center().z))
	_montar_lampadas()
	_montar_chamas()

	var chao := get_node_or_null("Chao")
	for malha in _malhas(self):
		if not mostrar_gravura:
			# Sem gravura, o chao continua a precisar de material proprio:
			# o plano nu e branco e reflete tudo.
			if malha == chao:
				var terra := StandardMaterial3D.new()
				terra.albedo_color = cor_do_chao
				terra.roughness = 1.0
				terra.metallic = 0.0
				malha.material_override = terra
			else:
				malha.material_override = null
			continue
		if malha.material_override == null or not malha.material_override is ShaderMaterial:
			malha.material_override = _material()
		var m: ShaderMaterial = malha.material_override
		if m == null:
			continue
		m.set_shader_parameter("resposta",
			resposta_do_chao if chao != null and chao.is_ancestor_of(malha) or malha == chao else 1.0)


## As lampadas sao a luz da cena e existem sempre. As `_chamas` abaixo sao
## esferas brancas que so fazem falta com a gravura ligada — os modelos das
## velas ja trazem a sua propria chama.
func _montar_lampadas() -> void:
	_montar_ambiente()
	while _lampadas.size() > _luzes.size():
		_lampadas.pop_back().queue_free()
	while _lampadas.size() < _luzes.size():
		var l := OmniLight3D.new()
		l.light_color = cor_da_chama
		l.omni_range = alcance_da_luz
		l.light_energy = forca_da_luz
		l.omni_attenuation = queda_da_luz
		l.shadow_enabled = false     # sombras de seis lados por vela, no
		                             # renderizador de compatibilidade, nao
		                             # compensam o que custam
		add_child(l)                 # sem `owner`: nao se grava na cena
		_lampadas.append(l)
	for i in _lampadas.size():
		_lampadas[i].position = _luzes[i]
		_lampadas[i].light_color = cor_da_chama
		_lampadas[i].omni_range = alcance_da_luz
		_lampadas[i].omni_attenuation = queda_da_luz


## Desenha uma chama para as velas que nao trazem chama no modelo.
##
## A vela preta e a branca trazem a sua; a vermelha e uma malha so, sem
## pavio aceso. Em vez de adivinhar pela contagem de malhas, quem precisa
## de chama diz-se pelo grupo `sem_chama` — assim uma vela nova resolve-se
## no editor e nao no codigo.
func _montar_chamas() -> void:
	var precisam: Array[Vector3] = []
	for i in _velas.size():
		if _velas[i].is_in_group("sem_chama"):
			precisam.append(_luzes[i])

	while _chamas.size() > precisam.size():
		_chamas.pop_back().queue_free()
	while _chamas.size() < precisam.size():
		var chama := MeshInstance3D.new()
		# Gota, nao esfera: uma chama e mais alta que larga.
		var gota := SphereMesh.new()
		gota.radius = 0.0045
		gota.height = 0.020
		chama.mesh = gota
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# Mais saturada que a luz que lanca: uma chama vista de perto e
		# amarela, nao branca. Sem isto le-se como uma bola palida ao lado
		# das chamas que os proprios modelos trazem.
		m.albedo_color = Color(1.0, 0.85, 0.45)
		chama.material_override = m
		# Sem `owner`: as chamas nao se gravam na cena, sao desenhadas.
		add_child(chama)
		_chamas.append(chama)
	for i in _chamas.size():
		_chamas[i].position = precisam[i] + Vector3(0, 0.010, 0)
		var mat := _chamas[i].material_override
		if mat is StandardMaterial3D:
			mat.albedo_color = Color(1.0, 0.85, 0.45)


## Escuro a serio: fundo preto e nada de luz ambiente. A unica luz da cena
## sao as velas.
func _montar_ambiente() -> void:
	var ja := get_node_or_null("Ambiente")
	if ja != null:
		# No editor a luz de bancada pode mudar no inspetor: acompanhar.
		if Engine.is_editor_hint() and ja is WorldEnvironment:
			var f := luz_de_bancada
			ja.environment.ambient_light_color = Color(f, f * 0.92, f * 0.84)
		return
	var amb := WorldEnvironment.new()
	amb.name = "Ambiente"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var f: float = luz_de_bancada if Engine.is_editor_hint() else luz_de_reserva
	env.ambient_light_color = Color(f, f * 0.92, f * 0.84)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	# Sem isto o que esta ao pe de uma chama queima para branco chapado —
	# e uma rosa negra encostada a tres velas deixa de ser negra.
	env.tonemap_white = 3.0
	amb.environment = env
	add_child(amb)


func _material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _gravura if _gravura != null else load("res://shaders/gravura.gdshader")
	m.set_shader_parameter("cor_tinta", COR_TINTA)
	return m


func _aplicar_luz(energias: PackedFloat32Array) -> void:
	var posicoes := PackedVector3Array(_luzes)
	var chao := get_node_or_null("Chao")
	for malha in _malhas(self):
		var m := malha.material_override
		if not m is ShaderMaterial:
			continue                 # gravura desligada: nao ha o que afinar
		var e_chao: bool = malha == chao
		m.set_shader_parameter("luz_pos", posicoes)
		m.set_shader_parameter("luz_energia", energias)
		m.set_shader_parameter("luzes", _luzes.size())
		m.set_shader_parameter("alcance", alcance_da_vela)
		m.set_shader_parameter("grao", grao)
		m.set_shader_parameter("angulo", deg_to_rad(angulo_do_chao) if e_chao else 0.0)
		m.set_shader_parameter("passo", trama * calibre_do_chao if e_chao else trama)
		m.set_shader_parameter("contorno", 0.0 if e_chao else contorno)


func _malhas(raiz: Node) -> Array[MeshInstance3D]:
	var saida: Array[MeshInstance3D] = []
	if raiz is MeshInstance3D and not _chamas.has(raiz):
		saida.append(raiz)
	for filho in raiz.get_children():
		saida.append_array(_malhas(filho))
	return saida


## Caixa envolvente de um no, no espaco local dele — sem contar a
## transformacao do proprio no. Acumulada a mao, para servir tambem antes
## de o no estar na arvore.
func _caixa_local(no: Node3D) -> AABB:
	var total := AABB()
	var primeiro := true
	var pilha: Array = [[no, Transform3D.IDENTITY]]
	while pilha:
		var par = pilha.pop_back()
		var n: Node = par[0]
		var t: Transform3D = par[1]
		if n is Node3D and n != no:
			t = t * (n as Node3D).transform
		if n is MeshInstance3D and n.mesh != null:
			var caixa: AABB = t * n.mesh.get_aabb()
			if primeiro:
				total = caixa
				primeiro = false
			else:
				total = total.merge(caixa)
		for f in n.get_children():
			pilha.append([f, t])
	return total


## Caixa envolvente de um no, em espaco de mundo.
##
## Em mundo e nao em local: em local a caixa vem nas unidades cruas do
## ficheiro e sem a escala do proprio no.
func _caixa_mundo(no: Node3D) -> AABB:
	var total := AABB()
	var primeiro := true
	for malha in _malhas(no):
		if malha.mesh == null:
			continue
		var caixa: AABB = malha.global_transform * malha.mesh.get_aabb()
		if primeiro:
			total = caixa
			primeiro = false
		else:
			total = total.merge(caixa)
	return total
