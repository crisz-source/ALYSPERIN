class_name Hurtbox
extends Area3D
## Área que pode SER atingida. Fica no corpo de quem apanha e repassa o golpe
## para o HealthComponent configurado no Inspetor.
##
## Não detecta nada sozinha (monitoring desligado): quem detecta é o Hitbox.

signal hit_received(info: DamageInfo)

@export var health: HealthComponent


func _ready() -> void:
	monitoring = false
	monitorable = true
	assert(health != null, "Hurtbox '%s' sem HealthComponent configurado" % get_path())


## Retorna true se o golpe causou dano de fato (false se invulnerável, morto
## ou bloqueado; no bloqueio, info.blocked fica true).
func receive_hit(info: DamageInfo) -> bool:
	if not health.apply_damage(info):
		return false
	hit_received.emit(info)
	return true
