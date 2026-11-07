class_name Hud
extends CanvasLayer
## HUD provisório: barra de vida do jogador, nível, experiência, habilidades,
## texto de ajuda e caixa de mensagem (placas, portas...).
##
## Só escuta sinais do jogador; não decide nada do jogo. A morte tem tela
## própria (DeathScreen), controlada pela área.

## Texto de controles mostrado no rodapé (provisório, some quando houver tutorial).
@export_multiline var help_text: String = ""
## Tempo mínimo e máximo que uma mensagem fica na tela (s); textos longos ficam mais.
@export var message_min_time: float = 2.5
@export var message_max_time: float = 7.0

const SLOT: float = 20.0
const SLOT_GAP: float = 2.0
const EMPTY_SLOT_COLOR := Color(0.1, 0.1, 0.13, 0.75)
## Topo de cada fileira (tela 640x360): F1-F12 em cima, 1-9 embaixo.
const ROW_F_Y: float = 314.0
const ROW_NUMBERS_Y: float = 337.0

var _message_time_left: float = 0.0
var _player: Player

@onready var _health_fill: ColorRect = $PlayerHealth/Fill
@onready var _help_label: Label = $HelpPlaceholder
@onready var _message_box: Control = $MessageBox
@onready var _message_label: Label = $MessageBox/Text
@onready var _level_label: Label = $LevelLabel
@onready var _xp_fill: ColorRect = $XpBar/Fill
@onready var _ability_bar: Control = $AbilityBar
@onready var _mana_fill: ColorRect = $PlayerMana/Fill
@onready var _quest_tracker: Label = $QuestTracker


func _ready() -> void:
	_help_label.text = help_text
	_message_box.visible = false


func bind_player(player: Player) -> void:
	_player = player
	player.health.health_changed.connect(_on_player_health_changed)
	player.message_requested.connect(show_message)
	player.stats.xp_changed.connect(_on_xp_changed)
	_on_xp_changed(player.stats.xp, player.stats.xp_to_next())
	_build_ability_bar()
	player.discipline_changed.connect(func(_d: DisciplineData) -> void: _build_ability_bar())
	player.hotbar_changed.connect(_build_ability_bar)
	player.inventory.changed.connect(_build_ability_bar)
	player.mana.mana_changed.connect(_on_mana_changed)
	player.quest_log.quest_started.connect(func(_q: QuestData) -> void: _update_quest_tracker())
	player.quest_log.quest_progressed.connect(func(_q: QuestData, _p: int) -> void: _update_quest_tracker())
	player.quest_log.quest_completed.connect(func(_q: QuestData) -> void: _update_quest_tracker())
	_update_quest_tracker()
	_on_mana_changed(player.mana.current(), player.mana.max_mana)


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


## Barra de habilidades no centro, embaixo: fileira de cima F1-F12, de baixo
## 1-9. Todo espaço aparece (vazio = só o número). Espaço com habilidade: cor,
## sombra da recarga e cadeado (nível) enquanto bloqueada. Provisório até ícones.
func _build_ability_bar() -> void:
	for old: Node in _ability_bar.get_children():
		_ability_bar.remove_child(old)
		old.queue_free()
	for i in PlayerInput.ABILITY_SLOTS:
		var ability: AbilityData = _player.abilities[i] if i < _player.abilities.size() else null
		var box := ColorRect.new()
		box.name = "Ability%d" % (i + 1)
		box.size = Vector2(SLOT, SLOT)
		box.position = _slot_position(i)
		box.color = ability.icon_color if ability else EMPTY_SLOT_COLOR
		var key := Label.new()
		key.name = "Key"
		key.text = PlayerInput.ABILITY_KEY_LABELS[i]
		key.position = Vector2(1, -2)
		key.add_theme_font_size_override("font_size", 8)
		key.add_theme_constant_override("outline_size", 2)
		key.add_theme_color_override("font_outline_color", Color.BLACK)
		var item: ItemData = _player.hotbar_items[i] if i < _player.hotbar_items.size() else null
		_setup_item_drop(box, i)
		if ability == null:
			box.add_child(key)
			if item:
				box.color = item.icon_color
				var count := Label.new()
				count.name = "Count"
				count.text = "x%d" % _player.inventory.count_of(item)
				count.position = Vector2(6, 9)
				count.add_theme_font_size_override("font_size", 8)
				count.add_theme_constant_override("outline_size", 2)
				count.add_theme_color_override("font_outline_color", Color.BLACK)
				box.add_child(count)
			_ability_bar.add_child(box)
			continue
		var shade := ColorRect.new()
		shade.name = "Cooldown"
		shade.size = Vector2(SLOT, SLOT)
		shade.color = Color(0, 0, 0, 0.7)
		box.add_child(shade)
		box.add_child(key)
		var lock := Label.new()
		lock.name = "Lock"
		lock.text = "Nv%d" % ability.unlock_level
		lock.position = Vector2(1, 9)
		lock.add_theme_font_size_override("font_size", 8)
		lock.add_theme_constant_override("outline_size", 2)
		lock.add_theme_color_override("font_outline_color", Color.BLACK)
		box.add_child(lock)
		_ability_bar.add_child(box)


## Espaço da barra aceita consumível arrastado do inventário (se não tiver
## habilidade); clique direito tira o item.
func _setup_item_drop(box: Control, slot: int) -> void:
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.set_drag_forwarding(Callable(),
		func(_at: Vector2, data: Variant) -> bool:
			return data is Dictionary and data.get("item") is ConsumableData \
				and not (slot < _player.abilities.size() and _player.abilities[slot] != null),
		func(_at: Vector2, data: Variant) -> void:
			_player.assign_hotbar_item(slot, data["item"]))
	box.gui_input.connect(func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_player.clear_hotbar_slot(slot))


## Posição do espaço na tela: 0-8 = fileira de baixo (1-9), 9-20 = de cima (F1-F12).
func _slot_position(slot: int) -> Vector2:
	var in_numbers: bool = slot < 9
	var count: int = 9 if in_numbers else 12
	var index: int = slot if in_numbers else slot - 9
	var width: float = count * SLOT + (count - 1) * SLOT_GAP
	var x0: float = roundf((640.0 - width) / 2.0)
	return Vector2(x0 + index * (SLOT + SLOT_GAP), ROW_NUMBERS_Y if in_numbers else ROW_F_Y)


func _update_ability_bar() -> void:
	if _player == null:
		return
	for box: Node in _ability_bar.get_children():
		if not box.has_node("Cooldown"):
			continue
		var slot: int = int(String(box.name).trim_prefix("Ability")) - 1
		var unlocked: bool = _player.is_ability_unlocked(slot)
		var shade: ColorRect = box.get_node("Cooldown")
		(box.get_node("Lock") as Label).visible = not unlocked
		# Sombra cobre tudo se bloqueada; senão, encolhe conforme a recarga acaba.
		var ratio: float = 1.0 if not unlocked else _player.ability_cooldown_ratio(slot)
		shade.size.y = SLOT * ratio
		shade.position.y = SLOT - shade.size.y


## Canto superior direito: a primeira missão ativa e o progresso.
func _update_quest_tracker() -> void:
	var active: Array[QuestData] = _player.quest_log.active_quests()
	if active.is_empty():
		_quest_tracker.text = ""
		return
	var quest: QuestData = active[0]
	if _player.quest_log.is_ready(quest):
		_quest_tracker.text = "Missão: %s\nConcluída! Volte para entregar." % quest.title
	else:
		_quest_tracker.text = "Missão: %s (%d/%d)" % [quest.title, _player.quest_log.progress_of(quest), quest.required_count]


func _on_mana_changed(current: int, maximum: int) -> void:
	_mana_fill.scale.x = float(current) / float(maxi(maximum, 1))


func _on_xp_changed(xp: int, xp_to_next: int) -> void:
	_level_label.text = "Nv %d" % _player.stats.level
	_xp_fill.scale.x = float(xp) / float(xp_to_next)


func _on_player_health_changed(current: int, maximum: int) -> void:
	_health_fill.scale.x = float(current) / float(maximum)

