extends Node
## Testes: consumíveis na barra (arrastar/usar/tirar), números de dano,
## barra de vida dos monstros sempre visível, inventário na tecla I.

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const AREA := "res://game/world/areas/prototype_area/prototype_area.tscn"
const D := "res://game/items/data/"

var _failures: int = 0
var _passes: int = 0
var area: Node
var player: Player
var fake: Node


func _ready() -> void:
	_run.call_deferred()


func check(label: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + label + ("" if detail.is_empty() else " | " + detail))
	if ok:
		_passes += 1
	else:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func item(name: String) -> ItemData:
	return load(D + name + ".tres")


func _run() -> void:
	Hitstop.enabled = false
	area = load(AREA).instantiate()
	get_tree().root.add_child(area)
	get_tree().current_scene = area
	player = area.get_node("Entities/Player")
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	var select: ClassSelectScreen = area.get_node("ClassSelectScreen")
	select.choose_class(1)  # Devoto
	for n: Node in area.get_node("Entities").get_children():
		if n is BasicEnemy:
			n.set_physics_process(false)
	await frames(2)
	var hud: Hud = area.get_node("Hud")
	var screen: InventoryScreen = area.get_node("InventoryScreen")

	print("--- 1. tecla I ---")
	var ev := InputEventAction.new()
	ev.action = "inventory"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	check("ação 'inventory' abre a tela", screen.is_open)
	var events: Array = InputMap.action_get_events("inventory")
	check("'inventory' mapeada na tecla I", events.size() == 1 and (events[0] as InputEventKey).physical_keycode == KEY_I)
	check("'interact' mapeada na tecla F", (InputMap.action_get_events("interact")[0] as InputEventKey).physical_keycode == KEY_F)

	print("--- 2. arrastar consumível para a barra ---")
	var herb: ItemData = item("healing_herb")
	var herb_slot: int = -1
	for i in player.inventory.slots.size():
		var st: ItemStack = player.inventory.get_slot(i)
		if st and st.item == herb:
			herb_slot = i
	var data: Variant = screen.drag_payload(herb_slot)
	check("arrastar erva gera dados do item", data is Dictionary and data["item"] == herb)
	var sword_slot := 7
	player.inventory.set_slot(sword_slot, ItemStack.create(item("short_sword")))
	check("arma não pode ser arrastada para a barra", screen.drag_payload(sword_slot) == null)
	var box3: ColorRect = hud.get_node("AbilityBar/Ability7")
	var box1: ColorRect = hud.get_node("AbilityBar/Ability1")
	check("espaço com magia recusa item", not player.assign_hotbar_item(0, herb))
	check("espaço vazio aceita (pelo mesmo caminho do soltar)", player.assign_hotbar_item(6, herb))
	await frames(1)
	box3 = hud.get_node("AbilityBar/Ability7")
	check("espaço 7 mostra a erva e a quantidade", box3.color == herb.icon_color and (box3.get_node("Count") as Label).text == "x1",
		(box3.get_node("Count") as Label).text if box3.has_node("Count") else "sem contador")

	print("--- 3. usar pela tecla ---")
	screen.set_open(false)
	player.health.current_health = 40
	fake.press_ability(6)
	await frames(2)
	check("tecla 7 usa a erva (+30)", player.health.current_health == 70 and player.inventory.count_of(herb) == 0, str(player.health.current_health))
	await frames(1)
	box3 = hud.get_node("AbilityBar/Ability7")
	check("contador vai a x0 e o atalho continua", player.hotbar_items[6] == herb and (box3.get_node("Count") as Label).text == "x0")
	fake.press_ability(6)
	await frames(2)
	check("sem erva: avisa", (hud.get_node("MessageBox/Text") as Label).text == "Você não tem Erva medicinal.")
	player.inventory.add(ItemStack.create(herb, 3))
	await frames(1)
	box3 = hud.get_node("AbilityBar/Ability7")
	check("achou mais: contador volta (x3)", (box3.get_node("Count") as Label).text == "x3")
	player.clear_hotbar_slot(6)
	await frames(1)
	box3 = hud.get_node("AbilityBar/Ability7")
	check("tirar da barra: espaço vazio de novo", player.hotbar_items[6] == null and not box3.has_node("Count"))
	player.assign_hotbar_item(10, item("mana_potion"))
	player.mana._current = 0.0
	fake.press_ability(10)
	await frames(2)
	check("poção de mana na F2 funciona", player.mana.current() == 25, str(player.mana.current()))

	print("--- 4. barra de vida dos monstros e números de dano ---")
	var enemy: BasicEnemy = area.get_node("Entities/BasicEnemy1")
	var bar: HealthBar3D = enemy.get_node("HealthBar")
	check("barra de vida visível com vida cheia", bar.visible)
	var before: int = player.get_child_count()
	enemy.health.apply_damage(DamageInfo.new(12, Vector3.ZERO, player))
	await frames(1)
	var number: FloatingText = null
	for c: Node in player.get_children():
		if c is FloatingText and c.text == "12":
			number = c
	check("número '12' aparece sobre o inimigo", number != null and number.global_position.distance_to(enemy.global_position) < 2.5)
	check("barra encolhe (18/30)", is_equal_approx(bar.ratio, 0.6), "%.2f" % bar.ratio)
	enemy.health.apply_damage(DamageInfo.new(40, Vector3.ZERO, player))
	await frames(1)
	var big: FloatingText = null
	for c: Node in player.get_children():
		if c is FloatingText and c.text == "40":
			big = c
	check("dano maior = número maior", big != null and number != null and big.font_size > number.font_size, "%d vs %d" % [big.font_size if big else 0, number.font_size if number else 0])
	check("barra some quando o inimigo morre", not bar.visible)
	await frames(30)
	check("número do golpe final continua após o inimigo sumir", is_instance_valid(big))
	player.health._invulnerable_time = 0.0
	player.health.apply_damage(DamageInfo.new(7, Vector3.ZERO, null))
	await frames(1)
	var red: FloatingText = null
	for c: Node in player.get_children():
		if c is FloatingText and c.text == "7":
			red = c
	check("dano no jogador: número vermelho", red != null and red.modulate.r > 0.9 and red.modulate.g < 0.5)

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
