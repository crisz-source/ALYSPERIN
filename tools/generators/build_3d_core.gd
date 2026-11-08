extends SceneTree
## Gera as cenas 3D básicas: jogador, inimigo, projétil, item no chão e arena de teste.
## Escala: 1 metro = 1 tile da versão 2D (16 px). Formas simples (PROVISÓRIO).

const PLAYER_SCENE := "res://game/actors/player/player.tscn"
const ENEMY_SCENE := "res://game/actors/enemies/basic_enemy/basic_enemy.tscn"
const PROJECTILE_SCENE := "res://game/combat/projectile.tscn"
const PICKUP_SCENE := "res://game/world/objects/item_pickup/item_pickup.tscn"
const ARENA_SCENE := "res://game/world/arenas/test_arena/test_arena.tscn"
const HUD_SCENE := "res://game/ui/hud/hud.tscn"
const INVENTORY_SCENE := "res://game/ui/inventory/inventory_screen.tscn"
const DEATH_SCENE := "res://game/ui/death_screen/death_screen.tscn"
const DIALOGUE_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const L_WORLD := 1
const L_PLAYER := 2
const L_ENEMY := 4
const L_PLAYER_HITBOX := 8
const L_ENEMY_HITBOX := 16
const L_INTERACTABLE := 32
const HELP := "WASD andar | Mouse câmera | Clique atacar | Dir. defender | Espaço esquivar | F usar | I inventário | Esc solta o mouse"


func _initialize() -> void:
	var err := OK
	for job: Array in [[_build_player(), PLAYER_SCENE], [_build_enemy(), ENEMY_SCENE],
			[_build_projectile(), PROJECTILE_SCENE], [_build_pickup(), PICKUP_SCENE]]:
		err = _save(job[0], job[1])
		if err != OK:
			break
	if err == OK:
		err = _save(_build_arena(), ARENA_SCENE)
	print("BUILD 3D CORE ", "OK" if err == OK else "FALHOU: " + error_string(err))
	quit(0 if err == OK else 1)


func _save(root: Node, path: String) -> Error:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err != OK:
		return err
	return ResourceSaver.save(packed, path)


func _own(child: Node, parent: Node, owner_node: Node) -> Node:
	parent.add_child(child)
	child.owner = owner_node
	return child


# --- Peças ----------------------------------------------------------------

static func mat(color: Color, emission: float = 0.0, transparent: bool = false, unshaded: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _mesh(node_name: String, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	return mi


func _box_mesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _shape(shape: Shape3D, pos: Vector3 = Vector3.ZERO) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape"
	cs.shape = shape
	cs.position = pos
	return cs


func _capsule(radius: float, height: float) -> CapsuleShape3D:
	var c := CapsuleShape3D.new()
	c.radius = radius
	c.height = height
	return c


func _boxshape(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


func _area(node_name: String, script_path: String, layer: int, mask: int) -> Area3D:
	var a := Area3D.new()
	a.name = node_name
	if not script_path.is_empty():
		a.set_script(load(script_path))
	a.collision_layer = layer
	a.collision_mask = mask
	return a


func _health(max_health: int) -> Node:
	var h := Node.new()
	h.name = "HealthComponent"
	h.set_script(load("res://game/components/health_component.gd"))
	h.set("max_health", max_health)
	return h


## Pontos de um setor (fatia) apontando para -Z, com altura (forma da lâmina).
func _sector_points(radius: float, half_angle_deg: float, steps: int, half_height: float) -> PackedVector3Array:
	var pts := PackedVector3Array([Vector3(0, -half_height, 0), Vector3(0, half_height, 0)])
	for i in steps + 1:
		var a: float = deg_to_rad(-half_angle_deg + 2.0 * half_angle_deg * i / steps)
		var p := Vector3(sin(a) * radius, 0, -cos(a) * radius)
		pts.append(p + Vector3(0, -half_height, 0))
		pts.append(p + Vector3(0, half_height, 0))
	return pts


## Malha plana de um setor (o arco visível do golpe).
func _sector_mesh(radius: float, half_angle_deg: float, steps: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		var a0: float = deg_to_rad(-half_angle_deg + 2.0 * half_angle_deg * i / steps)
		var a1: float = deg_to_rad(-half_angle_deg + 2.0 * half_angle_deg * (i + 1) / steps)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a1) * radius, 0, -cos(a1) * radius))
		st.add_vertex(Vector3(sin(a0) * radius, 0, -cos(a0) * radius))
	return st.commit()


# --- Jogador --------------------------------------------------------------

func _build_player() -> Node:
	var root := CharacterBody3D.new()
	root.name = "Player"
	root.set_script(load("res://game/actors/player/player.gd"))
	root.collision_layer = L_PLAYER
	root.collision_mask = L_WORLD
	_own(_shape(_capsule(0.35, 1.6), Vector3(0, 0.8, 0)), root, root)

	var model := Node3D.new()
	model.name = "Model"
	_own(model, root, root)
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.35
	body_mesh.height = 1.6
	# Boneco provisório: some quando a classe tem modelo de arte (ClassData.model_scene).
	var placeholder := Node3D.new()
	placeholder.name = "Placeholder"
	_own(placeholder, model, root)
	_own(_mesh("BodyPlaceholder", body_mesh, mat(Color(0.36, 0.62, 0.92)), Vector3(0, 0.8, 0)), placeholder, root)
	_own(_mesh("VisorPlaceholder", _box_mesh(Vector3(0.4, 0.1, 0.08)), mat(Color(1, 0.85, 0.3), 1.5), Vector3(0, 1.35, -0.32)), placeholder, root)
	# Mãos: recebem o modelo da arma (direita) e do escudo (esquerda) equipados.
	# Quem move as mãos (e o Model) é o PlayerAnimator.
	for hand: Array in [["RightHand", Vector3(0.45, 0.85, -0.15)], ["LeftHand", Vector3(-0.45, 0.85, -0.15)]]:
		var node := Node3D.new()
		node.name = hand[0]
		node.position = hand[1]
		_own(node, model, root)
		if hand[0] == "RightHand":
			# Espada provisória (arma sem modelo): em pé na mão, empunhadura embaixo.
			_own(_mesh("SwordPlaceholder", _box_mesh(Vector3(0.06, 0.9, 0.06)), mat(Color(0.85, 0.88, 0.95)), Vector3(0, 0.3, 0)), node, root)
	var animator := Node.new()
	animator.name = "PlayerAnimator"
	animator.set_script(load("res://game/actors/player/player_animator.gd"))
	_own(animator, root, root)

	var health := _own(_health(100), root, root)
	var hurtbox := _area("Hurtbox", "res://game/components/hurtbox.gd", L_PLAYER, 0)
	_own(hurtbox, root, root)
	hurtbox.set("health", health)
	_own(_shape(_capsule(0.35, 1.6), Vector3(0, 0.8, 0)), hurtbox, root)

	var pivot := Node3D.new()
	pivot.name = "AttackPivot"
	pivot.position = Vector3(0, 0.9, 0)
	_own(pivot, root, root)
	var sword := _area("SwordHitbox", "res://game/components/hitbox.gd", L_PLAYER_HITBOX, L_ENEMY)
	_own(sword, pivot, root)
	sword.set("damage", 10)
	sword.set("knockback_force", 8.75)
	sword.set("attacker", root)
	var convex := ConvexPolygonShape3D.new()
	convex.points = _sector_points(1.5, 65.0, 8, 0.7)
	_own(_shape(convex), sword, root)
	var swing := _mesh("SwingPlaceholder", _sector_mesh(1.5, 65.0, 12), mat(Color(1, 1, 0.85, 0.6), 0.0, true, true), Vector3(0, -0.2, 0))
	swing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_own(swing, pivot, root)
	var shield := _mesh("ShieldPlaceholder", _box_mesh(Vector3(0.9, 1.0, 0.08)), mat(Color(0.75, 0.85, 1.0, 0.85), 0.0, true), Vector3(0, 0, -0.6))
	_own(shield, pivot, root)

	var spin := _area("SpinHitbox", "res://game/components/hitbox.gd", L_PLAYER_HITBOX, L_ENEMY)
	_own(spin, root, root)
	spin.set("attacker", root)
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.9
	cyl.height = 1.6
	_own(_shape(cyl, Vector3(0, 0.8, 0)), spin, root)
	var disc := CylinderMesh.new()
	disc.top_radius = 1.9
	disc.bottom_radius = 1.9
	disc.height = 0.05
	var spin_vis := _mesh("SpinPlaceholder", disc, mat(Color(1, 1, 0.85, 0.4), 0.0, true, true), Vector3(0, 0.35, 0))
	spin_vis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_own(spin_vis, root, root)

	var detector := _area("InteractionDetector", "", 0, L_INTERACTABLE)
	detector.monitorable = false
	_own(detector, root, root)
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	_own(_shape(sphere, Vector3(0, 0.8, 0)), detector, root)
	var prompt := Label3D.new()
	prompt.name = "InteractPrompt"
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.fixed_size = true
	prompt.pixel_size = 0.0008
	prompt.no_depth_test = true
	prompt.font_size = 40
	prompt.outline_size = 10
	_own(prompt, root, root)

	var inventory := Node.new()
	inventory.name = "Inventory"
	inventory.set_script(load("res://game/inventory/inventory.gd"))
	var start_items: Array[ItemStack] = [
		ItemStack.create(load("res://game/items/data/healing_herb.tres"), 1),
		ItemStack.create(load("res://game/items/data/mana_potion.tres"), 1)]
	inventory.set("starting_items", start_items)
	_own(inventory, root, root)
	var equipment := Node.new()
	equipment.name = "Equipment"
	equipment.set_script(load("res://game/inventory/equipment.gd"))
	equipment.set("starting_weapon", ItemStack.create(load("res://game/items/data/short_sword.tres")))
	equipment.set("starting_shield", ItemStack.create(load("res://game/items/data/wooden_shield.tres")))
	_own(equipment, root, root)
	for spec: Array in [["ManaComponent", "res://game/components/mana_component.gd"],
			["QuestLog", "res://game/quests/quest_log.gd"],
			["CharacterStats", "res://game/actors/player/character_stats.gd"],
			["PlayerInput", "res://game/actors/player/player_input.gd"]]:
		var n := Node.new()
		n.name = spec[0]
		n.set_script(load(spec[1]))
		_own(n, root, root)
	var abilities: Array[AbilityData] = [load("res://game/abilities/data/spin_slash.tres")]
	root.set("abilities", abilities)

	var rig := Node3D.new()
	rig.name = "CameraRig"
	rig.set_script(load("res://game/actors/player/player_camera.gd"))
	rig.position = Vector3(0, 1.4, 0)
	_own(rig, root, root)
	var pitch := Node3D.new()
	pitch.name = "Pitch"
	# Câmera por cima do ombro direito e mais alta: o personagem fica embaixo e à
	# esquerda, e o centro da tela (mira) fica livre — nem a espada passa por ele.
	pitch.position = Vector3(1.0, 0.9, 0)
	pitch.rotation_degrees = Vector3(-24, 0, 0)
	_own(pitch, rig, root)
	var arm := SpringArm3D.new()
	arm.name = "SpringArm"
	arm.spring_length = 6.5
	arm.margin = 0.3
	arm.collision_mask = L_WORLD
	_own(arm, pitch, root)
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = 65.0
	cam.current = true
	_own(cam, arm, root)
	return root


# --- Inimigo --------------------------------------------------------------

func _build_enemy() -> Node:
	var root := CharacterBody3D.new()
	root.name = "BasicEnemy"
	root.set_script(load("res://game/actors/enemies/basic_enemy/basic_enemy.gd"))
	# Esqueleto lacaio animado (KayKit Skeletons, CC0) no lugar do cubo.
	root.set("model_scene", load("res://assets/characters/kaykit/Skeleton_Minion.glb"))
	root.set("model_scale", 0.6)
	root.collision_layer = L_ENEMY
	root.collision_mask = L_WORLD | L_ENEMY
	_own(_shape(_capsule(0.4, 1.0), Vector3(0, 0.5, 0)), root, root)
	var telegraph := _mesh("LungeTelegraph", PlaneMesh.new(), mat(Color(1.0, 0.2, 0.15, 0.25), 0.0, true, true), Vector3(0, 0.03, 0))
	telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	telegraph.visible = false
	_own(telegraph, root, root)
	var model := Node3D.new()
	model.name = "Model"
	_own(model, root, root)
	_own(_mesh("BodyPlaceholder", _box_mesh(Vector3(0.9, 0.9, 0.9)), mat(Color(0.78, 0.25, 0.25)), Vector3(0, 0.45, 0)), model, root)
	# "Olho" amarelo na frente: mostra para onde o inimigo está virado (costas = lado oposto).
	_own(_mesh("FacingIndicator", _box_mesh(Vector3(0.6, 0.12, 0.08)), mat(Color(1, 0.9, 0.6), 2.0), Vector3(0, 0.62, -0.47)), model, root)
	var health := _own(_health(30), root, root)
	var hurtbox := _area("Hurtbox", "res://game/components/hurtbox.gd", L_ENEMY, 0)
	_own(hurtbox, root, root)
	hurtbox.set("health", health)
	_own(_shape(_boxshape(Vector3(0.9, 0.9, 0.9)), Vector3(0, 0.45, 0)), hurtbox, root)
	var lunge := _area("LungeHitbox", "res://game/components/hitbox.gd", L_ENEMY_HITBOX, L_PLAYER)
	_own(lunge, root, root)
	lunge.set("damage", 15)
	lunge.set("knockback_force", 12.5)
	lunge.set("attacker", root)
	_own(_shape(_boxshape(Vector3(0.9, 0.9, 0.9)), Vector3(0, 0.45, 0)), lunge, root)
	var bar := Node3D.new()
	bar.name = "HealthBar"
	bar.set_script(load("res://game/ui/health_bar_3d/health_bar_3d.gd"))
	bar.position = Vector3(0, 1.3, 0)
	_own(bar, root, root)
	return root


func _build_projectile() -> Node:
	var root := _area("Projectile", "res://game/combat/projectile.gd", L_PLAYER_HITBOX, L_ENEMY | L_WORLD)
	var sphere := SphereShape3D.new()
	sphere.radius = 0.2
	_own(_shape(sphere), root, root)
	var vis := SphereMesh.new()
	vis.radius = 0.15
	vis.height = 0.3
	_own(_mesh("Visual", vis, mat(Color(0.6, 0.5, 1.0), 3.0)), root, root)
	return root


func _build_pickup() -> Node:
	var root := Node3D.new()
	root.name = "ItemPickup"
	root.set_script(load("res://game/world/objects/item_pickup/item_pickup.gd"))
	var shadow := CylinderMesh.new()
	shadow.top_radius = 0.25
	shadow.bottom_radius = 0.25
	shadow.height = 0.01
	_own(_mesh("Shadow", shadow, mat(Color(0, 0, 0, 0.4), 0.0, true, true), Vector3(0, 0.02, 0)), root, root)
	var icon := _mesh("IconPlaceholder", _box_mesh(Vector3(0.25, 0.25, 0.25)), mat(Color(0.8, 0.8, 0.8), 1.2), Vector3(0, 0.45, 0))
	icon.rotation_degrees = Vector3(45, 0, 45)
	_own(icon, root, root)
	var area := _area("Interactable", "res://game/components/interactable.gd", L_INTERACTABLE, 0)
	_own(area, root, root)
	_own(_shape(_boxshape(Vector3(1, 1, 1)), Vector3(0, 0.5, 0)), area, root)
	area.set("prompt_offset", Vector3(0, 1.2, 0))
	return root


# --- Arena de teste -------------------------------------------------------

## Luz e ambiente de masmorra (o visual que o proprietário aprovou no protótipo).
func add_environment(root: Node, owner_node: Node) -> void:
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.04, 0.035, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.33, 0.42)
	e.ambient_light_energy = 0.6
	e.fog_enabled = true
	e.fog_light_color = Color(0.08, 0.07, 0.1)
	e.fog_density = 0.03
	# Clima: tons de filme, brilho nas chamas, cores um pouco mais frias e contrastadas.
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.7
	e.glow_bloom = 0.05
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.12
	e.adjustment_saturation = 0.85
	env.environment = e
	_own(env, root, owner_node)
	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.rotation_degrees = Vector3(-55, -30, 0)
	moon.light_color = Color(0.6, 0.65, 0.85)
	moon.light_energy = 0.5
	moon.shadow_enabled = true
	_own(moon, root, owner_node)


func add_static_box(parent: Node, owner_node: Node, node_name: String, size: Vector3, center: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = L_WORLD
	body.collision_mask = 0
	body.position = center
	_own(body, parent, owner_node)
	_own(_shape(_boxshape(size)), body, owner_node)
	_own(_mesh("Visual", _box_mesh(size), mat(color)), body, owner_node)


func add_torch(parent: Node, owner_node: Node, node_name: String, pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = pos
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 1.6
	light.omni_range = 7.0
	_own(light, parent, owner_node)
	_own(_mesh("Flame", _box_mesh(Vector3(0.15, 0.3, 0.15)), mat(Color(1.0, 0.55, 0.2), 3.0)), light, owner_node)


func add_ui(root: Node, owner_node: Node, help: String) -> void:
	var hud: Node = (load(HUD_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	hud.name = "Hud"
	hud.set("help_text", help)
	_own(hud, root, owner_node)
	for spec: Array in [[INVENTORY_SCENE, "InventoryScreen"], [DEATH_SCENE, "DeathScreen"], [DIALOGUE_SCENE, "DialogueBox"]]:
		var n: Node = (load(spec[0]) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		n.name = spec[1]
		_own(n, root, owner_node)


func _build_arena() -> Node:
	var root := Node3D.new()
	root.name = "TestArena"
	root.set_script(load("res://game/world/arenas/test_arena/test_arena.gd"))
	root.set("enemy_scene", load(ENEMY_SCENE))
	add_environment(root, root)
	var level := Node3D.new()
	level.name = "Level"
	_own(level, root, root)
	# Mesmo tamanho da arena 2D: 1024x576 px = 64x36 m.
	add_static_box(level, root, "Floor", Vector3(64, 1, 36), Vector3(32, -0.5, 18), Color(0.22, 0.21, 0.24))
	for spec: Array in [["WallNorth", Vector3(64, 3, 1), Vector3(32, 1.5, 0.5)], ["WallSouth", Vector3(64, 3, 1), Vector3(32, 1.5, 35.5)],
			["WallWest", Vector3(1, 3, 36), Vector3(0.5, 1.5, 18)], ["WallEast", Vector3(1, 3, 36), Vector3(63.5, 1.5, 18)]]:
		add_static_box(level, root, spec[0], spec[1], spec[2], Color(0.42, 0.36, 0.3))
	var pillars: Array[Vector3] = [Vector3(22, 0, 12.5), Vector3(42, 0, 12.5), Vector3(32, 0, 26.25)]
	for i in pillars.size():
		add_static_box(level, root, "Pillar%d" % (i + 1), Vector3(2, 3, 1), pillars[i] + Vector3(0, 1.5, -0.5), Color(0.5, 0.45, 0.4))
		add_torch(level, root, "Torch%d" % (i + 1), pillars[i] + Vector3(0, 2.2, 0.15))
	var entities := Node3D.new()
	entities.name = "Entities"
	_own(entities, root, root)
	var player: Node3D = (load(PLAYER_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	player.position = Vector3(32, 0, 18)
	_own(player, entities, root)
	var enemy_positions: Array[Vector3] = [Vector3(12.5, 0, 7.5), Vector3(51.25, 0, 8.75), Vector3(50, 0, 29.4)]
	for i in enemy_positions.size():
		var enemy: Node3D = (load(ENEMY_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		enemy.name = "BasicEnemy%d" % (i + 1)
		enemy.position = enemy_positions[i]
		enemy.add_to_group(&"arena_enemies", true)
		_own(enemy, entities, root)
	add_ui(root, root, HELP)
	return root
