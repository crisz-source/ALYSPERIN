class_name HealthComponent
extends Node
## Vida de qualquer coisa que pode apanhar: jogador, inimigo, objeto quebrável.
##
## É o único lugar que decide se o dano vale e se algo morreu. Quem mostra barra,
## pisca ou toca som apenas escuta os sinais. No co-op, só o host vai chamar
## apply_damage(); os outros recebem o resultado.

signal health_changed(current: int, maximum: int)
signal damaged(info: DamageInfo)
signal died

@export var max_health: int = 100

var current_health: int
var is_dead: bool = false
## Enquanto for maior que zero, nenhum dano é aplicado (esquiva, pós-dano).
var _invulnerable_time: float = 0.0
## Invulnerabilidade controlada por outro sistema (ex.: janela da esquiva).
var _invulnerable_flag: bool = false


func _ready() -> void:
	current_health = max_health


func _physics_process(delta: float) -> void:
	if _invulnerable_time > 0.0:
		_invulnerable_time = maxf(_invulnerable_time - delta, 0.0)


func is_invulnerable() -> bool:
	return _invulnerable_flag or _invulnerable_time > 0.0


## Invulnerabilidade temporária. Não encurta uma que já dure mais.
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_time = maxf(_invulnerable_time, seconds)


func set_invulnerable(value: bool) -> void:
	_invulnerable_flag = value


## Retorna true se o dano foi aplicado.
func apply_damage(info: DamageInfo) -> bool:
	if is_dead or is_invulnerable() or info.amount <= 0:
		return false
	current_health = maxi(current_health - info.amount, 0)
	damaged.emit(info)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		is_dead = true
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
