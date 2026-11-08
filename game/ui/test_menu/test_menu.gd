class_name TestMenu
extends CanvasLayer
## Menu de TESTES (provisório, só para desenvolvimento): tecla P.
## Troca de classe, cria aliados de teste feridos (para testar curas), sobe
## de nível e enche vida/mana. Não faz parte do jogo final.

const CLASSES := "res://game/classes/data/"
const ALLY_COUNT: int = 3
const ALLY_WOUNDED_HEALTH: int = 40

var is_open: bool = false
var _area: GameArea
var _root: Control
var _box: VBoxContainer


## Liga o menu à área (onde ficam o jogador e as entidades).
func bind(area: GameArea) -> void:
	_area = area


func _ready() -> void:
	layer = 9
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var panel := ColorRect.new()
	panel.position = Vector2(200, 60)
	panel.size = Vector2(240, 220)
	panel.color = Color(0.05, 0.05, 0.09, 0.95)
	_root.add_child(panel)
	var title := Label.new()
	title.text = "MENU DE TESTES (P fecha)"
	title.position = Vector2(212, 66)
	title.add_theme_font_size_override("font_size", 10)
	_root.add_child(title)
	_box = VBoxContainer.new()
	_box.position = Vector2(212, 86)
	_box.custom_minimum_size = Vector2(216, 0)
	_box.add_theme_constant_override("separation", 4)
	_root.add_child(_box)
	for spec: Array in [
		["Jogar como Devoto (cura)", play_devotee],
		["Jogar como Guardião (tanque)", play_guardian],
		["Criar %d aliados de teste (feridos)" % ALLY_COUNT, spawn_allies],
		["Ferir os aliados de teste", wound_allies],
		["Subir 1 nível", level_up],
		["Encher vida e mana", refill],
	]:
		var b := Button.new()
		b.text = spec[0]
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 9)
		b.pressed.connect(spec[1])
		_box.add_child(b)
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _area == null:
		return
	if event.is_action_pressed("debug_menu") or (is_open and event.is_action_pressed("pause")):
		set_open(not is_open)
		get_viewport().set_input_as_handled()


func set_open(value: bool) -> void:
	is_open = value
	_root.visible = value
	_area.player.input_blocked = value


func play_devotee() -> void:
	_area.player.apply_class(load(CLASSES + "devotee.tres"))
	_area.player.message_requested.emit("Agora você é Devoto (cura).")


func play_guardian() -> void:
	_area.player.apply_class(load(CLASSES + "guardian.tres"))
	_area.player.message_requested.emit("Agora você é Guardião (tanque).")


## Aliados de teste à frente do jogador, com a vida baixa.
func spawn_allies() -> Array[AllyDummy]:
	var created: Array[AllyDummy] = _area.spawn_test_allies(ALLY_COUNT, ALLY_WOUNDED_HEALTH)
	_area.player.message_requested.emit("%d aliados de teste criados (vida %d/100)." % [created.size(), ALLY_WOUNDED_HEALTH])
	return created


func wound_allies() -> void:
	for node: Node in _area.get_tree().get_nodes_in_group(AllyDummy.GROUP):
		var ally := node as AllyDummy
		if ally:
			ally.health.current_health = ALLY_WOUNDED_HEALTH
			ally.health.shield_points = 0
			ally.health.health_changed.emit(ally.health.current_health, ally.health.max_health)


func level_up() -> void:
	var stats: CharacterStats = _area.player.stats
	stats.add_xp(stats.xp_to_next() - stats.xp)


func refill() -> void:
	_area.player.health.heal(_area.player.health.max_health)
	_area.player.mana.restore_full()
