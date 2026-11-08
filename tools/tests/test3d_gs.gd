extends Node
## Testes da Etapa D: Gear Score, escala de dano, teto de sync, óleos de arma (elemento).

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"
const ITEMS := "res://game/items/data/"
const CLASSES := "res://game/classes/data/"

var _failures: int = 0
var _passes: int = 0
var arena: GameArea
var player: Player
var fake: Node
var enemy: BasicEnemy
var hud: Hud


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
	return load(ITEMS + name + ".tres")


func _run() -> void:
	Hitstop.enabled = false
	arena = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	enemy = arena.get_node("Entities/BasicEnemy1")
	hud = arena.get_node("Hud")
	for n: Node in arena.get_node("Entities").get_children():
		if n is BasicEnemy:
			n.set_physics_process(false)
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	await frames(3)

	print("--- 1. GS dos itens e do personagem ---")
	check("itens iniciais: GS 100 (espada, escudo de madeira, cajado)", (item("short_sword") as WeaponData).gear_score == 100
		and (item("wooden_shield") as ShieldData).gear_score == 100 and (item("apprentice_staff") as WeaponData).gear_score == 100)
	check("GS 100 não muda o dano: espada nível 1 = 10", player.current_attack_damage(0) == 10, str(player.current_attack_damage(0)))
	player.apply_class(load(CLASSES + "guardian.tres"))
	check("Guardião (malho 120 + escudo 120) = GS 120", player.gear_score() == 120, str(player.gear_score()))
	player.equipment.unequip_shield()
	check("espaço vazio conta 0: (120 + 0) / 2 = 60", player.gear_score() == 60, str(player.gear_score()))
	player.apply_class(load(CLASSES + "devotee.tres"))
	check("Devoto conta só a arma (sem escudo): GS 100", player.gear_score() == 100, str(player.gear_score()))

	print("--- 2. escala de dano ---")
	player.apply_class(load(CLASSES + "guardian.tres"))
	var maul_dmg: int = player.current_attack_damage(0)
	player.equipment.equip(ItemStack.create(item("veteran_maul")))
	player.equipment.equip(ItemStack.create(item("veteran_shield")))
	check("veterano: GS 320", player.gear_score() == 320, str(player.gear_score()))
	check("multiplicador do GS 320 = x1,22", is_equal_approx(Player.gs_damage_multiplier(320), 1.22))
	check("dano do malho veterano = 14 x 1,22 = 17", player.current_attack_damage(0) == 17, "%d (malho comum %d)" % [player.current_attack_damage(0), maul_dmg])

	print("--- 3. teto de sync (base para a masmorra) ---")
	player.sync_gs_cap = 300
	player.sync_level_cap = 24
	player.gain_xp(200000)
	await frames(2)
	check("GS real continua 320, efetivo 300", player.gear_score() == 320 and player.effective_gear_score() == 300)
	check("nível real 60, efetivo 24", player.stats.level == 60 and player.effective_level() == 24)
	await get_tree().process_frame
	var label: String = (hud.get_node("LevelLabel") as Label).text
	check("HUD mostra real e sincronizado", label.contains("Nv 60 · GS 320") and label.contains("sinc.: Nv 24 · GS 300"), label)
	player.sync_gs_cap = 0
	player.sync_level_cap = 0
	await get_tree().process_frame
	check("sem teto: HUD sem 'sinc.'", not (hud.get_node("LevelLabel") as Label).text.contains("sinc."))

	print("--- 4. óleos de arma ---")
	player.inventory.set_slot(7, ItemStack.create(item("fire_oil")))
	var msg: String = player.use_inventory_slot(7)
	check("óleo de fogo: arma com Fogo por 60 s", player.weapon_element == &"fire" and msg == "Arma com Fogo por 60 s." and player.inventory.get_slot(7) == null, msg)
	await get_tree().process_frame
	check("HUD mostra [Fogo]", (hud.get_node("LevelLabel") as Label).text.contains("[Fogo]"))
	var seen: Array[StringName] = []
	enemy.health.damaged.connect(func(info: DamageInfo) -> void: seen.append(info.element))
	enemy.global_position = player.global_position + Vector3(0, 0, -1.2)
	enemy.health.current_health = 999
	fake.aim_direction = Vector3.FORWARD
	fake.press_attack()
	await frames(25)
	check("golpe com óleo leva o elemento Fogo", seen.has(&"fire"), str(seen))
	player._weapon_element_left = 0.02
	await frames(3)
	check("óleo acaba sozinho", player.weapon_element == &"")
	player.equipment.unequip_weapon()
	player.inventory.set_slot(7, ItemStack.create(item("ice_oil")))
	check("sem arma: óleo recusado e não gasto", player.use_inventory_slot(7) == "Equipe uma arma para usar o óleo." and player.inventory.get_slot(7) != null)

	print("--- 5. menu de testes ---")
	var menu: TestMenu = arena.find_children("*", "TestMenu", true, false)[0]
	player.inventory.set_slot(7, null)
	menu.give_veteran_gear()
	check("menu: equipamento GS 320 e óleos na bolsa", player.gear_score() == 320 and player.inventory.count_of(item("fire_oil")) >= 1)

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
