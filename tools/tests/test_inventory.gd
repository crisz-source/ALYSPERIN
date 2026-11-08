extends Node
## Testes unitários da Fase 5 (bloco 1): ItemStack, Inventory, Equipment, CharacterStats.

const SWORD := "res://game/items/data/short_sword.tres"
const AXE := "res://game/items/data/heavy_axe.tres"
const SHIELD := "res://game/items/data/wooden_shield.tres"
const HERB := "res://game/items/data/healing_herb.tres"

var _failures: int = 0
var _passes: int = 0


func _ready() -> void:
	_run.call_deferred()


func check(label: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + label + ("" if detail.is_empty() else " | " + detail))
	if ok:
		_passes += 1
	else:
		_failures += 1


func _run() -> void:
	var sword: WeaponData = load(SWORD)
	var axe: WeaponData = load(AXE)
	var shield: ShieldData = load(SHIELD)
	var herb: ConsumableData = load(HERB)

	print("--- ItemStack ---")
	var s := ItemStack.create(sword)
	check("cria com durabilidade cheia", s.durability == 80 and is_equal_approx(s.durability_ratio(), 1.0), str(s.durability))
	check("erva sem durabilidade", ItemStack.create(herb).durability == -1 and not herb.has_durability())
	var broke_now: bool = s.wear(79)
	check("gastar sem quebrar", not broke_now and s.durability == 1 and not s.is_broken())
	check("quebra exatamente ao chegar a 0", s.wear(5) and s.durability == 0 and s.is_broken())
	check("quebrada não 'quebra de novo'", not s.wear(1) and s.durability == 0)
	var c := ItemStack.create(sword)
	var c2 := c.copy()
	c2.wear(10)
	check("cópia é independente", c.durability == 80 and c2.durability == 70)
	var configured := ItemStack.new()
	configured.item = axe
	check("pilha do Inspetor (-1) vira máxima ao copiar", configured.copy().durability == 45)

	print("--- Inventory ---")
	var inv := Inventory.new()
	inv.slot_count = 4
	var start := ItemStack.create(herb, 2)
	inv.starting_items = [start]
	add_child(inv)
	var changes := [0]
	inv.changed.connect(func() -> void: changes[0] += 1)
	check("começa com itens iniciais", inv.count_of(herb) == 2 and inv.get_slot(0).item == herb)
	check("itens iniciais copiados (não a mesma pilha)", inv.get_slot(0) != start)
	check("empilha na mesma vaga", inv.add(ItemStack.create(herb, 2)) == 0 and inv.get_slot(0).count == 4 and inv.get_slot(1) == null)
	check("passa do limite (5): resto vai para outra vaga", inv.add(ItemStack.create(herb, 3)) == 0 and inv.get_slot(0).count == 5 and inv.get_slot(1).count == 2)
	check("armas não empilham", inv.add(ItemStack.create(sword)) == 0 and inv.add(ItemStack.create(axe)) == 0 and inv.get_slot(2).item == sword and inv.get_slot(3).item == axe)
	check("cheio", inv.is_full())
	check("cheio: arma não cabe (devolve 1)", inv.add(ItemStack.create(shield)) == 1)
	check("cheio: erva completa a pilha incompleta", inv.space_for(herb) == 3 and inv.add(ItemStack.create(herb, 5)) == 2 and inv.get_slot(1).count == 5)
	check("sinal changed emitido", changes[0] >= 4, str(changes[0]))
	var taken: ItemStack = inv.remove(1, 2)
	check("remover parte da pilha", taken.count == 2 and inv.get_slot(1).count == 3)
	taken = inv.remove(3)
	check("remover item único esvazia a vaga", taken.item == axe and inv.get_slot(3) == null and not inv.is_full())
	check("remover vaga vazia devolve null", inv.remove(3) == null)
	check("índice inválido é seguro", inv.get_slot(99) == null and inv.get_slot(-1) == null)
	inv.expand(2)
	check("expandir vagas", inv.slots.size() == 6 and inv.slot_count == 6)
	var worn := ItemStack.create(sword)
	worn.wear(30)
	inv.add(worn)
	var found: ItemStack = null
	for st: ItemStack in inv.slots:
		if st and st.item == sword and st.durability == 50:
			found = st
	check("durabilidade preservada ao guardar", found != null)

	print("--- Equipment ---")
	var eq := Equipment.new()
	eq.starting_weapon = ItemStack.create(sword)
	add_child(eq)
	check("começa com arma inicial", eq.weapon_data() == sword and eq.shield == null)
	var prev: ItemStack = eq.equip(ItemStack.create(axe))
	check("equipar arma devolve a anterior", prev.item == sword and eq.weapon_data() == axe)
	prev = eq.equip(ItemStack.create(shield))
	check("escudo vai para a vaga de escudo", prev == null and eq.shield_data() == shield and eq.weapon_data() == axe)
	var herb_stack := ItemStack.create(herb)
	check("erva não equipa (devolve ela mesma)", eq.equip(herb_stack) == herb_stack)
	check("desequipar escudo", eq.unequip_shield().item == shield and eq.shield == null)

	print("--- CharacterStats ---")
	var st := CharacterStats.new()
	add_child(st)
	var levels: Array[int] = []
	st.leveled_up.connect(func(l: int) -> void: levels.append(l))
	check("nível 1, precisa de 30", st.level == 1 and st.xp_to_next() == 30)
	st.add_xp(20)
	check("20 xp: ainda nível 1", st.level == 1 and st.xp == 20)
	st.add_xp(15)
	check("35 xp: nível 2, sobra 5", st.level == 2 and st.xp == 5 and levels == [2], "lvl=%d xp=%d" % [st.level, st.xp])
	st.add_xp(200)
	check("vários níveis de uma vez", st.level == 4 and levels == [2, 3, 4], "lvl=%d xp=%d níveis=%s" % [st.level, st.xp, levels])
	check("xp negativo/zero ignorado", (func() -> bool: var x: int = st.xp; st.add_xp(-5); st.add_xp(0); return st.xp == x).call())
	check("crescimento automático no nível 4: +24 vida, +6 mana, +30% dano",
		st.bonus_max_health() == 24 and st.bonus_max_mana() == 6 and is_equal_approx(st.damage_multiplier(), 1.3))
	check("sem sistema de pontos", not ("unspent_points" in st) and not st.has_method("spend_point"))
	st.add_xp(999999)
	check("nível máximo 60", st.level == 60 and st.is_max_level() and st.xp == 0, "lvl=%d" % st.level)
	st.add_xp(500)
	check("no 60 não ganha mais experiência", st.level == 60 and st.xp == 0)
	check("nível 60: +472 vida, +118 mana, dano x6,9", st.bonus_max_health() == 472 and st.bonus_max_mana() == 118 and is_equal_approx(st.damage_multiplier(), 6.9))

	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
