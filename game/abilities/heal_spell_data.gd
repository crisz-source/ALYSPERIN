class_name HealSpellData
extends AbilityData
## Magia de cura. Com `requires_target`, abre o modo de seleção: o jogador
## passa a mira em um ou mais aliados (ficam esverdeados) e confirma com Espaço.
## Sem isso, cura quem conjurou.

@export var heal_amount: int = 30
## Tempo conjurando antes de curar (s); levar dano nesse tempo cancela.
@export var cast_time: float = 0.25
## true = escolhe aliados com a mira (custo de mana fixo por uso, qualquer número de aliados).
@export var requires_target: bool = false


func is_implemented() -> bool:
	return true
