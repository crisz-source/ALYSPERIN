class_name AbilityData
extends Resource
## Definição de uma habilidade ativa (teclas 1–6): nome, recarga, nível para liberar.
##
## Cada tipo de habilidade estende esta classe com os próprios números
## (ex.: SpinSlashData). Quem executa é o Player; a habilidade só descreve.
## Na Fase 6, as Disciplinas vão decidir quais habilidades cada personagem tem.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
## Segundos até poder usar de novo.
@export var cooldown: float = 4.0
## Nível do personagem a partir do qual a habilidade pode ser usada.
@export var unlock_level: int = 1
## Mana gasta ao usar (0 = não usa mana).
@export var mana_cost: int = 0
## Cor do quadrado na barra de habilidades (provisório, até haver ícones).
@export var icon_color: Color = Color(0.8, 0.8, 0.8)


## true = esta habilidade já tem funcionamento no jogo. As que ainda não têm
## aparecem na barra, mas a tecla só avisa (sem gastar mana nem recarga).
## Tipos de habilidade com funcionamento sobrescrevem e devolvem true.
func is_implemented() -> bool:
	return false
