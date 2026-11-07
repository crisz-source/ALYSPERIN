class_name ManaComponent
extends Node
## Mana: recurso gasto pelas magias. NÃO recupera sozinha (decisão do
## proprietário): volta com itens de mana (e cheia ao continuar após a morte).
## Como a vida, só guarda e avisa; quem decide gastar é o dono.

signal mana_changed(current: int, maximum: int)

@export var max_mana: int = 30
## Mana recuperada por segundo. 0 = não recupera sozinha (padrão do jogo).
@export var regen_per_second: float = 0.0

## Guardada com fração para a recuperação ser suave; a interface mostra inteiro.
var _current: float = 0.0


func _ready() -> void:
	_current = max_mana


func _physics_process(delta: float) -> void:
	if _current >= max_mana:
		return
	var before: int = current()
	_current = minf(_current + regen_per_second * delta, max_mana)
	if current() != before:
		mana_changed.emit(current(), max_mana)


func current() -> int:
	return int(_current)


func has(amount: int) -> bool:
	return current() >= amount


## Gasta mana. Devolve false (sem gastar nada) se não houver o suficiente.
func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if not has(amount):
		return false
	_current -= amount
	mana_changed.emit(current(), max_mana)
	return true


func restore(amount: int) -> void:
	if amount <= 0:
		return
	_current = minf(_current + amount, max_mana)
	mana_changed.emit(current(), max_mana)


func restore_full() -> void:
	_current = max_mana
	mana_changed.emit(current(), max_mana)


## Muda o máximo (Disciplina); aumento também enche a mana atual na mesma quantia.
func set_max_mana(new_max: int) -> void:
	var increase: int = maxi(new_max - max_mana, 0)
	max_mana = maxi(new_max, 0)
	_current = clampf(_current + increase, 0.0, max_mana)
	mana_changed.emit(current(), max_mana)
