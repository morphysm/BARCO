## A passagem: o sol imenso que entra em eclipse e fica sol negro, e por
## ele entra-se no `assentamento`.
##
## E o que costura a primeira fase a segunda (SPEC.md §1.1): so se ve
## depois de os tres `pontos` terem sido riscados, e uma vez atravessada
## nao se volta a ver.
##
## Nao se salta. Nao ha botao, nao ha toque que a apresse: e uma travessia
## em tempo real, como a `permanencia` (SPEC.md §7). O que ela custa e o
## que ela vale.
extends Node2D

## Quanto dura a travessia inteira, em segundos.
@export var duracao := 16.0

## O tamanho do sol no ecra. `imenso` — o disco sozinho passa de um terco
## da altura, e a coroa vai muito alem dele.
@export_range(0.05, 1.2) var tamanho := 0.26

## O que toca por cima. Fica vazio ate haver som proprio; sem stream a
## passagem corre em silencio, que e melhor do que correr com o som
## errado.
@export var som: AudioStream

var _tela: ColorRect
var _material: ShaderMaterial
var _tocador: AudioStreamPlayer
var _tempo := 0.0
var _entregue := false


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = load("res://shaders/eclipse.gdshader")
	_material.set_shader_parameter("tamanho", tamanho)

	_tela = ColorRect.new()
	_tela.material = _material
	_tela.color = Color.BLACK
	_tela.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var camada := CanvasLayer.new()
	camada.add_child(_tela)
	add_child(camada)

	if som != null:
		_tocador = AudioStreamPlayer.new()
		_tocador.stream = som
		add_child(_tocador)
		_tocador.play()

	get_viewport().size_changed.connect(_medir)
	_medir()
	set_process(true)


func _medir() -> void:
	var v := get_viewport_rect().size
	_material.set_shader_parameter("proporcao", v.x / maxf(v.y, 1.0))


func _process(delta: float) -> void:
	_tempo += delta
	var f: float = clampf(_tempo / maxf(duracao, 0.001), 0.0, 1.0)
	_material.set_shader_parameter("fase", f)
	if f >= 1.0 and not _entregue:
		_entregue = true
		_entrar()


## Entrar no `assentamento`. Daqui nao se volta ao risco.
func _entrar() -> void:
	if Engine.is_editor_hint():
		return
	get_tree().change_scene_to_file("res://scenes/assentamento.tscn")
