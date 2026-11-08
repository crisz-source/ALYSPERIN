class_name DisciplineData
extends Resource
## Disciplina: a especialização dentro de uma classe (ex.: Bastião no Guardião).
##
## Regra do proprietário: disciplinas NÃO dão bônus de vida/mana/dano — a base é
## igual para todos. A identidade vem do traço passivo e das 6 habilidades,
## liberadas pelo nível (1, 1, 10, 20, 35, 50). Ver
## documentation/design/classes-disciplinas-progressao-masmorras.md.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon_color: Color = Color(0.7, 0.7, 0.7)
## false = aparece na tela de criação como "Em breve" e não pode ser escolhida.
@export var available: bool = true

@export_group("Passivo")
## Identificador que o Player reconhece (ex.: &"muralha", &"graca").
@export var passive_id: StringName
@export var passive_name: String = ""
@export_multiline var passive_description: String = ""

@export_group("Habilidades")
## Habilidades da barra (posição na lista = tecla: 0 = tecla 1).
@export var abilities: Array[AbilityData] = []
## Habilidade do botão direito do mouse, para classes sem escudo (quem tem
## escudo usa o botão direito para defender). Ex.: Oração de cura do Sacerdote.
@export var secondary_ability: AbilityData
