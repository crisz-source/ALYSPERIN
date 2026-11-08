class_name Npc
extends StaticBody3D
## Personagem não jogável (PROVISÓRIO: cápsula sem arte, sem nome definitivo). 3D.
## Conversa com o jogador (E) e pode oferecer uma missão.
##
## Fluxo com missão: oferece ("!") -> sem marcador enquanto a etapa está em
## andamento -> "?" etapa cumprida e há continuação (falar dá a próxima etapa)
## -> "*" última etapa cumprida (falar entrega e dá a recompensa) -> falas comuns.

@export var npc_name: String = "Viajante"
@export var idle_lines: Array[String] = []
@export var quest: QuestData

## Último jogador que conversou (para o marcador "!"/"?"). No co-op cada
## jogador verá o próprio marcador; por ora vale o último.
var _last_player: Player = null

@onready var _interactable: Interactable = $Interactable
@onready var _marker: Label3D = $QuestMarker


func _ready() -> void:
	_interactable.prompt_text = "Falar"
	_interactable.handler = _on_interact


func _process(_delta: float) -> void:
	# "!" nova; "" em andamento; "?" etapa cumprida com continuação; "*" pronta para entregar.
	_marker.text = _marker_text(_last_player if is_instance_valid(_last_player) else null)


func _on_interact(by: Player) -> String:
	_last_player = by
	var quests: QuestLog = by.quest_log
	if quest and not quests.is_active(quest) and not quests.is_completed(quest):
		by.request_dialogue(npc_name, quest.offer_lines, func() -> void: quests.start(quest))
	elif quest and quests.is_ready(quest):
		by.request_dialogue(npc_name, quest.complete_lines, func() -> void: by.turn_in_quest(quest))
	elif quest and quests.is_step_done(quest):
		by.request_dialogue(npc_name, quests.current_step(quest).advance_lines, func() -> void: by.advance_quest(quest))
	elif quest and quests.is_active(quest):
		by.request_dialogue(npc_name, quests.current_step(quest).in_progress_lines)
	else:
		by.request_dialogue(npc_name, idle_lines)
	return ""


func _marker_text(player: Player) -> String:
	if quest == null:
		return ""
	if player == null:
		return "!"
	if player.quest_log.is_completed(quest):
		return ""
	if player.quest_log.is_ready(quest):
		return "*"
	if player.quest_log.is_step_done(quest):
		return "?"
	return "" if player.quest_log.is_active(quest) else "!"
