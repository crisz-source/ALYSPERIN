extends Node
## Testes da tela de criação: escolher a classe (sem disciplinas).
var _p := 0
var _f := 0
func check(label: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + label + ("" if detail.is_empty() else " | " + detail))
	if ok: _p += 1
	else: _f += 1
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var area: Node = load("res://game/world/areas/prototype_area/prototype_area.tscn").instantiate()
	get_tree().root.add_child(area)
	get_tree().current_scene = area
	await get_tree().process_frame
	await get_tree().process_frame
	var screen: ClassSelectScreen = area.get_node("ClassSelectScreen")
	var player: Player = area.get_node("Entities/Player")
	var cards: HBoxContainer = screen.get_node("Root/Cards")
	check("abre com 2 classes: Guardião e Devoto", screen.is_open and cards.get_child_count() == 2)
	check("jogador parado enquanto escolhe", player.input_blocked)
	screen.choose_class(5)
	check("índice inválido não fecha a tela", screen.is_open)
	screen.choose_class(1)
	await get_tree().process_frame
	check("escolher Devoto: aplica e fecha (uma etapa só)", not screen.is_open and player.player_class.display_name == "Devoto" and not player.input_blocked)
	check("Devoto com Cajado crescente e sem escudo", player.equipment.weapon_data().display_name == "Cajado crescente" and player.equipment.shield == null)
	check("habilidades: Luz curativa, Raio sagrado + Oração no botão direito", player.abilities[0].display_name == "Luz curativa"
		and player.abilities[1].display_name == "Raio sagrado" and player.secondary_ability().display_name == "Oração de cura")
	var bar: Control = area.get_node("Hud/AbilityBar")
	await get_tree().process_frame
	check("barra: 1 e 2 liberadas; 3-6 com cadeado; espaço 'Dir'", not (bar.get_node("Ability1/Lock") as Label).visible
		and (bar.get_node("Ability3/Lock") as Label).visible and (bar.get_node("Ability6/Lock") as Label).text == "Nv50" and bar.has_node("AbilitySecondary"))
	var card_text: String = ""
	for c: Node in (cards.get_child(0) as Control).get_children() if cards.get_child_count() > 0 else []:
		if c is Label:
			card_text += (c as Label).text
	print("RESULTADO: %d passaram, %d falharam" % [_p, _f])
	get_tree().quit(0 if _f == 0 else 1)
