class_name ItemData
extends Resource
## Definição de um tipo de item (o "molde"): nome, descrição, quanto empilha.
##
## Cada item do jogo é um arquivo .tres com estes dados, editável no Inspetor.
## O item que o jogador carrega de fato é um ItemStack (molde + quantidade +
## durabilidade). Tipos específicos (arma, escudo, consumível) estendem esta classe.

enum Kind { MATERIAL, CONSUMABLE, WEAPON, SHIELD, KEY }

## Identificador único e estável (não muda se o nome mudar).
@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
## Ícone (opcional). Sem ícone, a interface mostra um quadrado desta cor (provisório).
@export var icon: Texture2D
@export var icon_color: Color = Color(0.6, 0.6, 0.6)
## Quantos cabem numa mesma vaga do inventário.
@export_range(1, 99) var max_stack: int = 1

@export_group("Modelo 3D")
## Modelo segurado na mão (arma/escudo). Vazio = sem modelo (boneco provisório).
## O modelo deve estar em pé, com a base em y = 0.
@export var model_scene: PackedScene
@export var model_scale: float = 1.0
## Posição da base do modelo em relação à mão (m).
@export var model_offset: Vector3 = Vector3.ZERO
## Giro do modelo em volta do eixo vertical (graus).
@export var model_yaw_degrees: float = 0.0


func kind() -> Kind:
	return Kind.MATERIAL


## Itens com durabilidade se desgastam com o uso (armas, escudos).
func max_durability() -> int:
	return 0


func has_durability() -> bool:
	return max_durability() > 0
