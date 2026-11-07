class_name ShieldData
extends ItemData
## Escudo: sem escudo equipado não há defesa.

## Metade do ângulo protegido, à frente da mira (graus).
@export_range(0.0, 180.0) var block_half_angle: float = 75.0
## Quanto do empurrão do golpe ainda chega ao defender.
@export_range(0.0, 1.0) var knockback_multiplier: float = 0.35
@export var durability: int = 40
## Escudo quebrado ainda segura parte: deixa passar esta fração do dano.
@export_range(0.0, 1.0) var broken_damage_through: float = 0.5


func kind() -> Kind:
	return Kind.SHIELD


func max_durability() -> int:
	return durability
