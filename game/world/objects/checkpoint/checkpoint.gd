class_name Checkpoint
extends Node2D
## Ponto de descanso (PROVISÓRIO: losango azul sem arte). Interagir marca aqui
## como o lugar onde o jogador volta ao continuar depois da morte e restaura
## vida e mana.

const IDLE_COLOR := Color(0.35, 0.6, 1.0)
const ACTIVE_COLOR := Color(0.6, 0.95, 1.0)
const MESSAGE := "Ponto de descanso marcado. Vida e mana restauradas."

@onready var _interactable: Interactable = $Interactable
@onready var _crystal: Polygon2D = $CrystalPlaceholder


func _ready() -> void:
	_interactable.prompt_text = "Descansar"
	_interactable.handler = _on_interact
	_crystal.color = IDLE_COLOR


func _on_interact(by: Player) -> String:
	by.rest_at(global_position + Vector2(0, 14))
	_crystal.color = ACTIVE_COLOR
	return MESSAGE
