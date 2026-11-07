class_name Hud
extends CanvasLayer
## HUD provisório: barra de vida do jogador, texto de ajuda, caixa de mensagem
## (placas, portas...) e aviso de morte.
##
## Só escuta sinais do jogador; não decide nada do jogo. Quem reinicia a cena
## depois da morte é a própria área/arena.

## Texto de controles mostrado no rodapé (provisório, some quando houver tutorial).
@export_multiline var help_text: String = ""
## Tempo mínimo e máximo que uma mensagem fica na tela (s); textos longos ficam mais.
@export var message_min_time: float = 2.5
@export var message_max_time: float = 7.0

var _message_time_left: float = 0.0

@onready var _health_fill: ColorRect = $PlayerHealth/Fill
@onready var _status_label: Label = $StatusLabel
@onready var _help_label: Label = $HelpPlaceholder
@onready var _message_box: Control = $MessageBox
@onready var _message_label: Label = $MessageBox/Text


func _ready() -> void:
	_status_label.visible = false
	_help_label.text = help_text
	_message_box.visible = false


func bind_player(player: Player) -> void:
	player.health.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.message_requested.connect(show_message)


## Mostra um texto na caixa de baixo. Uma mensagem nova substitui a anterior.
func show_message(text: String) -> void:
	_message_label.text = text
	_message_box.visible = true
	_message_time_left = clampf(1.5 + text.length() * 0.05, message_min_time, message_max_time)


func is_showing_message() -> bool:
	return _message_box.visible


func _process(delta: float) -> void:
	if _message_time_left <= 0.0:
		return
	_message_time_left -= delta
	if _message_time_left <= 0.0:
		_message_box.visible = false


func _on_player_health_changed(current: int, maximum: int) -> void:
	_health_fill.scale.x = float(current) / float(maximum)


func _on_player_died() -> void:
	_status_label.visible = true
