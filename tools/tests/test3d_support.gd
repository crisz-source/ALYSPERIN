extends Node
## Testes das habilidades de nível alto (SupportSpellData) do Guardião e do Devoto.

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"
const CLASSES := "res://game/classes/data/"

var _failures: int = 0
var _passes: int = 0
var arena: GameArea
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
	player.health.shield_points = 0
	player.mana.restore_full()
	player._ability_cooldowns.fill(0.0)
	fake.defend_held = false
	fake.move_direction = Vector2.ZERO
	fake.aim_direction = Vector3.FORWARD


## Usa a habilidade da tecla `slot` e espera ela terminar.
func cast(slot: int) -> void:
	fake.press_ability(slot)
	await frames(30)


func _hit(target_health: HealthComponent, amount: int, from: Node3D) -> int:
	var before: int = target_health.current_health
	target_health.apply_damage(DamageInfo.new(amount, Vector3.ZERO, from))
	return before - target_health.current_health


func _run() -> void:
	Hitstop.enabled = false
	arena = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	enemy = arena.get_node("Entities/BasicEnemy1")
	for n: Node in arena.get_node("Entities").get_children():
		if n is BasicEnemy:
			n.set_physics_process(false)
			(n as Node3D).global_position += Vector3(0, 0, 40)
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	await frames(3)
	player.gain_xp(200000)  # nível máximo: tudo liberado
	await frames(2)
	check("nível 50+ para liberar tudo", player.stats.level >= 50, str(player.stats.level))

	print("--- Guardião ---")
	player.apply_class(load(CLASSES + "guardian.tres"))
	var allies: Array[AllyDummy] = arena.spawn_test_allies(1, 100)
	await frames(2)
	var ally: AllyDummy = allies[0]
	ally.global_position = player.global_position + Vector3(2, 0, 0)
	_reset()
	await frames(2)

	await cast(3)  # Muralha compartilhada
	check("Muralha: você e o aliado ficam Protegidos", player.status.has(StatusEffects.PROTECT) and ally.status.has(StatusEffects.PROTECT))
	check("Protegido: 20 de dano vira 14 no aliado (-30%)", _hit(ally.health, 20, enemy) == 14)
	_reset()
	ally.health.revive()

	await cast(4)  # Bastião eterno
	check("Bastião: Inabalável ativo", player.status.has(StatusEffects.UNDYING))
	_hit(player.health, 99999, enemy)
	check("Inabalável: dano enorme deixa em 1 de vida, vivo", player.health.current_health == 1 and not player.health.is_dead, str(player.health.current_health))
	_reset()

	ally.global_position = player.global_position + Vector3(1.5, 0, 0)
	await cast(5)  # Fortaleza viva
	var dome: Node = arena.find_child("Dome", true, false)
	check("Fortaleza: cúpula criada", dome is SupportZone)
	await frames(40)
	check("dentro da cúpula: aliado Protegido (50%)", ally.status.has(StatusEffects.PROTECT) and is_equal_approx(ally.status.strength_of(StatusEffects.PROTECT), 0.5))
	ally.global_position = player.global_position + Vector3(8, 0, 0)
	await frames(50)
	check("fora da cúpula: proteção acaba", not ally.status.has(StatusEffects.PROTECT))
	await seconds(8.0)
	check("cúpula some sozinha depois de 8 s", not is_instance_valid(dome))
	_reset()

	print("--- Devoto ---")
	player.apply_class(load(CLASSES + "devotee.tres"))
	_reset()
	ally.global_position = player.global_position + Vector3(2, 0, 0)
	await cast(2)  # Bênção de proteção sem aliado na mira -> em você
	check("Bênção sem aliado na mira: escudo de 40 em você", player.health.shield_points == 40, str(player.health.shield_points))
	_reset()

	ally.health.current_health = 40
	ally.global_position = player.global_position + Vector3(1.5, 0, 0)
	await cast(3)  # Círculo de cura
	check("Círculo de cura criado", arena.find_child("HealZone", true, false) is SupportZone)
	await seconds(2.0)
	check("aliado dentro do círculo recupera vida (8/s)", ally.health.current_health >= 40 + 14, str(ally.health.current_health))
	_reset()

	ally.health.apply_damage(DamageInfo.new(9999))
	await frames(2)
	check("aliado caiu", ally.health.is_dead)
	ally.global_position = player.global_position + Vector3(2, 0, 0)
	var mana0: int = player.mana.current()
	await cast(4)  # Ressurreição
	check("Ressurreição levanta o aliado com metade da vida", not ally.health.is_dead and ally.health.current_health == 50, str(ally.health.current_health))
	check("gastou a mana", player.mana.current() < mana0)
	_reset()
	mana0 = player.mana.current()
	await cast(4)
	check("sem aliado caído: avisa e não gasta", player.mana.current() == mana0)
	_reset()

	player.self_revive_available = true
	_hit(player.health, 99999, enemy)
	await frames(2)
	check("sozinho: revive ao morrer com metade da vida", not player.health.is_dead and player.state != Player.State.DEAD
		and player.health.current_health == player.health.max_health / 2, str(player.health.current_health))
	_reset()
	player.self_revive_available = false
	player.health.grant_invulnerability(0.0)
	player.health._invulnerable_time = 0.0
	_hit(player.health, 99999, enemy)
	await frames(2)
	check("segunda morte (carga usada): morre de verdade", player.state == Player.State.DEAD)
	player.respawn(Vector3(32, 0, 18))
	check("continuar recarrega a ressurreição", player.self_revive_available)
	_reset()

	player.health.current_health = 10
	ally.health.current_health = 10
	ally.global_position = player.global_position + Vector3(3, 0, 0)
	player.status.apply(StatusEffects.POISON, 10.0, 2.0)
	ally.status.apply(StatusEffects.SLOW, 10.0, 0.5)
	await cast(5)  # Milagre
	check("Milagre: vida cheia em você e no aliado", player.health.current_health == player.health.max_health and ally.health.current_health == ally.health.max_health)
	check("Milagre: remove efeitos negativos", not player.status.has(StatusEffects.POISON) and not ally.status.has(StatusEffects.SLOW))

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
