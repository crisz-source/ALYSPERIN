class_name SignPost
extends StaticBody3D
## Placa (PROVISÓRIA: sem arte), 3D. Interagir mostra o texto no HUD.

@export_multiline var message: String = ""

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.prompt_text = "Ler"
	_interactable.handler = func(_by: Player) -> String: return message
