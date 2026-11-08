extends Node
## Testes da Vila de Brisaclara (portal, dia, aldeões, colisão, limites, volta)
## e do visual de anime (ToonStyle).

const AREA := "res://game/world/areas/prototype_area/prototype_area.tscn"

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


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return area.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))


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
	await frames(3)

	print("--- 1. visual de anime ---")
	var knight_mesh: MeshInstance3D = null
	for m: Node in player.class_model().find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).visible:
			knight_mesh = m
			break
	var mat := knight_mesh.get_active_material(0) as BaseMaterial3D if knight_mesh else null
	check("cavaleiro com luz em faixas (toon)", mat != null and mat.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON)
	check("cavaleiro com contorno escuro (casca invertida)", mat != null and mat.next_pass is BaseMaterial3D
		and (mat.next_pass as BaseMaterial3D).cull_mode == BaseMaterial3D.CULL_FRONT and (mat.next_pass as BaseMaterial3D).grow)
	var grid: GridMap = area.find_children("*", "GridMap", true, false)[0]
	var floor_mat := grid.mesh_library.get_item_mesh(0).surface_get_material(0) as BaseMaterial3D
	check("blocos do mapa também em toon", floor_mat != null and floor_mat.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON)
	var telegraph_ok: bool = true
	for e: Node in area.entities.get_children():
		if e is BasicEnemy:
			var tm := (e.get_node("LungeTelegraph") as MeshInstance3D).material_override as BaseMaterial3D
			telegraph_ok = telegraph_ok and tm.diffuse_mode != BaseMaterial3D.DIFFUSE_TOON
	check("avisos transparentes no chão não mudam", telegraph_ok)

	print("--- 2. portal ---")
	var portal: TravelPortal = area.find_child("VillagePortal", true, false)
	check("portal da vila na sala inicial", portal != null)
	var q := PhysicsPointQueryParameters3D.new()
	q.position = portal.global_position + Vector3.UP
	q.collision_mask = 1
	check("portal em chão livre", not _ray(portal.global_position + Vector3.UP * 2, portal.global_position + Vector3.DOWN).is_empty()
		and area.get_world_3d().direct_space_state.intersect_point(q).is_empty())
	var back_to: Vector3 = player.global_position
	(portal.get_node("Interactable") as Interactable).interact(player)
	await frames(3)

	print("--- 3. na vila ---")
	var village: VillageMap = area.current_village
	check("chegou à vila", village != null and player.global_position.distance_to(village.start_point()) < 1.0)
	var env: Environment = (area.get_node("WorldEnvironment") as WorldEnvironment).environment
	check("de dia: céu, sem neblina", env.background_mode == Environment.BG_SKY and not env.fog_enabled)
	check("sol mais forte e quente", (area.get_node("MoonLight") as DirectionalLight3D).light_energy > 0.8)
	check("chão firme sob o início e a praça", not _ray(village.start_point() + Vector3.UP, village.start_point() + Vector3.DOWN).is_empty()
		and not _ray(village.global_position + Vector3(0, 2, 2), village.global_position + Vector3(0, -1, 2)).is_empty())
	var tavern_hit: Dictionary = _ray(village.global_position + Vector3(-6, 1, -6), village.global_position + Vector3(-12, 1, -6))
	check("casas têm colisão (taverna bloqueia)", not tavern_hit.is_empty())
	var edge_hit: Dictionary = _ray(village.global_position + Vector3(0, 1, 30), village.global_position + Vector3(0, 1, 40))
	check("limite invisível: não sai da vila", not edge_hit.is_empty())
	var villagers: Array[Node] = village.find_children("Villager_*", "", false, false)
	check("3 aldeões", villagers.size() == 3, str(villagers.size()))
	var anim: AnimationPlayer = villagers[0].find_children("*", "AnimationPlayer", true, false)[0]
	check("aldeões animados (Idle)", anim.is_playing() and anim.current_animation == "Idle")
	var said: Array = []
	player.dialogue_requested.connect(func(speaker: String, lines: Array[String], _cb: Callable) -> void: said.append([speaker, lines.size()]))
	(villagers[0].get_node("Interactable") as Interactable).interact(player)
	check("conversar com o ferreiro abre diálogo", not said.is_empty() and String(said[0][0]).contains("ferreiro"), str(said))
	check("nenhum monstro na vila", get_tree().get_nodes_in_group(BasicEnemy.GROUP).all(func(e: Variant) -> bool:
		return (e as Node3D).global_position.distance_to(village.global_position) > 60.0))

	print("--- 4. volta ---")
	(village.get_node("ExitPortal/Interactable") as Interactable).interact(player)
	await frames(3)
	env = (area.get_node("WorldEnvironment") as WorldEnvironment).environment
	check("voltou ao ponto de onde saiu", area.current_village == null and player.global_position.distance_to(back_to) < 0.5)
	check("noite de volta: neblina e cor da área", env.fog_enabled and env.background_mode == Environment.BG_COLOR)
	check("sol volta ao normal", is_equal_approx((area.get_node("MoonLight") as DirectionalLight3D).light_energy, 0.5))
	check("vila removida", not is_instance_valid(village))

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
