class_name Lever
extends StaticBody3D
## Alavanca (PROVISÓRIA: sem arte), 3D. Ao ser puxada, abre as portas ligadas a ela.
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

var _material: StandardMaterial3D

@onready var _handle: Node3D = $HandlePivot
@onready var _handle_mesh: MeshInstance3D = $HandlePivot/HandlePlaceholder
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_material = (_handle_mesh.material_override as StandardMaterial3D).duplicate()
	_handle_mesh.material_override = _material
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
	_material.albedo_color = ON_COLOR if is_on else OFF_COLOR
	# Alavanca inclinada para um lado ou outro.
	_handle.rotation_degrees.x = 40.0 if is_on else -40.0
	_interactable.prompt_text = "Puxar"
	_interactable.enabled = not (one_shot and is_on)
