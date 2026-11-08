class_name VillageMap
extends Node3D
## Vila de Brisaclara — refúgio seguro entre as masmorras (PROVISÓRIO: layout
## montado por código com peças KayKit Medieval Hexagon, CC0).
## De dia, colorida, sem monstros. Visual de anime (ToonStyle) + céu e sol próprios
## (o ambiente da área é trocado ao entrar e devolvido ao sair, pela GameArea).

signal exit_requested(by: Player)

const DISPLAY_NAME := "Vila de Brisaclara"
const PIECES := "res://assets/environment/kaykit_village/"
const SIZE: float = 70.0
const GRASS_COLOR := Color(0.42, 0.72, 0.32)
const PATH_COLOR := Color(0.72, 0.58, 0.38)
## As peças do pacote estão em escala de miniatura (casa ~0,9): ampliadas para o personagem.
const BUILDING_SCALE: float = 5.5
const TREE_SCALE: float = 5.0
const PROP_SCALE: float = 5.0

## [peça, posição (x, z), giro (graus), escala]
const BUILDINGS: Array = [
	["building_tavern_red", Vector2(-12, -6), 90.0, BUILDING_SCALE],
	["building_blacksmith_yellow", Vector2(12, -6), -90.0, BUILDING_SCALE],
	["building_church_blue", Vector2(0, -22), 0.0, BUILDING_SCALE],
	["building_market_red", Vector2(12, 8), -90.0, BUILDING_SCALE],
	["building_home_A_blue", Vector2(-13, 9), 90.0, BUILDING_SCALE],
	["building_home_B_red", Vector2(-20, -18), 45.0, BUILDING_SCALE],
	["building_home_A_yellow", Vector2(20, -18), -45.0, BUILDING_SCALE],
	["building_windmill_green", Vector2(-24, 14), 120.0, BUILDING_SCALE],
	["building_well_blue", Vector2(0, -4), 0.0, BUILDING_SCALE * 0.8],
]
const TREES: Array = [
	["trees_A_large", Vector2(-28, -28)], ["trees_B_large", Vector2(26, -28)], ["tree_single_A", Vector2(-6, 18)],
	["tree_single_B", Vector2(7, 19)], ["trees_A_medium", Vector2(28, 20)], ["tree_single_A", Vector2(-29, 0)],
	["tree_single_B", Vector2(29, -2)], ["trees_A_medium", Vector2(-18, 27)], ["tree_single_A", Vector2(18, 27)],
	["trees_B_large", Vector2(-30, 28)], ["tree_single_B", Vector2(-8, -28)], ["tree_single_A", Vector2(9, -29)],
]
const PROPS: Array = [
	["barrel", Vector2(9.5, 5)], ["barrel", Vector2(9.8, 6.2)], ["sack", Vector2(9.2, 11)], ["crate_A_big", Vector2(10, 12)],
	["wheelbarrow", Vector2(-9, 5)], ["weaponrack", Vector2(9, -3)], ["bucket_water", Vector2(1.6, -2.5)],
	["flag_red", Vector2(-3, -15)], ["flag_red", Vector2(3, -15)], ["tent", Vector2(20, 2)], ["rock_single_A", Vector2(-4, 12)],
	["rock_single_C", Vector2(5, 14)], ["rock_single_A", Vector2(15, -12)],
]
## Aldeões: [modelo, posição, giro, nome, falas]
const VILLAGERS: Array = [
	["Barbarian", Vector3(8, 0, -4), -90.0, "Borak, o ferreiro", ["Bem-vindo a Brisaclara!", "Aqui as sombras não entram. Descanse antes de voltar às ruínas.", "Se achar Casca Ancestral, me traga. Um dia faço um escudo com ela."]],
	["Rogue", Vector3(8, 0, 9), -90.0, "Lys, a mercadora", ["Poções, óleos, cordas... quase tudo!", "(A loja ainda não abriu: volte depois.)"]],
	["Rogue_Hooded", Vector3(-4, 0, 4), 30.0, "Viajante encapuzado", ["Dizem que a Mãe-Raiz teme o fogo...", "...mas que a água a deixa diferente. Fique de olho nas poças."]],
]


func _ready() -> void:
	name = "VillageMap"
	_ground()
	for b: Array in BUILDINGS:
		_piece(b[0], b[1], b[2], b[3], true)
	for t: Array in TREES:
		_piece(t[0], t[1], float(hash(t[1]) % 360), TREE_SCALE, true)
	for p: Array in PROPS:
		_piece(p[0], p[1], float(hash(p[1]) % 360), PROP_SCALE, false)
	_fences()
	_backdrop()
	for v: Array in VILLAGERS:
		_villager(v)
	var exit := TravelPortal.create("Voltar às ruínas", "Voltar", Color(0.55, 0.4, 1.0, 0.7))
	exit.name = "ExitPortal"
	exit.position = Vector3(0, 0, 27)
	exit.used.connect(func(by: Player) -> void: exit_requested.emit(by))
	add_child(exit)


## Onde o jogador aparece ao chegar.
func start_point() -> Vector3:
	return global_position + Vector3(0, 0.1, 23)


func _ground() -> void:
	_box(Vector3(SIZE, 0.2, SIZE), Vector3(0, -0.1, 0), GRASS_COLOR, true, 0.25)
	# Caminhos de terra: do portal à praça e da praça à igreja e às laterais.
	_box(Vector3(4, 0.04, 34), Vector3(0, 0.02, 10), PATH_COLOR, false, 0.5)
	_box(Vector3(4, 0.04, 16), Vector3(0, 0.02, -14), PATH_COLOR, false, 0.5)
	_box(Vector3(26, 0.04, 4), Vector3(0, 0.02, -2), PATH_COLOR, false, 0.5)
	# Limites invisíveis (não sai da vila andando).
	var h: float = SIZE / 2.0
	for spec: Array in [[Vector3(SIZE, 6, 1), Vector3(0, 3, -h)], [Vector3(SIZE, 6, 1), Vector3(0, 3, h)],
			[Vector3(1, 6, SIZE), Vector3(-h, 3, 0)], [Vector3(1, 6, SIZE), Vector3(h, 3, 0)]]:
		var body := StaticBody3D.new()
		body.name = "Boundary"
		body.collision_layer = 1
		body.position = spec[1]
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = spec[0]
		cs.shape = box
		body.add_child(cs)
		add_child(body)


func _fences() -> void:
	for i in 6:
		_piece("fence_wood_straight", Vector2(-2.6, 14 + i * 2.2), 0.0, 3.8, false)
		_piece("fence_wood_straight", Vector2(2.6, 14 + i * 2.2), 0.0, 3.8, false)


## Montanhas e nuvens ao longe (só visual).
func _backdrop() -> void:
	var ring: int = 10
	for i in ring:
		var a: float = TAU * i / ring
		var pos := Vector2(cos(a), sin(a)) * (SIZE / 2.0 + 18.0)
		_no_shadow(_piece("mountain_A_grass_trees", pos, rad_to_deg(a) * 3.0, 16.0 + (i % 3) * 3.0, false))
	for i in 6:
		var cloud: Node3D = _piece("cloud_big" if i % 2 == 0 else "cloud_small", Vector2(-40 + i * 16, -30 + (i % 3) * 25), 0.0, 6.0, false)
		cloud.position.y = 26.0 + (i % 2) * 5.0
		_no_shadow(cloud)  # nuvem lá no alto não pode escurecer o chão
		cloud.add_to_group(&"village_clouds")


static func _no_shadow(node: Node) -> void:
	for m: Node in node.find_children("*", "MeshInstance3D", true, false):
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	for cloud: Node in get_tree().get_nodes_in_group(&"village_clouds"):
		var c := cloud as Node3D
		c.position.x += delta * 0.8
		if c.position.x > 60.0:
			c.position.x = -60.0


func _piece(id: String, pos: Vector2, yaw_deg: float, scale: float, solid: bool) -> Node3D:
	var root := Node3D.new()
	root.name = id.capitalize().replace(" ", "")
	root.position = Vector3(pos.x, 0, pos.y)
	root.rotation.y = deg_to_rad(yaw_deg)
	var model: Node3D = (load(PIECES + id + ".gltf") as PackedScene).instantiate()
	model.scale = Vector3.ONE * scale
	root.add_child(model)
	add_child(root)
	if solid:
		var box: AABB = _local_aabb(model)
		var body := StaticBody3D.new()
		body.name = "Collision"
		body.collision_layer = 1
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(box.size.x * 0.8, maxf(box.size.y, 2.0), box.size.z * 0.8)
		cs.shape = shape
		cs.position = box.get_center()
		body.add_child(cs)
		root.add_child(body)
	return root


## Caixa do modelo em coordenadas do nó pai dele (antes de entrar no mundo).
static func _local_aabb(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var t: Transform3D = model.transform
		var n: Node = mi
		var chain := Transform3D.IDENTITY
		while n != model:
			chain = (n as Node3D).transform * chain
			n = n.get_parent()
		var b: AABB = (t * chain) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _box(size: Vector3, pos: Vector3, color: Color, solid: bool, uv_scale: float) -> void:
	var parent: Node3D = self
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.position = pos
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		add_child(body)
		parent = body
		pos = Vector3.ZERO
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.position = pos
	mesh.material_override = Decor.stone_material(color, uv_scale)
	parent.add_child(mesh)


func _villager(spec: Array) -> void:
	var root := Node3D.new()
	root.name = "Villager_" + String(spec[0])
	root.position = spec[1]
	root.rotation.y = deg_to_rad(spec[2])
	add_child(root)
	var model: Node3D = (load("res://assets/characters/kaykit/%s.glb" % spec[0]) as PackedScene).instantiate()
	model.scale = Vector3.ONE * 0.7
	root.add_child(model)
	Player._hide_builtin_gear(model)
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var anim := players[0] as AnimationPlayer
		anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		anim.play("Idle")
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	cs.shape = capsule
	cs.position = Vector3(0, 0.8, 0)
	body.add_child(cs)
	root.add_child(body)
	var area := Interactable.new()
	area.name = "Interactable"
	area.prompt_text = "Conversar"
	area.prompt_offset = Vector3(0, 2.2, 0)
	area.collision_layer = 32
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.4
	shape.shape = sphere
	shape.position = Vector3(0, 0.9, 0)
	area.add_child(shape)
	var lines: Array[String] = []
	lines.assign(spec[4])
	var speaker: String = spec[3]
	area.handler = func(by: Player) -> String:
		by.request_dialogue(speaker, lines)
		return ""
	root.add_child(area)
