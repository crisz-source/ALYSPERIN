class_name ConsumableData
extends ItemData
## Item que se gasta ao usar (ex.: cura).

## Vida recuperada ao usar. 0 = não cura.
@export var heal_amount: int = 0
## Mana recuperada ao usar. 0 = não recupera mana.
@export var mana_amount: int = 0
## Óleo de arma: dá este elemento aos golpes da arma por `element_duration` s
## (&"fire", &"ice", &"lightning"...). Vazio = não é óleo.
@export var weapon_element: StringName = &""
@export var element_duration: float = 60.0


func kind() -> Kind:
	return Kind.CONSUMABLE
