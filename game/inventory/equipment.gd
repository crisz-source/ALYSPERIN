class_name Equipment
extends Node
## O que está equipado: uma arma e um escudo. Ficam FORA das vagas da bolsa.

signal changed

@export var starting_weapon: ItemStack
@export var starting_shield: ItemStack

var weapon: ItemStack = null
var shield: ItemStack = null


func _ready() -> void:
	if starting_weapon and starting_weapon.item is WeaponData:
		weapon = starting_weapon.copy()
	if starting_shield and starting_shield.item is ShieldData:
		shield = starting_shield.copy()


func weapon_data() -> WeaponData:
	return weapon.item as WeaponData if weapon else null


func shield_data() -> ShieldData:
	return shield.item as ShieldData if shield else null


## Equipa na vaga certa (pelo tipo do item). Devolve o que estava equipado antes
## (para voltar à bolsa) ou null. Item que não é arma nem escudo é recusado: devolve o próprio.
func equip(stack: ItemStack) -> ItemStack:
	var previous: ItemStack
	if stack.item is WeaponData:
		previous = weapon
		weapon = stack
	elif stack.item is ShieldData:
		previous = shield
		shield = stack
	else:
		return stack
	changed.emit()
	return previous


func unequip_weapon() -> ItemStack:
	var previous: ItemStack = weapon
	weapon = null
	changed.emit()
	return previous


func unequip_shield() -> ItemStack:
	var previous: ItemStack = shield
	shield = null
	changed.emit()
	return previous


## Avisa a interface quando a durabilidade muda (o item é o mesmo, só gastou).
func notify_wear() -> void:
	changed.emit()
