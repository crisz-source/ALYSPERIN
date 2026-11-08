class_name ClassData
extends Resource
## Classe do personagem (ex.: Guardião, Devoto): identidade de combate, armas
## permitidas, equipamento inicial e as 3 disciplinas que pode seguir.
##
## Regra do proprietário: cada personagem escolhe 1 classe e 1 disciplina e não
## mistura. Todas as classes têm a mesma base de vida/mana/dano; a diferença vem
## das habilidades.

@export var id: StringName
@export var display_name: String = ""
## Função no grupo, mostrada na tela de criação (ex.: "Tanque", "Cura").
@export var role: String = ""
@export_multiline var description: String = ""
@export var icon_color: Color = Color(0.7, 0.7, 0.7)
## Tipos de arma que a classe pode usar (WeaponData.weapon_type).
@export var allowed_weapon_types: Array[StringName] = []
## Usa escudo na mão secundária (defesa com o botão direito).
@export var uses_shield: bool = false
@export var starting_weapon: ItemStack
@export var starting_shield: ItemStack
@export var disciplines: Array[DisciplineData] = []


func allows_weapon(weapon: WeaponData) -> bool:
	return allowed_weapon_types.has(weapon.weapon_type)
