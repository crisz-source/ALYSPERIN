class_name Chest
extends StaticBody2D
## Baú (PROVISÓRIO: caixa sem arte). Interagir abre e passa o conteúdo para a
## bolsa; o que não couber fica guardado para pegar depois.

const CLOSED_LID := Color(0.5, 0.33, 0.18)
const OPEN_LID := Color(0.25, 0.16, 0.09)

## Conteúdo (copiado ao iniciar, para cada baú ter os próprios itens).
@export var contents: Array[ItemStack] = []

var is_open: bool = false
var _items: Array[ItemStack] = []

@onready var _interactable: Interactable = $Interactable
@onready var _lid: ColorRect = $LidPlaceholder


func _ready() -> void:
	for stack: ItemStack in contents:
		if stack and stack.item:
			_items.append(stack.copy())
	_interactable.handler = _on_interact
	_refresh()


## Itens ainda dentro do baú (para testes e para a interface no futuro).
func remaining() -> Array[ItemStack]:
	return _items


func _on_interact(by: Player) -> String:
	is_open = true
	if _items.is_empty():
		_refresh()
		return "Vazio."
	var taken: Array[String] = []
	var kept: Array[ItemStack] = []
	for stack: ItemStack in _items:
		var before: int = stack.count
		var left: int = by.pick_up(stack)
		if left < before:
			taken.append(stack.item.display_name if before - left == 1 else "%s x%d" % [stack.item.display_name, before - left])
		if left > 0:
			stack.count = left
			kept.append(stack)
	_items = kept
	_refresh()
	if taken.is_empty():
		return "Inventário cheio."
	var message: String = "Encontrou: " + ", ".join(taken) + "."
	if not _items.is_empty():
		message += " O resto ficou no baú."
	return message


func _refresh() -> void:
	_lid.color = OPEN_LID if is_open else CLOSED_LID
	_interactable.prompt_text = "Abrir" if not is_open else "Pegar o resto"
	_interactable.enabled = not (is_open and _items.is_empty())
