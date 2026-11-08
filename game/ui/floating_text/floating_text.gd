class_name FloatingText
extends Label3D
## Texto curto que aparece no mundo 3D, sobe e some (ex.: "Esquiva perfeita!",
## números de dano). Sempre virado para a câmera e visível através de paredes.
##
## Só apresentação: quem cria decide quando; o texto não afeta o jogo.
## Usa top_level para ficar parado no mundo mesmo se quem criou continuar andando.

## Metros por segundo que o texto sobe.
@export var rise_speed: float = 1.1
## Segundos até sumir.
@export var lifetime: float = 0.9

var _age: float = 0.0
var _anchor: Vector3 = Vector3.ZERO
var _base_alpha: float = 1.0


## Cria o texto em world_position, como filho de `owner_node` (some junto com
## ele se a cena for trocada). `size` segue a escala da versão 2D (10 = normal).
static func spawn(owner_node: Node, message: String, world_position: Vector3, color: Color = Color.WHITE, size: int = 10) -> FloatingText:
	var label := FloatingText.new()
	label.text = message
	label.font_size = size * 4
	label.modulate = color
	label._anchor = world_position
	owner_node.add_child(label)
	return label


func _ready() -> void:
	top_level = true
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	pixel_size = 0.0008
	outline_size = 10
	outline_modulate = Color(0.05, 0.05, 0.08)
	render_priority = 10
	_base_alpha = modulate.a
	global_position = _anchor


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	global_position = _anchor + Vector3.UP * rise_speed * _age
	# Some na segunda metade da vida.
	var fade_start: float = lifetime * 0.5
	modulate.a = _base_alpha * (1.0 - clampf((_age - fade_start) / (lifetime - fade_start), 0.0, 1.0))
	outline_modulate.a = modulate.a
