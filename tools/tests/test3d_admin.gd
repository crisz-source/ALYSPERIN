extends Node
## Testes do console de administrador: /add players N, /add mob N, /boss, /help.
var _p := 0
var _f := 0
func check(label: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + label + ("" if detail.is_empty() else " | " + detail))
	if ok: _p += 1
	else: _f += 1
func _ready() -> void:
	_run.call_deferred()
func _count(group: StringName) -> int:
	var n := 0
	for node: Node in get_tree().get_nodes_in_group(group):
		if node is BasicEnemy and (node as BasicEnemy).health.is_dead:
			continue
		n += 1
	return n
func _inside_wall(world: World3D, pos: Vector3) -> bool:
	var q := PhysicsPointQueryParameters3D.new()
	q.position = pos + Vector3.UP
	q.collision_mask = 1
	return not world.direct_space_state.intersect_point(q).is_empty()
func _run() -> void:
	Hitstop.enabled = false
	var area: Node = load("res://game/world/areas/prototype_area/prototype_area.tscn").instantiate()
	get_tree().root.add_child(area)
	get_tree().current_scene = area
	for i in 3: await get_tree().process_frame
	var select: ClassSelectScreen = area.get_node("ClassSelectScreen")
	select.choose_class(1)
	var player: Player = area.get_node("Entities/Player")
	var console: AdminConsole = area.get_node("AdminConsole")
	var msg: Label = area.get_node("Hud/MessageBox/Text")
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = "chat"
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame
	check("Enter abre o console e trava o personagem", console.is_open and player.input_blocked)
	var input: LineEdit = console.get_node("Input")
	input.text = "/add players 4"
	input.text_submitted.emit(input.text)
	for i in 5: await get_tree().physics_frame
	check("/add players 4: 4 aliados criados", _count(AllyDummy.GROUP) == 4 and msg.text == "4 aliado(s) de teste adicionado(s) ao grupo.", msg.text)
	check("console fecha depois de executar", not console.is_open and not player.input_blocked)
	var world: World3D = player.get_world_3d()
	var walls := 0
	for a: Node in get_tree().get_nodes_in_group(AllyDummy.GROUP):
		if _inside_wall(world, (a as Node3D).global_position):
			walls += 1
	check("nenhum aliado dentro de parede", walls == 0)
	var before: int = _count(BasicEnemy.GROUP)
	console.execute("/add mob 5")
	for i in 30: await get_tree().physics_frame
	check("/add mob 5: 5 monstros a mais", _count(BasicEnemy.GROUP) == before + 5, "%d -> %d" % [before, _count(BasicEnemy.GROUP)])
	var bad := 0
	for e: Node in get_tree().get_nodes_in_group(BasicEnemy.GROUP):
		if String(e.name).begins_with("MonstroDeTeste") and (_inside_wall(world, (e as Node3D).global_position) or absf((e as Node3D).global_position.y) > 0.2):
			bad += 1
	check("monstros no chão e fora das paredes", bad == 0)
	check("/boss chama Khar'Vesh", console.execute("/boss").contains("Khar'Vesh") and not get_tree().get_nodes_in_group(KharVesh.GROUP).is_empty())
	check("/help lista os comandos", console.execute("/help").contains("/add players N"))
	check("comando desconhecido avisa", console.execute("/voar").begins_with("Comando desconhecido"))
	check("/add mob 0 pede número válido", console.execute("/add mob 0").begins_with("Use um número"))
	var before2: int = _count(BasicEnemy.GROUP)
	var r: String = console.execute("/add mob 50")
	await get_tree().physics_frame
	check("/add mob 50 respeita o limite de 20", _count(BasicEnemy.GROUP) == before2 + 20 and r.contains("limite"), r)
	check("maiúsculas funcionam (/ADD PLAYERS 1)", console.execute("/ADD PLAYERS 1").begins_with("1 aliado"))
	print("RESULTADO: %d passaram, %d falharam" % [_p, _f])
	get_tree().quit(0 if _f == 0 else 1)
