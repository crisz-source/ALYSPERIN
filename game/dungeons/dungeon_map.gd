class_name DungeonMap
extends Node3D
## Mapa PROVISÓRIO das Ruínas Esquecidas, montado por código (blocos sem arte):
## sala de entrada (com o portal de saída) -> corredor -> salão com monstros ->
## corredor -> arena do chefe (com poças d'água nos cantos).
## A frente do mapa é -Z a partir da origem do nó. Quem cria e destrói é a GameArea.

const WALL_HEIGHT: float = 3.0
const DOOR_WIDTH: float = 4.0
const FLOOR_COLOR := Color(0.2, 0.22, 0.2)
const WALL_COLOR := Color(0.32, 0.36, 0.3)
const PUDDLE_COLOR := Color(0.25, 0.45, 0.7, 0.7)
const PORTAL_COLOR := Color(0.55, 0.4, 1.0, 0.6)
## Grupo das poças (o chefe mergulha raízes nelas).
const PUDDLE_GROUP: StringName = &"puddles"

## Salas: [centro (x, z), tamanho (x, z), saídas: "n" = para -Z, "s" = para +Z].
const ROOMS: Array = [
	[Vector2(0, 0), Vector2(12, 12), "n"],
	[Vector2(0, -26), Vector2(16, 16), "ns"],
	[Vector2(0, -58), Vector2(28, 28), "s"],
]
## Corredores: [z inicial, z final] (largura DOOR_WIDTH, centrados em x = 0).
const CORRIDORS: Array = [[-6.0, -18.0], [-34.0, -44.0]]
const ENEMY_SPOTS: Array[Vector3] = [Vector3(-4, 0, -22), Vector3(4, 0, -22), Vector3(-4, 0, -30), Vector3(4, 0, -30)]
const PUDDLE_SPOTS: Array[Vector3] = [Vector3(-10, 0, -48), Vector3(10, 0, -48), Vector3(-10, 0, -68), Vector3(10, 0, -68)]
const PUDDLE_RADIUS: float = 2.2

var data: DungeonData
## Pedido de saída (portal usado).
signal exit_requested(by: Player)
## O jogador passou pela entrada da arena do chefe (uma vez só).
signal boss_arena_entered

var _arena_triggered: bool = false


func _ready() -> void:
	name = "DungeonMap"
	for room: Array in ROOMS:
		_build_room(room[0], room[1], room[2])
	for c: Array in CORRIDORS:
		_build_corridor(c[0], c[1])
	for spot: Vector3 in PUDDLE_SPOTS:
		_build_puddle(spot)
	_build_exit_portal(Vector3(0, 0, 4.5))
	_build_arena_trigger(Vector3(0, 1.5, -45.5))
	var light := OmniLight3D.new()
	light.position = Vector3(0, 6, -26)
	light.omni_range = 60.0
	light.light_energy = 0.35
	add_child(light)
	_decorate()


## Onde o jogador aparece ao entrar (e ao continuar depois de morrer).
func start_point() -> Vector3:
	return global_position + Vector3(0, 0.1, 1.5)


## Centro da arena do chefe.
func boss_point() -> Vector3:
	return global_position + Vector3(0, 0, -60)


func enemy_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for spot: Vector3 in ENEMY_SPOTS:
		points.append(global_position + spot)
	return points


## A posição está numa poça d'água?
func is_in_puddle(pos: Vector3) -> bool:
	for spot: Vector3 in PUDDLE_SPOTS:
		var p: Vector3 = global_position + spot
		if Vector2(pos.x - p.x, pos.z - p.z).length() <= PUDDLE_RADIUS:
			return true
	return false


func _build_room(center: Vector2, size: Vector2, exits: String) -> void:
	_block(Vector3(size.x, 0.2, size.y), Vector3(center.x, -0.1, center.y), FLOOR_COLOR)
	var half := size / 2.0
	var y: float = WALL_HEIGHT / 2.0
	# Paredes leste/oeste inteiras.
	_block(Vector3(1, WALL_HEIGHT, size.y), Vector3(center.x - half.x - 0.5, y, center.y), WALL_COLOR)
	_block(Vector3(1, WALL_HEIGHT, size.y), Vector3(center.x + half.x + 0.5, y, center.y), WALL_COLOR)
	# Paredes norte (-Z) e sul (+Z), com abertura para o corredor quando há saída.
	for side: Array in [["n", center.y - half.y - 0.5], ["s", center.y + half.y + 0.5]]:
		var z: float = side[1]
		if exits.contains(side[0]):
			var piece: float = (size.x + 2.0 - DOOR_WIDTH) / 2.0
			_block(Vector3(piece, WALL_HEIGHT, 1), Vector3(center.x - DOOR_WIDTH / 2.0 - piece / 2.0, y, z), WALL_COLOR)
			_block(Vector3(piece, WALL_HEIGHT, 1), Vector3(center.x + DOOR_WIDTH / 2.0 + piece / 2.0, y, z), WALL_COLOR)
		else:
			_block(Vector3(size.x + 2.0, WALL_HEIGHT, 1), Vector3(center.x, y, z), WALL_COLOR)


func _build_corridor(z_from: float, z_to: float) -> void:
	var length: float = absf(z_to - z_from)
	var z: float = (z_from + z_to) / 2.0
	_block(Vector3(DOOR_WIDTH, 0.2, length + 1.0), Vector3(0, -0.1, z), FLOOR_COLOR)
	_block(Vector3(1, WALL_HEIGHT, length), Vector3(-DOOR_WIDTH / 2.0 - 0.5, WALL_HEIGHT / 2.0, z), WALL_COLOR)
	_block(Vector3(1, WALL_HEIGHT, length), Vector3(DOOR_WIDTH / 2.0 + 0.5, WALL_HEIGHT / 2.0, z), WALL_COLOR)


## Bloco sólido (camada "world"): chão ou parede.
func _block(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _stone(color)
	body.add_child(mesh)
	add_child(body)


func _build_puddle(spot: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Puddle"
	var disc := CylinderMesh.new()
	disc.top_radius = PUDDLE_RADIUS
	disc.bottom_radius = PUDDLE_RADIUS
	disc.height = 0.02
	mesh.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PUDDLE_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.6
	mat.roughness = 0.1
	mesh.material_override = mat
	mesh.position = spot + Vector3(0, 0.02, 0)
	mesh.add_to_group(PUDDLE_GROUP)
	add_child(mesh)


## Material de pedra por cor (um por cor, reaproveitado entre blocos).
var _stone_cache: Dictionary = {}


func _stone(color: Color) -> StandardMaterial3D:
	if not _stone_cache.has(color):
		_stone_cache[color] = Decor.stone_material(color)
	return _stone_cache[color]


## Decoração KayKit (CC0): tochas nos corredores, ossos e escombros no salão,
## pilares, caixões, lápides e árvore morta na arena do chefe.
func _decorate() -> void:
	var torch_spots: Array[Vector3] = [Vector3(-5.4, 0, 0), Vector3(5.4, 0, 0), Vector3(-1.6, 0, -12), Vector3(1.6, 0, -12),
		Vector3(-7.4, 0, -26), Vector3(7.4, 0, -26), Vector3(-1.6, 0, -39), Vector3(1.6, 0, -39)]
	for spot: Vector3 in torch_spots:
		Decor.place(self, &"lantern", spot)
	for spec: Array in [[&"skull_candle", Vector3(-2.5, 0, 4.5)], [&"skull_candle", Vector3(2.5, 0, 4.5)],
			[&"bones", Vector3(-6, 0, -20)], [&"ribcage", Vector3(5.5, 0, -32)], [&"rubble", Vector3(6.5, 0, -19.5)],
			[&"broken_gear", Vector3(-6.5, 0, -32.5)], [&"barrel", Vector3(-6.8, 0, -19)], [&"crates", Vector3(6.8, 0, -33)]]:
		Decor.place(self, spec[0], spec[1])
	# Arena do chefe: pilares nos cantos, caixões e lápides nas paredes, árvore morta.
	for corner: Vector3 in [Vector3(-12.5, 0, -45.5), Vector3(12.5, 0, -45.5), Vector3(-12.5, 0, -70.5), Vector3(12.5, 0, -70.5)]:
		Decor.place(self, &"pillar", corner)
	for spec: Array in [[&"coffin", Vector3(-13, 0, -56), PI / 2.0], [&"coffin", Vector3(13, 0, -60), -PI / 2.0],
			[&"grave", Vector3(-6, 0, -71), 0.0], [&"gravestone", Vector3(6, 0, -71), 0.0], [&"grave", Vector3(0, 0, -71.2), 0.0],
			[&"dead_tree", Vector3(-12.5, 0, -63), 0.0], [&"shrine", Vector3(12.5, 0, -52), -PI / 2.0],
			[&"bones", Vector3(-4, 0, -64)], [&"skull", Vector3(5, 0, -52)], [&"rubble_half", Vector3(8, 0, -66)]]:
		Decor.place(self, spec[0], spec[1], spec[2] if spec.size() > 2 else 0.0)


## Faixa invisível no fim do corredor: ao passar, o chefe aparece.
func _build_arena_trigger(pos: Vector3) -> void:
	var area := Area3D.new()
	area.name = "BossArenaTrigger"
	area.collision_layer = 0
	area.collision_mask = 2  # jogador
	area.monitorable = false
	area.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(DOOR_WIDTH, 3.0, 1.0)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is Player and not _arena_triggered:
			_arena_triggered = true
			boss_arena_entered.emit())
	add_child(area)


func _build_exit_portal(pos: Vector3) -> void:
	var portal := Node3D.new()
	portal.name = "ExitPortal"
	portal.position = pos
	add_child(portal)
	var mesh := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.2
	mesh.mesh = ring
	mesh.rotation_degrees = Vector3(90, 0, 0)
	mesh.position = Vector3(0, 1.3, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PORTAL_COLOR
	mat.emission_enabled = true
	mat.emission = PORTAL_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	portal.add_child(mesh)
	var area := Interactable.new()
	area.name = "Interactable"
	area.prompt_text = "Sair da masmorra"
	area.prompt_offset = Vector3(0, 2.8, 0)
	area.collision_layer = 32
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.5, 2.0)
	shape.shape = box
	shape.position = Vector3(0, 1.2, 0)
	area.add_child(shape)
	area.handler = func(by: Player) -> String:
		exit_requested.emit(by)
		return ""
	portal.add_child(area)
