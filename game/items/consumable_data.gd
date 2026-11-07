class_name ConsumableData
extends ItemData
## Item que se gasta ao usar (ex.: cura).

## Vida recuperada ao usar. 0 = não cura.
@export var heal_amount: int = 0


func kind() -> Kind:
	return Kind.CONSUMABLE
