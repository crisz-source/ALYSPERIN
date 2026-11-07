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
var _player: Player

@onready var _health_fill: ColorRect = $PlayerHealth/Fill
@onready var _status_label: Label = $StatusLabel
@onready var _help_label: Label = $HelpPlaceholder
@onready var _message_box: Control = $MessageBox
@onready var _message_label: Label = $MessageBox/Text
@onready var _level_label: Label = $LevelLabel
@onready var _xp_fill: ColorRect = $XpBar/Fill
@onready var _ability_bar: HBoxContainer = $AbilityBar


func _ready() -> void:
	_status_label.visible = false
	_help_label.text = help_text
	_message_box.visible = false


func bind_player(player: Player) -> void:
	_player = player
	player.health.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.message_requested.connect(show_message)
	player.stats.xp_changed.connect(_on_xp_changed)
	_on_xp_changed(player.stats.xp, player.stats.xp_to_next())
	_build_ability_bar()


## Mostra um texto na caixa de baixo. Uma mensagem nova substitui a anterior.
func show_message(text: String) -> void:
	_message_label.text = text
	_message_box.visible = true
	_message_time_left = clampf(1.5 + text.length() * 0.05, message_min_time, message_max_time)


func is_showing_message() -> bool:
	return _message_box.visible


func _process(delta: float) -> void:
	_update_ability_bar()
	if _message_time_left <= 0.0:
		return
	_message_time_left -= delta
	if _message_time_left <= 0.0:
		_message_box.visible = false


## Um quadrado por habilidade: cor, número da tecla, sombra da recarga e
## cadeado (nível) enquanto bloqueada. Provisório até haver ícones.
func _build_ability_bar() -> void:
	for i in _player.abilities.size():
		var ability: AbilityData = _player.abilities[i]
		if ability == null:
			continue
		var box := ColorRect.new()
		box.name = "Ability%d" % (i + 1)
		box.custom_minimum_size = Vector2(18, 18)
		box.color = ability.icon_color
		var shade := ColorRect.new()
		shade.name = "Cooldown"
		shade.size = Vector2(18, 18)
		shade.color = Color(0, 0, 0, 0.7)
		box.add_child(shade)
		var key := Label.new()
		key.name = "Key"
		key.text = str(i + 1)
		key.position = Vector2(1, -2)
		key.add_theme_font_size_override("font_size", 8)
		key.add_theme_constant_override("outline_size", 2)
		key.add_theme_color_override("font_outline_color", Color.BLACK)
		box.add_child(key)
		var lock := Label.new()
		lock.name = "Lock"
		lock.text = "Nv%d" % ability.unlock_level
		lock.position = Vector2(1, 7)
		lock.add_theme_font_size_override("font_size", 8)
		lock.add_theme_constant_override("outline_size", 2)
		lock.add_theme_color_override("font_outline_color", Color.BLACK)
		box.add_child(lock)
		_ability_bar.add_child(box)


func _update_ability_bar() -> void:
	if _player == null:
		return
	for box: Node in _ability_bar.get_children():
		var slot: int = int(String(box.name).trim_prefix("Ability")) - 1
		var unlocked: bool = _player.is_ability_unlocked(slot)
		var shade: ColorRect = box.get_node("Cooldown")
		(box.get_node("Lock") as Label).visible = not unlocked
		# Sombra cobre tudo se bloqueada; senão, encolhe conforme a recarga acaba.
		var ratio: float = 1.0 if not unlocked else _player.ability_cooldown_ratio(slot)
		shade.size.y = 18.0 * ratio
		shade.position.y = 18.0 - shade.size.y


func _on_xp_changed(xp: int, xp_to_next: int) -> void:
	_level_label.text = "Nv %d" % _player.stats.level
	_xp_fill.scale.x = float(xp) / float(xp_to_next)


func _on_player_health_changed(current: int, maximum: int) -> void:
	_health_fill.scale.x = float(current) / float(maximum)


func _on_player_died() -> void:
	_status_label.visible = true
