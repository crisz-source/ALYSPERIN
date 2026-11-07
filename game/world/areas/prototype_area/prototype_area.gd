extends GameArea
## Área de protótipo (PROVISÓRIA: mapa, nome e arte ainda não definidos).
##
## Primeiro mapa com salas e corredores feito de tiles. Inimigos não renascem;
## ao morrer, o jogador pode continuar do último ponto de descanso (GameArea).

@onready var _walls: TileMapLayer = $Walls


## Retângulo do mapa em pixels, calculado a partir das paredes desenhadas.
## Se o mapa for editado no editor, os limites da câmera acompanham sozinhos.
func map_bounds() -> Rect2:
	var used: Rect2i = _walls.get_used_rect()
	var tile_size: Vector2 = Vector2(_walls.tile_set.tile_size)
	return Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)
