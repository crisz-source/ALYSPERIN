extends Node
## Testes da Etapa I: Khar'Vesh (resistências, partes, fases, Fúria, ataques
## com aviso, cura, morte/recompensas, Provocar/atordoar, arena da masmorra).

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"

var _failures: int = 0
var _passes: int = 0
var arena: GameArea
var player: Player
var fake: Node
var console: AdminConsole


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


## Golpe de `amount` numa parte, num quadro novo (não se junta a outro golpe).
func hit(boss: KharVesh, part: StringName, amount: int, element: StringName = &"") -> int:
	await frames(1)
	var before: int = boss.health.current_health
	var info := DamageInfo.new(amount, Vector3.ZERO, player)
	info.element = element
	boss.apply_part_hit(boss.parts[part], info)
	return before - boss.health.current_health


func fresh_boss() -> KharVesh:
	for b: Node in get_tree().get_nodes_in_group(KharVesh.GROUP):
		b.free()
	await frames(1)
	var boss: KharVesh = arena.spawn_boss(player.global_position + Vector3(0, 0, -8))
	await frames(2)
	boss.set_physics_process(false)
	return boss


func _run() -> void:
	Hitstop.enabled = false
	arena = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	for n: Node in arena.get_node("Entities").get_children():
		if n is BasicEnemy:
			n.set_physics_process(false)
			(n as Node3D).global_position += Vector3(0, 0, 60)
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	console = arena.find_children("*", "AdminConsole", true, false)[0]
	player.global_position = Vector3(32, 0, 26)
	await frames(3)

	print("--- 1. /boss ---")
	var reply: String = console.execute("/boss")
	var boss: KharVesh = get_tree().get_first_node_in_group(KharVesh.GROUP)
	check("/boss chama Khar'Vesh", boss != null and reply.contains("Khar'Vesh"), reply)
	check("segundo /boss recusa (um por vez)", console.execute("/boss").contains("Já existe"))
	await frames(2)
	check("barra de vida do chefe na tela", boss.find_child("BossBar", true, false) is ColorRect)

	print("--- 2. resistências (sem texto na tela) ---")
	boss = await fresh_boss()
	check("físico neutro: 100 -> 100", await hit(boss, &"bark", 100) == 100)
	check("Fogo muito vulnerável: 100 -> 175", await hit(boss, &"bark", 100, &"fire") == 175)
	check("Gelo vulnerável: 100 -> 135", await hit(boss, &"bark", 100, &"ice") == 135)
	check("Terra muito resistente: 100 -> 30", await hit(boss, &"bark", 100, &"earth") == 30)
	check("Trevas resistente: 100 -> 60", await hit(boss, &"bark", 100, &"dark") == 60)
	boss.wet_left = 10.0
	check("Molhada: Fogo cai para neutro", await hit(boss, &"bark", 100, &"fire") == 100)
	check("Molhada: Raio sobe para vulnerável", await hit(boss, &"bark", 100, &"lightning") == 135)
	boss.wet_left = 0.0

	print("--- 3. um golpe em várias partes conta uma vez na vida total ---")
	boss = await fresh_boss()
	await frames(1)
	var hp0: int = boss.health.current_health
	var mouth_hp0: int = (boss.parts[&"mouth"] as BossPart).part_hp
	boss.apply_part_hit(boss.parts[&"bark"], DamageInfo.new(50, Vector3.ZERO, player))
	boss.apply_part_hit(boss.parts[&"mouth"], DamageInfo.new(50, Vector3.ZERO, player))
	check("vida total caiu 50 (não 100)", hp0 - boss.health.current_health == 50, str(hp0 - boss.health.current_health))
	check("mas a boca também perdeu 50 de vida de parte", mouth_hp0 - (boss.parts[&"mouth"] as BossPart).part_hp == 50)

	print("--- 4. partes destrutíveis ---")
	boss = await fresh_boss()
	var pickups_before: int = arena.find_children("*", "ItemPickup", true, false).size()
	await hit(boss, &"bulb_1", 200)
	check("bulbo quebra: 2 bulbos vivos e Seiva Rubra no chão", boss.bulbs_alive() == 2 and boss.is_part_broken(&"bulb_1")
		and arena.find_children("*", "ItemPickup", true, false).size() == pickups_before + 1)
	check("bulbo quebrado não recebe mais golpes", await hit(boss, &"bulb_1", 100) == 0)
	boss.break_part(&"bulb_2")
	boss.break_part(&"bulb_3")
	check("sem bulbos: cura zero por tique", boss.bulbs_alive() == 0 and roundi(boss.health.max_health * KharVesh.HEAL_PER_BULB_TICK * boss.bulbs_alive()) == 0)
	boss.break_part(&"mouth")
	check("boca quebrada: atordoada por 4 s", boss.state == KharVesh.State.STUN and is_equal_approx(boss._state_duration, 4.0))
	boss.break_part(&"whip_right")
	boss.target = player
	boss.facing = Vector3.FORWARD
	player.global_position = boss.global_position + Vector3(3, 0, -3)  # à direita e à frente
	boss.start_attack(&"whip")
	check("chicote direito quebrado: chicotada curta daquele lado", is_equal_approx(float(boss._attack.length), KharVesh.WHIP_SHORT_LENGTH) and boss._attack.side == &"whip_right")
	boss._change_state(KharVesh.State.IDLE)
	boss.break_part(&"bark")
	await frames(1)
	check("casca quebrada: cerne exposto e fase 3", boss.phase == 3 and (boss.parts[&"core"] as BossPart).monitorable)
	boss.health.set_invulnerable(false)
	check("sem casca: Terra vira neutra", is_equal_approx(boss.resist_multiplier(&"earth"), 1.0))
	check("cerne: dano crítico x1,5 (100 -> 150)", await hit(boss, &"core", 100) == 150)
	boss.phase = 2
	boss._cooldowns[&"spores"] = 0.0
	boss._cooldowns[&"heal"] = 99.0
	boss._cooldowns[&"sprouts"] = 99.0
	boss._cooldowns[&"wet"] = 99.0
	boss._change_state(KharVesh.State.IDLE)
	boss.choose_action(5.0)
	check("boca quebrada: não solta mais esporos", boss._attack.id != &"spores", str(boss._attack.id))

	print("--- 4b. tanque alcança as partes com a espada (golpe real) ---")
	boss = await fresh_boss()
	var reach_ok: bool = true
	for id: StringName in boss.parts.keys():
		var part: BossPart = boss.parts[id]
		var box: BoxShape3D = (part.get_child(0) as CollisionShape3D).shape
		var low: float = part.position.y - box.size.y / 2.0
		var high: float = part.position.y + box.size.y / 2.0
		if high < KharVesh.MELEE_BAND_LOW or low > KharVesh.MELEE_BAND_HIGH:
			reach_ok = false
			print("  fora do alcance: ", id, " ", low, "..", high)
	check("toda parte quebrável dentro da faixa do golpe corpo a corpo", reach_ok)
	boss.facing = Vector3.FORWARD
	boss.get_node("Model").rotation.y = Player.yaw_of(Vector3.FORWARD)
	player.health.revive()
	player._change_state(Player.State.MOVE)
	# Atrás do chefe (as costas dele ficam para +Z), mirando nele.
	player.global_position = boss.global_position + Vector3(0, 0, 2.4)
	fake.aim_direction = Vector3.FORWARD
	var bulbs_before: int = 0
	for b: StringName in [&"bulb_1", &"bulb_2", &"bulb_3"]:
		bulbs_before += (boss.parts[b] as BossPart).part_hp
	fake.press_attack()
	await frames(25)
	var bulbs_after: int = 0
	for b: StringName in [&"bulb_1", &"bulb_2", &"bulb_3"]:
		bulbs_after += (boss.parts[b] as BossPart).part_hp
	check("espada pelas costas acerta os bulbos", bulbs_after < bulbs_before, "%d -> %d" % [bulbs_before, bulbs_after])
	player.global_position = boss.global_position + Vector3(0, 0, -2.4)
	fake.aim_direction = Vector3.BACK
	var mouth_before: int = (boss.parts[&"mouth"] as BossPart).part_hp
	var whips_before: int = (boss.parts[&"whip_left"] as BossPart).part_hp + (boss.parts[&"whip_right"] as BossPart).part_hp
	await frames(20)
	fake.press_attack()
	await frames(25)
	var front_hit: bool = (boss.parts[&"mouth"] as BossPart).part_hp < mouth_before 		or (boss.parts[&"whip_left"] as BossPart).part_hp + (boss.parts[&"whip_right"] as BossPart).part_hp < whips_before
	check("espada pela frente acerta a boca ou um chicote", front_hit)
	fake.aim_direction = Vector3.FORWARD

	print("--- 5. fases e Fúria ---")
	boss = await fresh_boss()
	var mx: int = boss.health.max_health
	check("começa na fase 1, sem Fúria, aviso da chicotada 0,9 s", boss.phase == 1 and boss.enrage_level == 0 and is_equal_approx(boss.windup_for(&"whip"), 0.9))
	boss.health.apply_damage(DamageInfo.new(roundi(mx * 0.31), Vector3.ZERO, player))
	check("70%: fase 2 + Fúria 1, rugido invulnerável", boss.phase == 2 and boss.enrage_level == 1 and boss.state == KharVesh.State.ROAR and boss.health.is_invulnerable())
	check("Fúria 1: aviso 15% mais curto", is_equal_approx(boss.windup_for(&"whip"), 0.9 / 1.15))
	boss._change_state(KharVesh.State.IDLE)
	boss.health.apply_damage(DamageInfo.new(roundi(mx * 0.21), Vector3.ZERO, player))
	check("50%: Fúria 2 (rugido curto)", boss.enrage_level == 2 and boss.state == KharVesh.State.ROAR and boss.phase == 2)
	boss._change_state(KharVesh.State.IDLE)
	boss.health.apply_damage(DamageInfo.new(roundi(mx * 0.16), Vector3.ZERO, player))
	check("35%: fase 3, a casca se parte sozinha", boss.phase == 3 and boss.is_part_broken(&"bark"))
	boss._change_state(KharVesh.State.IDLE)
	boss.health.apply_damage(DamageInfo.new(roundi(mx * 0.15), Vector3.ZERO, player))
	check("20%: Fúria 3", boss.enrage_level == 3)
	check("aviso nunca abaixo de 0,35 s", boss.windup_for(&"spear") >= KharVesh.MIN_WINDUP and is_equal_approx(boss.windup_for(&"spear"), maxf(0.8 / 1.4, 0.35)))
	boss.target = player
	boss.start_attack(&"whip")
	check("Fúria 3: dano 40% maior (45 -> 63)", int(boss._attack.damage) == 63, str(boss._attack.damage))

	print("--- 6. ataques com aviso no chão ---")
	boss = await fresh_boss()
	boss.target = player
	boss.facing = Vector3.FORWARD
	player.health.revive()
	player.status.clear_all()
	player.global_position = boss.global_position + Vector3(0, 0, -4)
	boss.set_physics_process(true)
	boss.start_attack(&"whip")
	check("aviso aparece no chão", (boss.find_child("Telegraph", true, false) as MeshInstance3D).visible)
	var php: int = player.health.current_health
	await seconds(1.0)
	check("chicotada acerta quem está na faixa (45)", php - player.health.current_health == 45, str(php - player.health.current_health))
	boss.set_physics_process(false)
	player.health._invulnerable_time = 0.0
	boss._change_state(KharVesh.State.IDLE)
	php = player.health.current_health
	player.global_position = boss.global_position + Vector3(6, 0, 0)
	boss.set_physics_process(true)
	boss.start_attack(&"whip")
	boss.target = null
	await seconds(1.0)
	check("fora da faixa: sem dano", player.health.current_health == php)
	boss.set_physics_process(false)
	boss._change_state(KharVesh.State.IDLE)
	boss.target = player
	player.global_position = boss.global_position + Vector3(0, 0, -5)
	player.health._invulnerable_time = 0.0
	boss.start_attack(&"spores")
	boss._strike()
	check("esporos: lento e envenenado", player.status.has(StatusEffects.SLOW) and player.status.has(StatusEffects.POISON))
	player.status.clear_all()
	player.health._invulnerable_time = 0.0
	player.health.set_invulnerable(true)
	php = player.health.current_health
	boss.start_attack(&"spear")
	boss._strike()
	check("invulnerável (esquiva): lança não acerta", player.health.current_health == php)
	player.health.set_invulnerable(false)

	print("--- 7. Sugar seiva ---")
	boss = await fresh_boss()
	# Leva a vida a 1000 pelo caminho normal (fases e Fúria já disparadas antes da cura).
	boss.health.apply_damage(DamageInfo.new(1400, Vector3.ZERO, player))
	boss._change_state(KharVesh.State.HEAL, KharVesh.HEAL_TIME)
	boss._heal_tick = 0.5
	boss.set_physics_process(true)
	await seconds(1.05)
	var healed: int = boss.health.current_health - 1000
	check("cura 3 bulbos: 2400 x 0,5% x 3 = 36 por tique (2 tiques em 1 s)", healed == 72, str(healed))
	await hit(boss, &"bulb_1", 70)
	await frames(1)
	check("dano alto num bulbo interrompe a cura", boss.state == KharVesh.State.RECOVER)
	boss.set_physics_process(false)

	print("--- 8. Provocar e Golpe de escudo funcionam no chefe ---")
	player.global_position = boss.global_position + Vector3(0, 0, -4)
	player._do_taunt(load("res://game/abilities/data/taunt.tres"))
	check("Provocar alcança o chefe", boss.is_taunted_by(player))
	check("Golpe de escudo acha o chefe a partir da parte atingida", Player._actor_with(boss.parts[&"mouth"], &"apply_stun") == boss)

	print("--- 9. morte e recompensas ---")
	boss = await fresh_boss()
	boss.set_physics_process(true)  # a animação de morte roda no processamento do chefe
	boss._change_state(KharVesh.State.STUN, 99.0)
	boss.rare_drop_chance = 1.0
	var xp_before: int = player.stats.xp + player.stats.level * 100000
	var drops_before: int = arena.find_children("*", "ItemPickup", true, false).size()
	await hit(boss, &"bark", 999999)
	await frames(2)
	check("morreu: experiência para quem matou", player.stats.xp + player.stats.level * 100000 > xp_before)
	check("Coração Germinado (raro) caiu", arena.find_children("*", "ItemPickup", true, false).size() >= drops_before + 1)
	await seconds(1.2)
	check("corpo some depois de morrer", not is_instance_valid(boss))

	print("--- 10. arena da masmorra chama o chefe ---")
	player.gain_xp(200000)
	player.equipment.equip(ItemStack.create(load("res://game/items/data/veteran_maul.tres")))
	player.equipment.equip(ItemStack.create(load("res://game/items/data/veteran_shield.tres")))
	await frames(1)
	arena.enter_dungeon(load("res://game/dungeons/data/forgotten_ruins.tres"))
	await frames(2)
	var map: DungeonMap = arena.current_dungeon
	check("nenhum chefe antes de entrar na arena", get_tree().get_nodes_in_group(KharVesh.GROUP).is_empty())
	player.global_position = map.global_position + Vector3(0, 0.1, -43)
	fake.move_direction = Vector2(0, -1)
	fake.aim_direction = Vector3.FORWARD
	player.camera_rig().face(Vector3.FORWARD)
	await seconds(1.2)
	fake.move_direction = Vector2.ZERO
	var spawned: KharVesh = get_tree().get_first_node_in_group(KharVesh.GROUP)
	check("passou pela entrada da arena: Khar'Vesh aparece no centro", spawned != null and spawned.global_position.distance_to(map.boss_point()) < 1.0)
	arena.exit_dungeon()
	await frames(2)
	check("sair da masmorra remove o chefe", get_tree().get_nodes_in_group(KharVesh.GROUP).is_empty() or not is_instance_valid(spawned) or spawned.is_queued_for_deletion())

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
