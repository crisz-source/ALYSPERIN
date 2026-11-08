extends Node
## Testes da migração 3D: armas, durabilidade, escudo, crescimento por nível,
## itens, Disciplinas (bônus), mana sem recuperação, habilidades (bloqueio por
## nível, recarga, HUD).

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"
const D := "res://game/items/data/"

var _failures: int = 0
var _passes: int = 0
var arena: Node
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


func seconds(s: float) -> void:
	await frames(int(ceil(s * 60.0)))


func item(name: String) -> ItemData:
	return load(D + name + ".tres")


func _reset_player() -> void:
	player.global_position = Vector3(32, 0, 18)
	player.velocity = Vector3.ZERO
	player._change_state(Player.State.MOVE)
	player._combo_step = 0
	player._combo_window_left = 0.0
	player.health.current_health = player.health.max_health
	player.health._invulnerable_time = 0.0
	fake.defend_held = false
	fake.move_direction = Vector2.ZERO
	fake.aim_direction = Vector3.FORWARD


func _reset_enemy(ai: bool = false, hp: int = 500) -> void:
	enemy.global_position = Vector3(32, 0, 16.8)
	enemy.velocity = Vector3.ZERO
	enemy.target = null
	enemy.facing = Vector3.BACK
	enemy._change_state(BasicEnemy.State.IDLE)
	enemy.health.max_health = maxi(hp, 30)
	enemy.health.current_health = hp
	enemy.set_physics_process(ai)


func _attack_frames() -> int:
	var n := 0
	while player.state == Player.State.ATTACK and n < 200:
		await get_tree().physics_frame
		n += 1
	return n


## Um golpe isolado no inimigo à frente. Devolve o dano.
func _single_hit() -> int:
	_reset_player()
	_reset_enemy()
	await frames(1)
	var hp0: int = enemy.health.current_health
	fake.press_attack()
	await get_tree().physics_frame
	await _attack_frames()
	await seconds(0.4)
	return hp0 - enemy.health.current_health


## O inimigo investe contra o jogador; devolve o dano recebido.
func _lunge(face_enemy: bool) -> int:
	_reset_player()
	_reset_enemy(true, 30)
	enemy.global_position = Vector3(32, 0, 15.8)
	enemy.target = player
	enemy._change_state(BasicEnemy.State.CHASE)
	fake.aim_direction = Vector3.FORWARD if face_enemy else Vector3.BACK
	fake.defend_held = true
	var hp0: int = player.health.current_health
	for i in 90:
		await get_tree().physics_frame
		if enemy.state == BasicEnemy.State.RECOVER or enemy.state == BasicEnemy.State.STAGGER:
			break
	fake.defend_held = false
	await seconds(0.8)
	return hp0 - player.health.current_health


func _run() -> void:
	Hitstop.enabled = false
	arena = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	enemy = arena.get_node("Entities/BasicEnemy1")
	hud = arena.get_node("Hud")
	for other: String in ["BasicEnemy2", "BasicEnemy3"]:
		(arena.get_node("Entities/" + other) as BasicEnemy).set_physics_process(false)
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	await frames(3)

	print("--- 1. armas ---")
	check("espada: 10", await _single_hit() == 10)
	player.equipment.equip(ItemStack.create(item("heavy_axe")))
	check("machado: 18 (finalizador 36)", await _single_hit() == 18 and player.current_attack_damage(2) == 36)
	_reset_player()
	fake.aim_direction = Vector3.BACK
	fake.press_attack()
	await get_tree().physics_frame
	var axe_frames: int = await _attack_frames()
	await seconds(0.4)
	player.equipment.equip(ItemStack.create(item("light_blade")))
	_reset_player()
	fake.aim_direction = Vector3.BACK
	fake.press_attack()
	await get_tree().physics_frame
	var blade_frames: int = await _attack_frames()
	await seconds(0.4)
	check("machado mais lento que a lâmina", axe_frames > blade_frames + 8, "%d vs %d" % [axe_frames, blade_frames])
	check("lâmina: 7", await _single_hit() == 7)
	player.equipment.unequip_weapon()
	check("sem arma: 4", await _single_hit() == 4)
	player.equipment.equip(ItemStack.create(item("short_sword")))

	print("--- 2. durabilidade ---")
	var weapon: ItemStack = player.equipment.weapon
	var d0: int = weapon.durability
	await _single_hit()
	check("acerto gasta 1", weapon.durability == d0 - 1)
	weapon.durability = 1
	await _single_hit()
	check("quebra no último ponto", weapon.is_broken())
	check("quebrada: 40% (4)", await _single_hit() == 4)
	player.equipment.equip(ItemStack.create(item("short_sword")))

	print("--- 3. escudo ---")
	var shield: ItemStack = player.equipment.unequip_shield()
	_reset_player()
	fake.defend_held = true
	await frames(3)
	check("sem escudo não defende", player.state == Player.State.MOVE)
	fake.defend_held = false
	player.equipment.equip(shield)
	check("com escudo: bloqueio sem dano", await _lunge(true) == 0)
	shield.durability = 0
	check("escudo quebrado: passa metade (15 -> 8)", await _lunge(true) == 8)
	shield.durability = 40
	check("pelas costas atravessa a defesa (15)", await _lunge(false) == 15)

	print("--- 4. crescimento por nível e itens ---")
	_reset_player()
	player.health.current_health = 50
	player.gain_xp(30)
	check("nível 2: vida 108 e mana 32, cheias ao subir", player.health.max_health == 108 and player.health.current_health == 108 and player.mana.max_mana == 32 and player.mana.current() == 32,
		"%d/%d mana %d" % [player.health.current_health, player.health.max_health, player.mana.max_mana])
	check("nível 2: dano 11", player.current_attack_damage(0) == 11)
	var herb_slot := -1
	for i in player.inventory.slots.size():
		var st: ItemStack = player.inventory.get_slot(i)
		if st and st.item == item("healing_herb"):
			herb_slot = i
	player.health.current_health = player.health.max_health
	check("erva com vida cheia: não gasta", player.use_inventory_slot(herb_slot) == "A vida já está cheia.")
	player.health.current_health = 40
	player.use_inventory_slot(herb_slot)
	check("erva cura 30", player.health.current_health == 70)
	var t0: int = player.mana.current()
	player.mana._current = 5.0
	await seconds(1.0)
	check("mana não recupera sozinha", player.mana.current() == 5)
	player.inventory.add(ItemStack.create(item("mana_potion"), 1))
	for i in player.inventory.slots.size():
		var st: ItemStack = player.inventory.get_slot(i)
		if st and st.item == item("mana_potion"):
			player.use_inventory_slot(i)
			break
	check("poção de mana +25", player.mana.current() == 30, str(player.mana.current()))
	player.mana._current = t0

	print("--- 5. habilidades ---")
	var arena2: Node = arena
	check("Golpe giratório liberado no nível 2", player.is_ability_unlocked(0))
	_reset_player()
	_reset_enemy(false, 500)
	fake.press_ability(0)
	await seconds(0.5)
	check("recarga em andamento", player.ability_cooldown_ratio(0) > 0.8)
	var shade: ColorRect = hud.get_node("AbilityBar/Ability1/Cooldown")
	check("HUD mostra a recarga", shade.size.y > 14.0, "%.1f" % shade.size.y)
	await seconds(3.8)
	check("recarga acaba em ~4 s", is_equal_approx(player.ability_cooldown_ratio(0), 0.0))

	print("--- 6. Guardião (tanque) ---")
	var guardian: ClassData = load("res://game/classes/data/guardian.tres")
	var devotee: ClassData = load("res://game/classes/data/devotee.tres")
	player.apply_class(guardian)
	check("base igual: vida 108 no nível 2 (sem bônus de classe)", player.health.max_health == 108, str(player.health.max_health))
	check("Guardião começa com malho e escudo sentinela", player.equipment.weapon_data().id == &"ember_maul"
		and player.equipment.weapon_data().weapon_type == &"maca" and player.equipment.shield_data().id == &"sentinel_shield")
	check("habilidades: Golpe de escudo, Provocar + 4 de níveis altos", player.abilities.size() == 6
		and player.abilities[0].display_name == "Golpe de escudo" and player.abilities[1].display_name == "Provocar"
		and player.abilities[2].unlock_level == 10 and player.abilities[5].unlock_level == 50)
	var model_root: Node3D = player.get_node("Model")
	var maul: Node3D = player.held_model(true)
	var kite: Node3D = player.held_model(false)
	check("Guardião segura o Malho de brasa (direita) e o Escudo sentinela (esquerda)",
		maul != null and maul.name == "ember_maul" and kite != null and kite.name == "sentinel_shield")
	check("espada provisória escondida quando há modelo de arma", not player.get_node("Model/RightHand/SwordPlaceholder").visible)
	var to_maul: Vector3 = model_root.to_local(maul.global_position) if maul else Vector3.ZERO
	var to_kite: Vector3 = model_root.to_local(kite.global_position) if kite else Vector3.ZERO
	check("malho à direita, escudo à esquerda (espaço do Model, frente = -Z)", to_maul.x > 0.3 and to_kite.x < -0.3, "%s %s" % [to_maul, to_kite])
	var tint: StandardMaterial3D = player.get("_tint_material")
	var held_meshes: Array[Node] = maul.find_children("*", "MeshInstance3D", true, false) + kite.find_children("*", "MeshInstance3D", true, false)
	check("peças das armas com a camada de cor (piscam junto)", held_meshes.size() >= 2
		and held_meshes.all(func(m: Node) -> bool: return (m as MeshInstance3D).material_overlay == tint), str(held_meshes.size()))
	await frames(2)
	check("sem efeito: camada invisível", is_zero_approx(tint.albedo_color.a))
	player.set_heal_selected(true)
	await frames(2)
	check("selecionado para cura: verde por cima", tint.albedo_color.g > 0.9 and tint.albedo_color.a > 0.3)
	player.set_heal_selected(false)
	await frames(2)
	check("desmarcado: volta ao normal", is_zero_approx(tint.albedo_color.a))
	player.equipment.equip(ItemStack.create(item("short_sword")))
	await frames(1)
	# Com modelo de personagem (cavaleiro), a espada de caixa provisória não aparece.
	check("trocar para arma sem modelo: mão vazia (sem espada de caixa no cavaleiro)", player.held_model(true) == null
		and not player.get_node("Model/RightHand/SwordPlaceholder").visible and player.class_model() != null and not is_instance_valid(maul))
	player.apply_class(guardian)
	_reset_player()
	_reset_enemy(false, 500)
	fake.press_ability(0)
	await frames(12)
	check("Golpe de escudo atordoa o alvo", enemy.state == BasicEnemy.State.STAGGER and enemy.health.current_health < 500, BasicEnemy.State.keys()[enemy.state])
	enemy.set_physics_process(true)  # o relógio do atordoamento roda na física do inimigo
	await seconds(1.6)
	check("atordoamento dura ~1,5 s", enemy.state != BasicEnemy.State.STAGGER)
	enemy.set_physics_process(false)
	_reset_player()
	_reset_enemy(false, 500)
	enemy.global_position = Vector3(32, 0, 12)  # 6 m: dentro do raio de 8 m
	enemy.set_physics_process(true)
	fake.press_ability(1)
	await frames(3)
	check("Provocar: inimigo passa a perseguir o Guardião", enemy.is_taunted_by(player) and enemy.target == player)
	enemy.set_physics_process(false)
	_reset_player()
	_reset_enemy(false, 30)
	fake.aim_direction = Vector3.FORWARD
	fake.defend_held = true
	await frames(3)
	player.health.apply_damage(DamageInfo.new(10, Vector3.ZERO, enemy))  # bloqueado (de frente)
	fake.defend_held = false
	await frames(3)
	var texts: Array[String] = []
	for c: Node in player.get_children():
		if c is FloatingText:
			texts.append((c as FloatingText).text)
	check("Muralha: bloquear dá Firmeza", player._firmeza_left > 2.5 and texts.has("Firmeza"))
	player.health._invulnerable_time = 0.0
	var hp0: int = player.health.current_health
	player.health.apply_damage(DamageInfo.new(20, Vector3.ZERO, null))
	check("Firmeza: 20 de dano vira 14 (-30%)", hp0 - player.health.current_health == 14, "%d" % (hp0 - player.health.current_health))
	await seconds(0.8)
	player.gain_xp(2000)  # passa do nível 10 (1350 de exp. no total)
	player._ability_cooldowns[2] = 0.0
	_reset_player()
	var mana0: int = player.mana.current()
	fake.press_ability(2)
	await frames(3)
	await frames(20)
	check("Postura inabalável (nível 10) funciona: Postura ativa e gasta 10 de mana", player.status.has(StatusEffects.STANCE) and player.mana.current() == mana0 - 10, "mana %d -> %d" % [mana0, player.mana.current()])

	print("--- 7. Devoto (cura) ---")
	player.apply_class(devotee)
	await frames(1)
	var staff: Node3D = player.held_model(true)
	check("Devoto segura o Cajado crescente e não tem escudo na mão", staff != null and staff.name == "apprentice_staff"
		and player.held_model(false) == null)
	check("Devoto começa com cajado e sem escudo", player.equipment.weapon_data().id == &"apprentice_staff" and player.equipment.shield == null)
	player.inventory.set_slot(7, ItemStack.create(item("short_sword")))
	check("Devoto não equipa espada", player.use_inventory_slot(7) == "Sua classe não usa Espada curta." and player.equipment.weapon_data().id == &"apprentice_staff")
	player.inventory.set_slot(7, ItemStack.create(item("wooden_shield")))
	check("Devoto não usa escudo", player.use_inventory_slot(7) == "Sua classe não usa escudo." and player.equipment.shield == null)
	_reset_player()
	player.health.current_health = 50
	player.mana.restore_full()
	fake.press_ability(0)
	await seconds(0.5)
	check("Luz curativa abre a seleção de aliados (não cura a si mesmo)", player.is_heal_targeting() and player.health.current_health == 50
		and player.mana.current() == player.mana.max_mana)
	player.cancel_heal_targeting()
	_reset_player()
	_reset_enemy(false, 500)
	enemy.global_position = Vector3(32, 0, 13)
	var mana1: int = player.mana.current()
	fake.press_ability(1)
	await seconds(0.6)
	check("Raio sagrado: 8 de dano (x1,1 do nível não vale para magia), -6 de mana", enemy.health.current_health == 492 and player.mana.current() == mana1 - 6,
		"vida=%d mana %d->%d" % [enemy.health.current_health, mana1, player.mana.current()])

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
