class_name CharacterStats
extends Node
## Progressão do personagem: experiência, nível e atributos.
##
## Cada nível dá pontos para distribuir (o jogador escolhe):
## - Vigor: mais vida máxima.
## - Força: mais dano com qualquer arma.
## Só guarda números e avisa por sinal; o Player aplica os efeitos.

signal xp_changed(xp: int, xp_to_next: int)
signal leveled_up(new_level: int)
signal attributes_changed

enum Attribute { VIGOR, STRENGTH }

## Experiência para passar do nível N para N+1 = xp_per_level * N.
@export var xp_per_level: int = 30
@export var points_per_level: int = 1
@export var health_per_vigor: int = 10
## Dano extra por ponto de Força (0.08 = +8%).
@export var damage_per_strength: float = 0.08

var level: int = 1
var xp: int = 0
var unspent_points: int = 0
var vigor: int = 0
var strength: int = 0


func xp_to_next() -> int:
	return xp_per_level * level


## Soma experiência; pode subir vários níveis de uma vez.
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		unspent_points += points_per_level
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_next())


## Gasta 1 ponto no atributo. Devolve false se não há pontos.
func spend_point(attribute: Attribute) -> bool:
	if unspent_points <= 0:
		return false
	unspent_points -= 1
	match attribute:
		Attribute.VIGOR:
			vigor += 1
		Attribute.STRENGTH:
			strength += 1
	attributes_changed.emit()
	return true


func bonus_max_health() -> int:
	return vigor * health_per_vigor


func damage_multiplier() -> float:
	return 1.0 + strength * damage_per_strength
