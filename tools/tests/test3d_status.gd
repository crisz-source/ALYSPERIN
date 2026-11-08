extends Node
## Testes dos efeitos de status (Etapa B): lentidão, congelar, queimar, veneno,
## atordoar, medo, provocar — no inimigo e no jogador — e o comando /efeito.

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


func _reset() -> void:
	player.global_position = Vector3(32, 0, 18)
	player.velocity = Vector3.ZERO
	player._change_state(Player.State.MOVE)
	player.status.clear_all()
	player.health.revive()
	fake.defend_held = false
	fake.move_direction = Vector2.ZERO
	fake.aim_direction = Vector3.FORWARD
	enemy.global_position = Vector3(32, 0, 12)
	enemy.velocity = Vector3.ZERO
	enemy.status.clear_all()
	enemy.target = null
	enemy._change_state(BasicEnemy.State.IDLE)
	enemy.health.max_health = 500
	enemy.health.current_health = 500
	enemy.set_physics_process(false)


func _label(node: Node) -> Label3D:
	return node.get_node_or_null("StatusLabel") as Label3D


func _run() -> void:
	Hitstop.enabled = false
	arena = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	enemy = arena.get_node("Entities/BasicEnemy1")
	for other: String in ["BasicEnemy2", "BasicEnemy3"]:
		var e: BasicEnemy = arena.get_node("Entities/" + other)
		e.set_physics_process(false)
		e.global_position += Vector3(0, 0, 60)
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	await frames(3)
	_reset()

	print("--- 1. componente ---")
	check("jogador e inimigo têm StatusEffects", player.status is StatusEffects and enemy.status is StatusEffects)
	enemy.status.apply(StatusEffects.SLOW, 2.0, 0.3)
	enemy.status.apply(StatusEffects.SLOW, 1.0, 0.5)
	check("mais forte substitui (força e duração dele)", is_equal_approx(enemy.status.remaining(StatusEffects.SLOW), 1.0)
		and is_equal_approx(enemy.status.speed_multiplier(), 0.5))
	enemy.status.apply(StatusEffects.SLOW, 3.0, 0.5)
	check("igual estende a duração", is_equal_approx(enemy.status.remaining(StatusEffects.SLOW), 3.0))
	enemy.status.apply(StatusEffects.SLOW, 9.0, 0.2)
	check("mais fraco é ignorado", is_equal_approx(enemy.status.remaining(StatusEffects.SLOW), 3.0)
		and is_equal_approx(enemy.status.speed_multiplier(), 0.5))
	await frames(2)
	check("nome do efeito aparece acima da cabeça", _label(enemy) != null and _label(enemy).visible and _label(enemy).text == "Lento", _label(enemy).text if _label(enemy) else "sem label")
	enemy.status.clear_all()
	await frames(1)
	check("sem efeitos: texto some", not _label(enemy).visible)

	print("--- 2. lentidão no inimigo ---")
	_reset()
	enemy.global_position = Vector3(32, 0, 10)
	enemy.status.apply(StatusEffects.SLOW, 5.0, 0.5)
	enemy.set_physics_process(true)
	await seconds(0.6)
	var slowed: float = Player.flat(enemy.velocity).length()
	check("persegue com metade da velocidade", enemy.state == BasicEnemy.State.CHASE and slowed <= enemy.move_speed * 0.5 + 0.05 and slowed > 0.5, "%.2f de %.2f" % [slowed, enemy.move_speed])

	print("--- 3. congelar no inimigo ---")
	_reset()
	enemy.set_physics_process(true)
	enemy.status.apply(StatusEffects.FREEZE, 1.0)
	await frames(2)
	check("congelado: parado (atordoado) e azulado", enemy.state == BasicEnemy.State.STAGGER and enemy._body_material.albedo_color.b > 0.8, str(enemy._body_material.albedo_color))
	check("texto Congelado", _label(enemy).text.contains("Congelado"), _label(enemy).text)
	await seconds(1.2)
	check("descongela sozinho", enemy.state != BasicEnemy.State.STAGGER and not enemy.status.has(StatusEffects.FREEZE))

	print("--- 4. queimadura no inimigo ---")
	_reset()
	enemy.status.apply(StatusEffects.BURN, 3.0, 6.0, player)
	enemy.set_physics_process(true)
	enemy.detect_radius = 0.1
	await seconds(3.1)
	var burned: int = 500 - enemy.health.current_health
	check("6 de dano por segundo por 3 s = 18", burned == 18, str(burned))
	check("queimadura não interrompe (não fica em 'ferido')", enemy.state != BasicEnemy.State.HURT, BasicEnemy.State.keys()[enemy.state])
	enemy.detect_radius = 8.1

	print("--- 5. veneno no jogador ---")
	_reset()
	player.status.apply(StatusEffects.POISON, 2.0, 4.0)
	player.health.set_invulnerable(true)
	await seconds(2.1)
	var poisoned: int = player.health.max_health - player.health.current_health
	check("veneno: 4/s por 2 s = 8, mesmo invulnerável", poisoned == 8, str(poisoned))
	check("veneno não joga no estado de dor", player.state == Player.State.MOVE, Player.State.keys()[player.state])
	player.health.set_invulnerable(false)
	player.status.apply(StatusEffects.POISON, 1.0, 4.0)
	await frames(2)
	check("envenenado: tinta verde por cima do corpo", (player.get("_tint_material") as StandardMaterial3D).albedo_color.a > 0.2)

	print("--- 6. congelar no jogador ---")
	_reset()
	player.status.apply(StatusEffects.FREEZE, 1.0)
	fake.press_attack()
	fake.move_direction = Vector2(0, -1)
	await frames(10)
	check("congelado: não ataca nem anda", player.state == Player.State.MOVE and Player.flat(player.velocity).length() < 0.1)
	await seconds(1.0)
	fake.press_attack()
	await frames(3)
	check("descongelou: volta a atacar", player.state == Player.State.ATTACK, Player.State.keys()[player.state])
	_reset()

	print("--- 7. lentidão no jogador ---")
	player.status.apply(StatusEffects.SLOW, 3.0, 0.5)
	fake.move_direction = Vector2(0, -1)
	await seconds(0.5)
	var speed: float = Player.flat(player.velocity).length()
	check("anda na metade da velocidade", absf(speed - player.max_speed * 0.5) < 0.1, "%.2f" % speed)
	_reset()

	print("--- 8. medo ---")
	enemy.set_physics_process(true)
	enemy.status.apply(StatusEffects.FEAR, 1.5, 0.0, player)
	var d0: float = enemy.global_position.distance_to(player.global_position)
	await seconds(1.0)
	check("inimigo com medo foge e não ataca", enemy.global_position.distance_to(player.global_position) > d0 + 1.0
		and enemy.state != BasicEnemy.State.WINDUP and enemy.state != BasicEnemy.State.LUNGE, "%.1f -> %.1f" % [d0, enemy.global_position.distance_to(player.global_position)])
	_reset()
	player.status.apply(StatusEffects.FEAR, 1.0, 0.0, enemy)
	fake.move_direction = Vector2(0, -1)  # tenta ir na direção do inimigo
	var p0: float = player.global_position.distance_to(enemy.global_position)
	await seconds(0.6)
	check("jogador com medo foge do inimigo (comando ignorado)", player.global_position.distance_to(enemy.global_position) > p0 + 1.0, "%.1f -> %.1f" % [p0, player.global_position.distance_to(enemy.global_position)])
	_reset()

	print("--- 9. atordoar e provocar mostram o efeito ---")
	enemy.apply_stun(1.0)
	enemy.apply_taunt(player, 1.0)
	await frames(2)
	check("textos Atordoado e Provocado", _label(enemy).text.contains("Atordoado") and _label(enemy).text.contains("Provocado"), _label(enemy).text)
	_reset()

	print("--- 10. morte limpa os efeitos ---")
	enemy.status.apply(StatusEffects.POISON, 10.0, 2.0)
	enemy.health.apply_damage(DamageInfo.new(9999))
	await frames(1)
	check("morreu: sem efeitos", enemy.status.active_ids().is_empty())

	print("--- 10b. esqueleto animado ---")
	var other: BasicEnemy = arena.get_node("Entities/BasicEnemy2")
	check("monstro é o esqueleto lacaio (cubo escondido)", other.get_node_or_null("Model/Skin") != null and not other.get_node("Model/BodyPlaceholder").visible)
	other.global_position = Vector3(32, 0, 12)
	other.set_physics_process(true)
	_reset()
	await frames(10)
	check("perseguindo: corrida", other.state == BasicEnemy.State.CHASE and other.current_animation() == "Running_A", "%s %s" % [BasicEnemy.State.keys()[other.state], other.current_animation()])
	var n := 0
	while other.state != BasicEnemy.State.WINDUP and n < 300:
		await frames(1)
		n += 1
	await frames(1)
	check("preparando o golpe: animação de estocada", other.current_animation() == "1H_Melee_Attack_Stab", other.current_animation())
	other.health.apply_damage(DamageInfo.new(9999, Vector3.ZERO, player))
	await frames(2)
	check("morto: esqueleto desmonta (animação de morte)", other.current_animation() == "Death_C_Skeletons", other.current_animation())

	print("--- 11. comando /efeito ---")
	var console: AdminConsole = arena.find_children("*", "AdminConsole", true, false)[0] if not arena.find_children("*", "AdminConsole", true, false).is_empty() else null
	if console:
		var reply: String = console.execute("/efeito veneno eu")
		check("/efeito veneno eu", player.status.has(StatusEffects.POISON), reply)
		reply = console.execute("/efeito xyz")
		check("/efeito com nome errado explica os nomes", reply.contains("lento") and reply.contains("congelar"), reply)
	else:
		check("arena tem console de admin", false)

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
