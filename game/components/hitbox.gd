class_name Hitbox
extends Area3D
## Área que CAUSA dano: lâmina da espada, investida de inimigo, projétil.
##
## Só machuca enquanto ativa. Cada ativação atinge cada alvo no máximo uma vez,
## a não ser que rehit_interval > 0 (dano contínuo, ex.: chão de espinhos).
## Quem é atingido é decidido pela collision_mask (ex.: espada do jogador só
## enxerga a camada "enemy").

signal hit_landed(target: Hurtbox)
## O alvo defendeu o golpe (ex.: jogador com escudo levantado).
signal hit_blocked(target: Hurtbox)

@export var damage: int = 10
## Força do empurrão aplicado no alvo, em metros por segundo (no chão).
@export var knockback_force: float = 10.0
## 0 = acerta cada alvo uma vez por ativação. > 0 = pode repetir após N segundos.
@export var rehit_interval: float = 0.0
## Quem é considerado o autor do golpe (usado para direção do empurrão).
@export var attacker: Node3D
## Elemento dos golpes desta área (vazio = físico). Ex.: óleo de fogo na arma.
var element: StringName = &""

var is_active: bool = false
var _hit_times: Dictionary = {}   # Hurtbox -> tempo (s) do último acerto
var _clock: float = 0.0


func _ready() -> void:
	monitorable = false
	monitoring = true


func activate() -> void:
	is_active = true
	_hit_times.clear()


func deactivate() -> void:
	is_active = false


func _physics_process(delta: float) -> void:
	_clock += delta
	if not is_active:
		return
	# Varre o que está sobreposto a cada quadro em vez de depender só do sinal
	# area_entered: assim um alvo que já estava encostado na hora da ativação
	# também é atingido.
	for area: Area3D in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or not _can_hit(hurtbox):
			continue
		_hit_times[hurtbox] = _clock
		var info: DamageInfo = _build_damage(hurtbox)
		if hurtbox.receive_hit(info):
			hit_landed.emit(hurtbox)
		elif info.blocked:
			hit_blocked.emit(hurtbox)


func _can_hit(hurtbox: Hurtbox) -> bool:
	if not _hit_times.has(hurtbox):
		return true
	return rehit_interval > 0.0 and _clock - float(_hit_times[hurtbox]) >= rehit_interval


## O empurrão é sempre no chão (sem componente vertical).
func _build_damage(target: Hurtbox) -> DamageInfo:
	var origin: Vector3 = attacker.global_position if attacker else global_position
	var direction: Vector3 = target.global_position - origin
	direction.y = 0.0
	var info := DamageInfo.new(damage, direction.normalized() * knockback_force, attacker)
	info.element = element
	return info
