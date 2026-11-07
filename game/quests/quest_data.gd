class_name QuestData
extends Resource
## Missão: uma ou mais etapas, a recompensa (só ao entregar tudo) e as falas.
## PROVISÓRIO quanto ao conteúdo (textos e números); a estrutura é a base.
##
## Marcadores no NPC: "!" missão nova; nada enquanto a etapa está em andamento;
## "?" etapa cumprida e há continuação; "*" última etapa cumprida, pronta para entregar.

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""
@export var steps: Array[QuestStep] = []

@export_group("Recompensa")
@export var reward_xp: int = 0
@export var reward_items: Array[ItemStack] = []

@export_group("Falas")
## Ao oferecer a missão (aceita ao fim da conversa).
@export var offer_lines: Array[String] = []
## Ao entregar a missão completa.
@export var complete_lines: Array[String] = []
