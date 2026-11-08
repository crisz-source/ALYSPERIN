class_name AllyDummy
extends CharacterBody3D
## Aliado de TESTE (provisório): boneco parado com vida, para testar curas
## antes do co-op existir. Criado pelo menu de testes (tecla P).
##
## Não é atacado pelos inimigos (não está no grupo "players"). Mostra a vida
## acima da cabeça e fica esverdeado quando selecionado para cura.

const GROUP: StringName = &"allies"
const BODY_COLOR := Color(0.7, 0.65, 0.85)
const SELECTED_COLOR := Color(0.45, 1.0, 0.5)
const GRAVITY: float = 20.0

var health: HealthComponent
var _material: StandardMaterial3D
var _label: Label3D
var _selected: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 2   # camada "player": a mira de cura enxerga aliados aqui
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	shape.shape = capsule
	shape.position = Vector3(0, 0.8, 0)
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.6
	mesh.mesh = cm
	_material = StandardMaterial3D.new()
	_material.albedo_color = BODY_COLOR
	mesh.material_override = _material
	mesh.position = Vector3(0, 0.8, 0)
	add_child(mesh)
	health = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 100
	add_child(health)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0008
	_label.font_size = 36
	_label.outline_size = 8
	_label.position = Vector3(0, 2.0, 0)
	add_child(_label)
	health.health_changed.connect(func(_c: int, _m: int) -> void: _refresh())
	health.shield_changed.connect(func(_p: int) -> void: _refresh())
	_refresh()


func _physics_process(delta: float) -> void:
	velocity.y = velocity.y - GRAVITY * delta if not is_on_floor() else 0.0
	move_and_slide()


## Seleção para cura: fica esverdeado enquanto selecionado.
func set_heal_selected(value: bool) -> void:
	_selected = value
	_material.albedo_color = BODY_COLOR.lerp(SELECTED_COLOR, 0.65) if value else BODY_COLOR


func is_heal_selected() -> bool:
	return _selected


func _refresh() -> void:
	if health == null:
		return
	var shield: String = "  +%d escudo" % health.shield_points if health.shield_points > 0 else ""
	_label.text = "Aliado de teste  %d/%d%s" % [health.current_health, health.max_health, shield]
	_label.modulate = Color(0.6, 1.0, 0.6) if health.current_health >= health.max_health else Color(1.0, 0.85, 0.5)
