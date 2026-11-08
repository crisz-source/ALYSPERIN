extends Node
## Testes da animação por código (PlayerAnimator): poses de cada estado,
## seguindo os tempos reais do golpe, e volta ao repouso.

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"

var _failures: int = 0
var _passes: int = 0
var player: Player
var fake: Node
var right: Node3D
var left: Node3D
var model: Node3D


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


## Espera até o tempo do estado atual passar de `t` (ou o estado mudar).
func until_state_time(t: float, in_state: Player.State) -> void:
	var n := 0
	while player.state == in_state and player.state_time() < t and n < 300:
		await get_tree().process_frame
		n += 1


## O golpe seguinte do combo começa no mesmo quadro em que o anterior acaba
## (o estado nunca sai de ATTACK), então espera-se a troca do número do golpe.
func until_combo_step(step: int) -> void:
	var n := 0
	while player.combo_step() != step and n < 300:
		await get_tree().physics_frame
		n += 1


func _yaw_diff() -> float:
	return absf(angle_difference(model.rotation.y, Player.yaw_of(player.facing)))


func _at_rest() -> bool:
	return right.rotation.length() < 0.12 and absf(model.rotation.x) < 0.03 and absf(model.rotation.z) < 0.03 \
		and _yaw_diff() < 0.03 and is_equal_approx(model.scale.y, 1.0)


func _reset() -> void:
	player.global_position = Vector3(32, 0, 18)
	player.velocity = Vector3.ZERO
	player._change_state(Player.State.MOVE)
	player._combo_step = 0
	player._combo_window_left = 0.0
	fake.defend_held = false
	fake.move_direction = Vector2.ZERO
	fake.aim_direction = Vector3.FORWARD


func _run() -> void:
	Hitstop.enabled = false
	var arena: Node = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	for n: Node in arena.get_node("Entities").get_children():
		if n is BasicEnemy:
			n.set_physics_process(false)
			(n as Node3D).global_position += Vector3(0, 0, 40)
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	right = player.get_node("Model/RightHand")
	left = player.get_node("Model/LeftHand")
	model = player.get_node("Model")
	_reset()
	await frames(20)

	print("--- 1. repouso ---")
	check("animador presente", player.get_node_or_null("PlayerAnimator") is PlayerAnimator)
	check("parado: arma em pé, corpo reto, virado para a frente", _at_rest(), "%s %s" % [right.rotation, model.rotation])
	fake.aim_direction = Vector3.RIGHT
	player.call("_set_facing", Vector3.RIGHT)
	await frames(2)
	check("corpo acompanha a direção (só pelo animador)", _yaw_diff() < 0.03, "%.2f" % model.rotation.y)
	fake.aim_direction = Vector3.FORWARD
	player.call("_set_facing", Vector3.FORWARD)

	print("--- 2. combo ---")
	fake.press_attack()
	await frames(1)
	var times: Vector3 = player.attack_phase_times()
	check("golpe 1 começou", player.state == Player.State.ATTACK and player.combo_step() == 0, str(times))
	await until_state_time(times.x * 0.95, Player.State.ATTACK)
	check("golpe 1, preparação: arma recolhida à direita", right.rotation.y < -0.6, str(right.rotation))
	await until_state_time(times.x + times.y * 0.98, Player.State.ATTACK)
	check("golpe 1, fim do golpe: arma varreu para a esquerda", right.rotation.y > 0.6, str(right.rotation))
	check("corpo inclina para a frente no golpe", model.rotation.x < -0.05, "%.2f" % model.rotation.x)
	fake.press_attack()
	await until_combo_step(1)
	times = player.attack_phase_times()
	check("golpe 2 começou", player.state == Player.State.ATTACK and player.combo_step() == 1)
	await until_state_time(times.x * 0.95, Player.State.ATTACK)
	check("golpe 2, preparação: arma à esquerda", right.rotation.y > 0.5, str(right.rotation))
	await until_state_time(times.x + times.y * 0.98, Player.State.ATTACK)
	check("golpe 2, fim: varreu para a direita", right.rotation.y < -0.6, str(right.rotation))
	fake.press_attack()
	await until_combo_step(2)
	times = player.attack_phase_times()
	check("finalizador começou", player.state == Player.State.ATTACK and player.combo_step() == 2)
	await until_state_time(times.x * 0.95, Player.State.ATTACK)
	check("finalizador, preparação: arma erguida para trás", right.rotation.x > 0.3, str(right.rotation))
	await until_state_time(times.x + times.y * 0.98, Player.State.ATTACK)
	check("finalizador, fim: arma desceu à frente", right.rotation.x < -1.5, str(right.rotation))
	await until_state_time(99.0, Player.State.ATTACK)
	await frames(30)
	check("depois do combo: volta ao repouso", _at_rest(), "%s %s" % [right.rotation, model.rotation])

	print("--- 3. arma lenta anima mais devagar ---")
	var sword_total: float = times.x + times.y + times.z
	player.equipment.equip(ItemStack.create(load("res://game/items/data/ember_maul.tres")))
	_reset()
	fake.press_attack()
	await frames(1)
	times = player.attack_phase_times()
	await until_state_time(times.x * 0.95, Player.State.ATTACK)
	check("malho: preparação acompanha o tempo do malho", right.rotation.y < -0.6, "%.2f s" % times.x)
	check("malho: tempos 1,2x maiores", times.x > 0.0 and is_equal_approx(player.attack_phase_times().x, 0.06 * 1.2), str(times))
	await until_state_time(99.0, Player.State.ATTACK)
	_reset()
	await frames(30)

	print("--- 4. defesa ---")
	fake.defend_held = true
	await frames(15)
	check("defendendo: escudo à frente do corpo", player.state == Player.State.BLOCK and left.position.z < -0.35 and left.position.x > -0.25, str(left.position))
	fake.defend_held = false
	await frames(30)
	check("soltou: escudo volta ao lado", left.position.distance_to(PlayerAnimator.LEFT_REST_POS) < 0.05, str(left.position))

	print("--- 5. esquiva ---")
	fake.press_dodge()
	await frames(5)
	check("esquivando: corpo mergulha e achata", player.state == Player.State.DODGE and model.rotation.x < -0.2 and is_equal_approx(model.scale.y, 0.6), "%.2f %.2f" % [model.rotation.x, model.scale.y])
	await frames(40)
	_reset()
	await frames(20)
	check("depois da esquiva: corpo reto", _at_rest(), str(model.rotation))

	print("--- 6. Giro cortante ---")
	player.player_class = null
	player.abilities = [load("res://game/abilities/data/spin_slash.tres")]
	player._ability_cooldowns = [0.0]
	player.gain_xp(30)  # Golpe giratório libera no nível 2
	player.mana.restore_full()
	fake.press_ability(0)
	await frames(1)
	var spin: SpinSlashData = player.active_ability() as SpinSlashData
	check("giro começou", spin != null and player.state == Player.State.ABILITY)
	if spin:
		await until_state_time(spin.duration * 0.4, Player.State.ABILITY)
		check("no meio do giro: corpo girou e arma estendida", _yaw_diff() > 0.8 and right.rotation.x < -1.2, "%.2f" % _yaw_diff())
	await until_state_time(99.0, Player.State.ABILITY)
	await frames(10)
	check("fim do giro: corpo de volta à frente", _yaw_diff() < 0.05, "%.2f" % _yaw_diff())

	print("--- 7. Devoto: cura e projétil ---")
	player.apply_class(load("res://game/classes/data/devotee.tres"))
	_reset()
	player.mana.restore_full()
	player.health.current_health = player.health.max_health - 30
	fake.defend_held = true
	await frames(1)
	fake.defend_held = false
	check("Oração de cura começou", player.active_ability() is HealSpellData, str(player.active_ability()))
	await until_state_time(0.25, Player.State.ABILITY)
	var animator: PlayerAnimator = player.get_node("PlayerAnimator")
	check("Devoto é o mago animado (KayKit)", player.class_model() != null and player.held_model(true) != null)
	check("curando: animação de erguer o cajado", animator.current_animation() == "Spellcast_Raise", animator.current_animation())
	await frames(40)
	_reset()
	await frames(10)
	fake.press_ability(1)
	await frames(1)
	var bolt := player.active_ability() as ProjectileSpellData
	check("Raio sagrado começou", bolt != null)
	if bolt:
		await until_state_time(bolt.cast_time * 0.9, Player.State.ABILITY)
		check("lançando: animação de disparo", animator.current_animation() == "Spellcast_Shoot", animator.current_animation())
	await frames(40)

	print("--- 8. morte ---")
	_reset()
	player.call("_on_died")
	await frames(45)
	check("morto: animação de morte", animator.current_animation() == "Death_A", animator.current_animation())
	player.respawn(Vector3(32, 0, 18))
	await frames(30)
	check("reviveu: de pé de novo (parado)", animator.current_animation() == "Idle" and is_equal_approx(model.rotation.x, 0.0), animator.current_animation())

	print("--- 9. Guardião animado (cavaleiro) ---")
	player.apply_class(load("res://game/classes/data/guardian.tres"))
	_reset()
	await frames(5)
	check("parado: Idle", animator.current_animation() == "Idle", animator.current_animation())
	check("malho preso no osso da mão do cavaleiro", player.held_model(true) != null and player.held_model(true).get_parent() is BoneAttachment3D)
	fake.move_direction = Vector2(0, -1)
	await frames(20)
	check("andando: corrida", animator.current_animation() == "Running_A", animator.current_animation())
	fake.move_direction = Vector2.ZERO
	await frames(20)
	var seen_attacks: Array[String] = []
	for i in 3:
		fake.press_attack()
		await until_combo_step(i)
		await frames(2)
		seen_attacks.append(animator.current_animation())
		await until_state_time(player.attack_phase_times().x + player.attack_phase_times().y, Player.State.ATTACK)
	check("combo: três golpes diferentes do cavaleiro", seen_attacks == PlayerAnimator.ANIM_COMBO_1H, str(seen_attacks))
	await until_state_time(99.0, Player.State.ATTACK)
	_reset()
	fake.defend_held = true
	await frames(8)
	check("defendendo: Blocking", animator.current_animation() == "Blocking", animator.current_animation())
	fake.defend_held = false

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
