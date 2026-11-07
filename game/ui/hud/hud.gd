class_name Hud
extends CanvasLayer
## HUD provisório: barra de vida do jogador, texto de ajuda e aviso de morte.
##
## Só escuta sinais do jogador; não decide nada do jogo. Quem reinicia a cena
## depois da morte é a própria área/arena.

## Texto de controles mostrado no rodapé (provisório, some quando houver tutorial).
@export_multiline var help_text: String = ""

@onready var _health_fill: ColorRect = $PlayerHealth/Fill
@onready var _status_label: Label = $StatusLabel
@onready var _help_label: Label = $HelpPlaceholder


func _ready() -> void:
	_status_label.visible = false
	_help_label.text = help_text


func bind_player(player: Player) -> void:
	player.health.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)


func _on_player_health_changed(current: int, maximum: int) -> void:
	_health_fill.scale.x = float(current) / float(maximum)


func _on_player_died() -> void:
	_status_label.visible = true
