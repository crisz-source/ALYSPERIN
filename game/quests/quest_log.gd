class_name QuestLog
extends Node
## Diário de missões do jogador: missões ativas, em que etapa estão, o
## progresso da etapa e quais já foram entregues. Só guarda e avisa; quem dá
## recompensa e retira itens é o Player.

signal quest_started(quest: QuestData)
signal quest_progressed(quest: QuestData, progress: int)
signal quest_step_advanced(quest: QuestData, step_index: int)
signal quest_completed(quest: QuestData)

## id -> {"step": int, "kills": int}. Coleta é contada na bolsa na hora.
var _active: Dictionary = {}
var _quests: Dictionary = {}   # id -> QuestData
var _completed: Array[StringName] = []
## Bolsa usada para contar itens de etapas de coleta (definida pelo dono).
var inventory: Inventory


func start(quest: QuestData) -> void:
	if quest.steps.is_empty() or is_active(quest) or is_completed(quest):
		return
	_active[quest.id] = {"step": 0, "kills": 0}
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


func step_index(quest: QuestData) -> int:
	return int(_active[quest.id]["step"]) if is_active(quest) else -1


func current_step(quest: QuestData) -> QuestStep:
	return quest.steps[step_index(quest)] if is_active(quest) else null


func is_last_step(quest: QuestData) -> bool:
	return is_active(quest) and step_index(quest) == quest.steps.size() - 1


func progress_of(quest: QuestData) -> int:
	var step: QuestStep = current_step(quest)
	if step == null:
		return 0
	if step.objective == QuestStep.Objective.COLLECT:
		return mini(inventory.count_of(step.target_item) if inventory else 0, step.required_count)
	return int(_active[quest.id]["kills"])


## A etapa atual foi cumprida?
func is_step_done(quest: QuestData) -> bool:
	var step: QuestStep = current_step(quest)
	return step != null and progress_of(quest) >= step.required_count


## Última etapa cumprida: pronta para entregar.
func is_ready(quest: QuestData) -> bool:
	return is_last_step(quest) and is_step_done(quest)


## Um inimigo foi derrotado por este jogador.
func notify_kill(kind: StringName) -> void:
	for id: StringName in _active:
		var quest: QuestData = _quests[id]
		var step: QuestStep = current_step(quest)
		if step.objective != QuestStep.Objective.KILL:
			continue
		if step.target_kind != &"" and step.target_kind != kind:
			continue
		var entry: Dictionary = _active[id]
		if int(entry["kills"]) >= step.required_count:
			continue
		entry["kills"] = int(entry["kills"]) + 1
		quest_progressed.emit(quest, int(entry["kills"]))


## Avisa a interface quando a bolsa muda (etapas de coleta).
func refresh_collect() -> void:
	for id: StringName in _active:
		var quest: QuestData = _quests[id]
		if current_step(quest).objective == QuestStep.Objective.COLLECT:
			quest_progressed.emit(quest, progress_of(quest))


## Passa para a próxima etapa. Só se a atual foi cumprida e não é a última.
func advance(quest: QuestData) -> bool:
	if not is_step_done(quest) or is_last_step(quest):
		return false
	var entry: Dictionary = _active[quest.id]
	entry["step"] = int(entry["step"]) + 1
	entry["kills"] = 0
	quest_step_advanced.emit(quest, int(entry["step"]))
	return true


## Marca como entregue. Devolve false se a última etapa ainda não foi cumprida.
func complete(quest: QuestData) -> bool:
	if not is_ready(quest):
		return false
	_active.erase(quest.id)
	_completed.append(quest.id)
	quest_completed.emit(quest)
	return true
