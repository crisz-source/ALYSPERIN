class_name CharacterStats
extends Node
## Progressão do personagem: experiência e nível (máximo 60).
##
## Sem pontos para distribuir (decisão do proprietário): a cada nível, vida,
## mana e dano crescem automaticamente e IGUAL para todas as classes. As
## diferenças entre classes/disciplinas vêm das habilidades.

signal xp_changed(xp: int, xp_to_next: int)
signal leveled_up(new_level: int)

@export var max_level: int = 60
## Experiência para passar do nível N para N+1 = xp_per_level * N.
@export var xp_per_level: int = 30
@export var health_per_level: int = 8
@export var mana_per_level: int = 2
## Dano-base extra por nível (0.1 = +10% do dano do nível 1 a cada nível).
@export var damage_per_level: float = 0.1

var level: int = 1
var xp: int = 0


func xp_to_next() -> int:
	return xp_per_level * level


func is_max_level() -> bool:
	return level >= max_level


## Soma experiência; pode subir vários níveis de uma vez. No nível máximo, para.
func add_xp(amount: int) -> void:
	if amount <= 0 or is_max_level():
		return
	xp += amount
	while not is_max_level() and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled_up.emit(level)
	if is_max_level():
		xp = 0
	xp_changed.emit(xp, xp_to_next())


## at_level > 0 = calcula para outro nível (ex.: nível efetivo da masmorra).
func bonus_max_health(at_level: int = 0) -> int:
	return ((at_level if at_level > 0 else level) - 1) * health_per_level


func bonus_max_mana(at_level: int = 0) -> int:
	return ((at_level if at_level > 0 else level) - 1) * mana_per_level


func damage_multiplier(at_level: int = 0) -> float:
	return 1.0 + ((at_level if at_level > 0 else level) - 1) * damage_per_level
