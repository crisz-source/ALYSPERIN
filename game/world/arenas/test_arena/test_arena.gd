extends Node2D
## Arena de teste (PROVISÓRIA): liga a barra de vida do jogador, faz os
## inimigos voltarem alguns segundos depois de morrer e reinicia a arena
## quando o jogador morre. Serve para testar o combate em loop.

@export var enemy_scene: PackedScene
## Segundos até um inimigo derrotado reaparecer no mesmo lugar.
@export var enemy_respawn_delay: float = 4.0
## Segundos entre a morte do jogador e o reinício da arena.
@export var restart_delay: float = 2.0
## Tamanho da arena em pixels (a câmera não mostra nada fora disto).
@export var bounds: Rect2 = Rect2(0, 0, 1024, 576)

@onready var _player: Player = $Entities/Player
@onready var _entities: Node2D = $Entities
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_hud.bind_player(_player)
	($InventoryScreen as InventoryScreen).bind_player(_player)
	_player.set_camera_bounds(bounds)
	_player.died.connect(_on_player_died)
	_player.item_dropped.connect(func(stack: ItemStack, at: Vector2) -> void: ItemPickup.spawn(_entities, stack, at))
	for node: Node in get_tree().get_nodes_in_group(&"arena_enemies"):
		_watch_enemy(node as BasicEnemy)


func _watch_enemy(enemy: BasicEnemy) -> void:
	var spawn_position: Vector2 = enemy.global_position
	enemy.died.connect(_on_enemy_died.bind(spawn_position))


## Timers via conexão de sinal (e não await): se a arena for reiniciada antes
## do tempo acabar, a conexão some junto com ela e nada roda sobre um nó liberado.
func _on_enemy_died(spawn_position: Vector2) -> void:
	get_tree().create_timer(enemy_respawn_delay).timeout.connect(_respawn_enemy.bind(spawn_position))


func _respawn_enemy(spawn_position: Vector2) -> void:
	if _player.health.is_dead:
		return
	var enemy: BasicEnemy = enemy_scene.instantiate()
	enemy.position = spawn_position
	enemy.add_to_group(&"arena_enemies")
	_entities.add_child(enemy)
	_watch_enemy(enemy)


func _on_player_died() -> void:
	get_tree().create_timer(restart_delay).timeout.connect(_restart)


func _restart() -> void:
	get_tree().reload_current_scene()
