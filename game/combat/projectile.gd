class_name Projectile
extends Hitbox
## Projétil (ex.: Dardo arcano). É um Hitbox que anda em linha reta: some ao
## acertar alguém, ao bater numa parede ou depois de percorrer max_distance.
##
## Criado como filho de quem disparou com top_level = true, para andar sozinho
## pelo mundo sem precisar procurar o nó da área.

const SCENE_PATH := "res://game/combat/projectile.tscn"

var direction: Vector2 = Vector2.RIGHT
var speed: float = 240.0
var max_distance: float = 220.0
var _traveled: float = 0.0


static func fire(shooter: Node2D, from: Vector2, p_direction: Vector2, data: ProjectileSpellData) -> Projectile:
	var p: Projectile = (load(SCENE_PATH) as PackedScene).instantiate()
	p.direction = p_direction.normalized()
	p.speed = data.speed
	p.max_distance = data.max_distance
	p.damage = data.damage
	p.knockback_force = data.knockback
	p.attacker = shooter
	p.top_level = true
	shooter.add_child(p)
	p.global_position = from
	p.rotation = p.direction.angle()
	(p.get_node("Visual") as Polygon2D).color = data.projectile_color
	return p


func _ready() -> void:
	super()
	# O Hitbox desliga monitorable, mas na física da Godot uma área assim NÃO
	# detecta corpos estáticos (paredes, portas, tiles): o projétil atravessaria.
	monitorable = true
	activate()
	hit_landed.connect(func(_t: Hurtbox) -> void: queue_free())
	body_entered.connect(func(_b: Node2D) -> void: queue_free())  # parede (camada world)


func _physics_process(delta: float) -> void:
	var step: Vector2 = direction * speed * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_distance:
		queue_free()
		return
	super(delta)
