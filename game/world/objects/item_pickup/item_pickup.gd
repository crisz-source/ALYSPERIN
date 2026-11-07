class_name ItemPickup
extends Node2D
## Item caído no chão (PROVISÓRIO: quadrado da cor do item, sem ícone).
## Interagir (E) põe na bolsa; o que não couber continua no chão.

const SCENE_PATH := "res://game/world/objects/item_pickup/item_pickup.tscn"
const BOB_HEIGHT: float = 1.5
const BOB_SPEED: float = 3.0

@export var stack: ItemStack

var _clock: float = 0.0

@onready var _interactable: Interactable = $Interactable
@onready var _visual: Polygon2D = $IconPlaceholder


## Cria um item no chão (usado ao descartar da bolsa). `parent` é o nó das
## entidades da área, para entrar na ordenação por profundidade.
static func spawn(parent: Node, p_stack: ItemStack, at_position: Vector2) -> ItemPickup:
	var pickup: ItemPickup = (load(SCENE_PATH) as PackedScene).instantiate()
	pickup.stack = p_stack
	pickup.position = at_position
	parent.add_child(pickup)
	return pickup


func _ready() -> void:
	assert(stack != null and stack.item != null, "ItemPickup '%s' sem item configurado" % name)
	_interactable.handler = _on_interact
	_refresh()


func _process(delta: float) -> void:
	_clock += delta
	# Flutua 1-2 px para chamar atenção; arredondado para não borrar a pixel art.
	_visual.position.y = roundf(-4.0 + sin(_clock * BOB_SPEED) * BOB_HEIGHT)


func _on_interact(by: Player) -> String:
	var before: int = stack.count
	var left: int = by.pick_up(stack)
	if left == before:
		return "Inventário cheio."
	var taken: int = before - left
	var label: String = _describe(stack.item, taken)
	if left > 0:
		stack.count = left
		_refresh()
		return "Pegou %s. O resto não coube." % label
	queue_free()
	return "Pegou %s." % label


func _refresh() -> void:
	_visual.color = stack.item.icon_color
	_interactable.prompt_text = "Pegar " + _describe(stack.item, stack.count)


static func _describe(item: ItemData, count: int) -> String:
	return item.display_name if count == 1 else "%s x%d" % [item.display_name, count]
