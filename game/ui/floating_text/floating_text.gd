class_name FloatingText
extends Label
## Texto curto que aparece no mundo, sobe e some (ex.: "Esquiva perfeita!").
##
## Só apresentação: quem cria decide quando; o texto não afeta o jogo.
## Usa top_level para ficar parado no mundo mesmo se quem criou continuar andando.

## Pixels por segundo que o texto sobe.
@export var rise_speed: float = 18.0
## Segundos até sumir.
@export var lifetime: float = 0.9

var _age: float = 0.0
var _anchor: Vector2 = Vector2.ZERO


## Cria o texto centralizado em world_position, como filho de `owner_node`
## (some junto com ele se a cena for trocada).
static func spawn(owner_node: Node, message: String, world_position: Vector2, color: Color = Color.WHITE) -> FloatingText:
	var label := FloatingText.new()
	label.text = message
	label.modulate = color
	label._anchor = world_position
	owner_node.add_child(label)
	return label


func _ready() -> void:
	top_level = true
	z_index = 10
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 10)
	add_theme_constant_override("outline_size", 3)
	add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	_place()


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	_place()
	# Some na segunda metade da vida.
	var fade_start: float = lifetime * 0.5
	modulate.a = 1.0 - clampf((_age - fade_start) / (lifetime - fade_start), 0.0, 1.0)


func _place() -> void:
	# Centraliza pelo tamanho do texto e arredonda para não borrar a pixel art.
	var size_now: Vector2 = get_combined_minimum_size()
	global_position = (_anchor + Vector2(0, -rise_speed * _age) - size_now / 2.0).round()
