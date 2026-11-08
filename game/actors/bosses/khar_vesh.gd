class_name KharVesh
extends CharacterBody3D
## Khar'Vesh, a Mãe-Raiz — chefe das Ruínas Esquecidas.
## Design aprovado: documentation/design/chefes-iniciais.md §0 e §1.
##
## Corpo PROVISÓRIO montado por código (formas simples, sem arte). Tudo que o
## jogador precisa saber aparece no corpo ou no chão, nunca em texto:
## fraquezas pelo tamanho/cor do número, partes quebradas, aura da Fúria,
## casca molhada e brilhante, cerne vermelho exposto.
## Números provisórios (⚑ no design).

signal died
signal phase_changed(phase: int)
signal part_broken(part_id: StringName)

const GROUP: StringName = &"bosses"
const GRAVITY: float = 20.0
const MAX_HEALTH: int = 2400
const XP_REWARD: int = 3000
const DISPLAY_NAME := "Khar'Vesh, a Mãe-Raiz"
const ITEMS := "res://game/items/data/"

## Fases por vida (fração): 1 enraizada, 2 desperta, 3 ferida aberta.
const PHASE_2_AT: float = 0.70
const PHASE_3_AT: float = 0.35
## Fúria (regra do proprietário): limiar -> multiplicador de velocidade e dano.
const ENRAGE_THRESHOLDS: Array[float] = [0.70, 0.50, 0.20]
const ENRAGE_MULT: Array[float] = [1.0, 1.15, 1.25, 1.40]
const MIN_WINDUP: float = 0.35
const PHASE_ROAR_TIME: float = 1.5
const ENRAGE_ROAR_TIME: float = 0.8
const RECOVER_TIME: float = 1.1
const PANT_TIME: float = 3.0
const CRAWL_SPEED: float = 1.2
const TURN_RATE: float = 2.0

## Resistências (multiplicador de dano por elemento). "" = físico neutro.
const BASE_RESIST: Dictionary = {&"": 1.0, &"fire": 1.75, &"ice": 1.35, &"lightning": 1.0, &"earth": 0.3, &"light": 1.0, &"dark": 0.6}
const WET_TIME: float = 10.0
const WET_PUDDLE_RANGE: float = 5.0
const WET_COOLDOWN: float = 14.0

## Cura (Sugar seiva): por tique de 0,5 s, fração da vida máxima por bulbo vivo.
const HEAL_TIME: float = 3.0
const HEAL_PER_BULB_TICK: float = 0.005
const HEAL_INTERRUPT_DAMAGE: int = 60
const HEAL_COOLDOWN: float = 20.0
const SPROUT_COOLDOWN: float = 25.0
const SPORE_COOLDOWN: float = 12.0
const MAX_SPROUTS: int = 3

## Ataques: id -> [aviso base (s), dano base].
const ATTACKS: Dictionary = {
	&"whip": [0.9, 45],
	&"sweep": [1.0, 40],
	&"spear": [0.8, 50],
	&"spores": [1.0, 10],
}
const WHIP_LENGTH: float = 9.0
const WHIP_SHORT_LENGTH: float = 4.0
const WHIP_WIDTH: float = 1.6
const SWEEP_RADIUS: float = 6.0
const SPEAR_RADIUS: float = 1.5
const SPORE_RADIUS: float = 4.5

const BARK_COLOR := Color(0.12, 0.09, 0.08)
const WET_BARK_COLOR := Color(0.06, 0.08, 0.1)
const TELEGRAPH_COLOR := Color(1.0, 0.2, 0.15, 0.35)
const SPORE_TELEGRAPH_COLOR := Color(0.6, 0.9, 0.3, 0.35)

enum State { IDLE, WINDUP, RECOVER, ROAR, HEAL, STUN, PANT, DIP, DEAD }

var state: State = State.IDLE
var phase: int = 1
var enrage_level: int = 0
var facing: Vector3 = Vector3.FORWARD
var target: Player = null
var wet_left: float = 0.0
## Chance do material raro ao morrer (testes podem forçar 1,0).
var rare_drop_chance: float = 0.25

var health: HealthComponent
var status: StatusEffects
var parts: Dictionary = {}   # part_id -> BossPart

var _state_time: float = 0.0
var _state_duration: float = 0.0
var _attack: Dictionary = {}
var _queued_spears: int = 0
var _cooldowns: Dictionary = {&"heal": 8.0, &"sprouts": 6.0, &"spores": 4.0, &"wet": 0.0}
var _heal_tick: float = 0.0
var _heal_bulb_damage: int = 0
var _taunted_by: Player = null
var _taunt_left: float = 0.0
var _last_attacker: Player = null
var _current_part: BossPart = null
var _hit_frames: Dictionary = {}
var _sprouts: Array[BasicEnemy] = []
var _model: Node3D
var _bark_material: StandardMaterial3D
var _core_mesh: MeshInstance3D
var _aura: OmniLight3D
var _telegraph: MeshInstance3D
var _telegraph_material: StandardMaterial3D
var _bar: ColorRect
var _bar_layer: CanvasLayer


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(BasicEnemy.GROUP)  # Provocar, /efeito e mira tratam como inimigo
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.6
	cyl.height = 6.0
	shape.shape = cyl
	shape.position = Vector3(0, 3, 0)
	add_child(shape)
	health = HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = MAX_HEALTH
	add_child(health)
	health.damage_modifier = _modify_damage
	health.damaged.connect(_on_damaged)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	status = StatusEffects.attach(self, health, 7.0)
	_build_body()
	_build_parts()
	_build_telegraph()
	_build_bar()


# --- Corpo provisório ---------------------------------------------------------

func _build_body() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	_bark_material = _mat(BARK_COLOR)
	var trunk := _mesh_cylinder(1.6, 6.0, _bark_material)
	trunk.position = Vector3(0, 3, 0)
	trunk.name = "Trunk"
	_model.add_child(trunk)
	_core_mesh = _mesh_sphere(1.0, _mat(Color(0.9, 0.1, 0.1), Color(1.0, 0.1, 0.05)))
	_core_mesh.position = Vector3(0, 3.0, -1.0)
	_core_mesh.visible = false
	_model.add_child(_core_mesh)
	_aura = OmniLight3D.new()
	_aura.light_color = Color(1.0, 0.15, 0.1)
	_aura.omni_range = 9.0
	_aura.light_energy = 0.0
	_aura.position = Vector3(0, 3, 0)
	_model.add_child(_aura)


func _build_parts() -> void:
	# [id, vida, forma (tamanho), posição local, cor, escala de dano]
	var specs: Array = [
		[&"bark", 900, Vector3(3.5, 5.0, 3.5), Vector3(0, 3, 0), BARK_COLOR, 1.0],
		[&"core", 0, Vector3(2.0, 2.0, 2.0), Vector3(0, 3, -1.0), Color(0.9, 0.1, 0.1), 1.5],
		[&"mouth", 250, Vector3(1.0, 1.6, 0.6), Vector3(0, 3.6, -1.7), Color(0.55, 0.05, 0.05), 1.0],
		[&"whip_left", 250, Vector3(0.5, 0.5, 3.0), Vector3(-2.2, 2.5, -1.2), Color(0.18, 0.12, 0.08), 1.0],
		[&"whip_right", 250, Vector3(0.5, 0.5, 3.0), Vector3(2.2, 2.5, -1.2), Color(0.18, 0.12, 0.08), 1.0],
		[&"bulb_1", 150, Vector3(0.9, 0.9, 0.9), Vector3(-0.8, 3.5, 1.6), Color(0.9, 0.1, 0.15, 0.75), 1.0],
		[&"bulb_2", 150, Vector3(0.9, 0.9, 0.9), Vector3(0.8, 3.0, 1.7), Color(0.9, 0.1, 0.15, 0.75), 1.0],
		[&"bulb_3", 150, Vector3(0.9, 0.9, 0.9), Vector3(0.0, 4.3, 1.5), Color(0.9, 0.1, 0.15, 0.75), 1.0],
	]
	for spec: Array in specs:
		var part := BossPart.new()
		part.name = "Part_" + String(spec[0])
		part.part_id = spec[0]
		part.part_max_hp = spec[1]
		part.damage_scale = spec[5]
		part.health = health
		part.boss = self
		part.collision_layer = 4
		part.collision_mask = 0
		part.position = spec[3]
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = spec[2]
		cs.shape = box
		part.add_child(cs)
		if spec[0] != &"bark" and spec[0] != &"core":
			var mesh := MeshInstance3D.new()
			mesh.name = "Visual"
			var bm := BoxMesh.new() if not String(spec[0]).begins_with("bulb") else null
			if bm:
				bm.size = spec[2]
				mesh.mesh = bm
			else:
				var sm := SphereMesh.new()
				sm.radius = 0.45
				sm.height = 0.9
				mesh.mesh = sm
			mesh.material_override = _mat(spec[4])
			part.add_child(mesh)
		_model.add_child(part)
		parts[spec[0]] = part
	(parts[&"core"] as BossPart).set_hittable(false)


func _build_telegraph() -> void:
	_telegraph = MeshInstance3D.new()
	_telegraph.name = "Telegraph"
	_telegraph.top_level = true
	_telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_telegraph_material = _mat(TELEGRAPH_COLOR)
	_telegraph_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph.material_override = _telegraph_material
	_telegraph.visible = false
	add_child(_telegraph)


func _build_bar() -> void:
	_bar_layer = CanvasLayer.new()
	_bar_layer.layer = 4
	add_child(_bar_layer)
	var back := ColorRect.new()
	back.position = Vector2(170, 14)
	back.size = Vector2(300, 6)
	back.color = Color(0.1, 0.05, 0.05, 0.85)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_layer.add_child(back)
	_bar = ColorRect.new()
	_bar.name = "BossBar"
	_bar.position = back.position
	_bar.size = back.size
	_bar.color = Color(0.8, 0.12, 0.1)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_layer.add_child(_bar)
	var label := Label.new()
	label.text = DISPLAY_NAME
	label.position = Vector2(170, 1)
	label.size = Vector2(300, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_layer.add_child(label)


# --- Laço principal ------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_state_time += delta
	for key: StringName in _cooldowns.keys():
		_cooldowns[key] = maxf(float(_cooldowns[key]) - delta, 0.0)
	_taunt_left = maxf(_taunt_left - delta, 0.0)
	if wet_left > 0.0:
		wet_left = maxf(wet_left - delta, 0.0)
	_update_target()
	var vertical: float = velocity.y
	velocity = Vector3.ZERO
	match state:
		State.IDLE:
			_process_idle(delta)
		State.WINDUP:
			_face_target(delta * 0.5)
			if _state_time >= _state_duration:
				_strike()
		State.RECOVER, State.ROAR, State.PANT, State.DIP:
			if _state_time >= _state_duration:
				if state == State.DIP:
					wet_left = WET_TIME
				_change_state(State.IDLE)
		State.HEAL:
			_process_heal(delta)
		State.STUN:
			if _state_time >= _state_duration:
				_change_state(State.IDLE)
		State.DEAD:
			_model.scale = Vector3.ONE * maxf(1.0 - _state_time, 0.05)
			if _state_time >= 1.0:
				queue_free()
	velocity.y = vertical - GRAVITY * delta if not is_on_floor() else 0.0
	move_and_slide()
	_update_visuals()


func _process_idle(delta: float) -> void:
	if target == null:
		return
	_face_target(delta)
	var dist: float = _flat(target.global_position - global_position).length()
	if phase >= 2 and dist > 5.0 and status.speed_multiplier() > 0.0:
		velocity = _flat(target.global_position - global_position).normalized() * CRAWL_SPEED * status.speed_multiplier()
	if _state_time < 0.4:
		return
	choose_action(dist)


## Escolhe o próximo ataque/ação pela fase, distância e recargas.
func choose_action(dist: float) -> void:
	var bulbs: int = bulbs_alive()
	if phase >= 2 and _cooldowns[&"wet"] <= 0.0 and wet_left <= 0.0 and _near_puddle():
		_cooldowns[&"wet"] = WET_COOLDOWN
		_change_state(State.DIP, 1.0)
		return
	if bulbs > 0 and _cooldowns[&"heal"] <= 0.0 and health.current_health < health.max_health * 0.85:
		_cooldowns[&"heal"] = HEAL_COOLDOWN
		_heal_bulb_damage = 0
		_heal_tick = 0.5
		_change_state(State.HEAL, HEAL_TIME)
		return
	if phase >= 2 and _cooldowns[&"sprouts"] <= 0.0 and _alive_sprouts() < MAX_SPROUTS:
		_cooldowns[&"sprouts"] = SPROUT_COOLDOWN
		_spawn_sprouts(2)
		_change_state(State.RECOVER, 0.8)
		return
	if phase >= 2 and not is_part_broken(&"mouth") and _cooldowns[&"spores"] <= 0.0:
		_cooldowns[&"spores"] = SPORE_COOLDOWN
		start_attack(&"spores")
		return
	if phase == 3:
		_queued_spears = 2
		start_attack(&"spear")
	elif dist <= SWEEP_RADIUS - 0.5:
		start_attack(&"sweep")
	elif dist <= WHIP_LENGTH:
		start_attack(&"whip")
	else:
		start_attack(&"spear")


## Começa um ataque com aviso no chão. Público para os testes.
func start_attack(id: StringName) -> void:
	var spec: Array = ATTACKS[id]
	var tpos: Vector3 = target.global_position if target else global_position + facing * 4.0
	_attack = {"id": id, "damage": roundi(float(spec[1]) * ENRAGE_MULT[enrage_level]), "origin": global_position, "dir": facing}
	match id:
		&"whip":
			# Lado do chicote: o mais perto do alvo; quebrado = golpe curto.
			var right: Vector3 = facing.cross(Vector3.UP).normalized()
			var side: StringName = &"whip_right" if right.dot(tpos - global_position) >= 0.0 else &"whip_left"
			_attack["length"] = WHIP_SHORT_LENGTH if is_part_broken(side) else WHIP_LENGTH
			_attack["side"] = side
		&"spear":
			_attack["center"] = _flat(tpos) + Vector3(0, global_position.y, 0)
		&"spores":
			_attack["center"] = _flat(tpos) + Vector3(0, global_position.y, 0)
	_show_telegraph(_attack)
	_change_state(State.WINDUP, windup_for(id))


## Tempo de aviso do ataque com a Fúria (nunca abaixo de MIN_WINDUP).
func windup_for(id: StringName) -> float:
	return maxf(float(ATTACKS[id][0]) / ENRAGE_MULT[enrage_level], MIN_WINDUP)


func _strike() -> void:
	_telegraph.visible = false
	for p: Player in _players():
		if is_in_attack_area(_attack, p.global_position):
			var kb: Vector3 = _flat(p.global_position - global_position).normalized() * 9.0
			var info := DamageInfo.new(int(_attack.damage), kb, self)
			if p.health.apply_damage(info) and _attack.id == &"spores":
				p.status.apply(StatusEffects.SLOW, 4.0, 0.4, self)
				p.status.apply(StatusEffects.POISON, 5.0, 5.0, self)
	if _attack.id == &"spear" and _queued_spears > 0:
		_queued_spears -= 1
		start_attack(&"spear")
		return
	if phase == 3 and _attack.id == &"spear":
		_change_state(State.PANT, PANT_TIME)  # ofegante: janela para bater no cerne
		return
	_change_state(State.RECOVER, RECOVER_TIME / ENRAGE_MULT[enrage_level])


## A posição está dentro da área do ataque? (geometria no chão)
func is_in_attack_area(attack: Dictionary, pos: Vector3) -> bool:
	var origin: Vector3 = attack.origin
	var rel: Vector3 = _flat(pos - origin)
	var dir: Vector3 = attack.dir
	match attack.id:
		&"whip":
			var forward: float = rel.dot(dir)
			var side: float = absf(rel.dot(dir.cross(Vector3.UP).normalized()))
			return forward >= 0.0 and forward <= float(attack.length) + 1.6 and side <= WHIP_WIDTH / 2.0 + 0.35
		&"sweep":
			return rel.length() <= SWEEP_RADIUS + 0.35 and (rel.length() < 0.01 or rel.normalized().dot(dir) >= -0.05)
		&"spear":
			return _flat(pos - attack.center).length() <= SPEAR_RADIUS + 0.35
		&"spores":
			return _flat(pos - attack.center).length() <= SPORE_RADIUS + 0.35
	return false


func _process_heal(delta: float) -> void:
	if status.is_disabled():
		_change_state(State.STUN, status.remaining(StatusEffects.STUN))
		return
	_heal_tick -= delta
	if _heal_tick <= 0.0:
		_heal_tick += 0.5
		health.heal(maxi(roundi(health.max_health * HEAL_PER_BULB_TICK * bulbs_alive()), 0))
	if _state_time >= _state_duration:
		_change_state(State.IDLE)


# --- Dano, partes, resistências -------------------------------------------------

## Golpe numa parte. Um mesmo golpe (mesma fonte, mesmo quadro) tira da vida
## total uma vez só, mesmo encostando em várias partes.
func apply_part_hit(part: BossPart, info: DamageInfo) -> bool:
	if part.broken and part.part_max_hp > 0:
		return false
	var key: int = info.source.get_instance_id() if is_instance_valid(info.source) else 0
	var frame: int = Engine.get_physics_frames()
	_current_part = part
	var ok: bool
	if not info.over_time and _hit_frames.get(key, -1) == frame:
		_modify_damage(info)
		ok = not health.is_dead and not health.is_invulnerable()
	else:
		_hit_frames[key] = frame
		ok = health.apply_damage(info)
	_current_part = null
	if ok:
		_damage_part(part, info.amount)
	return ok


## Multiplicador do elemento agora (muda com Molhada e sem casca).
func resist_multiplier(element: StringName) -> float:
	var m: float = BASE_RESIST.get(element, 1.0)
	if wet_left > 0.0:
		if element == &"fire":
			m = 1.0
		elif element == &"lightning":
			m = 1.35
	if element == &"earth" and is_part_broken(&"bark"):
		m = 1.0
	return m


func _modify_damage(info: DamageInfo) -> void:
	var m: float = resist_multiplier(info.element)
	if _current_part:
		m *= _current_part.damage_scale
	info.amount = maxi(roundi(info.amount * m), 1)
	info.set_meta(&"resist", m)


func _damage_part(part: BossPart, amount: int) -> void:
	if part.part_max_hp <= 0 or part.broken:
		return
	part.part_hp -= amount
	if state == State.HEAL and String(part.part_id).begins_with("bulb"):
		_heal_bulb_damage += amount
		if _heal_bulb_damage >= HEAL_INTERRUPT_DAMAGE:
			_change_state(State.RECOVER, 1.0)  # cura interrompida
	if part.part_hp <= 0:
		break_part(part.part_id)


## Quebra uma parte: consequência no corpo e na luta + material garantido.
func break_part(id: StringName) -> void:
	var part: BossPart = parts[id]
	if part.broken or part.part_max_hp <= 0:
		return
	part.broken = true
	part.part_hp = 0
	part.set_hittable(false)
	var visual: Node3D = part.get_node_or_null("Visual")
	if visual:
		visual.visible = false
	match id:
		&"mouth":
			apply_stun(4.0)
			_drop(&"altar_thorn")
		&"whip_left", &"whip_right":
			_drop(&"living_branch")
		&"bark":
			_expose_core()
			_drop(&"ancestral_bark")
		_:
			_drop(&"crimson_sap")
	part_broken.emit(id)


func is_part_broken(id: StringName) -> bool:
	return parts.has(id) and (parts[id] as BossPart).broken


func bulbs_alive() -> int:
	var n: int = 0
	for id: StringName in [&"bulb_1", &"bulb_2", &"bulb_3"]:
		if not is_part_broken(id):
			n += 1
	return n


func _expose_core() -> void:
	(parts[&"bark"] as BossPart).broken = true
	(parts[&"bark"] as BossPart).set_hittable(false)
	(parts[&"core"] as BossPart).set_hittable(true)
	_core_mesh.visible = true
	_bark_material.albedo_color = BARK_COLOR.lerp(Color(0.5, 0.1, 0.08), 0.5)
	if phase < 3:
		_enter_phase(3)


func _on_damaged(info: DamageInfo) -> void:
	if is_instance_valid(info.source) and info.source is Player:
		_last_attacker = info.source
		if target == null:
			target = info.source
	_show_damage_number(info)


## Número de dano: tamanho e cor pela força (fraqueza = grande e quente; resistência = pequeno e apagado).
func _show_damage_number(info: DamageInfo) -> void:
	var m: float = float(info.get_meta(&"resist", 1.0))
	var color := Color(1.0, 0.95, 0.8)
	var size: int = 12
	if m >= 1.3:
		color = Color(1.0, 0.55, 0.15)
		size = 18
	elif m < 0.9:
		color = Color(0.6, 0.6, 0.65)
		size = 8
	var parent: Node = info.source if is_instance_valid(info.source) else get_parent()
	FloatingText.spawn(parent, str(info.amount), global_position + Vector3(randf_range(-0.8, 0.8), 6.6, 0), color, size)


func _on_health_changed(current: int, maximum: int) -> void:
	_bar.size.x = 300.0 * float(current) / float(maxi(maximum, 1))
	# Vida zero: o aviso de vida chega antes de "morto" ser marcado; nada de fase/rugido.
	if health.is_dead or current <= 0:
		return
	var ratio: float = float(current) / float(maximum)
	var new_enrage: int = 0
	for t: float in ENRAGE_THRESHOLDS:
		if ratio <= t:
			new_enrage += 1
	var roar: float = 0.0
	if new_enrage > enrage_level:
		enrage_level = new_enrage
		roar = ENRAGE_ROAR_TIME
	if phase < 2 and ratio <= PHASE_2_AT:
		_enter_phase(2)
	elif phase < 3 and ratio <= PHASE_3_AT:
		if not is_part_broken(&"bark"):
			(parts[&"bark"] as BossPart).part_max_hp = 1
			break_part(&"bark")  # a casca se parte sozinha
		else:
			_enter_phase(3)
	elif roar > 0.0 and state != State.ROAR:
		_telegraph.visible = false
		_change_state(State.ROAR, roar)


## Troca de fase: rugido de 1,5 s, parada e invulnerável (respiro para o grupo).
func _enter_phase(new_phase: int) -> void:
	if health.is_dead or health.current_health <= 0:
		return  # golpe final quebrando a casca não pode tirar o chefe do estado de morte
	phase = new_phase
	_telegraph.visible = false
	_queued_spears = 0
	health.set_invulnerable(true)
	_change_state(State.ROAR, PHASE_ROAR_TIME)
	phase_changed.emit(phase)


func _on_died() -> void:
	# Morto e desaparecendo não conta mais como chefe em luta (não bloqueia outro).
	remove_from_group(GROUP)
	remove_from_group(BasicEnemy.GROUP)
	_telegraph.visible = false
	_change_state(State.DEAD)
	for s: BasicEnemy in _sprouts:
		if is_instance_valid(s):
			s.health.apply_damage(DamageInfo.new(99999))
	if randf() < rare_drop_chance:
		_drop(&"sprouted_heart")
	if is_instance_valid(_last_attacker):
		_last_attacker.on_enemy_defeated(&"khar_vesh", XP_REWARD)
	_bar_layer.queue_free()
	died.emit()


func _drop(item_id: StringName) -> void:
	var data: ItemData = load(ITEMS + String(item_id) + ".tres")
	if data and get_parent():
		var at: Vector3 = global_position + Vector3(randf_range(-2.5, 2.5), 0.2, randf_range(-1.0, 3.5))
		ItemPickup.spawn(get_parent(), ItemStack.create(data), at)


# --- Controle (Provocar, atordoar) -----------------------------------------------

func apply_stun(seconds: float) -> void:
	if health.is_dead or state == State.ROAR:
		return
	_telegraph.visible = false
	_queued_spears = 0
	status.apply(StatusEffects.STUN, seconds)
	_change_state(State.STUN, seconds)


func apply_taunt(by: Player, seconds: float) -> void:
	if health.is_dead:
		return
	_taunted_by = by
	_taunt_left = seconds
	target = by
	status.apply(StatusEffects.TAUNT, seconds, 0.0, by)


func is_taunted_by(player: Player) -> bool:
	return _taunt_left > 0.0 and _taunted_by == player


func reset_to_spawn() -> void:
	pass  # o chefe não volta: continuar depois de morrer mantém a luta como está


# --- Auxiliares -------------------------------------------------------------------

func _change_state(new_state: State, duration: float = 0.0) -> void:
	if state == State.ROAR and new_state != State.ROAR:
		health.set_invulnerable(false)
	state = new_state
	_state_time = 0.0
	_state_duration = duration


func _update_target() -> void:
	if _taunt_left > 0.0 and is_instance_valid(_taunted_by) and not _taunted_by.health.is_dead:
		target = _taunted_by
		return
	if is_instance_valid(target) and not target.health.is_dead:
		return
	target = null
	var best_d: float = 30.0
	for p: Player in _players():
		var d: float = p.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			target = p


func _players() -> Array[Player]:
	var list: Array[Player] = []
	for node: Node in get_tree().get_nodes_in_group(Player.GROUP):
		var p := node as Player
		if p and not p.health.is_dead:
			list.append(p)
	return list


func _face_target(delta: float) -> void:
	if target == null:
		return
	var want: Vector3 = _flat(target.global_position - global_position).normalized()
	if want == Vector3.ZERO:
		return
	facing = facing.slerp(want, clampf(TURN_RATE * delta, 0.0, 1.0)).normalized()
	_model.rotation.y = Player.yaw_of(facing)


func _near_puddle() -> bool:
	for node: Node in get_tree().get_nodes_in_group(DungeonMap.PUDDLE_GROUP):
		var n := node as Node3D
		if n and _flat(n.global_position - global_position).length() <= WET_PUDDLE_RANGE:
			return true
	return false


func _spawn_sprouts(count: int) -> void:
	var scene: PackedScene = load("res://game/actors/enemies/basic_enemy/basic_enemy.tscn")
	for i in count:
		var sprout: BasicEnemy = scene.instantiate()
		sprout.name = "Broto%d" % (_sprouts.size() + 1)
		get_parent().add_child(sprout)
		sprout.global_position = global_position + facing.rotated(Vector3.UP, (i - 0.5) * 1.2) * 3.0
		sprout.scale_stats(60, 15, 20)
		sprout.get_node("Model").scale = Vector3.ONE * 0.6
		_sprouts.append(sprout)


func _alive_sprouts() -> int:
	var n: int = 0
	for s: BasicEnemy in _sprouts:
		if is_instance_valid(s) and not s.health.is_dead:
			n += 1
	return n


func _show_telegraph(attack: Dictionary) -> void:
	var mesh: Mesh
	var pos: Vector3
	var yaw: float = Player.yaw_of(attack.dir)
	match attack.id:
		&"whip":
			var box := BoxMesh.new()
			box.size = Vector3(WHIP_WIDTH, 0.03, float(attack.length))
			mesh = box
			pos = global_position + Vector3(attack.dir) * (float(attack.length) / 2.0 + 1.2)
		&"sweep":
			var cyl := CylinderMesh.new()
			cyl.top_radius = SWEEP_RADIUS
			cyl.bottom_radius = SWEEP_RADIUS
			cyl.height = 0.03
			mesh = cyl
			pos = global_position
		&"spear":
			var c := CylinderMesh.new()
			c.top_radius = SPEAR_RADIUS
			c.bottom_radius = SPEAR_RADIUS
			c.height = 0.03
			mesh = c
			pos = attack.center
		&"spores":
			var s := CylinderMesh.new()
			s.top_radius = SPORE_RADIUS
			s.bottom_radius = SPORE_RADIUS
			s.height = 0.03
			mesh = s
			pos = attack.center
	_telegraph.mesh = mesh
	_telegraph.global_position = Vector3(pos.x, global_position.y + 0.05, pos.z)
	_telegraph.global_rotation = Vector3(0, yaw, 0)
	_telegraph_material.albedo_color = SPORE_TELEGRAPH_COLOR if attack.id == &"spores" else TELEGRAPH_COLOR
	_telegraph.visible = true


func _update_visuals() -> void:
	_aura.light_energy = [0.0, 0.6, 1.4, 2.6][enrage_level]
	if not is_part_broken(&"bark"):
		_bark_material.albedo_color = WET_BARK_COLOR if wet_left > 0.0 else BARK_COLOR
		_bark_material.metallic = 0.7 if wet_left > 0.0 else 0.0
		_bark_material.roughness = 0.15 if wet_left > 0.0 else 1.0
	if state == State.HEAL:
		var pulse: float = 1.0 + 0.25 * sin(_state_time * 14.0)
		for id: StringName in [&"bulb_1", &"bulb_2", &"bulb_3"]:
			(parts[id] as Node3D).scale = Vector3.ONE * pulse
	if _core_mesh.visible:
		_core_mesh.scale = Vector3.ONE * (1.0 + 0.1 * sin(_state_time * 6.0))


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


static func _mat(color: Color, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
	return m


static func _mesh_cylinder(r: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r * 0.8
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.material_override = mat
	return mi


static func _mesh_sphere(r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.material_override = mat
	return mi
