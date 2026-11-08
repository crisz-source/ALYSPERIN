class_name TauntData
extends AbilityData
## Provocar (Guardião): inimigos próximos passam a atacar quem provocou
## por alguns segundos, mesmo que outro jogador esteja mais perto (co-op).

## Alcance da provocação (m).
@export var radius: float = 8.0
## Quanto tempo os inimigos ficam presos ao provocador (s).
@export var taunt_time: float = 4.0


func is_implemented() -> bool:
	return true
