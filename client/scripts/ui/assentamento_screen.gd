@tool
## O `assentamento`. GLOSSARY.md, GDD §8, SPEC.md §8.1.
##
## Nao e um quarto iluminado. E um plano escuro visto de um so ponto, sem
## paredes e sem camara que gire — uma chapa, nao um mundo. SPEC.md §11:
## a presenca indica-se por `ponto`, luz, fumo e movimento de objeto.
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

## Desliga o bruxuleio. Ligado por omissao fora do editor; no editor a luz
## fica quieta, para nao pulsar enquanto se arruma a nganga.
@export var bruxulear := true

var _gravura: Shader
var _luzes: Array[Vector3] = []
var _chamas: Array[MeshInstance3D] = []
var _tempo := 0.0


func _ready() -> void:
	_gravura = load("res://shaders/gravura.gdshader")
	_vestir()
	set_process(true)


func _process(delta: float) -> void:
	var no_editor := Engine.is_editor_hint()
	if no_editor:
		# No editor a nganga muda debaixo dos pes: refazer luzes e
		# materiais todos os quadros e o que faz arrastar uma vela mover a
		# luz dela.
		_vestir()
	_tempo += delta

	var energias := PackedFloat32Array()
	for i in _luzes.size():
		var e := brilho_da_vela
		if bruxulear and not no_editor:
			# Cada chama bruxuleia por sua conta; se todas pulsassem
			# juntas leria-se como um interruptor a piscar.
			var f := float(i) * 2.3
			e *= 1.0 + 0.06 * sin(_tempo * 3.1 + f) + 0.04 * sin(_tempo * 7.7 + f * 1.7)
			if i < _chamas.size():
				_chamas[i].scale = Vector3.ONE * (1.0 + 0.08 * sin(_tempo * 9.0 + f))
		energias.append(e)
	_aplicar_luz(energias)


## Poe a gravura em tudo e recalcula onde estao as chamas.
func _vestir() -> void:
	_luzes.clear()
	for vela in get_tree().get_nodes_in_group("vela"):
		if vela is Node3D and is_ancestor_of(vela):
			var caixa := _caixa_mundo(vela)
			if caixa.size != Vector3.ZERO:
				_luzes.append(Vector3(
					caixa.get_center().x, caixa.end.y + 0.012, caixa.get_center().z))
	_montar_chamas()

	var chao := get_node_or_null("Chao")
	for malha in _malhas(self):
		if malha.material_override == null or not malha.material_override is ShaderMaterial:
			malha.material_override = _material()
		var m: ShaderMaterial = malha.material_override
		m.set_shader_parameter("resposta",
			resposta_do_chao if chao != null and chao.is_ancestor_of(malha) or malha == chao else 1.0)


func _montar_chamas() -> void:
	while _chamas.size() > _luzes.size():
		_chamas.pop_back().queue_free()
	while _chamas.size() < _luzes.size():
		var chama := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.010
		esfera.height = 0.026
		chama.mesh = esfera
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = COR_TINTA
		chama.material_override = m
		# Sem `owner`: as chamas nao se gravam na cena, sao desenhadas.
		add_child(chama)
		_chamas.append(chama)
	for i in _chamas.size():
		_chamas[i].position = _luzes[i]


func _material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _gravura if _gravura != null else load("res://shaders/gravura.gdshader")
	m.set_shader_parameter("cor_tinta", COR_TINTA)
	return m


func _aplicar_luz(energias: PackedFloat32Array) -> void:
	var posicoes := PackedVector3Array(_luzes)
	for malha in _malhas(self):
		var m := malha.material_override
		if m is ShaderMaterial:
			m.set_shader_parameter("luz_pos", posicoes)
			m.set_shader_parameter("luz_energia", energias)
			m.set_shader_parameter("luzes", _luzes.size())
			m.set_shader_parameter("alcance", alcance_da_vela)
			m.set_shader_parameter("passo", trama)
			m.set_shader_parameter("grao", grao)


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
