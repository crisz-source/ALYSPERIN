extends GameArea
## Arena de teste (PROVISÓRIA): inimigos voltam alguns segundos depois de
## morrer, para testar o combate em loop. Morte e "continuar" vêm de GameArea.

@export var enemy_scene: PackedScene
## Segundos até um inimigo derrotado reaparecer no mesmo lugar.
@export var enemy_respawn_delay: float = 4.0
## Tamanho da arena em pixels (a câmera não mostra nada fora disto).
@export var bounds: Rect2 = Rect2(0, 0, 1024, 576)


func _ready() -> void:
	super()
	for node: Node in get_tree().get_nodes_in_group(&"arena_enemies"):
		_watch_enemy(node as BasicEnemy)


func map_bounds() -> Rect2:
	return bounds


func _watch_enemy(enemy: BasicEnemy) -> void:
	var spawn_position: Vector2 = enemy.global_position
	enemy.died.connect(_on_enemy_died.bind(spawn_position))


## Timers via conexão de sinal (e não await): se a arena for trocada antes do
## tempo acabar, a conexão some junto com ela e nada roda sobre um nó liberado.
func _on_enemy_died(spawn_position: Vector2) -> void:
	get_tree().create_timer(enemy_respawn_delay).timeout.connect(_respawn_enemy.bind(spawn_position))


func _respawn_enemy(spawn_position: Vector2) -> void:
	if player.health.is_dead:
		return
	var enemy: BasicEnemy = enemy_scene.instantiate()
	enemy.position = spawn_position
	enemy.add_to_group(&"arena_enemies")
	entities.add_child(enemy)
	_watch_enemy(enemy)
