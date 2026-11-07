class_name Inventory
extends Node
## Bolsa com número FIXO de vagas (inventário limitado: escolher o que carregar
## faz parte do jogo). Cada vaga guarda um ItemStack ou fica vazia (null).
##
## Só guarda e avisa: quem decide usar/equipar é o dono (Player). No co-op, o
## host será a autoridade sobre o conteúdo.

signal changed

## Vagas iniciais. Pode crescer durante o jogo com expand().
@export_range(1, 32) var slot_count: int = 8
## Itens com que o dono começa (copiados ao iniciar).
@export var starting_items: Array[ItemStack] = []

var slots: Array[ItemStack] = []


func _ready() -> void:
	slots.resize(slot_count)
	for stack: ItemStack in starting_items:
		if stack and stack.item:
			add(stack.copy())


func get_slot(index: int) -> ItemStack:
	return slots[index] if index >= 0 and index < slots.size() else null


func is_full() -> bool:
	return slots.find(null) == -1


## Põe a pilha na bolsa: primeiro completa pilhas do mesmo item, depois usa
## vagas vazias. Devolve quantos NÃO couberam (0 = coube tudo). A pilha recebida
## não é guardada como está: o inventário guarda cópias.
func add(stack: ItemStack) -> int:
	if stack == null or stack.item == null or stack.count <= 0:
		return 0
	var remaining: int = stack.count
	if stack.item.max_stack > 1:
		for existing: ItemStack in slots:
			if remaining == 0:
				break
			if existing and existing.item == stack.item and existing.count < stack.item.max_stack:
				var moved: int = mini(remaining, stack.item.max_stack - existing.count)
				existing.count += moved
				remaining -= moved
	while remaining > 0:
		var empty: int = slots.find(null)
		if empty == -1:
			break
		var piece: ItemStack = stack.copy()
		piece.count = mini(remaining, stack.item.max_stack)
		slots[empty] = piece
		remaining -= piece.count
	if remaining != stack.count:
		changed.emit()
	return remaining


## Quanto de um item ainda caberia (para avisar "inventário cheio" antes de pegar).
func space_for(item: ItemData) -> int:
	var space := 0
	for existing: ItemStack in slots:
		if existing == null:
			space += item.max_stack
		elif existing.item == item:
			space += item.max_stack - existing.count
	return space


## Tira `amount` itens da vaga. Devolve o que saiu (ou null se a vaga está vazia).
func remove(index: int, amount: int = 1) -> ItemStack:
	var stack: ItemStack = get_slot(index)
	if stack == null or amount <= 0:
		return null
	var taken: ItemStack = stack.copy()
	taken.count = mini(amount, stack.count)
	stack.count -= taken.count
	if stack.count <= 0:
		slots[index] = null
	changed.emit()
	return taken


## Troca o conteúdo de uma vaga (usado ao equipar: a arma antiga volta para cá).
func set_slot(index: int, stack: ItemStack) -> void:
	slots[index] = stack
	changed.emit()


func count_of(item: ItemData) -> int:
	var total := 0
	for existing: ItemStack in slots:
		if existing and existing.item == item:
			total += existing.count
	return total


## Mais vagas (ex.: bolsa maior encontrada no mundo).
func expand(extra: int) -> void:
	if extra <= 0:
		return
	slot_count += extra
	slots.resize(slot_count)
	changed.emit()
