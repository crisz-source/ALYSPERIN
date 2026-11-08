extends Node
## Testes da Etapa E/F: portal das Ruínas Esquecidas (requisitos), entrada com
## Dungeon Sync, monstros da masmorra, morte/continuar lá dentro e saída.

const AREA := "res://game/world/areas/prototype_area/prototype_area.tscn"
const ITEMS := "res://game/items/data/"

var _failures: int = 0
var _passes: int = 0
var area: GameArea
var player: Player


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


func _ray_down(from: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 2.0, from + Vector3.DOWN * 2.0, 1)
	return area.get_world_3d().direct_space_state.intersect_ray(q)


func _run() -> void:
	Hitstop.enabled = false
	area = load(AREA).instantiate()
	get_tree().root.add_child(area)
	get_tree().current_scene = area
	await frames(2)
	(area.find_children("*", "ClassSelectScreen", true, false)[0] as ClassSelectScreen).choose_class(0)
	player = area.player
	for n: Node in area.entities.get_children():
		if n is BasicEnemy:
			n.set_physics_process(false)
	await frames(2)

	print("--- 1. portal ---")
	var entrance: DungeonEntrance = area.find_children("*", "DungeonEntrance", true, false)[0] if not area.find_children("*", "DungeonEntrance", true, false).is_empty() else null
	check("portal das Ruínas Esquecidas na área inicial", entrance != null and entrance.dungeon.display_name == "Ruínas Esquecidas")
	if entrance == null:
		_finish()
		return
	var q := PhysicsPointQueryParameters3D.new()
	q.position = entrance.global_position + Vector3.UP
	q.collision_mask = 1
	check("portal em chão livre (sem parede em cima)", not _ray_down(entrance.global_position).is_empty()
		and area.get_world_3d().direct_space_state.intersect_point(q).is_empty(), str(entrance.global_position))
	var interact: Interactable = entrance.get_node("Interactable")
	var start_pos: Vector3 = player.global_position
	var msg: String = interact.interact(player)
	check("nível 1, GS 100: recusa dizendo nível e GS", msg.contains("nível 20") and msg.contains("GS 300") and area.current_dungeon == null, msg)
	player.gain_xp(200000)  # nível 60
	await frames(1)
	msg = interact.interact(player)
	check("nível 60 mas GS 120: recusa só pelo GS", not msg.contains("nível") and msg.contains("GS 300") and area.current_dungeon == null, msg)
	var real_hp: int = player.health.max_health
	player.equipment.equip(ItemStack.create(load(ITEMS + "veteran_maul.tres")))
	player.equipment.equip(ItemStack.create(load(ITEMS + "veteran_shield.tres")))
	msg = interact.interact(player)
	await frames(3)

	print("--- 2. dentro, sincronizado ---")
	var map: DungeonMap = area.current_dungeon
	check("entrou: mapa criado e jogador no início", map != null and player.global_position.distance_to(map.start_point()) < 1.5, str(player.global_position))
	check("sync: nível 60 -> 24, GS 320 -> 300", player.effective_level() == 24 and player.effective_gear_score() == 300 and player.stats.level == 60)
	check("vida máxima do nível 24 (100 + 23 x 8 = 284)", player.health.max_health == 284, "%d (real %d)" % [player.health.max_health, real_hp])
	check("dano do nível 24 com GS 300: 14 x 1,2 x 3,3 = 55", player.current_attack_damage(0) == 55, str(player.current_attack_damage(0)))
	check("habilidade de nível 35 bloqueada pela sincronização", not player.is_ability_unlocked(4) and player.is_ability_unlocked(3))
	check("chão sob o início, o salão e a arena do chefe", not _ray_down(map.start_point()).is_empty()
		and not _ray_down(map.enemy_points()[0]).is_empty() and not _ray_down(map.boss_point()).is_empty())
	var ruins: Array = []
	for n: Node in area.entities.get_children():
		if n is BasicEnemy and String(n.name).begins_with("Ruinas"):
			ruins.append(n)
	check("4 monstros da masmorra (vida 160, dano 30)", ruins.size() == 4 and ruins[0].health.max_health == 160
		and (ruins[0].get_node("LungeHitbox") as Hitbox).damage == 30, str(ruins.size()))
	check("poças d'água na arena", map.is_in_puddle(map.global_position + Vector3(-10, 0, -48)) and not map.is_in_puddle(map.boss_point()))

	print("--- 3. morrer e continuar lá dentro ---")
	player.self_revive_available = false
	player.global_position = map.enemy_points()[0] + Vector3(0, 0, 2)
	player.health.apply_damage(DamageInfo.new(99999))
	await frames(2)
	check("morreu na masmorra", player.state == Player.State.DEAD)
	area.continue_after_death()
	await frames(2)
	check("continuar: volta ao início da masmorra, ainda sincronizado", player.global_position.distance_to(map.start_point()) < 1.5
		and player.effective_level() == 24 and area.current_dungeon == map)

	print("--- 4. sair ---")
	var exit_area: Interactable = map.get_node("ExitPortal/Interactable")
	exit_area.interact(player)
	await frames(3)
	check("saiu: de volta ao ponto de onde entrou", area.current_dungeon == null and player.global_position.distance_to(start_pos) < 0.5, str(player.global_position))
	check("sem sync: nível 60, vida máxima real", not player.is_synced() and player.effective_level() == 60 and player.health.max_health == real_hp)
	check("monstros e mapa da masmorra removidos", ruins.all(func(e: Variant) -> bool: return not is_instance_valid(e)) and not is_instance_valid(map))
	interact.interact(player)
	await frames(2)
	check("dá para entrar de novo", area.current_dungeon != null and player.self_revive_available)
	_finish()


func _finish() -> void:
	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
