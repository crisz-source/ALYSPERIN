class_name DeathScreen
extends CanvasLayer
## Tela de morte (PROVISÓRIA: sem arte): "Você morreu!" e "Deseja continuar?"
## com Sim / Não. Só avisa a escolha por sinal; quem decide o que acontece é a área.

signal continue_requested
signal decline_requested

const OVERLAY := Color(0.05, 0.0, 0.02, 0.75)

var is_open: bool = false

var _root: Control
var _yes: Button
var _no: Button
var _note: Label


func _ready() -> void:
	layer = 10
	_build()
	_root.visible = false


func open() -> void:
	is_open = true
	_note.text = ""
	_root.visible = true
	# Foco no "Sim": Enter também confirma.
	_yes.grab_focus()


func close() -> void:
	is_open = false
	_root.visible = false


func show_note(text: String) -> void:
	_note.text = text


func choose_yes() -> void:
	continue_requested.emit()


func choose_no() -> void:
	decline_requested.emit()


func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = OVERLAY
	_root.add_child(overlay)
	var title := _centered_label("Você morreu!", 120, 24, Color(0.9, 0.2, 0.2))
	title.name = "Title"
	var question := _centered_label("Deseja continuar?", 168, 12, Color.WHITE)
	question.name = "Question"
	_yes = _button("Sim", Vector2(250, 200))
	_yes.name = "Yes"
	_yes.pressed.connect(choose_yes)
	_no = _button("Não", Vector2(340, 200))
	_no.name = "No"
	_no.pressed.connect(choose_no)
	_note = _centered_label("", 240, 10, Color(0.75, 0.75, 0.8))
	_note.name = "Note"


func _centered_label(text: String, y: float, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, y)
	l.size = Vector2(640, font_size + 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	_root.add_child(l)
	return l


func _button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = Vector2(50, 20)
	b.add_theme_font_size_override("font_size", 12)
	_root.add_child(b)
	return b
