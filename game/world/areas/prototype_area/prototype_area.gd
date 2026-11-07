extends Node2D
## Área de protótipo (PROVISÓRIA: mapa, nome e arte ainda não definidos).
##
## Primeiro mapa com salas e corredores feito de tiles. Serve para testar
## exploração + combate num espaço de verdade: a câmera fica presa às bordas do
## mapa e os inimigos não renascem. Quando o jogador morre, a área recomeça.

## Segundos entre a morte do jogador e o reinício da área.
@export var restart_delay: float = 2.0

@onready var _player: Player = $Entities/Player
@onready var _walls: TileMapLayer = $Walls
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_hud.bind_player(_player)
	_player.set_camera_bounds(map_bounds())
	_player.died.connect(_on_player_died)


## Retângulo do mapa em pixels, calculado a partir das paredes desenhadas.
## Se o mapa for editado no editor, os limites da câmera acompanham sozinhos.
func map_bounds() -> Rect2:
	var used: Rect2i = _walls.get_used_rect()
	var tile_size: Vector2 = Vector2(_walls.tile_set.tile_size)
	return Rect2(Vector2(used.position) * tile_size, Vector2(used.size) * tile_size)


## Timer via conexão de sinal (e não await): se a cena for trocada antes, a
## conexão some junto e nada roda sobre um nó já liberado.
func _on_player_died() -> void:
	get_tree().create_timer(restart_delay).timeout.connect(_restart)


func _restart() -> void:
	get_tree().reload_current_scene()
