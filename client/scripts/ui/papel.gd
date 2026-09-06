## O papel de um `pedido`, dentro do caldeirao, a arder.
##
## O que a pessoa escreveu e desenhado num SubViewport e usado como
## textura do papel — e por isso que as palavras se veem a queimar com
## ele, em vez de o papel ser um retangulo em branco.
class_name Papel
extends Node3D

const LARGURA := 384
const ALTURA := 256

var pedido: Pedido
var _quad: MeshInstance3D
var _vista: SubViewport
var _letra: Label


## A textura com o que foi escrito, para o menu poder mostrar a mesma
## folha sem a instanciar outra vez.
func escrito() -> Texture2D:
	return _vista.get_texture() if _vista != null else null


func _init(p: Pedido) -> void:
	pedido = p


func _ready() -> void:
	_vista = SubViewport.new()
	_vista.size = Vector2i(LARGURA, ALTURA)
	_vista.transparent_bg = true
	_vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vista)

	_letra = Pagina.texto(pedido.texto, 26)
	_letra.add_theme_color_override("font_color", Color(0.12, 0.10, 0.09))
	_letra.set_anchors_preset(Control.PRESET_FULL_RECT)
	_letra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_letra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_letra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_vista.add_child(_letra)

	_quad = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.115, 0.077)
	_quad.mesh = q
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/papel.gdshader")
	m.set_shader_parameter("escrito", _vista.get_texture())
	_quad.material_override = m
	# De pe: o papel esta espetado na lanca, nao pousado. Ligeiramente
	# tombado para tras, como papel enfiado num ferro.
	_quad.rotation_degrees = Vector3(-9, 0, 0)
	add_child(_quad)
	set_process(true)


func _process(_d: float) -> void:
	if pedido == null or _quad == null:
		return
	var m := _quad.material_override
	if m is ShaderMaterial:
		m.set_shader_parameter("consumido", pedido.consumido())
	if pedido.acabou():
		queue_free()
