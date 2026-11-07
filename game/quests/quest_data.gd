class_name QuestData
extends Resource
## Missão: objetivo, recompensa e as falas de quem a oferece.
## PROVISÓRIO quanto ao conteúdo (textos e números); a estrutura é a base.

enum Objective { KILL, COLLECT }

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""

@export_group("Objetivo")
@export var objective: Objective = Objective.KILL
## KILL: tipo de inimigo (BasicEnemy.kind). Vazio = qualquer inimigo.
@export var target_kind: StringName = &""
## COLLECT: item a entregar (sai da bolsa ao concluir).
@export var target_item: ItemData
@export var required_count: int = 1

@export_group("Recompensa")
@export var reward_xp: int = 0
@export var reward_items: Array[ItemStack] = []

@export_group("Falas")
@export var offer_lines: Array[String] = []
@export var in_progress_lines: Array[String] = []
@export var complete_lines: Array[String] = []
