extends Node
## Testes da migração 3D (etapa 2): área de protótipo — mapa, Disciplina,
## placa, porta/alavanca/visão, itens no chão, baús, descartar, NPC e missão
## em etapas, morte/continuar mantendo itens, inimigos não renascem.

const FAKE_INPUT := "res://tools/tests/fake_input.gd"
const AREA := "res://game/world/areas/prototype_area/prototype_area.tscn"
const D := "res://game/items/data/"

var _failures: int = 0
var _passes: int = 0
var area: Node
var player: Player
var fake: Node
var hud: Hud
var box: DialogueBox


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


func draw() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func item(name: String) -> ItemData:
	return load(D + name + ".tres")


func t(x: int, y: int) -> Vector3:
	return Vector3(x + 0.5, 0.0, y + 0.5)


func msg() -> String:
	return (hud.get_node("MessageBox/Text") as Label).text


func _go(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	await frames(3)


func _press_f() -> void:
	fake.press_interact()
	await frames(2)


func _talk_through() -> Array[String]:
	fake.press_interact()
	await frames(2)
	var seen: Array[String] = []
	var guard := 0
	while box.is_open and guard < 10:
		seen.append(box.current_text())
		box.advance()
		await frames(1)
		guard += 1
	await draw()
	return seen


func _enemies() -> Array[BasicEnemy]:
	var list: Array[BasicEnemy] = []
	for n: Node in area.get_node("Entities").get_children():
		if n is BasicEnemy and is_instance_valid(n) and not (n as BasicEnemy).health.is_dead:
			list.append(n)
	return list


func _run() -> void:
	Hitstop.enabled = false
	area = load(AREA).instantiate()
	get_tree().root.add_child(area)
	get_tree().current_scene = area
	player = area.get_node("Entities/Player")
	hud = area.get_node("Hud")
	box = area.get_node("DialogueBox")
	fake = player.get_node("PlayerInput")
	fake.set_script(load(FAKE_INPUT))
	await frames(3)
	var select: ClassSelectScreen = area.get_node("ClassSelectScreen")
	var prompt: Label3D = player.get_node("InteractPrompt")

	print("--- 1. início ---")
	check("cena principal é a área 3D", ProjectSettings.get_setting("application/run/main_scene") == AREA)
	check("escolha de Disciplina ao começar (jogador bloqueado)", select.is_open and player.input_blocked)
	select.choose_class(0)  # Guardião
	await frames(2)
	check("Guardião aplicado e jogador livre", player.player_class.display_name == "Guardião" and not player.input_blocked)
	for e: BasicEnemy in _enemies():
		e.set_physics_process(false)
	check("8 inimigos e mapa em blocos", _enemies().size() == 8 and (area.get_node("Blocks") as GridMap).get_used_cells().size() == 1422)
	check("nasce na sala inicial", player.global_position.distance_to(t(11, 23)) < 0.1, str(player.global_position))
	fake.move_direction = Vector2(-1, 0)
	await seconds(2.0)
	fake.move_direction = Vector2.ZERO
	check("parede de bloco segura o jogador (x ≈ 4,35)", absf(player.global_position.x - 4.35) < 0.1, "x=%.2f" % player.global_position.x)

	print("--- 2. placa ---")
	await _go(t(7, 19) + Vector3(0, 0, 1.1))
	check("aviso '[F] Ler'", prompt.visible and prompt.text == "[F] Ler", prompt.text)
	await _press_f()
	check("placa mostra o texto", msg().begins_with("Placa provisória"), msg())

	print("--- 3. porta, visão e alavanca ---")
	var door: Door = area.get_node("Entities/DoorSoutheast")
	await _go(t(49, 31))
	fake.move_direction = Vector2(1, 0)
	await seconds(1.0)
	fake.move_direction = Vector2.ZERO
	check("porta fechada bloqueia o corredor", player.global_position.x < 50.8, "x=%.2f" % player.global_position.x)
	await frames(2)
	check("aviso '[F] Abrir'", prompt.text == "[F] Abrir", prompt.text)
	await _press_f()
	check("abrir com a mão: trancada", not door.is_open and msg() == door.locked_message)
	var watcher: BasicEnemy = area.get_node("Entities/BasicEnemy6")
	watcher.global_position = t(53, 31)
	watcher.set_physics_process(true)
	await frames(8)
	check("porta fechada bloqueia a visão", watcher.state == BasicEnemy.State.IDLE, BasicEnemy.State.keys()[watcher.state])
	watcher.set_physics_process(false)
	await _go(t(66, 7) + Vector3(0, 0, 1.1))
	check("aviso '[F] Puxar'", prompt.text == "[F] Puxar", prompt.text)
	await _press_f()
	check("alavanca abre a porta", door.is_open and msg() == "Algo se abriu ao longe.")
	await _go(t(49, 31))
	fake.move_direction = Vector2(1, 0)
	await seconds(1.0)
	fake.move_direction = Vector2.ZERO
	check("porta aberta deixa passar", player.global_position.x > 52.5, "x=%.2f" % player.global_position.x)
	await _go(t(49, 31))
	watcher.target = null
	watcher._change_state(BasicEnemy.State.IDLE)
	watcher.set_physics_process(true)
	await frames(8)
	check("porta aberta: inimigo enxerga", watcher.state != BasicEnemy.State.IDLE)
	watcher.set_physics_process(false)
	watcher.global_position = t(59, 29)

	print("--- 4. itens no chão, baú, descartar ---")
	var blade: ItemPickup = area.get_node("Entities/Pickup1")
	await _go(blade.global_position + Vector3(0, 0, 0.9))
	check("aviso '[F] Pegar Lâmina leve'", prompt.text == "[F] Pegar Lâmina leve", prompt.text)
	await _press_f()
	check("pegou a lâmina", player.inventory.count_of(item("light_blade")) == 1 and msg() == "Pegou Lâmina leve.")
	var chest: Chest = area.get_node("Entities/Chest1")
	await _go(chest.global_position + Vector3(0, 0, 1.1))
	await _press_f()
	check("baú: tudo para a bolsa", chest.remaining().is_empty() and player.inventory.count_of(item("heavy_axe")) == 1, msg())
	var count_before: int = area.get_node("Entities").get_child_count()
	var axe_slot := -1
	for i in player.inventory.slots.size():
		var st: ItemStack = player.inventory.get_slot(i)
		if st and st.item == item("heavy_axe"):
			axe_slot = i
	player.discard_inventory_slot(axe_slot)
	await frames(2)
	check("descartar cria item no chão", area.get_node("Entities").get_child_count() == count_before + 1)
	await frames(2)
	await _press_f()
	check("pegar de volta", player.inventory.count_of(item("heavy_axe")) == 1)

	print("--- 5. NPC e missão em etapas ---")
	var npc: Npc = area.get_node("Entities/NpcQuestGiver")
	var marker: Label3D = npc.get_node("QuestMarker")
	await _go(npc.global_position + Vector3(0, 0, 1.1))
	await draw()
	check("missão nova: '!'", marker.text == "!", marker.text)
	await _talk_through()
	check("aceita; em andamento sem marcador", player.quest_log.is_active(npc.quest) and marker.text == "")
	var killed := 0
	for e: BasicEnemy in _enemies():
		if killed < 3:
			e.health.apply_damage(DamageInfo.new(999, Vector3.ZERO, player))
			killed += 1
	await frames(2)
	await draw()
	check("etapa cumprida com continuação: '?'", marker.text == "?", marker.text)
	await _talk_through()
	for i in player.inventory.slots.size():
		var st: ItemStack = player.inventory.get_slot(i)
		if st and st.item == item("healing_herb"):
			player.inventory.slots[i] = null
	player.inventory.add(ItemStack.create(item("healing_herb"), 2))
	await draw()
	check("última etapa cumprida: '*'", marker.text == "*", marker.text)
	await _talk_through()
	check("missão entregue", player.quest_log.is_completed(npc.quest) and msg() == "Missão concluída: Ameaça no salão")

	print("--- 6. morrer e continuar mantendo itens; sem renascimento ---")
	await seconds(4.5)
	check("derrotados não renascem (5 vivos)", _enemies().size() == 5, str(_enemies().size()))
	var axe_count: int = player.inventory.count_of(item("heavy_axe"))
	player.health.apply_damage(DamageInfo.new(999, Vector3.ZERO, null))
	await seconds(1.4)
	var death: DeathScreen = area.get_node("DeathScreen")
	check("tela de morte", death.is_open)
	death.choose_yes()
	await frames(2)
	check("continua no início, com os itens", not player.health.is_dead and player.global_position.distance_to(t(11, 23)) < 0.5
		and player.inventory.count_of(item("heavy_axe")) == axe_count)

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
