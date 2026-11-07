class_name QuestLog
extends Node
## Diário de missões do jogador: quais estão ativas, o progresso e quais já
## foram entregues. Só guarda e avisa; quem dá a recompensa é o NPC/Player.

signal quest_started(quest: QuestData)
signal quest_progressed(quest: QuestData, progress: int)
signal quest_completed(quest: QuestData)

## id -> progresso (KILL). Para COLLECT o progresso é lido da bolsa na hora.
var _active: Dictionary = {}
var _quests: Dictionary = {}   # id -> QuestData
var _completed: Array[StringName] = []
## Bolsa usada para contar itens de missões de coleta (definida pelo dono).
var inventory: Inventory


func start(quest: QuestData) -> void:
	if is_active(quest) or is_completed(quest):
		return
	_active[quest.id] = 0
	_quests[quest.id] = quest
	quest_started.emit(quest)


func is_active(quest: QuestData) -> bool:
	return _active.has(quest.id)


func is_completed(quest: QuestData) -> bool:
	return _completed.has(quest.id)


func active_quests() -> Array[QuestData]:
	var list: Array[QuestData] = []
	for id: StringName in _active:
		list.append(_quests[id])
	return list


func progress_of(quest: QuestData) -> int:
	if not is_active(quest):
		return 0
	if quest.objective == QuestData.Objective.COLLECT:
		return mini(inventory.count_of(quest.target_item) if inventory else 0, quest.required_count)
	return int(_active[quest.id])


func is_ready(quest: QuestData) -> bool:
	return is_active(quest) and progress_of(quest) >= quest.required_count


## Um inimigo foi derrotado por este jogador.
func notify_kill(kind: StringName) -> void:
	for id: StringName in _active:
		var quest: QuestData = _quests[id]
		if quest.objective != QuestData.Objective.KILL:
			continue
		if quest.target_kind != &"" and quest.target_kind != kind:
			continue
		if int(_active[id]) >= quest.required_count:
			continue
		_active[id] = int(_active[id]) + 1
		quest_progressed.emit(quest, int(_active[id]))


## Avisa a interface quando a bolsa muda (missões de coleta).
func refresh_collect() -> void:
	for id: StringName in _active:
		var quest: QuestData = _quests[id]
		if quest.objective == QuestData.Objective.COLLECT:
			quest_progressed.emit(quest, progress_of(quest))


## Marca como entregue. Devolve false se o objetivo ainda não foi cumprido.
func complete(quest: QuestData) -> bool:
	if not is_ready(quest):
		return false
	_active.erase(quest.id)
	_completed.append(quest.id)
	quest_completed.emit(quest)
	return true
