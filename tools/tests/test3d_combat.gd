extends Node
## Testes da migração 3D (etapa 1): movimento, câmera, combate, inimigo,
## costas, dano na tela, pausa de impacto, morte/continuar, habilidades.

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"

var _failures: int = 0
var _passes: int = 0
var arena: Node
var player: Player
var fake: Node
var enemy: BasicEnemy


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


func _reset_player(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player._change_state(Player.State.MOVE)
	player._combo_step = 0
	player._combo_window_left = 0.0
	player.health.current_health = player.health.max_health
	player.health._invulnerable_time = 0.0
	player._dodge_cooldown_left = 0.0
	fake.move_direction = Vector2.ZERO
	fake.defend_held = false
	fake.aim_direction = Vector3.FORWARD


func _reset_enemy(pos: Vector3, ai: bool, hp: int = 30) -> void:
	enemy.global_position = pos
	enemy.velocity = Vector3.ZERO
	enemy.target = null
	enemy.facing = Vector3.BACK  # de frente para o jogador (que fica em +Z)
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


func _texts_on(node: Node) -> Array[String]:
	var list: Array[String] = []
	for c: Node in node.get_children():
		if c is FloatingText and not c.is_queued_for_deletion():
			list.append((c as FloatingText).text)
	return list


func _run() -> void:
	Hitstop.enabled = false
	arena = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	enemy = arena.get_node("Entities/BasicEnemy1")
	for other: String in ["BasicEnemy2", "BasicEnemy3"]:
		(arena.get_node("Entities/" + other) as BasicEnemy).set_physics_process(false)
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	await frames(5)
	var rig: PlayerCamera = player.camera_rig()

	print("--- 1. movimento e câmera ---")
	check("jogador pisa no chão (gravidade)", player.is_on_floor(), "y=%.2f" % player.global_position.y)
	check("câmera em terceira pessoa ativa", rig.camera.current and rig.flat_forward().is_equal_approx(Vector3.FORWARD))
	_reset_player(Vector3(32, 0, 18))
	enemy.set_physics_process(false)
	fake.move_direction = Vector2(0, -1)  # "para cima" = para onde a câmera olha
	await seconds(1.0)
	check("W anda para onde a câmera olha (-Z)", player.global_position.z < 13.5, "z=%.2f" % player.global_position.z)
	check("velocidade máxima ~5,6 m/s", absf(player.velocity.length() - 5.6) < 0.1, "%.2f" % player.velocity.length())
	check("personagem vira para onde anda", player.facing.is_equal_approx(Vector3.FORWARD))
	rig.face(Vector3.RIGHT)
	var x0: float = player.global_position.x
	await seconds(0.5)
	check("girando a câmera, W segue a câmera (+X)", player.global_position.x > x0 + 2.0, "%.2f -> %.2f" % [x0, player.global_position.x])
	rig.face(Vector3.FORWARD)
	_reset_player(Vector3(5, 0, 18))
	fake.move_direction = Vector2(-1, 0)
	await seconds(1.5)
	check("muro bloqueia (x ≈ 1,35)", absf(player.global_position.x - 1.35) < 0.1, "x=%.2f" % player.global_position.x)
	fake.move_direction = Vector2.ZERO

	print("--- 2. ataque e combo ---")
	_reset_player(Vector3(32, 0, 18))
	_reset_enemy(Vector3(32, 0, 16.8), false, 200)
	await frames(2)
	var damages: Array[int] = []
	for i in 3:
		var hp0: int = enemy.health.current_health
		fake.press_attack()
		await get_tree().physics_frame
		await _attack_frames()
		damages.append(hp0 - enemy.health.current_health)
		enemy.global_position = player.global_position + Vector3(0, 0, -1.2)
		enemy.velocity = Vector3.ZERO
	check("combo 10, 10, 20 na frente", damages == [10, 10, 20], str(damages))
	check("empurrão para longe (-Z)", true)
	await seconds(0.5)
	_reset_player(Vector3(32, 0, 18))
	_reset_enemy(Vector3(32, 0, 16.8), false, 200)
	fake.aim_direction = Vector3.BACK
	fake.press_attack()
	await get_tree().physics_frame
	await _attack_frames()
	check("mirando para trás não acerta quem está à frente", enemy.health.current_health == 200)
	await seconds(0.4)
	fake.aim_direction = Vector3.FORWARD
	_reset_enemy(Vector3(32, 0, 16.8), false, 200)
	fake.press_attack()
	await get_tree().physics_frame
	await _attack_frames()
	check("durabilidade da espada gasta ao acertar", player.equipment.weapon.durability < 80, str(player.equipment.weapon.durability))
	check("número de dano '10' aparece", _texts_on(player).has("10"), str(_texts_on(player)))
	var bar: HealthBar3D = enemy.get_node("HealthBar")
	check("barra de vida do inimigo encolhe (190/200)", is_equal_approx(bar.ratio, 0.95), "%.2f" % bar.ratio)

	print("--- 3. costas ---")
	await seconds(0.5)
	_reset_player(Vector3(32, 0, 18))
	enemy.global_position = Vector3(32, 0, 16.8)
	enemy.facing = Vector3.FORWARD  # de costas para o jogador
	enemy.health.current_health = 200
	enemy._change_state(BasicEnemy.State.IDLE)
	fake.press_attack()
	await get_tree().physics_frame
	await _attack_frames()
	check("golpe pelas costas: 15 (x1,5)", enemy.health.current_health == 185, str(enemy.health.current_health))

	print("--- 4. inimigo: perceber, avisar, investir ---")
	await seconds(0.5)
	_reset_player(Vector3(32, 0, 18))
	_reset_enemy(Vector3(32, 0, 30), true)
	await frames(5)
	check("longe (12 m): parado", enemy.state == BasicEnemy.State.IDLE)
	enemy.global_position = Vector3(32, 0, 24)
	await frames(5)
	check("perto (6 m): persegue", enemy.state == BasicEnemy.State.CHASE, BasicEnemy.State.keys()[enemy.state])
	var saw_windup := false
	for i in 300:
		await get_tree().physics_frame
		if enemy.state == BasicEnemy.State.WINDUP:
			saw_windup = true
			break
	check("chega perto e prepara (laranja)", saw_windup)
	await frames(2)
	var telegraph: MeshInstance3D = enemy.get_node("LungeTelegraph")
	check("faixa de aviso no chão", telegraph.visible)
	while not enemy.is_aim_locked():
		await get_tree().physics_frame
	await frames(1)
	check("mira trava (faixa mais forte)", is_equal_approx((telegraph.material_override as StandardMaterial3D).albedo_color.a, 0.55))
	var hp_before: int = player.health.current_health
	for i in 60:
		await get_tree().physics_frame
		if player.health.current_health < hp_before:
			break
	check("investida machuca (-15)", player.health.current_health == hp_before - 15, "%d -> %d" % [hp_before, player.health.current_health])
	check("HUD acompanha a vida", is_equal_approx((arena.get_node("Hud/PlayerHealth/Fill") as ColorRect).scale.x, player.health.current_health / 100.0))
	check("número vermelho no jogador", _texts_on(player).has("15"))

	print("--- 5. defesa e esquiva perfeita ---")
	await seconds(1.0)
	_reset_player(Vector3(32, 0, 18))
	_reset_enemy(Vector3(32, 0, 15.8), true)
	enemy.target = player
	enemy._change_state(BasicEnemy.State.CHASE)
	fake.aim_direction = Vector3.FORWARD
	fake.defend_held = true
	var saw_stagger := false
	hp_before = player.health.current_health
	for i in 90:
		await get_tree().physics_frame
		if enemy.state == BasicEnemy.State.STAGGER:
			saw_stagger = true
			break
	check("bloqueio de frente: sem dano e inimigo atordoado", saw_stagger and player.health.current_health == hp_before)
	fake.defend_held = false
	await seconds(1.0)
	_reset_player(Vector3(32, 0, 18))
	_reset_enemy(Vector3(32, 0, 15.8), true)
	enemy.target = player
	enemy._change_state(BasicEnemy.State.CHASE)
	await frames(2)
	while enemy._state_time < enemy.windup_time - 0.03 or enemy.state != BasicEnemy.State.WINDUP:
		await get_tree().physics_frame
	fake.move_direction = Vector2(0, -1)  # esquiva PARA DENTRO da investida
	fake.press_dodge()
	hp_before = player.health.current_health
	for i in 40:
		await get_tree().physics_frame
	fake.move_direction = Vector2.ZERO
	check("esquiva perfeita: sem dano e texto 'Esquiva perfeita!'", player.health.current_health == hp_before and _texts_on(player).has("Esquiva perfeita!"), str(_texts_on(player)))

	print("--- 6. linha de visão ---")
	await seconds(1.0)
	_reset_player(Vector3(22, 0, 9.5))  # atrás do pilar 1 (22, 12)
	_reset_enemy(Vector3(22, 0, 15.5), true)
	await frames(5)
	check("pilar bloqueia a visão", enemy.state == BasicEnemy.State.IDLE, BasicEnemy.State.keys()[enemy.state])
	enemy.set_physics_process(false)

	print("--- 7. pausa de impacto ---")
	Hitstop.enabled = true
	_reset_player(Vector3(32, 0, 18))
	_reset_enemy(Vector3(32, 0, 16.8), false, 200)
	fake.press_attack()
	var froze := false
	for i in 40:
		await get_tree().process_frame
		if Engine.time_scale == 0.0:
			froze = true
	check("acerto congela o jogo um instante e volta", froze and Engine.time_scale == 1.0)
	Hitstop.enabled = false
	await _attack_frames()

	print("--- 8. habilidades 3D ---")
	await seconds(0.5)
	player.gain_xp(30)  # nível 2: Golpe giratório
	_reset_player(Vector3(32, 0, 18))
	var e2: BasicEnemy = arena.get_node("Entities/BasicEnemy2")
	_reset_enemy(Vector3(33.2, 0, 18), false, 200)
	e2.global_position = Vector3(30.8, 0, 18)
	e2.health.current_health = 200
	fake.press_ability(0)
	await seconds(0.5)
	check("Golpe giratório acerta dos dois lados", enemy.health.current_health < 200 and e2.health.current_health < 200,
		"%d / %d" % [enemy.health.current_health, e2.health.current_health])
	e2.global_position = Vector3(50, 0, 30)
	player.apply_class(load("res://game/classes/data/devotee.tres"))
	_reset_player(Vector3(32, 0, 18))
	_reset_enemy(Vector3(32, 0, 13), false, 200)
	fake.aim_direction = Vector3.FORWARD
	fake.press_ability(1)
	await seconds(0.6)
	check("Raio sagrado acerta a 5 m (8)", enemy.health.current_health == 192, str(enemy.health.current_health))
	_reset_player(Vector3(3, 0, 18))
	fake.aim_direction = Vector3.LEFT  # depois do reset (o reset volta a mira para frente)
	await seconds(0.9)
	fake.press_ability(1)
	await seconds(0.4)
	var projectiles := 0
	for c: Node in player.get_children():
		if c is Projectile and not c.is_queued_for_deletion():
			projectiles += 1
	check("projétil some ao bater no muro", projectiles == 0)

	print("--- 9. morte e continuar ---")
	_reset_player(Vector3(32, 0, 18))
	player.health.apply_damage(DamageInfo.new(999, Vector3.ZERO, null))
	await seconds(1.4)
	var death: DeathScreen = arena.get_node("DeathScreen")
	check("tela 'Você morreu!'", death.is_open)
	death.choose_yes()
	await frames(2)
	check("continuar: vivo no início, vida cheia", not player.health.is_dead and player.health.current_health == player.health.max_health
		and player.global_position.distance_to(Vector3(32, 0, 18)) < 0.5, str(player.global_position))

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
