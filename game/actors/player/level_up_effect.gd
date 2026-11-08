class_name LevelUpEffect
extends Node3D
## Efeito de subir de nível (PROVISÓRIO: formas simples, sem arte): duas asas
## douradas se abrem atrás do personagem e uma coroa surge acima da cabeça,
## com um brilho; ficam ~5 s (a coroa girando devagar) e depois sobem e somem.
## Filho do modelo do jogador.
##
## Só apresentação: criado pelo Player ao subir de nível e se apaga sozinho.

const GOLD := Color(1.0, 0.82, 0.3)
const DURATION: float = 5.0
## Últimos segundos: o efeito sobe e desaparece.
const FADE_TIME: float = 1.2
const HEAD_HEIGHT: float = 2.15

var _material: StandardMaterial3D
var _wings: Array[Node3D] = []
var _crown: Node3D
var _light: OmniLight3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = GOLD
	_material.emission_enabled = true
	_material.emission = GOLD
	_material.emission_energy_multiplier = 2.5
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side: float in [-1.0, 1.0]:
		_wings.append(_build_wing(side))
	_crown = _build_crown()
	_light = OmniLight3D.new()
	_light.light_color = GOLD
	_light.omni_range = 4.0
	_light.light_energy = 3.0
	_light.position = Vector3(0, 1.4, 0)
	add_child(_light)
	_animate()


## Asa: três "penas" achatadas em leque, presas nas costas (o modelo olha para
## -Z, então +Z é atrás; o efeito é filho do modelo e gira junto).
func _build_wing(side: float) -> Node3D:
	var wing := Node3D.new()
	wing.position = Vector3(side * 0.25, 1.35, 0.3)
	add_child(wing)
	for i in 3:
		var feather := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.28, 1.0 - i * 0.18, 0.03)
		feather.mesh = mesh
		feather.material_override = _material
		feather.position = Vector3(side * (0.35 + i * 0.22), 0.1 - i * 0.12, 0)
		feather.rotation_degrees = Vector3(0, 0, -side * (50.0 + i * 18.0))
		feather.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wing.add_child(feather)
	wing.scale = Vector3(0.05, 0.05, 0.05)
	return wing


## Coroa: anel com cinco pontas acima da cabeça.
func _build_crown() -> Node3D:
	var crown := Node3D.new()
	crown.position = Vector3(0, HEAD_HEIGHT, 0)
	add_child(crown)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.26
	ring.mesh = torus
	ring.material_override = _material
	crown.add_child(ring)
	for i in 5:
		var spike := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.1, 0.18, 0.04)
		spike.mesh = prism
		spike.material_override = _material
		var angle: float = TAU * i / 5.0
		spike.position = Vector3(cos(angle) * 0.23, 0.1, sin(angle) * 0.23)
		spike.rotation.y = -angle + PI / 2.0
		crown.add_child(spike)
	crown.scale = Vector3.ZERO
	return crown


func _animate() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for wing: Node3D in _wings:
		tween.tween_property(wing, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_crown, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	tween.tween_property(_crown, "rotation:y", TAU, DURATION)
	tween.tween_property(self, "position:y", 0.4, FADE_TIME).set_delay(DURATION - FADE_TIME)
	tween.tween_property(_material, "albedo_color:a", 0.0, FADE_TIME).set_delay(DURATION - FADE_TIME)
	# Brilho forte no começo, depois fica fraco enquanto as asas estão abertas.
	tween.tween_property(_light, "light_energy", 1.0, 1.0)
	tween.tween_property(_light, "light_energy", 0.0, FADE_TIME).set_delay(DURATION - FADE_TIME)
	tween.chain().tween_callback(queue_free)


## Para testes: o efeito tem asas e coroa montadas.
func part_count() -> Dictionary:
	return {"wings": _wings.size(), "crown_spikes": _crown.get_child_count() - 1}
