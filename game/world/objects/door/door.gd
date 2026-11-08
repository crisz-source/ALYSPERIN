class_name Door
extends StaticBody3D
## Porta (PROVISÓRIA: bloco sem arte), 3D. Fechada, bloqueia passagem e visão;
## aberta, não colide e fica quase invisível.
##
## Pode abrir com a mão (F) ou só por mecanismo (alavanca chama set_open).
## A colisão e o visual são montados pelo script a partir de `size_tiles`
## (1 tile = 1 m), para cada porta ter o próprio tamanho sem compartilhar a forma.

signal opened
signal closed

const HEIGHT: float = 3.0
const CLOSED_COLOR := Color(0.45, 0.3, 0.18)
const OPEN_COLOR := Color(0.45, 0.3, 0.18, 0.2)

## Tamanho no chão em tiles/metros: x = largura (X), y = profundidade (Z).
@export var size_tiles: Vector2i = Vector2i(1, 3)
## false = só abre por mecanismo (alavanca); a mão recebe `locked_message`.
@export var opens_by_hand: bool = false
@export var is_open: bool = false
@export_multiline var locked_message: String = "Trancada. Deve haver um mecanismo em algum lugar."

var _material: StandardMaterial3D

@onready var _shape: CollisionShape3D = $CollisionShape
@onready var _visual: MeshInstance3D = $Visual
@onready var _interactable: Interactable = $Interactable
@onready var _interact_shape: CollisionShape3D = $Interactable/CollisionShape


func _ready() -> void:
	var size := Vector3(size_tiles.x, HEIGHT, size_tiles.y)
	var body := BoxShape3D.new()
	body.size = size
	_shape.shape = body
	_shape.position = Vector3(0, HEIGHT / 2.0, 0)
	var reach := BoxShape3D.new()
	reach.size = size + Vector3(1.0, 0.0, 1.0)  # dá para usar encostado na porta
	_interact_shape.shape = reach
	_interact_shape.position = _shape.position
	var mesh := BoxMesh.new()
	mesh.size = size
	_visual.mesh = mesh
	_visual.position = _shape.position
	_material = (_visual.material_override as StandardMaterial3D).duplicate()
	_visual.material_override = _material
	_interactable.prompt_offset = Vector3(0, HEIGHT + 0.4, 0)
	_interactable.handler = _on_interact
	_apply_state()


func set_open(value: bool) -> void:
	if value == is_open:
		return
	is_open = value
	_apply_state()
	if is_open:
		opened.emit()
	else:
		closed.emit()


func _on_interact(_by: Player) -> String:
	if not opens_by_hand:
		return "" if is_open else locked_message
	set_open(not is_open)
	return ""


func _apply_state() -> void:
	# set_deferred: mudar colisão no meio do passo de física dá erro na Godot.
	_shape.set_deferred("disabled", is_open)
	_material.albedo_color = OPEN_COLOR if is_open else CLOSED_COLOR
	_interactable.prompt_text = "Fechar" if is_open else "Abrir"
	# Porta de mecanismo já aberta não tem mais o que fazer com a mão.
	_interactable.enabled = opens_by_hand or not is_open
