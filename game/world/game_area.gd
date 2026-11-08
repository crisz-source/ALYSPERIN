class_name GameArea
extends Node3D
## Base de toda área jogável (arena, mapas, dungeons): liga HUD, inventário e
## tela de morte ao jogador, põe no chão o que ele descarta e cuida do
## "continuar" depois da morte.
##
## Estrutura esperada na cena: Entities/Player, Hud, InventoryScreen, DeathScreen.
## Áreas filhas que precisarem de _ready chamam super().
##
## Continuar = o jogador volta ao início da área com vida e mana cheias e
## MANTÉM itens, equipamento e experiência. Inimigos vivos voltam ao lugar de
## origem com vida cheia; derrotados continuam derrotados; baús abertos continuam abertos.

## Segundos entre a morte e a tela "Você morreu!".
@export var death_screen_delay: float = 1.2
## Classes oferecidas ao começar. Vazio = não pergunta (ex.: arena de teste).
@export var class_options: Array[ClassData] = []
@export_group("Masmorra")
## Masmorra com entrada nesta área (vazio = nenhuma).
@export var dungeon: DungeonData
@export var dungeon_entrance_position: Vector3 = Vector3.ZERO

## Longe da área: a masmorra é montada aqui, na mesma cena (o jogador e tudo
## que ele carrega continuam os mesmos; sem troca de cena).
const DUNGEON_ORIGIN := Vector3(0, 0, -600)

## Masmorra em andamento (null = fora).
var current_dungeon: DungeonMap = null
var _return_point: Vector3 = Vector3.ZERO
var _area_respawn_point: Vector3 = Vector3.ZERO
var _dungeon_enemies: Array[BasicEnemy] = []

@onready var player: Player = $Entities/Player
@onready var entities: Node3D = $Entities
@onready var hud: Hud = $Hud
@onready var inventory_screen: InventoryScreen = $InventoryScreen
@onready var death_screen: DeathScreen = $DeathScreen


func _ready() -> void:
	hud.bind_player(player)
	inventory_screen.bind_player(player)
	player.died.connect(_on_player_died)
	player.item_dropped.connect(func(stack: ItemStack, at: Vector3) -> void: ItemPickup.spawn(entities, stack, at))
	death_screen.continue_requested.connect(continue_after_death)
	death_screen.decline_requested.connect(_on_decline)
	player.dialogue_requested.connect(_on_dialogue_requested)
	# Menu de testes (tecla P): ferramenta de desenvolvimento, criada por código.
	var test_menu := TestMenu.new()
	test_menu.name = "TestMenu"
	add_child(test_menu)
	test_menu.bind(self)
	# Console de administrador (Enter): /add players N, /add mob N, /boss, /help.
	var console := AdminConsole.new()
	console.name = "AdminConsole"
	add_child(console)
	console.bind(self)
	if dungeon:
		var entrance := DungeonEntrance.create(dungeon)
		entities.add_child(entrance)
		entrance.global_position = dungeon_entrance_position
		entrance.enter_requested.connect(func(_by: Player, d: DungeonData) -> void: enter_dungeon(d))
	_ask_class()


func _ask_class() -> void:
	if class_options.is_empty() or player.player_class != null or not has_node("ClassSelectScreen"):
		return
	var screen: ClassSelectScreen = $ClassSelectScreen
	player.input_blocked = true
	screen.chosen.connect(_on_class_chosen, CONNECT_ONE_SHOT)
	screen.open(class_options)


func _on_dialogue_requested(speaker: String, lines: Array[String], on_finished: Callable) -> void:
	var box: DialogueBox = $DialogueBox
	player.input_blocked = true
	box.start(speaker, lines, func() -> void:
		player.input_blocked = false
		if on_finished.is_valid():
			on_finished.call()
	)


func _on_class_chosen(chosen_class: ClassData) -> void:
	player.apply_class(chosen_class)
	player.input_blocked = false


## Leva o jogador para a masmorra (sincronizado). Devolve o motivo se não puder.
func enter_dungeon(data: DungeonData) -> String:
	var refusal: String = data.entry_refusal(player.stats.level, player.gear_score())
	if not refusal.is_empty() or current_dungeon:
		return refusal
	current_dungeon = DungeonMap.new()
	current_dungeon.data = data
	add_child(current_dungeon)
	current_dungeon.global_position = DUNGEON_ORIGIN
	current_dungeon.exit_requested.connect(func(_by: Player) -> void: exit_dungeon())
	var scene: PackedScene = load(ENEMY_SCENE_PATH)
	for i in current_dungeon.enemy_points().size():
		var enemy: BasicEnemy = scene.instantiate()
		enemy.name = "Ruinas%d" % (i + 1)
		entities.add_child(enemy)
		enemy.global_position = current_dungeon.enemy_points()[i]
		enemy.scale_stats(data.enemy_health, data.enemy_damage, data.enemy_xp)
		enemy.set("_spawn_position", enemy.global_position)
		_dungeon_enemies.append(enemy)
	_return_point = player.global_position
	_area_respawn_point = player.respawn_point
	player.apply_sync(data.level_cap, data.gs_cap)
	player.health.heal(player.health.max_health)
	player.self_revive_available = true
	player.respawn_point = current_dungeon.start_point()
	player.global_position = current_dungeon.start_point()
	player.velocity = Vector3.ZERO
	player.message_requested.emit("%s — sincronizado: nível %d, GS %d." % [data.display_name, player.effective_level(), player.effective_gear_score()])
	return ""


## Volta para a área: tira o sync, remove o mapa e os monstros da masmorra.
func exit_dungeon() -> void:
	if current_dungeon == null:
		return
	for enemy: BasicEnemy in _dungeon_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_dungeon_enemies.clear()
	for node: Node in get_tree().get_nodes_in_group(&"bosses"):
		node.queue_free()
	current_dungeon.queue_free()
	current_dungeon = null
	player.clear_sync()
	player.respawn_point = _area_respawn_point
	player.global_position = _return_point
	player.velocity = Vector3.ZERO
	player.message_requested.emit("Você saiu da masmorra.")


func continue_after_death() -> void:
	for node: Node in entities.get_children():
		var enemy := node as BasicEnemy
		if enemy and not enemy.health.is_dead:
			enemy.reset_to_spawn()
	player.respawn(player.respawn_point)
	death_screen.close()


## Timer via conexão de sinal (e não await): se a cena for trocada antes, a
## conexão some junto e nada roda sobre um nó já liberado.
func _on_player_died() -> void:
	inventory_screen.set_open(false)
	get_tree().create_timer(death_screen_delay).timeout.connect(death_screen.open)


# --- Ferramentas de teste (menu P e console de administrador) -----------------

const ENEMY_SCENE_PATH := "res://game/actors/enemies/basic_enemy/basic_enemy.tscn"
## Limite por comando, para não travar o jogo com um número enorme.
const MAX_SPAWN: int = 20


## Cria `count` aliados de teste (feridos) à frente do jogador.
func spawn_test_allies(count: int, wounded_health: int = 40) -> Array[AllyDummy]:
	var created: Array[AllyDummy] = []
	for i in mini(count, MAX_SPAWN):
		var ally := AllyDummy.new()
		ally.name = "AliadoDeTeste%d" % (get_tree().get_nodes_in_group(AllyDummy.GROUP).size() + 1)
		entities.add_child(ally)
		ally.global_position = _free_spot_near_player(4.0, i, count)
		ally.health.current_health = wounded_health
		ally.health.health_changed.emit(ally.health.current_health, ally.health.max_health)
		created.append(ally)
	return created


## Cria `count` monstros em volta do jogador (eles já começam perseguindo).
func spawn_test_enemies(count: int) -> Array[BasicEnemy]:
	var scene: PackedScene = load(ENEMY_SCENE_PATH)
	var created: Array[BasicEnemy] = []
	for i in mini(count, MAX_SPAWN):
		var enemy: BasicEnemy = scene.instantiate()
		enemy.name = "MonstroDeTeste%d" % (i + 1)
		entities.add_child(enemy)
		enemy.global_position = _free_spot_near_player(7.0, i, count)
		created.append(enemy)
	return created


## Ponto livre (sem parede) num círculo em volta do jogador; se bater em parede,
## tenta mais perto. Último recurso: ao lado do jogador.
func _free_spot_near_player(radius: float, index: int, total: int) -> Vector3:
	var angle: float = TAU * index / maxi(total, 1) + player.camera_rig().rotation.y
	for r: float in [radius, radius * 0.6, radius * 0.35]:
		var spot: Vector3 = player.global_position + Vector3(sin(angle), 0, cos(angle)) * -r
		var query := PhysicsPointQueryParameters3D.new()
		query.position = spot + Vector3.UP * 1.0
		query.collision_mask = 1
		var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, spot + Vector3.UP, 1)
		if get_world_3d().direct_space_state.intersect_point(query).is_empty() 				and get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			return spot
	return player.global_position + Vector3(0.8, 0, 0.8)


## PROVISÓRIO: o proprietário ainda vai definir o que "Não" faz.
func _on_decline() -> void:
	death_screen.show_note("A opção \"Não\" ainda será definida.")
