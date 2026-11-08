class_name ClassSelectScreen
extends CanvasLayer
## Criação do personagem (PROVISÓRIA: sem arte): escolher a classe.
## Só avisa por sinal; quem aplica é a área (GameArea -> Player.apply_class).

signal chosen(player_class: ClassData)

const CARD_SIZE := Vector2(180, 170)
const CARD_GAP: float = 14.0

var is_open: bool = false
var _classes: Array[ClassData] = []
var _root: Control
var _cards: HBoxContainer


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
	title.text = "Escolha sua classe"
	title.position = Vector2(0, 40)
	title.size = Vector2(640, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	_root.add_child(title)
	_cards = HBoxContainer.new()
	_cards.name = "Cards"
	_cards.add_theme_constant_override("separation", int(CARD_GAP))
	_root.add_child(_cards)
	_root.visible = false


func open(classes: Array[ClassData]) -> void:
	_classes = classes
	is_open = true
	_root.visible = true
	for c: Node in _cards.get_children():
		_cards.remove_child(c)
		c.queue_free()
	for i in classes.size():
		var index: int = i
		_cards.add_child(_make_card(classes[i], func() -> void: choose_class(index)))
	var total: float = classes.size() * CARD_SIZE.x + maxf(classes.size() - 1, 0) * CARD_GAP
	_cards.position = Vector2((640.0 - total) / 2.0, 92)


func close() -> void:
	is_open = false
	_root.visible = false


## Escolhe a classe pela posição (cartões e testes).
func choose_class(index: int) -> void:
	if not is_open or index < 0 or index >= _classes.size():
		return
	var picked: ClassData = _classes[index]
	close()
	chosen.emit(picked)


func _make_card(c: ClassData, on_press: Callable) -> Control:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(on_press)
	var swatch := ColorRect.new()
	swatch.position = Vector2(8, 8)
	swatch.size = Vector2(12, 12)
	swatch.color = c.icon_color
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(swatch)
	var name_label := Label.new()
	name_label.text = c.display_name
	name_label.position = Vector2(26, 4)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)
	var role := Label.new()
	role.text = c.role
	role.position = Vector2(26, 20)
	role.add_theme_font_size_override("font_size", 9)
	role.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(role)
	var names: Array[String] = []
	for a: AbilityData in c.abilities:
		if a and a.unlock_level <= 1:
			names.append(a.display_name)
	if c.secondary_ability:
		names.append("%s (botão direito)" % c.secondary_ability.display_name)
	var body := Label.new()
	# Ordem importa: quebra de linha, fonte e tamanho ANTES do texto (senão a
	# largura fica a de uma linha só e invade o cartão vizinho).
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 9)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.position = Vector2(8, 38)
	body.size = Vector2(CARD_SIZE.x - 16, CARD_SIZE.y - 44)
	body.text = "%s\n\nPassivo: %s\nInício: %s" % [c.description, c.passive_name, ", ".join(names)]
	card.add_child(body)
	return card
