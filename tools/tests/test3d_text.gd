extends Node
## Testes da nitidez do texto: interface em resolução cheia, 3D pixelado (1/3,
## sem suavizar) e textos do mundo 3D desenhados nítidos pela camada 2D (WorldText).

const ARENA := "res://game/world/arenas/test_arena/test_arena.tscn"

var _failures: int = 0
var _passes: int = 0


func _ready() -> void:
	_run.call_deferred()


func check(label: String, ok: bool, detail: String = "") -> void:
	print(("PASS " if ok else "FAIL ") + label + ("" if detail.is_empty() else " | " + detail))
	if ok:
		_passes += 1
	else:
		_failures += 1


func _run() -> void:
	check("interface desenhada na resolução da tela (canvas_items)", ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items")
	check("3D a 1/3 da resolução, sem suavizar (visual pixelado mantido)", get_viewport().scaling_3d_mode == Viewport.SCALING_3D_MODE_NEAREST
		and is_equal_approx(snappedf(get_viewport().scaling_3d_scale, 0.001), 0.333))
	var arena: Node = load(ARENA).instantiate()
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	var player: Player = arena.get_node("Entities/Player")
	await get_tree().process_frame
	var text: FloatingText = FloatingText.spawn(player, "42", player.global_position + Vector3(0, 2.2, -2), Color(1, 0.8, 0.3), 12)
	await get_tree().process_frame
	await get_tree().process_frame
	var copy: Label = WorldText.overlay_for(text)
	check("texto 3D ganha cópia 2D nítida", copy != null and copy.visible and copy.text == "42")
	check("original 3D não é desenhado (camada que a câmera não vê)", text.layers == 1 << (WorldText.HIDDEN_RENDER_LAYER - 1)
		and not get_viewport().get_camera_3d().get_cull_mask_value(WorldText.HIDDEN_RENDER_LAYER))
	var cam: Camera3D = get_viewport().get_camera_3d()
	WorldText._process(0.0)  # mesmo instante: o sinal de quadro chega antes do _process
	var expected: Vector2 = cam.unproject_position(text.global_position)
	check("cópia no mesmo ponto da tela", (copy.position + copy.size / 2.0).distance_to(expected) < 1.0, "%s vs %s" % [copy.position + copy.size / 2.0, expected])
	check("mesma cor", copy.get_theme_color("font_color").is_equal_approx(text.modulate))
	# fixed_size: altura = font_size x pixel_size / tan(abertura/2) x meia altura da tela.
	var expected_size: int = roundi(text.font_size * text.pixel_size / tan(deg_to_rad(cam.fov) / 2.0) * 180.0)
	check("tamanho igual ao do fixed_size (pela abertura real da câmera)", copy.get_theme_font_size("font_size") == expected_size, "%d vs %d (fov %.0f)" % [copy.get_theme_font_size("font_size"), expected_size, cam.fov])
	text.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	check("texto some: cópia some junto", not is_instance_valid(copy))
	var status_label: Label3D = player.get_node_or_null("StatusLabel")
	player.status.apply(StatusEffects.SLOW, 2.0, 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	check("WorldText atualiza depois de câmera e textos (prioridade alta)", WorldText.process_priority > 0)
	check("nome de efeito também fica nítido", status_label != null and WorldText.overlay_for(status_label) != null and WorldText.overlay_for(status_label).text == "Lento")
	print("RESULTADO: %d passaram, %d falharam" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
