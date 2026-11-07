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
## O golpe chegou, mas foi bloqueado (escudo, defesa). Nenhum dano aplicado.
signal blocked(info: DamageInfo)
## O golpe chegou durante uma invulnerabilidade e foi ignorado (ex.: esquiva no
## tempo certo). Quem quiser recompensar isso escuta este sinal.
signal hit_ignored(info: DamageInfo)

@export var max_health: int = 100

var current_health: int
var is_dead: bool = false
## Enquanto for maior que zero, nenhum dano é aplicado (esquiva, pós-dano).
var _invulnerable_time: float = 0.0
## Invulnerabilidade controlada por outro sistema (ex.: janela da esquiva).
var _invulnerable_flag: bool = false
## Opcional: função que recebe o DamageInfo e devolve true se o golpe foi
## bloqueado. Quem sabe se está defendendo é o dono (ex.: Player), mas a
## decisão final continua passando por apply_damage().
var block_filter: Callable
## Opcional: func(info: DamageInfo) -> void que pode alterar info.amount antes
## do dano (ex.: golpe pelas costas). Quem sabe para onde está virado é o dono.
var damage_modifier: Callable


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
	if is_dead or info.amount <= 0:
		return false
	if is_invulnerable():
		hit_ignored.emit(info)
		return false
	if block_filter.is_valid() and block_filter.call(info):
		info.blocked = true
		blocked.emit(info)
		return false
	if damage_modifier.is_valid():
		damage_modifier.call(info)
	current_health = maxi(current_health - info.amount, 0)
	damaged.emit(info)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		is_dead = true
		died.emit()
	return true


## Muda a vida máxima (ex.: ponto de Vigor). Aumento também enche a vida atual
## na mesma quantia; redução só corta o que passar do novo máximo.
func set_max_health(new_max: int) -> void:
	new_max = maxi(new_max, 1)
	var increase: int = new_max - max_health
	max_health = new_max
	if not is_dead:
		current_health = clampi(current_health + maxi(increase, 0), 1, max_health)
	health_changed.emit(current_health, max_health)


## Volta à vida com vida cheia (continuar depois da morte, ponto de descanso).
func revive() -> void:
	is_dead = false
	current_health = max_health
	_invulnerable_time = 0.0
	_invulnerable_flag = false
	health_changed.emit(current_health, max_health)


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
