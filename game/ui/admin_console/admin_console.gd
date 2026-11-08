class_name AdminConsole
extends CanvasLayer
## Console de ADMINISTRADOR (provisório, ferramenta de desenvolvimento).
## Enter abre a caixa de texto; Enter executa; Esc fecha.
##
## Comandos:
##   /add players N  -> N aliados de teste (feridos) perto do jogador
##   /add mob N      -> N monstros em volta do jogador
##   /boss           -> chama Khar'Vesh, a Mãe-Raiz, à frente do jogador
##   /efeito NOME    -> efeito de status nos monstros próximos (com "eu": em você)
##   /help           -> lista os comandos

const HELP_TEXT := "Comandos: /add players N | /add mob N | /boss | /efeito NOME [eu] | /help"
## /efeito: nome em português -> [id, duração (s), força].
const EFFECTS: Dictionary = {
	"lento": [&"slow", 6.0, 0.5],
	"congelar": [&"freeze", 3.0, 0.0],
	"queimar": [&"burn", 6.0, 6.0],
	"veneno": [&"poison", 8.0, 4.0],
	"atordoar": [&"stun", 2.0, 0.0],
	"medo": [&"fear", 3.0, 0.0],
}
## Alcance do /efeito nos monstros (m).
const EFFECT_RADIUS: float = 15.0

var is_open: bool = false
var _area: GameArea
var _input: LineEdit
var _panel: ColorRect


func bind(area: GameArea) -> void:
	_area = area


func _ready() -> void:
	layer = 9
	_panel = ColorRect.new()
	_panel.position = Vector2(8, 270)
	_panel.size = Vector2(300, 22)
	_panel.color = Color(0.03, 0.03, 0.06, 0.9)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_input = LineEdit.new()
	_input.name = "Input"
	_input.position = Vector2(10, 272)
	_input.size = Vector2(296, 18)
	_input.placeholder_text = "/help"
	_input.add_theme_font_size_override("font_size", 9)
	_input.text_submitted.connect(_on_submitted)
	add_child(_input)
	_set_visible(false)


func _unhandled_input(event: InputEvent) -> void:
	if _area == null:
		return
	if not is_open and event.is_action_pressed("chat") and not _area.player.input_blocked:
		open()
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	is_open = true
	_set_visible(true)
	_input.text = ""
	_input.grab_focus()
	_area.player.input_blocked = true


func close() -> void:
	is_open = false
	_set_visible(false)
	_input.release_focus()
	_area.player.input_blocked = false


## Executa um comando e devolve a resposta (também mostrada no HUD).
func execute(command: String) -> String:
	var parts: PackedStringArray = command.strip_edges().to_lower().split(" ", false)
	var reply: String
	if parts.is_empty():
		reply = ""
	elif parts[0] == "/help":
		reply = HELP_TEXT
	elif parts[0] == "/boss":
		var boss: KharVesh = _area.spawn_boss_near_player()
		reply = "%s apareceu!" % KharVesh.DISPLAY_NAME if boss else "Já existe um chefe em luta."
	elif parts[0] == "/efeito":
		reply = _apply_effect(parts)
	elif parts[0] == "/add" and parts.size() >= 2 and (parts[1] == "players" or parts[1] == "player" or parts[1] == "mob" or parts[1] == "mobs"):
		var count: int = parts[2].to_int() if parts.size() >= 3 and parts[2].is_valid_int() else 1
		if count <= 0:
			reply = "Use um número maior que zero. Ex.: /add mob 5"
		elif parts[1].begins_with("player"):
			var allies: Array[AllyDummy] = _area.spawn_test_allies(count)
			reply = "%d aliado(s) de teste adicionado(s) ao grupo." % allies.size()
		else:
			var enemies: Array[BasicEnemy] = _area.spawn_test_enemies(count)
			reply = "%d monstro(s) criado(s)." % enemies.size()
		if count > GameArea.MAX_SPAWN:
			reply += " (limite de %d por comando)" % GameArea.MAX_SPAWN
	else:
		reply = "Comando desconhecido: %s. %s" % [command.strip_edges(), HELP_TEXT]
	if not reply.is_empty():
		_area.player.message_requested.emit(reply)
	return reply


## /efeito NOME [eu]: aplica nos monstros próximos (ou em você, com "eu").
func _apply_effect(parts: PackedStringArray) -> String:
	var names: String = ", ".join(PackedStringArray(EFFECTS.keys()))
	if parts.size() < 2 or not EFFECTS.has(parts[1]):
		return "Use /efeito NOME [eu]. Nomes: %s" % names
	var spec: Array = EFFECTS[parts[1]]
	var player: Player = _area.player
	if parts.size() >= 3 and parts[2] == "eu":
		# Medo em si mesmo precisa de alguém de quem fugir: o monstro mais próximo.
		var source: Node3D = _nearest_enemy(player.global_position) if spec[0] == &"fear" else null
		if spec[0] == &"fear" and source == null:
			return "Medo precisa de um monstro por perto (de quem fugir)."
		player.status.apply(spec[0], spec[1], spec[2], source)
		return "Efeito %s em você por %d s." % [parts[1], int(spec[1])]
	var count: int = 0
	for node: Node in _area.get_tree().get_nodes_in_group(BasicEnemy.GROUP):
		var enemy := node as Node3D
		var fx: StatusEffects = enemy.get("status") if enemy else null
		var hp: HealthComponent = enemy.get("health") if enemy else null
		if fx and hp and not hp.is_dead and enemy.global_position.distance_to(player.global_position) <= EFFECT_RADIUS:
			fx.apply(spec[0], spec[1], spec[2], player)
			count += 1
	return "Efeito %s em %d monstro(s) a até %d m." % [parts[1], count, int(EFFECT_RADIUS)]


func _nearest_enemy(from: Vector3) -> Node3D:
	var best: Node3D = null
	for node: Node in _area.get_tree().get_nodes_in_group(BasicEnemy.GROUP):
		var enemy := node as BasicEnemy
		if enemy and not enemy.health.is_dead and (best == null or enemy.global_position.distance_to(from) < best.global_position.distance_to(from)):
			best = enemy
	return best


func _on_submitted(text: String) -> void:
	execute(text)
	close()


func _set_visible(value: bool) -> void:
	_panel.visible = value
	_input.visible = value
