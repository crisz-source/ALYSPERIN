class_name SpinSlashData
extends AbilityData
## Golpe giratório: acerta tudo num círculo em volta do personagem.

## Multiplica o dano do 1º golpe da arma equipada (já com Força e desgaste).
@export var damage_multiplier: float = 1.5
@export var knockback: float = 220.0
## Duração total do giro (s); a lâmina machuca no meio dele.
@export var duration: float = 0.32
@export var active_start: float = 0.06
@export var active_end: float = 0.26
