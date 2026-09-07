## Quem olha, e quem avanca, na sala da `fornalha`.
##
## Olha-se em volta e para cima com o rato — o teto e para se ver. Anda-se
## SO EM LINHA RETA, para a frente e para tras, entre dois limites: a
## sala nao e para passear, e a linha acaba na boca do forno.
##
## Sem fisica nenhuma. A posicao e escrita e presa entre `z_recuado` e
## `z_avancado`; nao ha nada em que bater, nao ha por onde cair, e nao ha
## um corredor de caixas para manter.
@tool
class_name Jogador
extends CharacterBody3D

## Enquanto for falso nao se anda nem se olha: e o tempo da pergunta.
var solto := false:
	set(valor):
		solto = valor
		Input.mouse_mode = (Input.MOUSE_MODE_CAPTURED if solto
			else Input.MOUSE_MODE_VISIBLE)

@export_range(0.2, 6.0) var velocidade := 1.5
@export_range(0.02, 1.0) var sensibilidade := 0.16
## Ate onde se pode olhar para cima e para baixo, em graus. Para cima
## chega ao teto.
@export_range(10.0, 89.0) var limite_vertical := 85.0
## Ate onde se pode virar a cabeca para os lados, a contar da linha da
## fornalha. Nao e uma volta inteira: a sala tem uma frente.
@export_range(15.0, 180.0) var limite_horizontal := 120.0

## Os dois extremos da linha. `z_recuado` e onde se comeca.
@export var z_recuado := 7.4
@export var z_avancado := 3.0

@onready var camara: Camera3D = $Camara


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	position.z = z_recuado


func _unhandled_input(evento: InputEvent) -> void:
	if not solto or Engine.is_editor_hint():
		return
	if evento is InputEventMouseMotion:
		var m := evento as InputEventMouseMotion
		rotation_degrees.y = clampf(
			rotation_degrees.y - m.relative.x * sensibilidade,
			-limite_horizontal, limite_horizontal)
		camara.rotation_degrees.x = clampf(
			camara.rotation_degrees.x - m.relative.y * sensibilidade,
			-limite_vertical, limite_vertical)
	# Largar o rato sem fechar nada.
	elif evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if not solto or Engine.is_editor_hint():
		return
	# Em linha reta e so em linha reta: a frente e a fornalha, atras e a
	# entrada. Nao ha andar de lado.
	var passo := (Input.get_action_strength("andar_frente")
		- Input.get_action_strength("andar_tras"))
	if is_zero_approx(passo):
		return
	position.z = clampf(
		position.z - passo * velocidade * delta,
		minf(z_avancado, z_recuado), maxf(z_avancado, z_recuado))
