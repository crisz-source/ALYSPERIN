class_name DisciplineSelectScreen
extends CanvasLayer
## Escolha de Disciplina ao começar (PROVISÓRIA: sem arte; Disciplinas provisórias).
## Mostra um cartão por opção; clicar escolhe. Só avisa por sinal.

signal chosen(discipline: DisciplineData)

const CARD_SIZE := Vector2(180, 170)
const CARD_GAP: float = 14.0

var is_open: bool = false
var _root: Control
var _cards: HBoxContainer
var _options: Array[DisciplineData] = []


func _ready() -> void:
	layer = 8
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.03, 0.06, 0.92)
	_root.add_child(overlay)
	var title := Label.new()
	title.text = "Escolha sua Disciplina"
	title.position = Vector2(0, 40)
	title.size = Vector2(640, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	_root.add_child(title)
	var note := Label.new()
	note.text = "(Disciplinas provisórias — serão substituídas pelas definitivas)"
	note.position = Vector2(0, 64)
	note.size = Vector2(640, 14)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 8)
	note.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_root.add_child(note)
	_cards = HBoxContainer.new()
	_cards.name = "Cards"
	_cards.add_theme_constant_override("separation", int(CARD_GAP))
	_root.add_child(_cards)
	_root.visible = false


func open(options: Array[DisciplineData]) -> void:
	_options = options
	for c: Node in _cards.get_children():
		c.queue_free()
	for d: DisciplineData in options:
		_cards.add_child(_make_card(d))
	var total: float = options.size() * CARD_SIZE.x + maxf(options.size() - 1, 0) * CARD_GAP
	_cards.position = Vector2((640.0 - total) / 2.0, 92)
	is_open = true
	_root.visible = true


func close() -> void:
	is_open = false
	_root.visible = false


## Escolhe pela posição (usado pelos cartões e pelos testes).
func choose(index: int) -> void:
	if not is_open or index < 0 or index >= _options.size():
		return
	var picked: DisciplineData = _options[index]
	close()
	chosen.emit(picked)


func _make_card(d: DisciplineData) -> Control:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(func() -> void: choose(_options.find(d)))
	var swatch := ColorRect.new()
	swatch.position = Vector2(8, 8)
	swatch.size = Vector2(12, 12)
	swatch.color = d.icon_color
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(swatch)
	var name_label := Label.new()
	name_label.text = d.display_name
	name_label.position = Vector2(26, 4)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)
	var body := Label.new()
	var ability_names: Array[String] = []
	for a: AbilityData in d.abilities:
		if a:
			ability_names.append("%s (nível %d)" % [a.display_name, a.unlock_level])
	body.text = d.description + "\n\nHabilidades:\n" + "\n".join(ability_names)
	body.position = Vector2(8, 28)
	body.size = Vector2(CARD_SIZE.x - 16, CARD_SIZE.y - 34)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 9)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(body)
	return card
