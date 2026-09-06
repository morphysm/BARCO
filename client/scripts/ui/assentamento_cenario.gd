@tool
## O `assentamento` como cenario: so a nganga, sem ritual.
##
## E uma copia do arranjo de `assentamento_screen.gd` sem nada do que se
## joga — sem `depor`, sem `pedidos` a arder, sem menu, sem registo em
## disco. Fica o que se ve: as pecas onde A.C. as pos, as velas a dar luz,
## o chao, o ambiente escuro e o que anda.
##
## Serve para levar o `assentamento` para outra cena ou outro jogo sem
## arrastar atras o `trabalho`. Nao depende de `Pedido`, `Papel` nem
## `Oferenda`: as unicas dependencias sao os modelos em
## `resources/modelos/` e, se a gravura estiver ligada,
## `shaders/gravura.gdshader`.
##
## Alterar o arranjo faz-se na cena, nao aqui. Cada peca do grupo "vela" e
## uma luz; quem precisa de chama desenhada diz-se pelo grupo "sem_chama";
## o que se mexe poe-se no grupo "anda".
extends Node3D

const COR_TINTA := Color(0.937, 0.925, 0.882)

## Cor do chao. Sem material o plano fica branco por omissao, e um branco
## de tres metros de lado devolve toda a luz das velas.
@export var cor_do_chao := Color(0.06, 0.055, 0.05)

## Quanto o chao responde a luz, comparado com os objetos.
@export_range(0.0, 1.0) var resposta_do_chao := 0.42

## Brilho de cada chama.
@export_range(0.0, 2.0) var brilho_da_vela := 0.55

## Ate onde a chama de uma vela chega.
@export_range(0.05, 1.0) var alcance_da_vela := 0.30

## Distancia entre os sulcos da gravura. Maior = trama mais fina.
@export_range(0.03, 0.40) var trama := 0.15

## Ruido por cima da trama.
@export_range(0.0, 1.0) var grao := 0.12

## Angulo da trama do chao, em graus, contra a dos objetos.
@export_range(0.0, 90.0) var angulo_do_chao := 22.0

## Trama do chao contra a dos objetos.
@export_range(0.2, 1.5) var calibre_do_chao := 0.55

## Contorno nas pecas.
@export_range(0.0, 1.0) var contorno := 0.85

## Desliga a gravura e mostra os modelos como o Godot os mostraria.
@export var mostrar_gravura := false:
	set(valor):
		mostrar_gravura = valor
		if is_inside_tree():
			_vestir()

## Cor da chama. Cera a arder e alaranjada, nao branca.
@export var cor_da_chama := Color(1.0, 0.72, 0.42)

## Quao depressa a luz cai.
@export_range(0.5, 8.0) var queda_da_luz := 3.0

## Ate onde a luz de uma vela chega, em metros.
@export_range(0.1, 3.0) var alcance_da_luz := 0.5

## Forca de cada vela.
@export_range(0.0, 8.0) var forca_da_luz := 0.26

## Luz de reserva fora do editor, para um `assentamento` sem vela nenhuma
## nao ser um ecra preto.
@export_range(0.0, 0.5) var luz_de_reserva := 0.16

## Luz no EDITOR. Nada a ver com a do app: aqui e uma bancada.
@export_range(0.0, 2.0) var luz_de_bancada := 0.75

## Desliga o bruxuleio.
@export var bruxulear := true

## Poe a andar o que esta no grupo `anda`. Desligado no editor, para a
## nganga ficar quieta enquanto se arruma.
@export var animar := true

var _gravura: Shader
var _luzes: Array[Vector3] = []
var _chamas: Array[MeshInstance3D] = []
var _lampadas: Array[OmniLight3D] = []
var _velas: Array[Node3D] = []
var _tempo := 0.0


func _ready() -> void:
	_gravura = load("res://shaders/gravura.gdshader")
	if animar and not Engine.is_editor_hint():
		_por_a_andar()
	_vestir()
	set_process(true)


## Poe a andar o que esta no grupo `anda`.
##
## Por adesao e nao por omissao: metade dos modelos traz uma animacao de
## fabrica, e tocar tudo o que aparece punha a garrafa a rodar sobre si
## propria em cima do `assentamento`.
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


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# No editor a nganga muda debaixo dos pes: refazer luzes e
		# materiais todos os quadros e o que faz arrastar uma vela mover a
		# luz dela.
		_vestir()
	_tempo += delta

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
## Quem precisa de chama diz-se pelo grupo `sem_chama` — assim uma vela
## nova resolve-se no editor e nao no codigo.
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
##
## So monta o `WorldEnvironment` se a cena for a raiz: instanciado dentro
## de outro jogo, o ambiente e de quem manda la fora, e dois ambientes na
## mesma arvore era o cenario a apagar o ceu do jogo que o recebe.
func _montar_ambiente() -> void:
	if not _e_raiz():
		return
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


## Esta cena e a que manda, ou esta instanciada dentro de outra?
func _e_raiz() -> bool:
	if Engine.is_editor_hint():
		return get_tree().edited_scene_root == self
	return get_parent() == get_tree().root or get_tree().current_scene == self


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
