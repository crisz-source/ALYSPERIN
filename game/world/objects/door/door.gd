class_name Door
extends StaticBody2D
## Porta (PROVISÓRIA: retângulo sem arte). Fechada, bloqueia passagem e visão;
## aberta, não colide.
##
## Pode abrir com a mão (E) ou só por mecanismo (alavanca chama set_open).
## A colisão e o visual são montados pelo script a partir de `size_tiles`, para
## cada porta ter o próprio tamanho sem compartilhar a mesma forma.

signal opened
signal closed

const TILE: float = 16.0
const CLOSED_COLOR := Color(0.45, 0.3, 0.18)
const OPEN_COLOR := Color(0.45, 0.3, 0.18, 0.25)

## Tamanho em tiles. Vertical (1x3) fecha um corredor horizontal.
@export var size_tiles: Vector2i = Vector2i(1, 3)
## false = só abre por mecanismo (alavanca); a mão recebe `locked_message`.
@export var opens_by_hand: bool = false
@export var is_open: bool = false
@export_multiline var locked_message: String = "Trancada. Deve haver um mecanismo em algum lugar."

@onready var _shape: CollisionShape2D = $CollisionShape
@onready var _visual: ColorRect = $Visual
@onready var _interactable: Interactable = $Interactable
@onready var _interact_shape: CollisionShape2D = $Interactable/CollisionShape


func _ready() -> void:
	var size_px: Vector2 = Vector2(size_tiles) * TILE
	var body := RectangleShape2D.new()
	body.size = size_px
	_shape.shape = body
	var reach := RectangleShape2D.new()
	reach.size = size_px + Vector2(12, 12)  # dá para usar encostado na porta
	_interact_shape.shape = reach
	_visual.position = -size_px / 2.0
	_visual.size = size_px
	_interactable.prompt_offset = Vector2(0, -size_px.y / 2.0 - 8.0)
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
	_visual.color = OPEN_COLOR if is_open else CLOSED_COLOR
	_interactable.prompt_text = "Fechar" if is_open else "Abrir"
	# Porta de mecanismo já aberta não tem mais o que fazer com a mão.
	_interactable.enabled = opens_by_hand or not is_open
