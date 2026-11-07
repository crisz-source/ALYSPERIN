extends Node2D
## Arena de teste (PROVISÓRIA): liga a barra de vida do jogador, faz os
## inimigos voltarem alguns segundos depois de morrer e reinicia a arena
## quando o jogador morre. Serve para testar o combate em loop.

@export var enemy_scene: PackedScene
## Segundos até um inimigo derrotado reaparecer no mesmo lugar.
@export var enemy_respawn_delay: float = 4.0
## Segundos entre a morte do jogador e o reinício da arena.
@export var restart_delay: float = 2.0

@onready var _player: Player = $Entities/Player
@onready var _entities: Node2D = $Entities
@onready var _health_fill: ColorRect = $Hud/PlayerHealth/Fill
@onready var _status_label: Label = $Hud/StatusLabel


func _ready() -> void:
	_player.health.health_changed.connect(_on_player_health_changed)
	_player.died.connect(_on_player_died)
	_status_label.visible = false
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


func _on_player_health_changed(current: int, maximum: int) -> void:
	_health_fill.scale.x = float(current) / float(maximum)


func _on_player_died() -> void:
	_status_label.visible = true
	get_tree().create_timer(restart_delay).timeout.connect(_restart)


func _restart() -> void:
	get_tree().reload_current_scene()
