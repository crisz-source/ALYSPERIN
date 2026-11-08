extends Node
## Testes: mira (livre/mirando, sem travar), distância da câmera (roda do
## mouse), efeito de subir de nível, barra de experiência embaixo, FPS/ping/hora.

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"

var _failures: int = 0
var _passes: int = 0


func check(label: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + label + ("" if detail.is_empty() else " | " + detail))
	if ok:
		_passes += 1
	else:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
	# A mira é atualizada no quadro de desenho (_process): garante que ele rodou.
	await get_tree().process_frame
	await get_tree().process_frame


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	Hitstop.enabled = false
	var arena: Node = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	var player: Player = arena.get_node("Entities/Player")
	var fake: Node = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	var hud: Hud = arena.get_node("Hud")
	var enemy: BasicEnemy = arena.get_node("Entities/BasicEnemy1")
	for n: String in ["BasicEnemy1", "BasicEnemy2", "BasicEnemy3"]:
		(arena.get_node("Entities/" + n) as BasicEnemy).set_physics_process(false)
	await frames(5)
	var crosshair: Crosshair = hud.get_node("Crosshair")
	var rig: PlayerCamera = player.camera_rig()

	print("--- 1. mira ---")
	check("mira no centro da tela", absf(crosshair.position.x + crosshair.size.x / 2.0 - 320.0) < 1.0 and absf(crosshair.position.y + crosshair.size.y / 2.0 - 180.0) < 1.0)
	enemy.global_position = player.global_position + Vector3(8, 0, 8)
	await frames(3)
	check("sem inimigo no centro: mira livre", crosshair.visible and not crosshair.targeted)
	# Inimigo exatamente no centro da tela: no ponto onde o raio da câmera toca o chão.
	var cam: Camera3D = rig.camera
	var center: Vector2 = cam.get_viewport().get_visible_rect().size / 2.0
	var origin: Vector3 = cam.project_ray_origin(center)
	var normal: Vector3 = cam.project_ray_normal(center)
	var t: float = (0.45 - origin.y) / normal.y
	var aim_point: Vector3 = origin + normal * t
	enemy.global_position = Vector3(aim_point.x, 0, aim_point.z)
	await frames(3)
	var seen: BasicEnemy = hud.enemy_in_crosshair()
	check("inimigo no centro: mira 'mirando' (vermelha)", crosshair.targeted and seen == enemy,
		"ponto=%s visto=%s inimigo_em=%s cam=%s" % [aim_point, seen.name if seen else "nada", enemy.global_position, cam.global_position])
	check("não trava: a câmera não gira sozinha", rig.flat_forward().is_equal_approx(Vector3.FORWARD))
	enemy.global_position += Vector3(4, 0, 0)
	await frames(3)
	check("inimigo sai do centro: volta ao normal", not crosshair.targeted)
	enemy.global_position -= Vector3(4, 0, 0)
	(arena.get_node("InventoryScreen") as InventoryScreen).set_open(true)
	await frames(2)
	check("inventário aberto: mira escondida", not crosshair.visible)
	(arena.get_node("InventoryScreen") as InventoryScreen).set_open(false)
	await frames(2)
	enemy.health.apply_damage(DamageInfo.new(999, Vector3.ZERO, null))
	await frames(2)
	check("inimigo morto não ativa a mira", not crosshair.targeted)

	print("--- 2. distância da câmera ---")
	var arm: SpringArm3D = rig.get_node("Pitch/SpringArm")
	var start: float = arm.spring_length
	for i in 4:
		rig.zoom(true)
	await frames(90)
	check("roda do mouse afasta a câmera", arm.spring_length > start + 3.5, "%.1f -> %.1f" % [start, arm.spring_length])
	for i in 30:
		rig.zoom(true)
	check("limite máximo 14 m", is_equal_approx(rig.target_distance, 14.0))
	for i in 30:
		rig.zoom(false)
	check("limite mínimo 3,5 m", is_equal_approx(rig.target_distance, 3.5))
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	rig._unhandled_input(wheel)
	check("evento da roda (para baixo) afasta 1 m", is_equal_approx(rig.target_distance, 4.5))

	print("--- 3. subir de nível ---")
	player.gain_xp(30)
	await frames(2)
	var effect: LevelUpEffect = null
	for c: Node in player.get_node("Model").get_children():
		if c is LevelUpEffect:
			effect = c
	check("efeito aparece no personagem", effect != null)
	if effect:
		var parts: Dictionary = effect.part_count()
		check("duas asas e coroa com 5 pontas", parts["wings"] == 2 and parts["crown_spikes"] == 5, str(parts))
	await get_tree().create_timer(3.5).timeout
	check("efeito ainda visível aos 3,5 s", is_instance_valid(effect))
	await get_tree().create_timer(2.0).timeout
	check("efeito dura ~5 s e some sozinho", not is_instance_valid(effect))

	print("--- 3b. mira livre do personagem ---")
	var cam2: Camera3D = rig.camera
	var tip_point: Vector3 = (player.get_node("Model/RightHand/SwordPlaceholder") as Node3D).global_transform * Vector3(0, 0.45, 0)
	var tip_screen: Vector2 = cam2.unproject_position(tip_point)
	var head_screen: Vector2 = cam2.unproject_position(player.global_position + Vector3(0, 1.6, 0))
	check("ponta da espada longe do centro (>= 35 px)", tip_screen.distance_to(Vector2(320, 180)) >= 35.0, "%.0f px" % tip_screen.distance_to(Vector2(320, 180)))
	check("cabeça longe do centro (>= 40 px)", head_screen.distance_to(Vector2(320, 180)) >= 40.0, "%.0f px" % head_screen.distance_to(Vector2(320, 180)))

	print("--- 3c. defesa bem-sucedida ---")
	var foe: BasicEnemy = arena.get_node("Entities/BasicEnemy2")
	foe.global_position = player.global_position + Vector3(0, 0, -1.5)
	fake.aim_direction = Vector3.FORWARD
	fake.defend_held = true
	await frames(3)
	player.health._invulnerable_time = 0.0
	var hp_block: int = player.health.current_health
	player.health.apply_damage(DamageInfo.new(10, Vector3.ZERO, foe))
	fake.defend_held = false
	var block_texts: Array[String] = []
	for c: Node in player.get_children():
		if c is FloatingText:
			block_texts.append((c as FloatingText).text)
	check("bloqueio mostra 'Defesa bem-sucedida!' sem dano", block_texts.has("Defesa bem-sucedida!") and player.health.current_health == hp_block, str(block_texts))

	print("--- 4. barra de experiência e informações ---")
	var xp_bar: ColorRect = hud.get_node("XpBar")
	check("barra de exp. ocupa toda a largura, embaixo", xp_bar.position == Vector2(0, 355) and is_equal_approx(xp_bar.size.x, 640.0))
	check("barra de exp. abaixo da barra de habilidades", xp_bar.position.y > (hud.get_node("AbilityBar/Ability1") as Control).position.y + 20.0)
	player.gain_xp(30)
	check("preenchimento da exp. (30/60)", is_equal_approx((hud.get_node("XpBar/Fill") as ColorRect).scale.x, 0.5))
	await get_tree().create_timer(0.6).timeout
	var stats: Label = hud.get_node("Stats")
	var re := RegEx.new()
	re.compile("^FPS \\d+\\nPing -- ms\\n\\d{2}:\\d{2}$")
	check("FPS, Ping e hora no canto inferior direito", re.search(stats.text) != null and stats.position.x > 500, stats.text.replace("\n", " / "))

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
