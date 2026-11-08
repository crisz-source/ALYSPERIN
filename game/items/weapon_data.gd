class_name WeaponData
extends ItemData
## Arma corpo a corpo. Os números multiplicam o golpe base do jogador
## (combo, tempos, alcance), então trocar de arma muda o jeito de lutar.

## Tipo de arma (espada, maca, machado, cajado...): define quais classes usam.
@export var weapon_type: StringName = &"espada"
## Gear Score (nível do item). Escala o dano da arma; entra na média do personagem.
@export var gear_score: int = 100
## Dano do 1º golpe do combo (os outros usam os multiplicadores do Player).
@export var damage: int = 10
## Multiplica os tempos do golpe (preparação, lâmina, recuperação): >1 = mais lento.
@export var timing_scale: float = 1.0
## Multiplica o alcance do arco do golpe.
@export var reach_scale: float = 1.0
@export var knockback_multiplier: float = 1.0
@export var durability: int = 80
## Arma quebrada continua usável, mas causa só esta fração do dano.
@export_range(0.0, 1.0) var broken_damage_multiplier: float = 0.4


func kind() -> Kind:
	return Kind.WEAPON


func max_durability() -> int:
	return durability
