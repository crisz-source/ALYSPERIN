class_name InventoryScreen
extends CanvasLayer
## Tela do inventário (Tab) — PROVISÓRIA: quadrados coloridos no lugar de ícones.
##
## Mostra a bolsa, o equipamento (com durabilidade), detalhes do item sob o
## mouse e a progressão (nível, experiência, vida/mana/dano). Não decide regras: cada
## clique chama uma ação do Player, que valida e responde.
## Não pausa o jogo (no co-op não dá para pausar para os outros).
##
## Controles: clique esquerdo = usar/equipar (ou desequipar, no equipamento);
## clique direito na bolsa = descartar; Tab/Esc = fechar.

const SLOT_SIZE := Vector2(32, 32)
const PANEL_RECT := Rect2(70, 40, 500, 270)
const BG := Color(0.06, 0.05, 0.08, 0.94)
const SLOT_BG := Color(0.16, 0.15, 0.2)
const SLOT_HOVER := Color(0.26, 0.25, 0.32)
const BROKEN_TINT := Color(1.0, 0.45, 0.4)
const TEXT_DIM := Color(0.7, 0.7, 0.75)

var is_open: bool = false
var _player: Player
var _hovered: ItemStack = null

var _root: Control
var _bag_grid: GridContainer
var _weapon_slot: Control
var _shield_slot: Control
var _detail_name: Label
var _detail_text: Label
var _level_label: Label
var _xp_fill: ColorRect
var _health_label: Label
var _growth_label: Label


func _ready() -> void:
	layer = 5
	_build()
	_root.visible = false


func bind_player(player: Player) -> void:
	_player = player
	player.inventory.changed.connect(_refresh)
	player.equipment.changed.connect(_refresh)
	player.stats.xp_changed.connect(func(_a: int, _b: int) -> void: _refresh())
	player.stats.leveled_up.connect(func(_l: int) -> void: _refresh())
	player.health.health_changed.connect(func(_a: int, _b: int) -> void: _refresh())
	player.mana.mana_changed.connect(func(_a: int, _b: int) -> void: _refresh())


func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return
	if event.is_action_pressed("inventory") or (is_open and event.is_action_pressed("pause")):
		set_open(not is_open)
		get_viewport().set_input_as_handled()


func set_open(value: bool) -> void:
	if _player == null or (value and _player.health.is_dead):
		return
	is_open = value
	_root.visible = value
	_player.input_blocked = value
	_hovered = null
	if value:
		_refresh()


# --- Ações (também usadas pelos testes) ------------------------------------

func click_bag_slot(index: int, button: MouseButton) -> void:
	if button == MOUSE_BUTTON_LEFT:
		_player.use_inventory_slot(index)
	elif button == MOUSE_BUTTON_RIGHT:
		_player.discard_inventory_slot(index)


func click_weapon_slot() -> void:
	_player.unequip_weapon()


func click_shield_slot() -> void:
	_player.unequip_shield()


# --- Montagem --------------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var bg := ColorRect.new()
	bg.position = PANEL_RECT.position
	bg.size = PANEL_RECT.size
	bg.color = BG
	_root.add_child(bg)

	var x0: float = PANEL_RECT.position.x + 12
	var y0: float = PANEL_RECT.position.y + 10
	_label("INVENTÁRIO  (Tab fecha)", Vector2(x0, y0), Color.WHITE)
	_label("Bolsa", Vector2(x0, y0 + 18), TEXT_DIM)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 4
	_bag_grid.position = Vector2(x0, y0 + 32)
	_bag_grid.add_theme_constant_override("h_separation", 4)
	_bag_grid.add_theme_constant_override("v_separation", 4)
	_root.add_child(_bag_grid)

	_label("Equipado", Vector2(x0, y0 + 122), TEXT_DIM)
	_label("Arma", Vector2(x0, y0 + 136), TEXT_DIM)
	_weapon_slot = _make_slot()
	_weapon_slot.position = Vector2(x0 + 34, y0 + 132)
	_weapon_slot.gui_input.connect(_on_equip_slot_input.bind(true))
	_weapon_slot.mouse_entered.connect(func() -> void: _hover(_player.equipment.weapon))
	_root.add_child(_weapon_slot)
	_label("Escudo", Vector2(x0 + 76, y0 + 136), TEXT_DIM)
	_shield_slot = _make_slot()
	_shield_slot.position = Vector2(x0 + 116, y0 + 132)
	_shield_slot.gui_input.connect(_on_equip_slot_input.bind(false))
	_shield_slot.mouse_entered.connect(func() -> void: _hover(_player.equipment.shield))
	_root.add_child(_shield_slot)
	var hint := _label("Clique: usar / equipar / tirar   |   Botão direito: descartar", Vector2(x0, y0 + 176), TEXT_DIM)
	hint.add_theme_font_size_override("font_size", 8)

	# Coluna da direita: detalhes e progressão.
	var x1: float = PANEL_RECT.position.x + 270
	_detail_name = _label("", Vector2(x1, y0 + 18), Color.WHITE)
	_detail_text = _label("", Vector2(x1, y0 + 34), TEXT_DIM)
	_detail_text.size = Vector2(210, 70)
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_level_label = _label("", Vector2(x1, y0 + 122), Color.WHITE)
	var xp_bg := ColorRect.new()
	xp_bg.position = Vector2(x1, y0 + 140)
	xp_bg.size = Vector2(200, 3)
	xp_bg.color = Color(0.15, 0.15, 0.2)
	_root.add_child(xp_bg)
	_xp_fill = ColorRect.new()
	_xp_fill.size = Vector2(200, 3)
	_xp_fill.color = Color(0.95, 0.8, 0.3)
	xp_bg.add_child(_xp_fill)
	_health_label = _label("", Vector2(x1, y0 + 148), TEXT_DIM)
	_growth_label = _label("", Vector2(x1, y0 + 166), TEXT_DIM)


func _label(text: String, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


## Vaga: fundo, ícone (cor do item), quantidade e barra de durabilidade.
func _make_slot() -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.size = SLOT_SIZE
	var back := ColorRect.new()
	back.name = "Back"
	back.size = SLOT_SIZE
	back.color = SLOT_BG
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(back)
	var icon := ColorRect.new()
	icon.name = "Icon"
	icon.position = Vector2(7, 6)
	icon.size = Vector2(18, 18)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	var count := Label.new()
	count.name = "Count"
	count.position = Vector2(18, 16)
	count.add_theme_font_size_override("font_size", 8)
	count.add_theme_constant_override("outline_size", 2)
	count.add_theme_color_override("font_outline_color", Color.BLACK)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)
	var bar := ColorRect.new()
	bar.name = "Durability"
	bar.position = Vector2(3, 28)
	bar.size = Vector2(26, 2)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(bar)
	slot.mouse_exited.connect(func() -> void:
		(slot.get_node("Back") as ColorRect).color = SLOT_BG
		_hover(null))
	slot.mouse_entered.connect(func() -> void: (slot.get_node("Back") as ColorRect).color = SLOT_HOVER)
	return slot


# --- Atualização -----------------------------------------------------------

func _refresh() -> void:
	if _player == null or not is_open:
		return
	var inv: Inventory = _player.inventory
	while _bag_grid.get_child_count() < inv.slots.size():
		var index: int = _bag_grid.get_child_count()
		var slot := _make_slot()
		slot.gui_input.connect(_on_bag_slot_input.bind(index))
		slot.mouse_entered.connect(func() -> void: _hover(_player.inventory.get_slot(index)))
		_bag_grid.add_child(slot)
	for i in inv.slots.size():
		_paint_slot(_bag_grid.get_child(i), inv.get_slot(i))
	_paint_slot(_weapon_slot, _player.equipment.weapon)
	_paint_slot(_shield_slot, _player.equipment.shield)

	var st: CharacterStats = _player.stats
	if st.is_max_level():
		_level_label.text = "Nível %d   —   nível máximo" % st.level
		_xp_fill.size.x = 200.0
	else:
		_level_label.text = "Nível %d   —   %d / %d exp." % [st.level, st.xp, st.xp_to_next()]
		_xp_fill.size.x = 200.0 * float(st.xp) / float(st.xp_to_next())
	_health_label.text = "Vida: %d / %d     Mana: %d / %d" % [_player.health.current_health, _player.health.max_health,
		_player.mana.current(), _player.mana.max_mana]
	_growth_label.text = "Dano do nível: +%d%%" % roundi((st.damage_multiplier() - 1.0) * 100.0)
	_show_details(_hovered)


func _paint_slot(slot: Control, stack: ItemStack) -> void:
	var icon: ColorRect = slot.get_node("Icon")
	var count: Label = slot.get_node("Count")
	var bar: ColorRect = slot.get_node("Durability")
	icon.visible = stack != null
	count.text = ""
	bar.visible = false
	if stack == null:
		return
	icon.color = stack.item.icon_color * (BROKEN_TINT if stack.is_broken() else Color.WHITE)
	if stack.count > 1:
		count.text = str(stack.count)
	if stack.item.has_durability():
		var ratio: float = stack.durability_ratio()
		bar.visible = true
		bar.size.x = maxf(26.0 * ratio, 1.0)
		bar.color = Color(0.9, 0.25, 0.2) if ratio <= 0.25 else Color(0.4, 0.85, 0.4)


func _hover(stack: ItemStack) -> void:
	_hovered = stack
	_show_details(stack)


func _show_details(stack: ItemStack) -> void:
	if stack == null or stack.item == null:
		_detail_name.text = "Passe o mouse sobre um item"
		_detail_text.text = ""
		return
	_detail_name.text = stack.item.display_name
	var lines: Array[String] = [stack.item.description]
	if stack.item is WeaponData:
		var w := stack.item as WeaponData
		lines.append("Dano %d   Velocidade %s" % [w.damage, "lenta" if w.timing_scale > 1.1 else ("rápida" if w.timing_scale < 0.9 else "normal")])
	elif stack.item is ShieldData:
		lines.append("Proteção %d°" % roundi((stack.item as ShieldData).block_half_angle * 2.0))
	elif stack.item is ConsumableData:
		var c := stack.item as ConsumableData
		if c.heal_amount > 0:
			lines.append("Cura %d de vida" % c.heal_amount)
		if c.mana_amount > 0:
			lines.append("Recupera %d de mana" % c.mana_amount)
	if stack.item.has_durability():
		var current: int = stack.durability if stack.durability >= 0 else stack.item.max_durability()
		lines.append("Durabilidade %d / %d%s" % [current, stack.item.max_durability(), "  (QUEBRADO)" if stack.is_broken() else ""])
	_detail_text.text = "\n".join(lines)


func _on_bag_slot_input(event: InputEvent, index: int) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		click_bag_slot(index, mb.button_index)
		_hover(_player.inventory.get_slot(index))


func _on_equip_slot_input(event: InputEvent, is_weapon: bool) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if is_weapon:
			click_weapon_slot()
		else:
			click_shield_slot()
