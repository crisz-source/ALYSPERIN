class_name Projectile
extends Hitbox
## Projétil (ex.: Dardo arcano), 3D. É um Hitbox que anda em linha reta no
## chão: some ao acertar alguém, ao bater numa parede ou depois de percorrer
## max_distance.
##
## Criado como filho de quem disparou com top_level = true, para andar sozinho
## pelo mundo sem precisar procurar o nó da área.

const SCENE_PATH := "res://game/combat/projectile.tscn"
## Conversão da escala da versão 2D (pixels) para metros.
const PIXELS_PER_METER: float = 16.0

var direction: Vector3 = Vector3.FORWARD
var speed: float = 15.0
var max_distance: float = 13.75
var _traveled: float = 0.0


## Os números de ProjectileSpellData estão na escala antiga (pixels): convertidos aqui.
static func fire(shooter: Node3D, from: Vector3, p_direction: Vector3, data: ProjectileSpellData) -> Projectile:
	var p: Projectile = (load(SCENE_PATH) as PackedScene).instantiate()
	p.direction = Vector3(p_direction.x, 0.0, p_direction.z).normalized()
	p.speed = data.speed / PIXELS_PER_METER
	p.max_distance = data.max_distance / PIXELS_PER_METER
	p.damage = data.damage
	p.knockback_force = data.knockback / PIXELS_PER_METER
	p.attacker = shooter
	p.top_level = true
	shooter.add_child(p)
	p.global_position = from
	var visual: MeshInstance3D = p.get_node("Visual")
	var mat := (visual.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	mat.albedo_color = data.projectile_color
	mat.emission = data.projectile_color
	visual.material_override = mat
	return p


func _ready() -> void:
	super()
	# O Hitbox desliga monitorable, mas na física da Godot uma área assim NÃO
	# detecta corpos estáticos (paredes, portas): o projétil atravessaria.
	monitorable = true
	activate()
	hit_landed.connect(func(_t: Hurtbox) -> void: queue_free())
	body_entered.connect(func(_b: Node3D) -> void: queue_free())  # parede (camada world)


func _physics_process(delta: float) -> void:
	var step: Vector3 = direction * speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_distance:
		queue_free()
		return
	super(delta)
