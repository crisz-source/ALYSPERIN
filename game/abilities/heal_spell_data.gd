class_name HealSpellData
extends AbilityData
## Magia de cura em si mesmo.

@export var heal_amount: int = 30
## Tempo conjurando antes de curar (s); levar dano nesse tempo cancela.
@export var cast_time: float = 0.25


func is_implemented() -> bool:
	return true
