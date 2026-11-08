extends "res://tools/generators/build_3d_core.gd"
## Gera o mundo 3D: objetos (porta, alavanca, placa, baú, NPC), a biblioteca de
## blocos do GridMap e a área de protótipo — MESMO traçado da versão 2D
## (1 tile = 1 m; tile (x, y) 2D -> célula (x, 0, y) 3D).

const AREA_SCENE := "res://game/world/areas/prototype_area/prototype_area.tscn"
const MESH_LIBRARY := "res://game/world/tilesets/dungeon_blocks_placeholder.tres"
const CLASS_SELECT_SCENE := "res://game/ui/class_select/class_select_screen.tscn"
const ITEMS := "res://game/items/data/"
const WALL_HEIGHT: float = 3.0
const FLOOR_A := 0
const FLOOR_B := 1
const WALL := 2

const FLOORS: Array[Rect2i] = [
	Rect2i(4, 18, 14, 10), Rect2i(18, 22, 8, 3), Rect2i(26, 8, 22, 28), Rect2i(48, 12, 8, 3),
	Rect2i(56, 6, 12, 12), Rect2i(48, 30, 8, 3), Rect2i(56, 26, 12, 14),
]
const PILLARS: Array[Rect2i] = [
	Rect2i(31, 13, 2, 2), Rect2i(41, 13, 2, 2), Rect2i(31, 29, 2, 2), Rect2i(41, 29, 2, 2), Rect2i(61, 32, 2, 2),
]
const PLAYER_TILE := Vector2i(11, 23)
const ENEMY_TILES: Array[Vector2i] = [
	Vector2i(34, 19), Vector2i(40, 24), Vector2i(36, 32), Vector2i(60, 10), Vector2i(64, 13),
	Vector2i(59, 29), Vector2i(65, 35), Vector2i(58, 37),
]
const DOOR_TILE := Vector2i(51, 31)
const LEVER_TILE := Vector2i(66, 7)
const SIGN_TILE := Vector2i(7, 19)
const NPC_TILE := Vector2i(6, 24)
const DUNGEON_TILE := Vector2i(11, 19)
const VILLAGE_TILE := Vector2i(15, 25)
const SIGN_TEXT := "Placa provisória: a passagem do sudeste está trancada. A alavanca fica na sala nordeste."
const PICKUPS: Array = [
	[Vector2i(28, 33), "light_blade", 1], [Vector2i(45, 10), "healing_herb", 1], [Vector2i(52, 13), "healing_herb", 1],
	[Vector2i(29, 10), "mana_potion", 1], [Vector2i(52, 31), "mana_potion", 1],
]
const CHESTS: Array = [
	[Vector2i(57, 7), [["heavy_axe", 1], ["healing_herb", 2], ["mana_potion", 1]]],
	[Vector2i(66, 38), [["reinforced_shield", 1], ["healing_herb", 1]]],
]
## Tochas nas paredes das salas (tile, para dar o clima de masmorra).
const TORCHES: Array[Vector2i] = [
	Vector2i(10, 19), Vector2i(36, 9), Vector2i(36, 34), Vector2i(27, 21), Vector2i(46, 21), Vector2i(61, 7), Vector2i(61, 38),
]


func _initialize() -> void:
	var err := OK
	for job: Array in [[_build_door(), "res://game/world/objects/door/door.tscn"],
			[_build_lever(), "res://game/world/objects/lever/lever.tscn"],
			[_build_sign(), "res://game/world/objects/sign_post/sign_post.tscn"],
			[_build_chest(), "res://game/world/objects/chest/chest.tscn"],
			[_build_npc(), "res://game/actors/npcs/npc.tscn"]]:
		err = _save(job[0], job[1])
		if err != OK:
			break
	if err == OK:
		err = _save(_build_class_select(), CLASS_SELECT_SCENE)
	if err == OK:
		err = ResourceSaver.save(_build_mesh_library(), MESH_LIBRARY)
	if err == OK:
		err = _save(_build_area(), AREA_SCENE)
	print("BUILD 3D WORLD ", "OK" if err == OK else "FALHOU: " + error_string(err))
	quit(0 if err == OK else 1)


func _tile_pos(tile: Vector2i) -> Vector3:
	return Vector3(tile.x + 0.5, 0.0, tile.y + 0.5)


func _body3d(node_name: String, script_path: String) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.name = node_name
	b.set_script(load(script_path))
	b.collision_layer = L_WORLD
	b.collision_mask = 0
	return b


func _interactable3d(root: Node, size: Vector3, center: Vector3, prompt_height: float) -> void:
	var area := _area("Interactable", "res://game/components/interactable.gd", L_INTERACTABLE, 0)
	_own(area, root, root)
	_own(_shape(_boxshape(size), center), area, root)
	area.set("prompt_offset", Vector3(0, prompt_height, 0))


# --- Objetos --------------------------------------------------------------

func _build_door() -> Node:
	var root := _body3d("Door", "res://game/world/objects/door/door.gd")
	# Formas reais são criadas pelo script a partir de size_tiles.
	_own(_shape(_boxshape(Vector3(1, 3, 3)), Vector3(0, 1.5, 0)), root, root)
	_own(_mesh("Visual", _box_mesh(Vector3(1, 3, 3)), mat(Color(0.45, 0.3, 0.18), 0.0, true), Vector3(0, 1.5, 0)), root, root)
	_interactable3d(root, Vector3(2, 3, 4), Vector3(0, 1.5, 0), 3.4)
	return root


func _build_lever() -> Node:
	var root := _body3d("Lever", "res://game/world/objects/lever/lever.gd")
	_own(_shape(_boxshape(Vector3(0.6, 0.4, 0.4)), Vector3(0, 0.2, 0)), root, root)
	_own(_mesh("BasePlaceholder", _box_mesh(Vector3(0.6, 0.4, 0.4)), mat(Color(0.35, 0.33, 0.38)), Vector3(0, 0.2, 0)), root, root)
	var pivot := Node3D.new()
	pivot.name = "HandlePivot"
	pivot.position = Vector3(0, 0.4, 0)
	_own(pivot, root, root)
	_own(_mesh("HandlePlaceholder", _box_mesh(Vector3(0.08, 0.7, 0.08)), mat(Color(0.6, 0.6, 0.65)), Vector3(0, 0.35, 0)), pivot, root)
	_interactable3d(root, Vector3(1.6, 1.5, 1.6), Vector3(0, 0.6, 0), 1.6)
	return root


func _build_sign() -> Node:
	var root := _body3d("SignPost", "res://game/world/objects/sign_post/sign_post.gd")
	_own(_shape(_boxshape(Vector3(0.2, 1.4, 0.2)), Vector3(0, 0.7, 0)), root, root)
	_own(_mesh("PostPlaceholder", _box_mesh(Vector3(0.12, 1.4, 0.12)), mat(Color(0.4, 0.28, 0.16)), Vector3(0, 0.7, 0)), root, root)
	_own(_mesh("BoardPlaceholder", _box_mesh(Vector3(0.9, 0.5, 0.08)), mat(Color(0.62, 0.48, 0.3)), Vector3(0, 1.3, 0)), root, root)
	_interactable3d(root, Vector3(1.6, 1.6, 1.6), Vector3(0, 0.8, 0), 2.0)
	return root


func _build_chest() -> Node:
	var root := _body3d("Chest", "res://game/world/objects/chest/chest.gd")
	_own(_shape(_boxshape(Vector3(0.9, 0.6, 0.6)), Vector3(0, 0.3, 0)), root, root)
	_own(_mesh("BoxPlaceholder", _box_mesh(Vector3(0.9, 0.5, 0.6)), mat(Color(0.42, 0.28, 0.15)), Vector3(0, 0.25, 0)), root, root)
	var lid := _mesh("LidPlaceholder", _box_mesh(Vector3(0.92, 0.15, 0.62)), mat(Color(0.5, 0.33, 0.18)), Vector3(0, 0.57, 0))
	_own(lid, root, root)
	_interactable3d(root, Vector3(1.8, 1.2, 1.6), Vector3(0, 0.5, 0), 1.3)
	return root


func _build_npc() -> Node:
	var root := _body3d("Npc", "res://game/actors/npcs/npc.gd")
	_own(_shape(_capsule(0.35, 1.6), Vector3(0, 0.8, 0)), root, root)
	var body := CapsuleMesh.new()
	body.radius = 0.35
	body.height = 1.6
	_own(_mesh("BodyPlaceholder", body, mat(Color(0.45, 0.75, 0.5)), Vector3(0, 0.8, 0)), root, root)
	var marker := Label3D.new()
	marker.name = "QuestMarker"
	marker.position = Vector3(0, 2.2, 0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.fixed_size = true
	marker.pixel_size = 0.0015
	marker.font_size = 48
	marker.modulate = Color(1.0, 0.85, 0.3)
	marker.outline_size = 12
	_own(marker, root, root)
	_interactable3d(root, Vector3(1.8, 1.8, 1.8), Vector3(0, 0.9, 0), 2.6)
	return root


func _build_class_select() -> Node:
	var root := CanvasLayer.new()
	root.name = "ClassSelectScreen"
	root.set_script(load("res://game/ui/class_select/class_select_screen.gd"))
	return root


# --- Mapa -----------------------------------------------------------------

## Biblioteca de blocos do GridMap: chão (2 variações) e parede, com colisão.
func _build_mesh_library() -> MeshLibrary:
	var lib := MeshLibrary.new()
	var specs: Array = [
		[FLOOR_A, "Chao_A", Vector3(1, 0.2, 1), -0.1, Color(0.24, 0.22, 0.24)],
		[FLOOR_B, "Chao_B", Vector3(1, 0.2, 1), -0.1, Color(0.2, 0.19, 0.2)],
		[WALL, "Parede", Vector3(1, WALL_HEIGHT, 1), WALL_HEIGHT / 2.0, Color(0.36, 0.33, 0.32)],
	]
	for spec: Array in specs:
		var id: int = spec[0]
		var mesh := BoxMesh.new()
		mesh.size = spec[2]
		mesh.material = Decor.stone_material(spec[4])
		lib.create_item(id)
		lib.set_item_name(id, spec[1])
		lib.set_item_mesh(id, mesh)
		var offset := Transform3D(Basis(), Vector3(0, spec[3], 0))
		lib.set_item_mesh_transform(id, offset)
		var shape := BoxShape3D.new()
		shape.size = spec[2]
		lib.set_item_shapes(id, [shape, offset])
	return lib


## Tiles que a decoração não pode ocupar (passagem, objetos, NPC, portal, monstros).
func _reserved_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = [PLAYER_TILE, DOOR_TILE, LEVER_TILE, SIGN_TILE, NPC_TILE, DUNGEON_TILE, VILLAGE_TILE]
	tiles.append_array(ENEMY_TILES)
	tiles.append_array(TORCHES)
	for p: Array in PICKUPS:
		tiles.append(p[0])
	for c: Array in CHESTS:
		tiles.append(c[0])
	return tiles


## Decoração encostada nas paredes (KayKit, CC0): escolha fixa por tile (sempre igual).
func _decorate(root: Node, floor_cells: Dictionary, wall_cells: Dictionary) -> void:
	var decor := Node3D.new()
	decor.name = "Decor"
	_own(decor, root, root)
	var pieces: Array[StringName] = [&"barrel", &"crates", &"candles", &"bones", &"barrel_small", &"skull_candle",
		&"rubble_half", &"box", &"broken_gear", &"gravestone", &"ribcage", &"trunk"]
	var reserved: Array[Vector2i] = _reserved_tiles()
	var count: int = 0
	var cells: Array = floor_cells.keys()
	cells.sort()
	for cell: Vector2i in cells:
		var wall_dir := Vector2i.ZERO
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if wall_cells.has(cell + d):
				wall_dir = d
		if wall_dir == Vector2i.ZERO:
			continue
		var blocked: bool = false
		for t: Vector2i in reserved:
			if (cell - t).length() < 3.0:
				blocked = true
				break
		# Corredores estreitos (parede dos dois lados) ficam livres.
		if blocked or (wall_cells.has(cell + wall_dir) and wall_cells.has(cell - wall_dir)):
			continue
		var h: int = absi((cell.x * 73856093) ^ (cell.y * 19349663))
		if h % 9 != 0:
			continue
		var id: StringName = pieces[(h / 9) % pieces.size()]
		var yaw: float = atan2(float(-wall_dir.x), float(-wall_dir.y))
		var node: Node3D = Decor.place(decor, id, _tile_pos(cell) + Vector3(wall_dir.x, 0, wall_dir.y) * 0.15, yaw)
		_own_decor(node, root)
		count += 1
	print("decoração: %d peças" % count)


## Dá dono ao nó e aos filhos criados aqui (não entra no modelo importado: ele é instância).
func _own_decor(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	if node.scene_file_path.is_empty():
		for child: Node in node.get_children():
			_own_decor(child, owner_node)


func _build_area() -> Node:
	var root := Node3D.new()
	root.name = "PrototypeArea"
	root.set_script(load("res://game/world/areas/prototype_area/prototype_area.gd"))
	add_environment(root, root)

	var floor_cells := {}
	for r: Rect2i in FLOORS:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				floor_cells[Vector2i(x, y)] = true
	var wall_cells := {}
	for r: Rect2i in PILLARS:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				wall_cells[Vector2i(x, y)] = true
				floor_cells.erase(Vector2i(x, y))
	for cell: Vector2i in floor_cells:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n := cell + Vector2i(dx, dy)
				if not floor_cells.has(n):
					wall_cells[n] = true

	var grid := GridMap.new()
	grid.name = "Blocks"
	grid.mesh_library = load(MESH_LIBRARY)
	grid.cell_size = Vector3(1, 1, 1)
	grid.cell_center_y = false
	grid.collision_layer = L_WORLD
	grid.collision_mask = 0
	_own(grid, root, root)
	for cell: Vector2i in floor_cells:
		var variant: bool = ((cell.x * 73856093) ^ (cell.y * 19349663)) % 7 == 0
		grid.set_cell_item(Vector3i(cell.x, 0, cell.y), FLOOR_B if variant else FLOOR_A)
	for cell: Vector2i in wall_cells:
		grid.set_cell_item(Vector3i(cell.x, 0, cell.y), WALL)
	for i in TORCHES.size():
		add_torch(root, root, "Torch%d" % (i + 1), _tile_pos(TORCHES[i]) + Vector3(0, 2.3, 0))
	_decorate(root, floor_cells, wall_cells)

	var entities := Node3D.new()
	entities.name = "Entities"
	_own(entities, root, root)
	var player: Node3D = (load(PLAYER_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	player.position = _tile_pos(PLAYER_TILE)
	_own(player, entities, root)
	for i in ENEMY_TILES.size():
		var enemy: Node3D = (load(ENEMY_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		enemy.name = "BasicEnemy%d" % (i + 1)
		enemy.position = _tile_pos(ENEMY_TILES[i])
		_own(enemy, entities, root)

	var door: Node3D = (load("res://game/world/objects/door/door.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	door.name = "DoorSoutheast"
	door.position = _tile_pos(DOOR_TILE)
	_own(door, entities, root)
	var lever: Node3D = (load("res://game/world/objects/lever/lever.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	lever.name = "LeverNortheast"
	lever.position = _tile_pos(LEVER_TILE)
	_own(lever, entities, root)
	(lever.get("targets") as Array).append(door)
	var sign_post: Node3D = (load("res://game/world/objects/sign_post/sign_post.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	sign_post.name = "SignStart"
	sign_post.position = _tile_pos(SIGN_TILE)
	sign_post.set("message", SIGN_TEXT)
	_own(sign_post, entities, root)
	var npc: Node3D = (load("res://game/actors/npcs/npc.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	npc.name = "NpcQuestGiver"
	npc.position = _tile_pos(NPC_TILE)
	npc.set("npc_name", "Sentinela (provisório)")
	var idle: Array[String] = ["O caminho está mais calmo graças a você."]
	npc.set("idle_lines", idle)
	npc.set("quest", load("res://game/quests/data/clear_the_hall.tres"))
	_own(npc, entities, root)
	for i in PICKUPS.size():
		var entry: Array = PICKUPS[i]
		var pickup: Node3D = (load(PICKUP_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		pickup.name = "Pickup%d" % (i + 1)
		pickup.position = _tile_pos(entry[0])
		pickup.set("stack", ItemStack.create(load(ITEMS + String(entry[1]) + ".tres"), entry[2]))
		_own(pickup, entities, root)
	for i in CHESTS.size():
		var entry: Array = CHESTS[i]
		var chest: Node3D = (load("res://game/world/objects/chest/chest.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		chest.name = "Chest%d" % (i + 1)
		chest.position = _tile_pos(entry[0])
		var contents: Array[ItemStack] = []
		for c: Array in entry[1]:
			contents.append(ItemStack.create(load(ITEMS + String(c[0]) + ".tres"), c[1]))
		chest.set("contents", contents)
		_own(chest, entities, root)

	add_ui(root, root, HELP)
	var select: Node = (load(CLASS_SELECT_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	select.name = "ClassSelectScreen"
	_own(select, root, root)
	var options: Array[ClassData] = []
	for c: String in ["guardian", "devotee"]:
		options.append(load("res://game/classes/data/%s.tres" % c))
	root.set("class_options", options)
	# Portal das Ruínas Esquecidas na sala inicial (masmorra a partir do nível 20).
	root.set("dungeon", load("res://game/dungeons/data/forgotten_ruins.tres"))
	root.set("dungeon_entrance_position", _tile_pos(DUNGEON_TILE))
	# Portal da Vila de Brisaclara (refúgio de dia, visual de anime).
	root.set("has_village", true)
	root.set("village_entrance_position", _tile_pos(VILLAGE_TILE))
	print("chão=%d paredes=%d inimigos=%d" % [floor_cells.size(), wall_cells.size(), ENEMY_TILES.size()])
	return root
