class_name ClassData
extends Resource
## Classe do personagem (ex.: Guardião = tanque, Devoto = cura): função no grupo,
## armas permitidas, equipamento inicial, traço passivo e habilidades.
##
## Decisão do proprietário: cada personagem escolhe UMA classe (sem disciplinas).
## Todas as classes têm a mesma base de vida/mana/dano; a diferença vem das
## habilidades, liberadas pelo nível (1, 1, 10, 20, 35, 50).

@export var id: StringName
@export var display_name: String = ""
## Função no grupo, mostrada na tela de criação (ex.: "Tanque", "Cura").
@export var role: String = ""
@export_multiline var description: String = ""
@export var icon_color: Color = Color(0.7, 0.7, 0.7)
## Modelo 3D do personagem (cena importada, olhando para -Z, pés em y = 0).
## Vazio = boneco provisório (cápsula).
@export var model_scene: PackedScene

@export_group("Equipamento")
## Tipos de arma que a classe pode usar (WeaponData.weapon_type).
@export var allowed_weapon_types: Array[StringName] = []
## Usa escudo na mão secundária (defesa com o botão direito).
@export var uses_shield: bool = false
@export var starting_weapon: ItemStack
@export var starting_shield: ItemStack

@export_group("Passivo")
## Identificador que o Player reconhece (ex.: &"muralha", &"graca").
@export var passive_id: StringName
@export var passive_name: String = ""
@export_multiline var passive_description: String = ""

@export_group("Habilidades")
## Habilidades da barra (posição na lista = tecla: 0 = tecla 1).
@export var abilities: Array[AbilityData] = []
## Habilidade do botão direito do mouse, para classes sem escudo (quem tem
## escudo usa o botão direito para defender). Ex.: Oração de cura do Devoto.
@export var secondary_ability: AbilityData


func allows_weapon(weapon: WeaponData) -> bool:
	return allowed_weapon_types.has(weapon.weapon_type)
