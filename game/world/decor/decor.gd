class_name Decor
extends RefCounted
## Decoração com as peças KayKit (CC0): barris, caixotes, velas, ossos, lápides,
## pilares, tochas... Usado pelo gerador da área e pelo mapa da masmorra.
## As peças foram feitas para personagens de ~2,4 de altura; o jogo usa 0,7.

const SCALE: float = 0.7
const DUNGEON := "res://assets/environment/kaykit_dungeon/"
const HALLOWEEN := "res://assets/environment/kaykit_halloween/"

## Peças: id -> [caminho, tem colisão (raio/meio-lado em m, 0 = atravessável)].
const PIECES: Dictionary = {
	&"barrel": [DUNGEON + "barrel_large.glb", 0.6],
	&"barrel_small": [DUNGEON + "barrel_small.glb", 0.35],
	&"crates": [DUNGEON + "crates_stacked.glb", 0.7],
	&"box": [DUNGEON + "box_large.glb", 0.6],
	&"candles": [DUNGEON + "candle_triple.glb", 0.0],
	&"rubble": [DUNGEON + "rubble_large.glb", 0.0],
	&"rubble_half": [DUNGEON + "rubble_half.glb", 0.0],
	&"pillar": [DUNGEON + "pillar_decorated.glb", 0.55],
	&"column": [DUNGEON + "column.glb", 0.4],
	&"banner": [DUNGEON + "banner_patternA_red.glb", 0.0],
	&"broken_gear": [DUNGEON + "sword_shield_broken.glb", 0.0],
	&"trunk": [DUNGEON + "trunk_medium_A.glb", 0.5],
	&"torch": [DUNGEON + "torch_mounted.glb", 0.0],
	&"grave": [HALLOWEEN + "grave_A.gltf", 0.6],
	&"gravestone": [HALLOWEEN + "gravestone.gltf", 0.35],
	&"skull": [HALLOWEEN + "skull.gltf", 0.0],
	&"skull_candle": [HALLOWEEN + "skull_candle.gltf", 0.0],
	&"ribcage": [HALLOWEEN + "ribcage.gltf", 0.0],
	&"bones": [HALLOWEEN + "bone_A.gltf", 0.0],
	&"coffin": [HALLOWEEN + "coffin.gltf", 0.6],
	&"dead_tree": [HALLOWEEN + "tree_dead_large.gltf", 0.4],
	&"lantern": [HALLOWEEN + "lantern_standing.gltf", 0.0],
	&"shrine": [HALLOWEEN + "shrine_candles.gltf", 0.6],
}
## Peças que soltam luz quente (velas, lanterna, tocha).
const LIGHTS: Dictionary = {&"candles": 0.6, &"skull_candle": 0.5, &"lantern": 0.9, &"torch": 1.6, &"shrine": 0.8}
const FLAME_COLOR := Color(1.0, 0.6, 0.25)


## Material de pedra com textura de ruído (no lugar de cor lisa). Projeção
## triplanar: funciona em qualquer bloco sem precisar de UV.
static func stone_material(color: Color, scale: float = 0.6) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.04
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = noise
	var gradient := Gradient.new()
	gradient.set_color(0, color.darkened(0.35))
	gradient.set_color(1, color.lightened(0.12))
	tex.color_ramp = gradient
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = 0.95
	# Visual de anime também nos blocos do mapa (GridMap não passa pelo ToonStyle).
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	return m


## Coloca uma peça. Devolve o nó (para o gerador poder dar dono a ele).
static func place(parent: Node, id: StringName, pos: Vector3, yaw: float = 0.0, extra_scale: float = 1.0) -> Node3D:
	assert(PIECES.has(id), "Decor: peça desconhecida %s" % id)
	var spec: Array = PIECES[id]
	var root := Node3D.new()
	root.name = String(id).capitalize().replace(" ", "")
	root.position = pos
	root.rotation.y = yaw
	var scene: PackedScene = load(spec[0])
	var model: Node3D = scene.instantiate()
	model.scale = Vector3.ONE * SCALE * extra_scale
	root.add_child(model)
	var radius: float = float(spec[1]) * extra_scale
	if radius > 0.0:
		var body := StaticBody3D.new()
		body.name = "Collision"
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(radius * 2.0, 2.0, radius * 2.0)
		shape.shape = box
		shape.position = Vector3(0, 1.0, 0)
		body.add_child(shape)
		root.add_child(body)
	if LIGHTS.has(id):
		var light := OmniLight3D.new()
		light.name = "Light"
		light.light_color = FLAME_COLOR
		light.light_energy = LIGHTS[id]
		light.omni_range = 6.0 if id == &"torch" else 3.5
		light.position = Vector3(0, 1.0 if id != &"torch" else 0.3, 0)
		root.add_child(light)
	parent.add_child(root)
	return root
