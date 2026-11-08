class_name DungeonEntrance
extends Node3D
## Portal de entrada de uma masmorra (PROVISÓRIO: anel colorido, sem arte).
## [F] Entrar: confere nível e GS; recusado, diz o que falta; aceito, pede à
## área para levar o jogador (GameArea.enter_dungeon).

signal enter_requested(by: Player, dungeon: DungeonData)

const RING_COLOR := Color(1.0, 0.55, 0.25, 0.7)

var dungeon: DungeonData


static func create(p_dungeon: DungeonData) -> DungeonEntrance:
	var entrance := DungeonEntrance.new()
	entrance.dungeon = p_dungeon
	return entrance


func _ready() -> void:
	name = "DungeonEntrance"
	var mesh := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.2
	mesh.mesh = ring
	mesh.rotation_degrees = Vector3(90, 0, 0)
	mesh.position = Vector3(0, 1.3, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = RING_COLOR
	mat.emission_enabled = true
	mat.emission = RING_COLOR
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	add_child(mesh)
	var label := Label3D.new()
	label.text = "%s\nNível %d · GS %d" % [dungeon.display_name, dungeon.min_level, dungeon.min_gear_score]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	label.pixel_size = 0.0008
	label.font_size = 22
	label.outline_size = 6
	label.position = Vector3(0, 3.0, 0)
	add_child(label)
	var area := Interactable.new()
	area.name = "Interactable"
	area.prompt_text = "Entrar"
	area.prompt_offset = Vector3(0, 2.5, 0)
	area.collision_layer = 32
	area.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.5, 2.0)
	shape.shape = box
	shape.position = Vector3(0, 1.2, 0)
	area.add_child(shape)
	area.handler = _on_interact
	add_child(area)


func _on_interact(by: Player) -> String:
	var refusal: String = dungeon.entry_refusal(by.stats.level, by.gear_score())
	if not refusal.is_empty():
		return refusal
	enter_requested.emit(by, dungeon)
	return ""
