class_name TravelPortal
extends Node3D
## Portal de viagem simples (anel colorido + nome + [F] verbo). Quem usa decide o
## destino pelo sinal `used`. PROVISÓRIO: sem arte.

signal used(by: Player)

var title: String = ""
var verb: String = "Viajar"
var color: Color = Color(0.4, 0.9, 0.6, 0.7)


static func create(p_title: String, p_verb: String, p_color: Color) -> TravelPortal:
	var portal := TravelPortal.new()
	portal.title = p_title
	portal.verb = p_verb
	portal.color = p_color
	return portal


func _ready() -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Ring"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.2
	mesh.mesh = ring
	mesh.rotation_degrees = Vector3(90, 0, 0)
	mesh.position = Vector3(0, 1.3, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	add_child(mesh)
	if not title.is_empty():
		var label := Label3D.new()
		label.text = title
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size = true
		label.pixel_size = 0.0008
		label.font_size = 22
		label.outline_size = 6
		label.position = Vector3(0, 3.0, 0)
		add_child(label)
	var area := Interactable.new()
	area.name = "Interactable"
	area.prompt_text = verb
	area.prompt_offset = Vector3(0, 2.5, 0)
	area.collision_layer = 32
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.5, 2.0)
	shape.shape = box
	shape.position = Vector3(0, 1.2, 0)
	area.add_child(shape)
	area.handler = func(by: Player) -> String:
		used.emit(by)
		return ""
	add_child(area)
