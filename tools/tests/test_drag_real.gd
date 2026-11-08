extends Node
## Arraste REAL com o mouse: vaga do inventário -> espaço 4 da barra.
const AREA := "res://game/world/areas/prototype_area/prototype_area.tscn"
func _ready() -> void:
	_run.call_deferred()
var _last: Vector2 = Vector2.ZERO


func _mouse(pos: Vector2, pressed: Variant) -> void:
	var ev: InputEvent
	if pressed == null:
		var m := InputEventMouseMotion.new()
		m.position = pos
		m.global_position = pos
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		# Um mouse real informa o deslocamento; a Godot soma isso para decidir
		# quando começa um arraste.
		m.relative = pos - _last
		ev = m
	else:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = pressed
		b.position = pos
		b.global_position = pos
		ev = b
	_last = pos
	get_viewport().push_input(ev)
	await get_tree().process_frame


func _run() -> void:
	var area: Node = load(AREA).instantiate()
	get_tree().root.add_child(area)
	get_tree().current_scene = area
	await get_tree().process_frame
	var select: ClassSelectScreen = area.get_node("ClassSelectScreen")
	select.choose_class(0)
	var player: Player = area.get_node("Entities/Player")
	var screen: InventoryScreen = area.get_node("InventoryScreen")
	screen.set_open(true)
	await get_tree().process_frame
	var from: Vector2 = (screen._bag_grid.get_child(0) as Control).get_global_rect().get_center()
	var to: Vector2 = (area.get_node("Hud/AbilityBar/Ability7") as Control).get_global_rect().get_center()
	var herb_before: int = player.inventory.count_of(load("res://game/items/data/healing_herb.tres"))
	await _mouse(from, true)
	for i in 8:
		await _mouse(from.lerp(to, (i + 1) / 8.0), null)
		if i == 0 or i == 7:
			print("  passo %d: arrastando=%s dados=%s" % [i, get_viewport().gui_is_dragging(), get_viewport().gui_get_drag_data()])
	var hovered: Control = get_viewport().gui_get_hovered_control()
	print("  debaixo do mouse no ponto de soltar: ", hovered.get_path() if hovered else "nada")
	print("  from=%s to=%s  slot0 rect=%s" % [from, to, (screen._bag_grid.get_child(0) as Control).get_global_rect()])
	await _mouse(to, false)
	await get_tree().process_frame
	var ok_assign: bool = player.hotbar_items[6] != null and player.hotbar_items[6].id == &"healing_herb"
	var ok_not_used: bool = player.inventory.count_of(load("res://game/items/data/healing_herb.tres")) == herb_before
	print(("PASS " if ok_assign else "FAIL ") + "arrastar com o mouse coloca a erva no espaço 7")
	print(("PASS " if ok_not_used else "FAIL ") + "arrastar NÃO usa a erva (clique só ao soltar sem arrastar)")
	print("RESULTADO: %d passaram, %d falharam" % [int(ok_assign) + int(ok_not_used), 2 - int(ok_assign) - int(ok_not_used)])
	get_tree().quit()
