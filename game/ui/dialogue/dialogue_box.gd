class_name DialogueBox
extends CanvasLayer
## Caixa de diálogo (PROVISÓRIA: sem arte). Mostra uma fala por vez; E (ou
## Enter) avança. Ao terminar, chama a função recebida em start().

signal finished

var is_open: bool = false
var _lines: Array[String] = []
var _index: int = 0
var _on_finished: Callable
## O E que abriu o diálogo ainda está segurado: espera soltar antes de aceitar
## o próximo (senão a primeira fala seria pulada). Olha a tecla, não a contagem
## de quadros, que varia com o ritmo do jogo.
var _waiting_release: bool = false

var _root: Control
var _speaker: Label
var _text: Label


func _ready() -> void:
	layer = 6
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var box := ColorRect.new()
	box.position = Vector2(80, 268)
	box.size = Vector2(480, 76)
	box.color = Color(0.05, 0.05, 0.09, 0.94)
	_root.add_child(box)
	_speaker = Label.new()
	_speaker.name = "Speaker"
	_speaker.position = Vector2(92, 272)
	_speaker.add_theme_font_size_override("font_size", 10)
	_speaker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_root.add_child(_speaker)
	_text = Label.new()
	_text.name = "Text"
	_text.position = Vector2(92, 288)
	_text.size = Vector2(456, 40)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 10)
	_root.add_child(_text)
	var hint := Label.new()
	hint.text = "[E] continuar"
	hint.position = Vector2(484, 330)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_root.add_child(hint)
	_root.visible = false


func start(speaker: String, lines: Array[String], on_finished: Callable = Callable()) -> void:
	_lines = lines
	_index = 0
	_on_finished = on_finished
	_speaker.text = speaker
	is_open = true
	_root.visible = true
	_waiting_release = Input.is_action_pressed("interact") or Input.is_action_pressed("ui_accept")
	if _lines.is_empty():
		_finish()
		return
	_text.text = _lines[0]


func current_text() -> String:
	return _text.text


## Próxima fala, ou fecha se era a última.
func advance() -> void:
	if not is_open:
		return
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		_text.text = _lines[_index]


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_released("interact") or event.is_action_released("ui_accept"):
		_waiting_release = false
		return
	if _waiting_release:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()


func _finish() -> void:
	is_open = false
	_root.visible = false
	finished.emit()
	if _on_finished.is_valid():
		_on_finished.call()
