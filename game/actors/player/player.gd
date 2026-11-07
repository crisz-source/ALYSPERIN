class_name Player
extends CharacterBody2D
## Personagem controlável.
##
## Etapa atual: movimento top-down em 8 direções, com aceleração e frenagem,
## e direção visual em 4 (cima, baixo, esquerda, direita), que é o que os
## sprites terão. Ataque e esquiva entram nas próximas etapas.

## Velocidade máxima, em pixels por segundo (16 px = 1 tile).
@export var max_speed: float = 90.0
## Quanto a velocidade cresce por segundo ao começar a andar.
@export var acceleration: float = 900.0
## Quanto a velocidade cai por segundo ao soltar as teclas.
@export var friction: float = 1100.0

## Direção para onde o personagem está virado: sempre uma das 4 cardeais.
var facing: Vector2 = Vector2.DOWN

@onready var _input: PlayerInput = $PlayerInput
@onready var _facing_indicator: Node2D = $FacingIndicator


func _ready() -> void:
	_facing_indicator.rotation = facing.angle()


func _physics_process(delta: float) -> void:
	_input.poll()
	var direction: Vector2 = _input.move_direction
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
		_update_facing(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()


func _update_facing(direction: Vector2) -> void:
	var new_facing: Vector2 = to_cardinal(direction)
	if new_facing == facing:
		return
	facing = new_facing
	_facing_indicator.rotation = facing.angle()


## Converte qualquer direção na cardeal mais próxima. Em diagonal exata
## (teclado), o lado horizontal vence, porque o sprite de perfil lê melhor.
static func to_cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP
