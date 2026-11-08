extends Node
## Testes: menu de testes (P) e Luz curativa com seleção de aliados
## (mira de cura, selecionar 1+, esverdeados, mensagem, Espaço cura, cancelar).

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"

var _failures: int = 0
var _passes: int = 0
var player: Player
var fake: Node
var hud: Hud


func check(label: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + label + ("" if detail.is_empty() else " | " + detail))
	if ok:
		_passes += 1
	else:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _ready() -> void:
	_run.call_deferred()


## Ponto do chão para onde a mira aponta, na altura do peito de um aliado.
func _aim_point() -> Vector3:
	var cam: Camera3D = player.camera_rig().camera
	var c: Vector2 = cam.get_viewport().get_visible_rect().size / 2.0
	var o: Vector3 = cam.project_ray_origin(c)
	var n: Vector3 = cam.project_ray_normal(c)
	var p: Vector3 = o + n * ((1.0 - o.y) / n.y)
	return Vector3(p.x, 0.0, p.z)


func _key(action: String) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame


func _run() -> void:
	Hitstop.enabled = false
	var arena: Node = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	player = arena.get_node("Entities/Player")
	hud = arena.get_node("Hud")
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	for n: String in ["BasicEnemy1", "BasicEnemy2", "BasicEnemy3"]:
		(arena.get_node("Entities/" + n) as BasicEnemy).set_physics_process(false)
	await frames(5)
	var menu: TestMenu = arena.get_node("TestMenu")
	var crosshair: Crosshair = hud.get_node("Crosshair")
	var hint: Label = hud.get_node("HealHint")

	print("--- 1. menu de testes ---")
	await _key("debug_menu")
	check("tecla P abre o menu e solta o mouse", menu.is_open and player.input_blocked)
	menu.play_devotee()
	check("menu troca para Devoto", player.player_class.display_name == "Devoto")
	var allies: Array[AllyDummy] = menu.spawn_allies()
	await frames(3)
	check("menu cria 3 aliados de teste feridos (40/100)", allies.size() == 3 and allies.all(func(a: AllyDummy) -> bool: return a.health.current_health == 40))
	await _key("debug_menu")
	check("P de novo fecha o menu", not menu.is_open and not player.input_blocked)

	print("--- 2. modo de seleção ---")
	player.mana.restore_full()
	fake.press_ability(0)
	await frames(2)
	check("tecla da Luz curativa abre a seleção (sem gastar mana)", player.is_heal_targeting() and player.mana.current() == player.mana.max_mana)
	check("mira muda para o formato de cura", crosshair.heal_mode and crosshair.visible)
	check("mensagem: passe a mira nos aliados", hint.visible and hint.text.begins_with("Passe a mira nos aliados"), hint.text)
	for a: AllyDummy in allies:
		a.global_position += Vector3(30, 0, 0)  # todos fora da mira
	await frames(2)
	fake.press_attack()
	await frames(2)
	check("clique sem aliado na mira não seleciona e não ataca", player.heal_selection().is_empty() and player.state == Player.State.MOVE)
	allies[0].global_position = _aim_point()
	await frames(3)
	check("aliado no centro: mira de cura reage", crosshair.ally_targeted and player.ally_in_crosshair() == allies[0])
	check("passar a mira já seleciona (sem clicar)", player.heal_selection().size() == 1 and allies[0].is_heal_selected())
	check("aliado selecionado fica esverdeado", allies[0]._material.albedo_color.g > 0.85)
	check("mensagem: aperte Espaço para curar (1)", hint.text == "Aperte Espaço para curar  (1 selecionado)", hint.text)
	allies[0].global_position += Vector3(4, 0, 0)
	allies[1].global_position = _aim_point()
	await frames(3)
	check("dá para selecionar mais de um", player.heal_selection().size() == 2 and allies[1].is_heal_selected())
	check("mensagem conta 2", hint.text == "Aperte Espaço para curar  (2 selecionados)", hint.text)
	allies[1].global_position += Vector3(-4, 0, 0)
	await frames(3)
	allies[1].global_position = _aim_point()  # passa a mira de novo no mesmo aliado
	await frames(3)
	check("passar de novo não desmarca", player.heal_selection().size() == 2 and allies[1].is_heal_selected())
	allies[1].global_position += Vector3(-4, 0, 0)
	fake.press_attack()
	await frames(2)
	check("clique não ataca no modo de cura", player.state == Player.State.MOVE and player.is_heal_targeting())

	print("--- 3. Espaço cura ---")
	var mana0: int = player.mana.current()
	var pos0: Vector3 = player.global_position
	fake.press_dodge()
	await frames(2)
	check("Espaço cura os selecionados (+25 cada)", allies[0].health.current_health == 65 and allies[1].health.current_health == 65 and allies[2].health.current_health == 40,
		"%d %d %d" % [allies[0].health.current_health, allies[1].health.current_health, allies[2].health.current_health])
	check("mana: 15 por uso, mesmo curando 2 aliados", player.mana.current() == mana0 - 15, "%d -> %d" % [mana0, player.mana.current()])
	check("Espaço não esquivou", player.state == Player.State.MOVE and player.global_position.distance_to(pos0) < 0.3)
	check("seleção termina: verde sai, mira volta, mensagem some", not player.is_heal_targeting() and not allies[0].is_heal_selected() and not crosshair.heal_mode and not hint.visible)
	check("recarga começa após curar", player.ability_cooldown_ratio(0) > 0.5)

	print("--- 4. cancelar, sem seleção, mana, Graça ---")
	await get_tree().create_timer(3.2).timeout
	fake.press_ability(0)
	await frames(2)
	fake.press_dodge()
	await frames(2)
	check("Espaço sem ninguém selecionado: avisa e continua escolhendo", player.is_heal_targeting()
		and (hud.get_node("MessageBox/Text") as Label).text == "Selecione um aliado primeiro.")
	fake.defend_held = true
	await frames(2)
	fake.defend_held = false
	check("botão direito cancela", not player.is_heal_targeting())
	fake.press_ability(0)
	await frames(2)
	fake.press_ability(0)
	await frames(2)
	check("mesma tecla de novo cancela", not player.is_heal_targeting())
	allies[0].health.current_health = allies[0].health.max_health
	allies[0].global_position = _aim_point()
	player.mana._current = 10.0
	fake.press_ability(0)
	await frames(3)
	fake.press_dodge()
	await frames(2)
	check("mana insuficiente: avisa e não cura", player.is_heal_targeting() and player.mana.current() == 10
		and (hud.get_node("MessageBox/Text") as Label).text.begins_with("Mana insuficiente"))
	player.mana.restore_full()
	fake.press_dodge()
	await frames(2)
	check("Graça: aliado com vida cheia ganha escudo de vida (12)", allies[0].health.shield_points == 12, str(allies[0].health.shield_points))

	print("--- 4c. Oração de cura (botão direito) ---")
	var sec_box: ColorRect = hud.get_node_or_null("AbilityBar/AbilitySecondary")
	check("barra mostra o espaço 'Dir' do Sacerdote", sec_box != null and (sec_box.get_node("Key") as Label).text == "Dir")
	await get_tree().create_timer(0.2).timeout
	player.health.current_health = 50
	player.mana.restore_full()
	var mana_r: int = player.mana.current()
	fake.defend_held = true
	await frames(2)
	fake.defend_held = false
	await get_tree().create_timer(0.5).timeout
	check("botão direito cura você mesmo (+25, -15 de mana)", player.health.current_health == 75 and player.mana.current() == mana_r - 15,
		"vida=%d mana %d->%d" % [player.health.current_health, mana_r, player.mana.current()])
	check("recarga da Oração de cura", player.secondary_cooldown_ratio() > 0.5)
	fake.defend_held = true
	await frames(2)
	fake.defend_held = false
	await get_tree().create_timer(0.5).timeout
	check("durante a recarga não cura de novo", player.health.current_health == 75)
	await get_tree().create_timer(5.6).timeout
	fake.press_ability(0)
	await frames(2)
	var hp_t: int = player.health.current_health
	fake.defend_held = true
	await frames(2)
	fake.defend_held = false
	await get_tree().create_timer(0.5).timeout
	check("no modo de seleção, botão direito só cancela (não cura você)", not player.is_heal_targeting() and player.health.current_health == hp_t)
	player.health.current_health = player.health.max_health
	fake.defend_held = true
	await frames(2)
	fake.defend_held = false
	await get_tree().create_timer(0.5).timeout
	check("Graça na Oração: vida cheia vira escudo (12)", player.health.shield_points >= 12, str(player.health.shield_points))
	menu.play_guardian()
	await frames(2)
	check("Guardião não tem espaço 'Dir'", hud.get_node_or_null("AbilityBar/AbilitySecondary") == null)
	fake.defend_held = true
	await frames(3)
	check("Guardião: botão direito continua sendo defesa", player.state == Player.State.BLOCK)
	fake.defend_held = false
	await frames(2)
	menu.play_devotee()

	print("--- 4b. subir de nível enche vida e mana ---")
	player.health.current_health = 20
	player.mana._current = 3.0
	player.gain_xp(1)  # exp. sem subir de nível
	check("ganhar exp. sem subir NÃO enche", player.health.current_health == 20 and player.mana.current() == 3)
	print("--- 5. animação de nível 4 s ---")
	player.gain_xp(player.stats.xp_to_next())
	check("subir de nível enche vida e mana (100%)", player.health.current_health == player.health.max_health and player.mana.current() == player.mana.max_mana,
		"vida %d/%d mana %d/%d" % [player.health.current_health, player.health.max_health, player.mana.current(), player.mana.max_mana])
	await frames(2)
	var effect: LevelUpEffect = null
	for c: Node in player.get_node("Model").get_children():
		if c is LevelUpEffect:
			effect = c
	var level_text: FloatingText = null
	for c: Node in player.get_children():
		if c is FloatingText and (c as FloatingText).text.begins_with("Nível"):
			level_text = c
	await get_tree().create_timer(1.5).timeout
	check("texto 'Nível N!' ainda visível aos 1,5 s (antes sumia em 0,9 s)", is_instance_valid(level_text))
	await get_tree().create_timer(0.6).timeout
	check("texto 'Nível N!' some por volta de 1,9 s", not is_instance_valid(level_text))
	await get_tree().create_timer(0.9).timeout
	check("ainda visível aos 3 s", is_instance_valid(effect))
	await get_tree().create_timer(1.5).timeout
	check("some por volta dos 4 s", not is_instance_valid(effect))

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
