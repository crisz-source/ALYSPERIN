class_name ShieldBashData
extends AbilityData
## Golpe de escudo (Guardião/Bastião): pancada curta à frente que empurra e
## atordoa. Precisa de escudo equipado.

## Multiplica o dano do 1º golpe da arma (já com nível e desgaste).
@export var damage_multiplier: float = 0.8
@export var knockback: float = 9.0
## Tempo que o alvo fica atordoado (s).
@export var stun_time: float = 1.5
@export var duration: float = 0.3
@export var active_start: float = 0.06
@export var active_end: float = 0.16


func is_implemented() -> bool:
	return true
