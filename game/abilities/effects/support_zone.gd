class_name SupportZone
extends Node3D
## Área parada no chão criada por uma habilidade de suporte:
##   - HEAL: cura `amount` por segundo quem do grupo está dentro (Círculo de cura);
##   - DOME: quem do grupo está dentro fica Protegido (menos dano) e projéteis
##     inimigos que entram somem (Fortaleza viva).
## Visual provisório (disco/cúpula translúcida). Some sozinha após `duration`.

enum Kind { HEAL, DOME }

const PULSE_INTERVAL: float = 0.5
const HEAL_COLOR := Color(0.5, 1.0, 0.55, 0.3)
const DOME_COLOR := Color(0.55, 0.75, 1.0, 0.22)

var kind: Kind = Kind.HEAL
var caster: Player
var radius: float = 4.0
var duration: float = 6.0
var amount: int = 0
var protect_strength: float = 0.5

var _time: float = 0.0
var _pulse: float = 0.0


static func spawn(p_caster: Player, p_kind: Kind, p_radius: float, p_duration: float, p_amount: int, p_strength: float = 0.5) -> SupportZone:
	var zone := SupportZone.new()
	zone.kind = p_kind
	zone.caster = p_caster
	zone.radius = p_radius
	zone.duration = p_duration
	zone.amount = p_amount
	zone.protect_strength = p_strength
	p_caster.get_parent().add_child(zone)
	zone.global_position = p_caster.global_position
	return zone


func _ready() -> void:
	name = "HealZone" if kind == Kind.HEAL else "Dome"
	var mesh := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = HEAL_COLOR if kind == Kind.HEAL else DOME_COLOR
	if kind == Kind.HEAL:
		var disc := CylinderMesh.new()
		disc.top_radius = radius
		disc.bottom_radius = radius
		disc.height = 0.04
		mesh.mesh = disc
		mesh.position.y = 0.03
	else:
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		sphere.is_hemisphere = true
		mesh.mesh = sphere
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


func _physics_process(delta: float) -> void:
	_time += delta
	_pulse -= delta
	if _pulse <= 0.0:
		_pulse += PULSE_INTERVAL
		_apply_pulse()
	if kind == Kind.DOME:
		_remove_enemy_projectiles()
	if _time >= duration:
		queue_free()


## Quem do grupo está dentro da área.
func members_inside() -> Array[Node3D]:
	var inside: Array[Node3D] = []
	if not is_instance_valid(caster):
		return inside
	for member: Node3D in caster.group_members(radius, global_position):
		inside.append(member)
	return inside


func _apply_pulse() -> void:
	for member: Node3D in members_inside():
		var hp: HealthComponent = member.get("health")
		if kind == Kind.HEAL:
			if hp and not hp.is_dead:
				hp.heal(maxi(roundi(amount * PULSE_INTERVAL), 1))
		else:
			var fx: StatusEffects = member.get("status")
			if fx:
				fx.apply(StatusEffects.PROTECT, PULSE_INTERVAL + 0.1, protect_strength, caster)


func _remove_enemy_projectiles() -> void:
	for node: Node in get_tree().get_nodes_in_group(Projectile.ENEMY_GROUP):
		var p := node as Node3D
		if p and p.global_position.distance_to(global_position) <= radius:
			p.queue_free()
