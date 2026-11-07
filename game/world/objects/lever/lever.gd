class_name Lever
extends StaticBody2D
## Alavanca (PROVISÓRIA: sem arte). Ao ser puxada, abre as portas ligadas a ela.
##
## As portas são escolhidas no Inspetor (`targets`). Com `one_shot`, depois de
## puxada fica travada e o aviso some.

signal pulled(is_on: bool)

const OFF_COLOR := Color(0.6, 0.6, 0.65)
const ON_COLOR := Color(0.95, 0.8, 0.3)

## Portas que esta alavanca abre (e fecha, se não for one_shot).
@export var targets: Array[Door] = []
@export var one_shot: bool = true
@export var is_on: bool = false
@export_multiline var pulled_message: String = "Algo se abriu ao longe."

@onready var _handle: Polygon2D = $HandlePlaceholder
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.handler = _on_interact
	_apply_state()


func _on_interact(_by: Player) -> String:
	is_on = not is_on
	for door: Door in targets:
		if is_instance_valid(door):
			door.set_open(is_on)
	_apply_state()
	pulled.emit(is_on)
	return pulled_message if is_on else ""


func _apply_state() -> void:
	_handle.color = ON_COLOR if is_on else OFF_COLOR
	# Alavanca inclinada para a direita quando ligada.
	_handle.rotation = deg_to_rad(35.0 if is_on else -35.0)
	_interactable.prompt_text = "Puxar"
	_interactable.enabled = not (one_shot and is_on)
