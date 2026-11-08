extends Node
## Testes da Fase 5 (bloco 4): tela de inventário e HUD de nível.

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const AREA := "res://game/world/areas/prototype_area/prototype_area.tscn"
const D := "res://game/items/data/"

var _failures: int = 0
var _passes: int = 0
var area: Node
var player: Player
var fake: Node
var screen: InventoryScreen


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


func _action(name: String) -> void:
	var ev := InputEventAction.new()
	ev.action = name
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = name
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _slot(i: int) -> Control:
	return screen._bag_grid.get_child(i)


func _run() -> void:
	Hitstop.enabled = false
	area = load(AREA).instantiate()
	get_tree().root.add_child(area)
	get_tree().current_scene = area
	player = area.get_node("Entities/Player")
	screen = area.get_node("InventoryScreen")
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	_skip_class_select()
	for n: Node in area.get_node("Entities").get_children():
		if n is BasicEnemy:
			n.set_physics_process(false)
	await frames(2)

	print("--- 1. abrir e fechar ---")
	check("começa fechada", not screen.is_open and not screen._root.visible)
	await _action("inventory")
	check("I abre", screen.is_open and screen._root.visible)
	check("jogador bloqueado enquanto aberta", player.input_blocked)
	fake.press_attack()
	await frames(3)
	check("clique não ataca com a tela aberta", player.state == Player.State.MOVE)
	check("8 vagas desenhadas", screen._bag_grid.get_child_count() == 8)
	await _action("inventory")
	check("I fecha e libera o jogador", not screen.is_open and not player.input_blocked)
	await _action("inventory")
	await _action("pause")
	check("Esc também fecha", not screen.is_open)

	print("--- 2. vagas e ações ---")
	screen.set_open(true)
	await frames(1)
	var herb_icon: ColorRect = _slot(0).get_node("Icon")
	check("erva na vaga 0 com a cor dela", herb_icon.visible and herb_icon.color == item("healing_herb").icon_color)
	check("vaga vazia sem ícone", not (_slot(5).get_node("Icon") as ColorRect).visible)
	var wbar: ColorRect = screen._weapon_slot.get_node("Durability")
	check("arma equipada com barra de durabilidade cheia", wbar.visible and is_equal_approx(wbar.size.x, 26.0))
	player.equipment.weapon.durability = 20
	player.equipment.notify_wear()
	await frames(1)
	check("barra encolhe e fica vermelha com 25%", is_equal_approx(wbar.size.x, 6.5) and wbar.color.r > 0.8, "w=%.1f" % wbar.size.x)

	player.health.current_health = 50
	# Clique de mouse real na vaga 0, passando pelo sistema de interface.
	var center: Vector2 = _slot(0).get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	press.global_position = center
	get_viewport().push_input(press)
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	get_viewport().push_input(release)
	await frames(2)
	check("clique real na erva: cura e gasta", player.health.current_health == 80 and player.inventory.count_of(item("healing_herb")) == 0,
		"vida=%d" % player.health.current_health)
	check("vaga fica vazia na tela", not herb_icon.visible)

	player.inventory.set_slot(1, ItemStack.create(item("heavy_axe")))
	await frames(1)
	screen.click_bag_slot(1, MOUSE_BUTTON_LEFT)
	await frames(1)
	check("clicar no machado equipa", player.equipment.weapon_data() == item("heavy_axe"))
	check("espada volta para a vaga 1 (desenhada)", (_slot(1).get_node("Icon") as ColorRect).color == item("short_sword").icon_color * Color(1, 1, 1))
	check("ícone da arma equipada atualiza", (screen._weapon_slot.get_node("Icon") as ColorRect).color == item("heavy_axe").icon_color)

	screen._hover(player.equipment.weapon)
	check("detalhes: nome e durabilidade", screen._detail_name.text == "Machado pesado" and screen._detail_text.text.contains("Durabilidade 45 / 45")
		and screen._detail_text.text.contains("lenta"), screen._detail_text.text)

	var dropped := [0]
	player.item_dropped.connect(func(_s: ItemStack, _p: Vector3) -> void: dropped[0] += 1)
	screen.click_bag_slot(1, MOUSE_BUTTON_RIGHT)
	await frames(1)
	check("botão direito descarta", dropped[0] == 1 and player.inventory.get_slot(1) == null)

	screen.click_shield_slot()
	await frames(1)
	check("clicar no escudo equipado tira", player.equipment.shield == null and player.inventory.count_of(item("wooden_shield")) == 1)

	print("--- 3. progressão na tela e no HUD ---")
	player.gain_xp(30)
	await frames(1)
	check("tela mostra vida e mana do nível 2", screen._health_label.text == "Vida: %d / 108     Mana: %d / 32" % [player.health.current_health, player.mana.current()], screen._health_label.text)
	check("tela mostra o dano do nível (+10%)", screen._growth_label.text == "Dano do nível: +10%", screen._growth_label.text)
	var hud: Hud = area.get_node("Hud")
	check("HUD mostra 'Nv 2 · GS'", (hud.get_node("LevelLabel") as Label).text.begins_with("Nv 2 · GS "), (hud.get_node("LevelLabel") as Label).text)
	player.gain_xp(30)
	check("barra de experiência do HUD (30/60)", is_equal_approx((hud.get_node("XpBar/Fill") as ColorRect).scale.x, 0.5))
	screen.set_open(false)

	print("--- 4. morto não abre ---")
	player.health.apply_damage(DamageInfo.new(999, Vector3.ZERO, null))
	await frames(2)
	await _action("inventory")
	check("com o jogador morto, I não abre", not screen.is_open)

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)


## A área pede a classe ao começar; estes testes seguem sem escolher.
func _skip_class_select() -> void:
	var s: Node = get_tree().current_scene
	if s and s.has_node("ClassSelectScreen"):
		(s.get_node("ClassSelectScreen") as ClassSelectScreen).close()
		(s.get_node("Entities/Player") as Player).input_blocked = false
