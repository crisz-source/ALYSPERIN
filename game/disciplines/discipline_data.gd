class_name DisciplineData
extends Resource
## Disciplina (classe do personagem): bônus e habilidades de quem a escolhe.
##
## PROVISÓRIO: as Disciplinas de ALYSPERIN ainda serão definidas pelo
## proprietário. Esta estrutura permite criar/editar Disciplinas como arquivos
## .tres sem mexer em código.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon_color: Color = Color(0.7, 0.7, 0.7)

@export_group("Bônus")
@export var bonus_health: int = 0
## Dano extra com armas (0.1 = +10%).
@export var damage_bonus: float = 0.0
@export var bonus_mana: int = 0
@export var mana_regen_multiplier: float = 1.0
## Graus extras protegidos pelo escudo (para cada lado).
@export var block_angle_bonus: float = 0.0
## Multiplica o desgaste do escudo ao bloquear (0.5 = gasta metade).
@export var shield_wear_multiplier: float = 1.0

@export_group("Habilidades")
## Habilidades nas teclas 1-6 (posição na lista = tecla).
@export var abilities: Array[AbilityData] = []
