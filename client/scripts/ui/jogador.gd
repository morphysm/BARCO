## Quem olha, e quem avanca, na sala da `fornalha`.
##
## Olha-se para TODOS OS LADOS com o rato — para cima, que o teto e para
## se ver, e para tras. Anda-se SO EM LINHA RETA, entre dois limites: a
## sala nao e para passear, e a linha acaba na boca do forno.
##
## O recuo aperta-se por tras: passada a cruz, ela passa a ser o limite e
## nao se volta atras dela. Assim quem avancou nao a perde de vista.
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
## Os dois extremos da linha. `z_recuado` e onde se comeca.
@export var z_recuado := 7.4
@export var z_avancado := 3.0

## Ate onde se pode recuar AGORA. Comeca em `z_recuado` e aperta quando
## se passa a barreira; nunca alarga.
var recuo_possivel := 7.4

## O que fecha o caminho de volta, quando se passa por ele. A cena poe
## aqui a cruz.
var barreira: Node3D

@onready var camara: Camera3D = $Camara


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	position.z = z_recuado
	recuo_possivel = z_recuado


func _unhandled_input(evento: InputEvent) -> void:
	if not solto or Engine.is_editor_hint():
		return
	if evento is InputEventMouseMotion:
		var m := evento as InputEventMouseMotion
		# Volta inteira: olhar para tras faz parte.
		rotate_y(deg_to_rad(-m.relative.x * sensibilidade))
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
	# Passar a barreira aperta o recuo: dai em diante ela fica sempre a
	# frente, e nao se volta atras dela.
	if barreira != null and is_instance_valid(barreira):
		var z_barreira := barreira.global_position.z
		if position.z < z_barreira:
			recuo_possivel = minf(recuo_possivel, z_barreira)

	position.z = clampf(
		position.z - passo * velocidade * delta,
		minf(z_avancado, recuo_possivel), maxf(z_avancado, recuo_possivel))
