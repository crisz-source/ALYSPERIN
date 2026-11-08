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
## Disciplinas oferecidas ao começar. Vazio = não pergunta (ex.: arena de teste).
@export var discipline_options: Array[DisciplineData] = []

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
	_ask_discipline()


func _ask_discipline() -> void:
	if discipline_options.is_empty() or player.discipline != null or not has_node("DisciplineSelectScreen"):
		return
	var screen: DisciplineSelectScreen = $DisciplineSelectScreen
	player.input_blocked = true
	screen.chosen.connect(_on_discipline_chosen, CONNECT_ONE_SHOT)
	screen.open(discipline_options)


func _on_dialogue_requested(speaker: String, lines: Array[String], on_finished: Callable) -> void:
	var box: DialogueBox = $DialogueBox
	player.input_blocked = true
	box.start(speaker, lines, func() -> void:
		player.input_blocked = false
		if on_finished.is_valid():
			on_finished.call()
	)


func _on_discipline_chosen(chosen: DisciplineData) -> void:
	player.apply_discipline(chosen)
	player.input_blocked = false


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


## PROVISÓRIO: o proprietário ainda vai definir o que "Não" faz.
func _on_decline() -> void:
	death_screen.show_note("A opção \"Não\" ainda será definida.")
