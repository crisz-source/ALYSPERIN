class_name ItemStack
extends Resource
## Um item que existe de fato: qual (ItemData), quantos e quanto de durabilidade.
##
## É um Resource para poder ser configurado no Inspetor (itens iniciais,
## conteúdo de baús). Ao entrar num inventário, é sempre copiado (duplicate),
## para dois baús nunca dividirem a mesma pilha.

@export var item: ItemData
@export_range(1, 99) var count: int = 1
## Durabilidade atual. -1 = ainda não definida (vira a máxima ao ser usada).
@export var durability: int = -1


static func create(p_item: ItemData, p_count: int = 1) -> ItemStack:
	var stack := ItemStack.new()
	stack.item = p_item
	stack.count = p_count
	stack.durability = p_item.max_durability() if p_item.has_durability() else -1
	return stack


## Cópia independente, com a durabilidade já definida.
func copy() -> ItemStack:
	var c: ItemStack = duplicate()
	if c.item and c.item.has_durability() and c.durability < 0:
		c.durability = c.item.max_durability()
	return c


func is_broken() -> bool:
	return item != null and item.has_durability() and durability == 0


## Fração da durabilidade restante (1.0 para itens sem durabilidade).
func durability_ratio() -> float:
	if item == null or not item.has_durability():
		return 1.0
	var current: int = item.max_durability() if durability < 0 else durability
	return float(current) / float(item.max_durability())


## Gasta durabilidade. Devolve true se o item quebrou AGORA (nesta chamada).
func wear(amount: int = 1) -> bool:
	if item == null or not item.has_durability() or durability == 0:
		return false
	if durability < 0:
		durability = item.max_durability()
	durability = maxi(durability - amount, 0)
	return durability == 0
