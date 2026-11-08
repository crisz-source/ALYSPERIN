extends SceneTree
## Gera as 2 primeiras classes (Guardião = tanque, Devoto = cura), sem
## disciplinas (decisão do proprietário), com as habilidades do design aprovado,
## o Cajado de aprendiz e o tipo de cada arma. Números provisórios.

const ITEMS := "res://game/items/data/"
const ABIL := "res://game/abilities/data/"
const CLASSES := "res://game/classes/data/"

var _err: Error = OK


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(CLASSES)
	# Tipo de cada arma existente.
	for pair: Array in [["short_sword", &"espada"], ["heavy_axe", &"machado"], ["light_blade", &"espada_leve"]]:
		var w: WeaponData = load(ITEMS + pair[0] + ".tres")
		w.weapon_type = pair[1]
		_save(w, ITEMS + pair[0] + ".tres")
	var staff := WeaponData.new()
	staff.id = &"apprentice_staff"
	staff.display_name = "Cajado crescente"
	staff.description = "Cajado com lua crescente e um orbe de éter, usado para canalizar a fé."
	_model(staff, "crescent_staff", 0.65, Vector3(0, -0.8, 0), 0.0)
	staff.weapon_type = &"cajado"
	staff.damage = 8
	staff.timing_scale = 1.1
	staff.reach_scale = 1.15
	staff.knockback_multiplier = 1.0
	staff.durability = 80
	staff.icon_color = Color(0.7, 0.55, 0.35)
	_save(staff, ITEMS + "apprentice_staff.tres")
	_remove(ITEMS + "pilgrim_mace.tres")  # substituída pelo cajado
	var maul := WeaponData.new()
	maul.id = &"ember_maul"
	maul.display_name = "Malho de brasa"
	maul.description = "Martelo de guerra com coroa de cristal âmbar. Pesado, empurra longe."
	maul.weapon_type = &"maca"
	maul.damage = 14
	maul.timing_scale = 1.2
	maul.reach_scale = 1.05
	maul.knockback_multiplier = 1.3
	maul.durability = 70
	maul.icon_color = Color(0.95, 0.55, 0.2)
	_model(maul, "ember_maul", 0.6, Vector3(0, -0.3, 0), 90.0)  # faces de impacto para a frente
	_save(maul, ITEMS + "ember_maul.tres")
	var kite := ShieldData.new()
	kite.id = &"sentinel_shield"
	kite.display_name = "Escudo sentinela"
	kite.description = "Escudo em pipa com borda chanfrada e cristal no centro."
	kite.block_half_angle = 80.0
	kite.knockback_multiplier = 0.3
	kite.durability = 60
	kite.icon_color = Color(0.55, 0.65, 0.85)
	_model(kite, "sentinel_shield", 0.7, Vector3(0, -0.45, 0), 180.0)  # cristal (frente) para fora
	_save(kite, ITEMS + "sentinel_shield.tres")
	maul.gear_score = 120
	_save(maul, ITEMS + "ember_maul.tres")
	kite.gear_score = 120
	_save(kite, ITEMS + "sentinel_shield.tres")

	# Equipamento de veterano (GS 320): permite entrar nas Ruínas Esquecidas (GS 300).
	var vmaul := maul.duplicate() as WeaponData
	vmaul.id = &"veteran_maul"
	vmaul.display_name = "Malho de veterano"
	vmaul.description = "Malho de brasa temperado em batalha. GS 320."
	vmaul.gear_score = 320
	vmaul.durability = 100
	_save(vmaul, ITEMS + "veteran_maul.tres")
	var vshield := kite.duplicate() as ShieldData
	vshield.id = &"veteran_shield"
	vshield.display_name = "Escudo de veterano"
	vshield.description = "Escudo sentinela reforçado. GS 320."
	vshield.gear_score = 320
	vshield.durability = 90
	_save(vshield, ITEMS + "veteran_shield.tres")
	var vstaff := staff.duplicate() as WeaponData
	vstaff.id = &"veteran_staff"
	vstaff.display_name = "Cajado de veterano"
	vstaff.description = "Cajado crescente com orbe desperto. GS 320."
	vstaff.gear_score = 320
	vstaff.durability = 100
	_save(vstaff, ITEMS + "veteran_staff.tres")

	# Óleos de arma (consumíveis): dão um elemento à arma por 60 s.
	for oil: Array in [["fire_oil", "Óleo de fogo", &"fire", Color(1.0, 0.45, 0.15)],
			["ice_oil", "Óleo de gelo", &"ice", Color(0.55, 0.85, 1.0)],
			["lightning_oil", "Óleo de raio", &"lightning", Color(1.0, 0.95, 0.4)]]:
		var c := ConsumableData.new()
		c.id = StringName(oil[0])
		c.display_name = oil[1]
		c.description = "Passa na arma: golpes com %s por 60 s." % String(oil[1]).trim_prefix("Óleo de ")
		c.weapon_element = oil[2]
		c.element_duration = 60.0
		c.max_stack = 5
		c.icon_color = oil[3]
		_save(c, ITEMS + String(oil[0]) + ".tres")

	# --- Guardião (tanque) ---
	var bash := ShieldBashData.new()
	_ability(bash, &"shield_bash", "Golpe de escudo", "Empurra e atordoa o alvo à frente.", 1, 6.0, 5, Color(0.6, 0.7, 0.9))
	var taunt := TauntData.new()
	_ability(taunt, &"taunt", "Provocar", "Inimigos próximos atacam você por 4 s.", 1, 10.0, 5, Color(1.0, 0.55, 0.3))
	var guardian_list: Array[AbilityData] = [bash, taunt,
		_support(&"steadfast_stance", "Postura inabalável", "Por 6 s, defendendo: bloqueia por todos os lados e não é empurrado.", 10, 15.0, 10, SupportSpellData.Mechanic.SELF_EFFECT, &"stance", 0.0, 6.0, 0.0, 0),
		_support(&"shared_wall", "Muralha compartilhada", "Você e aliados a até 8 m recebem 30% menos dano por 6 s.", 20, 20.0, 15, SupportSpellData.Mechanic.GROUP_EFFECT, &"protect", 0.3, 6.0, 8.0, 0),
		_support(&"eternal_bastion", "Bastião eterno", "Por 5 s não cai abaixo de 1 de vida.", 35, 45.0, 20, SupportSpellData.Mechanic.SELF_EFFECT, &"undying", 0.0, 5.0, 0.0, 0),
		_support(&"living_fortress", "Fortaleza viva", "Cúpula de 8 s: quem está dentro recebe 50% menos dano; projéteis inimigos somem.", 50, 60.0, 25, SupportSpellData.Mechanic.DOME, &"protect", 0.5, 8.0, 3.5, 0)]
	var guardian := ClassData.new()
	guardian.id = &"guardian"
	guardian.display_name = "Guardião"
	guardian.role = "Tanque"
	guardian.description = "Linha de frente com arma e escudo. Protege o grupo e segura os inimigos."
	guardian.icon_color = Color(0.45, 0.6, 0.85)
	guardian.model_scene = load("res://assets/characters/kaykit/Knight.glb")  # KayKit Adventurers (CC0)
	guardian.model_scale = 0.7
	var g_weapons: Array[StringName] = [&"espada", &"maca", &"machado"]
	guardian.allowed_weapon_types = g_weapons
	guardian.uses_shield = true
	guardian.starting_weapon = ItemStack.create(load(ITEMS + "ember_maul.tres"))
	guardian.starting_shield = ItemStack.create(load(ITEMS + "sentinel_shield.tres"))
	guardian.passive_id = &"muralha"
	guardian.passive_name = "Muralha"
	guardian.passive_description = "Bloquear dá Firmeza: 30% menos dano por 3 s."
	guardian.abilities = guardian_list
	_save(guardian, CLASSES + "guardian.tres")

	# --- Devoto (cura) ---
	var light := HealSpellData.new()
	light.heal_amount = 25
	light.cast_time = 0.3
	light.requires_target = true
	_ability(light, &"healing_light", "Luz curativa", "Passe a mira em um ou mais aliados e aperte Espaço: cura 25 em cada (15 de mana por uso, qualquer número de aliados).", 1, 3.0, 15, Color(1.0, 0.95, 0.6))
	var ray := ProjectileSpellData.new()
	ray.damage = 8
	ray.speed = 220.0
	ray.max_distance = 220.0
	ray.knockback = 60.0
	ray.projectile_color = Color(1.0, 0.9, 0.5)
	_ability(ray, &"holy_ray", "Raio sagrado", "Projétil sagrado fraco (no co-op: cura os aliados que atravessa).", 1, 0.8, 6, Color(1.0, 0.9, 0.5))
	var prayer := HealSpellData.new()
	prayer.heal_amount = 25
	prayer.cast_time = 0.3
	prayer.requires_target = false
	_ability(prayer, &"healing_prayer", "Oração de cura", "Cura você mesmo (botão direito do mouse).", 1, 6.0, 15, Color(0.95, 0.85, 1.0))
	var devotee_list: Array[AbilityData] = [light, ray,
		_support(&"blessing_of_protection", "Bênção de proteção", "Escudo de 40 no aliado da mira (sem aliado: em você).", 10, 8.0, 12, SupportSpellData.Mechanic.ALLY_SHIELD, &"", 0.0, 0.0, 0.0, 40),
		_support(&"circle_of_healing", "Círculo de cura", "Círculo no chão (raio 4 m) que cura 8 por segundo por 6 s.", 20, 18.0, 20, SupportSpellData.Mechanic.HEAL_ZONE, &"", 0.0, 6.0, 4.0, 8),
		_support(&"resurrection", "Ressurreição", "Levanta um aliado caído a até 6 m com metade da vida. Sozinho: você revive ao morrer, uma vez.", 35, 60.0, 30, SupportSpellData.Mechanic.REVIVE, &"", 0.0, 0.0, 6.0, 50),
		_support(&"miracle", "Milagre", "Cura total do grupo (15 m) e remove efeitos negativos.", 50, 90.0, 40, SupportSpellData.Mechanic.GROUP_HEAL, &"", 0.0, 0.0, 15.0, 0)]
	var devotee := ClassData.new()
	devotee.id = &"devotee"
	devotee.display_name = "Devoto"
	devotee.role = "Cura"
	devotee.description = "Canaliza a fé com um cajado para curar e proteger. Não usa escudo."
	devotee.icon_color = Color(1.0, 0.9, 0.6)
	devotee.model_scene = load("res://assets/characters/kaykit/Mage.glb")  # KayKit Adventurers (CC0)
	devotee.model_scale = 0.7
	var d_weapons: Array[StringName] = [&"cajado"]
	devotee.allowed_weapon_types = d_weapons
	devotee.uses_shield = false
	devotee.starting_weapon = ItemStack.create(load(ITEMS + "apprentice_staff.tres"))
	devotee.passive_id = &"graca"
	devotee.passive_name = "Graça"
	devotee.passive_description = "Curar quem está com a vida cheia vira escudo de vida."
	devotee.abilities = devotee_list
	devotee.secondary_ability = load(ABIL + "healing_prayer.tres")
	_save(devotee, CLASSES + "devotee.tres")

	print("BUILD CLASSES ", error_string(_err))
	quit(0 if _err == OK else 1)


func _save(res: Resource, path: String) -> void:
	if _err != OK:
		return
	_err = ResourceSaver.save(res, path)
	if _err != OK:
		print("falhou ao salvar ", path)


## Modelo 3D (CC0, assets/weapons/<nome>/) segurado na mão.
func _model(item: ItemData, name: String, scale: float, offset: Vector3, yaw: float) -> void:
	item.model_scene = load("res://assets/weapons/%s/%s.glb" % [name, name])
	item.model_scale = scale
	item.model_offset = offset
	item.model_yaw_degrees = yaw


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		print("removido ", path)


func _ability(a: AbilityData, id: StringName, name: String, desc: String, level: int, cooldown: float, mana: int, color: Color) -> void:
	a.id = id
	a.display_name = name
	a.description = desc
	a.unlock_level = level
	a.cooldown = cooldown
	a.mana_cost = mana
	a.icon_color = color
	_save(a, ABIL + String(id) + ".tres")


func _support(id: StringName, name: String, desc: String, level: int, cooldown: float, mana: int, mech: SupportSpellData.Mechanic, effect: StringName, strength: float, duration: float, radius: float, amount: int) -> AbilityData:
	var a := SupportSpellData.new()
	a.mechanic = mech
	a.effect_id = effect
	a.strength = strength
	a.duration = duration
	a.radius = radius
	a.amount = amount
	_ability(a, id, name, desc, level, cooldown, mana, Color(0.75, 0.85, 1.0))
	return load(ABIL + String(id) + ".tres")


## Habilidade ainda sem funcionamento: aparece na barra (com nível de liberação).
func _placeholder(id: StringName, name: String, desc: String, level: int) -> AbilityData:
	var a := AbilityData.new()
	_ability(a, id, name, desc + " (em desenvolvimento)", level, 10.0, 0, Color(0.45, 0.45, 0.5))
	return load(ABIL + String(id) + ".tres")
