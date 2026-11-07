class_name QuestStep
extends Resource
## Uma etapa de uma missão (ex.: "derrote 3 inimigos", depois "colete 2 ervas").
## A missão avança de etapa falando com quem a deu.

enum Objective { KILL, COLLECT }

## Texto curto mostrado no HUD (ex.: "Derrote 3 inimigos").
@export var description: String = ""
@export var objective: Objective = Objective.KILL
## KILL: tipo de inimigo (BasicEnemy.kind). Vazio = qualquer inimigo.
@export var target_kind: StringName = &""
## COLLECT: item a entregar (sai da bolsa ao concluir a etapa).
@export var target_item: ItemData
@export var required_count: int = 1
## Fala do NPC enquanto a etapa não foi cumprida.
@export var in_progress_lines: Array[String] = []
## Fala do NPC ao concluir esta etapa e passar para a próxima (não usada na última).
@export var advance_lines: Array[String] = []
