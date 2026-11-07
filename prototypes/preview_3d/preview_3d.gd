extends Node3D
## PROTÓTIPO 3D (só para visualizar) — NÃO faz parte do jogo.
##
## Pedido do proprietário: "crie algo pequeno só para eu ver como seria" um
## modo 3D em terceira pessoa. Tudo é montado por código com formas simples
## (cápsulas, caixas) — nenhuma arte. Reaproveita as ações de controle do jogo.
##
## Controles: WASD anda (relativo à câmera), mouse gira a câmera, clique ataca,
## Espaço esquiva, Esc solta/prende o mouse.

const MOUSE_SENSITIVITY: float = 0.004
const PLAYER_SPEED: float = 5.0
const DODGE_SPEED: float = 13.0
const DODGE_TIME: float = 0.24
const ATTACK_TIME: float = 0.3
const ATTACK_RANGE: float = 2.3
const ATTACK_HALF_ANGLE: float = 70.0
const GRAVITY: float = 20.0
const ENEMY_SPEED: float = 2.6
const ENEMY_DETECT: float = 14.0
const ENEMY_ATTACK_RANGE: float = 2.4
const ENEMY_WINDUP: float = 0.6
const ENEMY_LUNGE_SPEED: float = 11.0
const ENEMY_LUNGE_TIME: float = 0.25
const ENEMY_MAX_HP: int = 40

var player: CharacterBody3D
var enemy: CharacterBody3D
var _model: Node3D
var _sword: MeshInstance3D
var _yaw: Node3D
var _pitch: Node3D
var _camera: Camera3D
var _hud: Label
var _player_hp: int = 100
var _attack_left: float = 0.0
var _attack_hit_done: bool = false
var _dodge_left: float = 0.0
var _dodge_dir: Vector3 = Vector3.ZERO

var _enemy_hp: int = ENEMY_MAX_HP
var _enemy_state: String = "idle"
var _enemy_time: float = 0.0
var _enemy_dir: Vector3 = Vector3.FORWARD
var _enemy_mesh: MeshInstance3D
var _enemy_bar: Label3D
var _telegraph: MeshInstance3D
var _enemy_hit_done: bool = false


func _ready() -> void:
	_build_world()
	_build_player()
	_build_enemy()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- Montagem -------------------------------------------------------------

func _material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func _box(size: Vector3, pos: Vector3, color: Color, solid: bool = true) -> Node3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _material(color)
	if not solid:
		mesh.position = pos
		add_child(mesh)
		return mesh
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	body.add_child(mesh)
	add_child(body)
	return body


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.04, 0.035, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.33, 0.42)
	e.ambient_light_energy = 0.6
	e.fog_enabled = true
	e.fog_light_color = Color(0.08, 0.07, 0.1)
	e.fog_density = 0.035
	env.environment = e
	add_child(env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, -30, 0)
	moon.light_color = Color(0.6, 0.65, 0.85)
	moon.light_energy = 0.5
	moon.shadow_enabled = true
	add_child(moon)
	# Chão e muros da arena (pedra escura), pilares.
	_box(Vector3(40, 1, 40), Vector3(0, -0.5, 0), Color(0.22, 0.21, 0.24))
	for side: Array in [[Vector3(40, 3, 1), Vector3(0, 1.5, -20)], [Vector3(40, 3, 1), Vector3(0, 1.5, 20)],
			[Vector3(1, 3, 40), Vector3(-20, 1.5, 0)], [Vector3(1, 3, 40), Vector3(20, 1.5, 0)]]:
		_box(side[0], side[1], Color(0.42, 0.36, 0.3))
	for p: Vector3 in [Vector3(-6, 1.5, -6), Vector3(6, 1.5, -6), Vector3(-6, 1.5, 6), Vector3(6, 1.5, 6)]:
		_box(Vector3(1.4, 3, 1.4), p, Color(0.5, 0.45, 0.4))
		var torch := OmniLight3D.new()
		torch.position = p + Vector3(0, 1.0, 0.9)
		torch.light_color = Color(1.0, 0.6, 0.25)
		torch.light_energy = 1.6
		torch.omni_range = 7.0
		add_child(torch)
		var flame := _box(Vector3(0.15, 0.3, 0.15), torch.position, Color(1.0, 0.55, 0.2), false) as MeshInstance3D
		flame.material_override = _material(Color(1.0, 0.55, 0.2), 3.0)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player3D"
	player.position = Vector3(0, 1, 8)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.0
	player.add_child(shape)
	_model = Node3D.new()
	player.add_child(_model)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.8
	body.mesh = cm
	body.material_override = _material(Color(0.36, 0.62, 0.92))
	_model.add_child(body)
	var visor := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.5, 0.12, 0.1)
	visor.mesh = vm
	visor.position = Vector3(0, 0.55, -0.38)
	visor.material_override = _material(Color(1.0, 0.85, 0.3), 1.5)
	_model.add_child(visor)
	_sword = MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.08, 0.08, 1.1)
	_sword.mesh = sm
	_sword.position = Vector3(0.5, 0.1, -0.5)
	_sword.material_override = _material(Color(0.85, 0.88, 0.95))
	_model.add_child(_sword)
	add_child(player)
	# Câmera em terceira pessoa: yaw (horizontal) -> pitch (vertical) -> braço com colisão.
	_yaw = Node3D.new()
	_yaw.position = Vector3(0, 1.2, 0)
	player.add_child(_yaw)
	_pitch = Node3D.new()
	_pitch.rotation_degrees.x = -18.0
	_yaw.add_child(_pitch)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.0
	arm.margin = 0.3
	arm.add_excluded_object(player.get_rid())
	_pitch.add_child(arm)
	_camera = Camera3D.new()
	_camera.fov = 65.0
	arm.add_child(_camera)


func _build_enemy() -> void:
	enemy = CharacterBody3D.new()
	enemy.name = "Enemy3D"
	enemy.position = Vector3(0, 1, -8)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.55
	cap.height = 1.6
	shape.shape = cap
	enemy.add_child(shape)
	_enemy_mesh = MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.55
	cm.height = 1.6
	_enemy_mesh.mesh = cm
	_enemy_mesh.material_override = _material(Color(0.78, 0.25, 0.25))
	enemy.add_child(_enemy_mesh)
	var eye := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(0.6, 0.12, 0.1)
	eye.mesh = em
	eye.position = Vector3(0, 0.4, -0.52)
	eye.material_override = _material(Color(1.0, 0.9, 0.6), 2.0)
	enemy.add_child(eye)
	_enemy_bar = Label3D.new()
	_enemy_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_enemy_bar.position = Vector3(0, 1.3, 0)
	_enemy_bar.font_size = 48
	_enemy_bar.modulate = Color(1.0, 0.35, 0.3)
	enemy.add_child(_enemy_bar)
	add_child(enemy)
	# Aviso no chão: faixa vermelha do caminho da investida.
	_telegraph = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.2, ENEMY_LUNGE_SPEED * ENEMY_LUNGE_TIME + 0.6)
	_telegraph.mesh = pm
	var tm := _material(Color(1.0, 0.15, 0.1), 1.0)
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.albedo_color.a = 0.35
	_telegraph.material_override = tm
	_telegraph.visible = false
	add_child(_telegraph)
	_update_enemy_bar()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(8, 6)
	_hud.add_theme_font_size_override("font_size", 12)
	_hud.add_theme_constant_override("outline_size", 4)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	layer.add_child(_hud)
	var help := Label.new()
	help.text = "PROTÓTIPO 3D (só visualização) — WASD andar | mouse câmera | clique atacar | Espaço esquivar | Esc solta o mouse"
	# O projeto desenha em 640x360 e amplia (pixel art); a ajuda fica no rodapé dessa tela.
	help.position = Vector2(8, 344)
	help.add_theme_font_size_override("font_size", 8)
	help.add_theme_constant_override("outline_size", 3)
	help.add_theme_color_override("font_outline_color", Color.BLACK)
	layer.add_child(help)


# --- Loop -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw.rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		_pitch.rotation.x = clampf(_pitch.rotation.x - motion.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-60), deg_to_rad(10))
	elif event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_process_player(delta)
	_process_enemy(delta)
	_hud.text = "Vida: %d" % _player_hp + ("     (você caiu — voltando...)" if _player_hp <= 0 else "")


## Direção de movimento relativa à câmera (para frente = para onde a câmera olha).
func move_direction() -> Vector3:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var basis: Basis = _yaw.global_transform.basis
	var dir: Vector3 = (basis.x * input.x + basis.z * input.y)
	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.01 else Vector3.ZERO


func _process_player(delta: float) -> void:
	if _player_hp <= 0:
		return
	var dir: Vector3 = move_direction()
	if _dodge_left > 0.0:
		_dodge_left -= delta
		player.velocity.x = _dodge_dir.x * DODGE_SPEED
		player.velocity.z = _dodge_dir.z * DODGE_SPEED
		_model.scale = Vector3(1.0, 0.6, 1.0)
	else:
		_model.scale = Vector3.ONE
		var speed: float = PLAYER_SPEED * (0.3 if _attack_left > 0.0 else 1.0)
		player.velocity.x = dir.x * speed
		player.velocity.z = dir.z * speed
		if Input.is_action_just_pressed("dodge"):
			_dodge_dir = dir if dir != Vector3.ZERO else -_model.global_transform.basis.z
			_dodge_left = DODGE_TIME
		elif Input.is_action_just_pressed("attack") and _attack_left <= 0.0 and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_attack_left = ATTACK_TIME
			_attack_hit_done = false
			# Ataca para onde a câmera olha.
			var look: Vector3 = -_yaw.global_transform.basis.z
			_model.look_at(_model.global_position + Vector3(look.x, 0, look.z), Vector3.UP)
	if dir != Vector3.ZERO and _attack_left <= 0.0 and _dodge_left <= 0.0:
		_model.look_at(_model.global_position + dir, Vector3.UP)
	if _attack_left > 0.0:
		_attack_left -= delta
		var t: float = 1.0 - _attack_left / ATTACK_TIME
		_sword.rotation.y = lerpf(1.3, -1.3, t)  # arco da espada
		if not _attack_hit_done and t > 0.3:
			_attack_hit_done = true
			_try_hit_enemy()
	else:
		_sword.rotation.y = 0.0
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	player.move_and_slide()


func _try_hit_enemy() -> void:
	if _enemy_hp <= 0:
		return
	var to_enemy: Vector3 = enemy.global_position - player.global_position
	to_enemy.y = 0.0
	var forward: Vector3 = -_model.global_transform.basis.z
	if to_enemy.length() <= ATTACK_RANGE and rad_to_deg(forward.angle_to(to_enemy)) <= ATTACK_HALF_ANGLE:
		var damage: int = 10
		# Costas: igual ao jogo 2D, x1,5.
		var enemy_forward: Vector3 = -enemy.global_transform.basis.z
		if rad_to_deg(enemy_forward.angle_to(-to_enemy)) >= 120.0:
			damage = 15
		_enemy_hp = maxi(_enemy_hp - damage, 0)
		_damage_number(enemy.global_position + Vector3(0, 1.6, 0), damage, damage > 10)
		enemy.velocity = to_enemy.normalized() * 6.0
		_enemy_state = "hurt"
		_enemy_time = 0.0
		_update_enemy_bar()
		if _enemy_hp == 0:
			_enemy_state = "dead"


func _process_enemy(delta: float) -> void:
	_enemy_time += delta
	var to_player: Vector3 = player.global_position - enemy.global_position
	to_player.y = 0.0
	var mat := _enemy_mesh.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.78, 0.25, 0.25)
	match _enemy_state:
		"idle":
			enemy.velocity = Vector3.ZERO
			if to_player.length() < ENEMY_DETECT and _player_hp > 0:
				_enemy_state = "chase"
		"chase":
			if _player_hp <= 0:
				_enemy_state = "idle"
			elif to_player.length() <= ENEMY_ATTACK_RANGE:
				_enemy_state = "windup"
				_enemy_time = 0.0
				enemy.velocity = Vector3.ZERO
			else:
				enemy.velocity = to_player.normalized() * ENEMY_SPEED
				enemy.look_at(enemy.global_position + to_player, Vector3.UP)
		"windup":
			# Mira acompanha e trava nos últimos 0,2 s (igual ao 2D).
			if _enemy_time < ENEMY_WINDUP - 0.2 and to_player.length() > 0.1:
				_enemy_dir = to_player.normalized()
				enemy.look_at(enemy.global_position + _enemy_dir, Vector3.UP)
			mat.albedo_color = Color(1.0, 0.6, 0.15)
			_telegraph.visible = true
			var length: float = ENEMY_LUNGE_SPEED * ENEMY_LUNGE_TIME + 0.6
			var center: Vector3 = enemy.global_position + _enemy_dir * (length / 2.0)
			_telegraph.global_position = Vector3(center.x, 0.02, center.z)  # rente ao chão
			_telegraph.look_at(_telegraph.global_position + _enemy_dir, Vector3.UP)
			if _enemy_time >= ENEMY_WINDUP:
				_enemy_state = "lunge"
				_enemy_time = 0.0
				_enemy_hit_done = false
				_telegraph.visible = false
		"lunge":
			enemy.velocity = _enemy_dir * ENEMY_LUNGE_SPEED
			if not _enemy_hit_done and to_player.length() < 1.3 and _dodge_left <= 0.06 and _player_hp > 0:
				_enemy_hit_done = true
				_player_hp = maxi(_player_hp - 15, 0)
				_damage_number(player.global_position + Vector3(0, 1.4, 0), 15, false, Color(1.0, 0.35, 0.3))
				player.velocity += _enemy_dir * 8.0
				if _player_hp == 0:
					get_tree().create_timer(2.0).timeout.connect(_reset_player)
			if _enemy_time >= ENEMY_LUNGE_TIME:
				_enemy_state = "recover"
				_enemy_time = 0.0
		"recover", "hurt":
			enemy.velocity = enemy.velocity.move_toward(Vector3.ZERO, 30.0 * delta)
			if _enemy_time >= (0.7 if _enemy_state == "recover" else 0.3):
				_enemy_state = "chase"
		"dead":
			enemy.velocity = Vector3.ZERO
			_telegraph.visible = false
			enemy.scale = enemy.scale.move_toward(Vector3(1, 0.05, 1), delta * 3.0)
			if _enemy_time >= 3.0:
				_respawn_enemy()
	if not enemy.is_on_floor():
		enemy.velocity.y -= GRAVITY * delta
	enemy.move_and_slide()


func _damage_number(at: Vector3, amount: int, backstab: bool, color: Color = Color.WHITE) -> void:
	var label := Label3D.new()
	label.text = str(amount)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64 if backstab else 48
	label.modulate = Color(1.0, 0.55, 0.2) if backstab else color
	label.outline_size = 12
	add_child(label)
	label.global_position = at + Vector3(randf_range(-0.3, 0.3), 0, 0)
	var tween := create_tween()
	tween.tween_property(label, "global_position:y", at.y + 1.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func _update_enemy_bar() -> void:
	var filled: int = int(round(10.0 * _enemy_hp / ENEMY_MAX_HP))
	_enemy_bar.text = "|".repeat(filled) + ".".repeat(10 - filled)
	_enemy_bar.visible = _enemy_hp > 0


func _respawn_enemy() -> void:
	_enemy_hp = ENEMY_MAX_HP
	enemy.scale = Vector3.ONE
	enemy.global_position = Vector3(randf_range(-8, 8), 1, -8)
	_enemy_state = "idle"
	_update_enemy_bar()


func _reset_player() -> void:
	_player_hp = 100
	player.global_position = Vector3(0, 1, 8)
	player.velocity = Vector3.ZERO
