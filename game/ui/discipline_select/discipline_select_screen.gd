class_name DisciplineSelectScreen
extends CanvasLayer
## Criação do personagem (PROVISÓRIA: sem arte), em duas etapas:
## 1) escolher a classe; 2) escolher a disciplina dessa classe.
## Disciplina ainda não pronta aparece como "Em breve" e não pode ser escolhida.
## Só avisa por sinal; quem aplica é a área (GameArea -> Player.apply_class).

signal chosen(player_class: ClassData, discipline: DisciplineData)

const CARD_SIZE := Vector2(180, 170)
const CARD_GAP: float = 14.0
const DISABLED_TINT := Color(0.55, 0.55, 0.6)

var is_open: bool = false
## Classe escolhida na 1ª etapa (null = ainda escolhendo a classe).
var selected_class: ClassData = null
var _classes: Array[ClassData] = []
var _root: Control
var _title: Label
var _cards: HBoxContainer
var _back: Button


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
	_title = Label.new()
	_title.position = Vector2(0, 40)
	_title.size = Vector2(640, 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 18)
	_root.add_child(_title)
	_cards = HBoxContainer.new()
	_cards.name = "Cards"
	_cards.add_theme_constant_override("separation", int(CARD_GAP))
	_root.add_child(_cards)
	_back = Button.new()
	_back.name = "Back"
	_back.text = "Voltar"
	_back.position = Vector2(20, 320)
	_back.add_theme_font_size_override("font_size", 10)
	_back.pressed.connect(back)
	_root.add_child(_back)
	_root.visible = false


func open(classes: Array[ClassData]) -> void:
	_classes = classes
	selected_class = null
	is_open = true
	_root.visible = true
	_show_classes()


func close() -> void:
	is_open = false
	_root.visible = false


## 1ª etapa: escolhe a classe pela posição.
func choose_class(index: int) -> void:
	if not is_open or selected_class != null or index < 0 or index >= _classes.size():
		return
	selected_class = _classes[index]
	_show_disciplines()


## 2ª etapa: escolhe a disciplina pela posição (só as disponíveis).
func choose_discipline(index: int) -> void:
	if not is_open or selected_class == null or index < 0 or index >= selected_class.disciplines.size():
		return
	var picked: DisciplineData = selected_class.disciplines[index]
	if not picked.available:
		return
	var picked_class: ClassData = selected_class
	close()
	chosen.emit(picked_class, picked)


## Volta da escolha de disciplina para a escolha de classe.
func back() -> void:
	if selected_class != null:
		selected_class = null
		_show_classes()


func _clear_cards() -> void:
	for c: Node in _cards.get_children():
		_cards.remove_child(c)
		c.queue_free()


func _layout(count: int) -> void:
	var total: float = count * CARD_SIZE.x + maxf(count - 1, 0) * CARD_GAP
	_cards.position = Vector2((640.0 - total) / 2.0, 92)


func _show_classes() -> void:
	_title.text = "Escolha sua classe"
	_back.visible = false
	_clear_cards()
	for i in _classes.size():
		var c: ClassData = _classes[i]
		var index: int = i
		_cards.add_child(_make_card(c.display_name, c.role, c.description, c.icon_color, true,
			func() -> void: choose_class(index)))
	_layout(_classes.size())


func _show_disciplines() -> void:
	_title.text = "%s — escolha sua disciplina" % selected_class.display_name
	_back.visible = true
	_clear_cards()
	for i in selected_class.disciplines.size():
		var d: DisciplineData = selected_class.disciplines[i]
		var index: int = i
		var body: String = d.description
		if d.available:
			var names: Array[String] = []
			for a: AbilityData in d.abilities:
				if a and a.unlock_level <= 1:
					names.append(a.display_name)
			body += "\n\nPassivo: %s\nInício: %s" % [d.passive_name, ", ".join(names)]
		_cards.add_child(_make_card(d.display_name, "" if d.available else "Em breve", body, d.icon_color,
			d.available, func() -> void: choose_discipline(index)))
	_layout(selected_class.disciplines.size())


func _make_card(title: String, subtitle: String, body_text: String, color: Color, enabled: bool, on_press: Callable) -> Control:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.disabled = not enabled
	card.pressed.connect(on_press)
	card.modulate = Color.WHITE if enabled else DISABLED_TINT
	var swatch := ColorRect.new()
	swatch.position = Vector2(8, 8)
	swatch.size = Vector2(12, 12)
	swatch.color = color
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(swatch)
	var name_label := Label.new()
	name_label.text = title
	name_label.position = Vector2(26, 4)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)
	if not subtitle.is_empty():
		var sub := Label.new()
		sub.text = subtitle
		sub.position = Vector2(26, 20)
		sub.add_theme_font_size_override("font_size", 9)
		sub.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sub)
	var body := Label.new()
	# Ordem importa: quebra de linha, fonte e tamanho ANTES do texto. Atribuído
	# antes, o texto fixa a largura de uma linha só (fonte padrão) e invade o
	# cartão vizinho.
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 9)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.position = Vector2(8, 38)
	body.size = Vector2(CARD_SIZE.x - 16, CARD_SIZE.y - 44)
	body.text = body_text
	card.add_child(body)
	return card
