extends SceneTree
## Gera os dados das masmorras (números provisórios, design §4).

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://game/dungeons/data/")
	var d := DungeonData.new()
	d.id = &"forgotten_ruins"
	d.display_name = "Ruínas Esquecidas"
	d.min_level = 20
	d.min_gear_score = 300
	d.level_cap = 24
	d.gs_cap = 300
	d.enemy_health = 160
	d.enemy_damage = 30
	d.enemy_xp = 120
	var err: Error = ResourceSaver.save(d, "res://game/dungeons/data/forgotten_ruins.tres")
	# Materiais de Khar'Vesh (design §1.11). Sem uso ainda: base da criação de itens.
	for m: Array in [["crimson_sap", "Seiva Rubra", "Seiva de sangue dos bulbos da Mãe-Raiz.", Color(0.85, 0.1, 0.15)],
			["living_branch", "Galho Vivo", "Galho-chicote que ainda se mexe.", Color(0.4, 0.28, 0.15)],
			["ancestral_bark", "Casca Ancestral", "Casca negra com veios vermelhos.", Color(0.15, 0.1, 0.08)],
			["altar_thorn", "Espinho de Altar", "Espinho da fenda-boca.", Color(0.75, 0.7, 0.6)],
			["sprouted_heart", "Coração Germinado", "Raro. Pulsa como se ainda estivesse vivo.", Color(1.0, 0.3, 0.35)]]:
		var item := ItemData.new()
		item.id = StringName(m[0])
		item.display_name = m[1]
		item.description = m[2]
		item.icon_color = m[3]
		item.max_stack = 99
		if err == OK:
			err = ResourceSaver.save(item, "res://game/items/data/%s.tres" % m[0])
	print("BUILD DUNGEONS ", error_string(err))
	quit(0 if err == OK else 1)
