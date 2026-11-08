class_name DungeonData
extends Resource
## Uma masmorra: nome, requisitos de entrada, tetos do Dungeon Sync e força dos
## inimigos. Criar uma masmorra nova = um arquivo destes + o mapa.
## Números provisórios (design: documentation/design/classes-disciplinas-progressao-masmorras.md §4–5).

@export var id: StringName
@export var display_name: String = ""
@export_group("Requisitos de entrada")
@export var min_level: int = 20
@export var min_gear_score: int = 300
@export_group("Dungeon Sync (tetos)")
## Nível efetivo máximo dentro da masmorra.
@export var level_cap: int = 24
## GS efetivo máximo de cada item dentro da masmorra.
@export var gs_cap: int = 300
@export_group("Inimigos")
@export var enemy_health: int = 160
@export var enemy_damage: int = 30
@export var enemy_xp: int = 120


## Motivo para não poder entrar ("" = pode entrar). Recebe nível e GS reais
## (não o jogador: os dados não dependem de quem os usa).
func entry_refusal(level: int, gear_score: int) -> String:
	var missing: Array[String] = []
	if level < min_level:
		missing.append("nível %d (você: %d)" % [min_level, level])
	if gear_score < min_gear_score:
		missing.append("GS %d (você: %d)" % [min_gear_score, gear_score])
	if missing.is_empty():
		return ""
	return "%s exige %s." % [display_name, " e ".join(missing)]
