## Quem anda na sala da `fornalha`.
##
## Primeira pessoa, com rato preso e uma mira ao centro. Nao ha salto, nao
## ha corrida, nao ha agachar: anda-se e olha-se, e mais nada.
##
## Os limites nao estao aqui — estao na cena, em `Corredor`, feitos de
## caixas que se veem e se arrastam no editor. Sao estreitos de proposito:
## da para olhar em volta, nao da para passear. Quem entra nesta sala vai
## a fornalha.
class_name Jogador
extends CharacterBody3D

@export_range(0.5, 6.0) var velocidade := 2.1
@export_range(0.02, 1.0) var sensibilidade := 0.16
## Ate onde se pode olhar para cima e para baixo, em graus.
@export_range(10.0, 89.0) var limite_vertical := 78.0

## Enquanto isto for falso nao se anda nem se olha: e o tempo da pergunta.
var solto := false:
	set(valor):
		solto = valor
		Input.mouse_mode = (Input.MOUSE_MODE_CAPTURED if solto
			else Input.MOUSE_MODE_VISIBLE)

@onready var camara: Camera3D = $Camara


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(evento: InputEvent) -> void:
	if not solto:
		return
	if evento is InputEventMouseMotion:
		var m := evento as InputEventMouseMotion
		rotate_y(deg_to_rad(-m.relative.x * sensibilidade))
		camara.rotation_degrees.x = clampf(
			camara.rotation_degrees.x - m.relative.y * sensibilidade,
			-limite_vertical, limite_vertical)
	# Largar o rato sem fechar nada: quem quer o ponteiro de volta carrega
	# em ESC e volta a preende-lo com um clique.
	elif evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if not solto:
		return
	var querer := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direcao := (transform.basis * Vector3(querer.x, 0.0, querer.y)).normalized()
	velocity.x = direcao.x * velocidade
	velocity.z = direcao.z * velocidade
	# Cola-se ao chao. Nao ha salto e nao ha queda: a sala e plana.
	velocity.y = -2.0
	move_and_slide()
