@tool
extends Node2D
## PROVISÓRIO: chão quadriculado para enxergar o movimento da câmera.
## Será substituído por um TileMapLayer com arte real na Fase 4.

@export var area_size: Vector2i = Vector2i(1024, 576)
@export var cell_size: int = 32
@export var color_a: Color = Color(0.16, 0.17, 0.2)
@export var color_b: Color = Color(0.19, 0.2, 0.24)


func _draw() -> void:
	var row: int = 0
	for y: int in range(0, area_size.y, cell_size):
		var column: int = 0
		for x: int in range(0, area_size.x, cell_size):
			var is_even: bool = (row + column) % 2 == 0
			draw_rect(Rect2(x, y, cell_size, cell_size), color_a if is_even else color_b)
			column += 1
		row += 1
