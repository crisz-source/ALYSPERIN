class_name HealthBar3D
extends Node3D
## Barra de vida flutuando acima de um inimigo (3D). Sempre virada para a
## câmera. PROVISÓRIA: duas faixas coloridas, sem arte.
##
## Monta os próprios quadrados no _ready (fundo escuro + preenchimento vermelho
## que encolhe a partir da esquerda).

@export var width: float = 0.9
@export var height: float = 0.09
@export var fill_color: Color = Color(0.85, 0.2, 0.2)
@export var background_color: Color = Color(0.08, 0.08, 0.1, 0.9)

var ratio: float = 1.0
var _fill: MeshInstance3D


func _ready() -> void:
	add_child(_quad("Background", background_color, 0.0, Vector3(-width / 2.0, 0, 0)))
	_fill = _quad("Fill", fill_color, 0.002, Vector3(-width / 2.0, 0, 0))
	add_child(_fill)
	set_ratio(ratio)


func set_ratio(value: float) -> void:
	ratio = clampf(value, 0.0, 1.0)
	if _fill:
		_fill.scale.x = maxf(ratio, 0.001)


func _process(_delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam:
		global_basis = cam.global_basis


## Quadrado com a borda esquerda na origem (para encolher a partir da esquerda).
func _quad(node_name: String, color: Color, z: float, pos: Vector3) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width, height)
	mesh.center_offset = Vector3(width / 2.0, 0, z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.render_priority = 5 if z > 0.0 else 4
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
