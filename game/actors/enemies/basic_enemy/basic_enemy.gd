class_name BasicEnemy
extends CharacterBody3D
## Inimigo básico de teste (PROVISÓRIO: sem arte, sem identidade definida). 3D.
##
## Comportamento: fica parado até ver um jogador; persegue; ao chegar perto,
## avisa o ataque (fica laranja e pulsa) e dá uma investida em linha reta.
## Depois da investida fica vulnerável por um instante. Apanhar interrompe
## qualquer ação. O aviso existe para que a esquiva (ou a defesa) seja uma
## resposta justa: durante a preparação aparece no chão o caminho exato da
## investida; a mira acompanha o jogador e trava no fim da preparação.
## Investida bloqueada pelo escudo deixa o inimigo atordoado.
## Toda a lógica acontece no chão (X/Z); a altura só é usada pela gravidade.

signal died

const GROUP: StringName = &"enemies"

enum State { IDLE, CHASE, WINDUP, LUNGE, RECOVER, HURT, STAGGER, DEAD }

const GRAVITY: float = 20.0
const BODY_COLOR := Color(0.78, 0.25, 0.25)
const WINDUP_COLOR := Color(1.0, 0.6, 0.15)
const STAGGER_COLOR := Color(0.55, 0.5, 0.7)
const TELEGRAPH_TRACKING_COLOR := Color(1.0, 0.2, 0.15, 0.25)
const TELEGRAPH_LOCKED_COLOR := Color(1.0, 0.2, 0.15, 0.55)
## Metade da largura da LungeHitbox: a faixa cobre tudo que a investida toca.
const LUNGE_HALF_WIDTH: float = 0.45
## Camada "world" (paredes): é o que bloqueia a visão.
const SIGHT_BLOCKING_MASK: int = 1
## A visão sai da altura do tronco, não dos pés.
const EYE_HEIGHT: float = 0.6
## Altura onde aparecem os números de dano.
const TEXT_HEIGHT: float = 1.6

@export_group("Percepção")
## Distância em que o inimigo nota um jogador (m).
@export var detect_radius: float = 8.1
## Distância em que desiste da perseguição (m).
@export var lose_radius: float = 13.75
## Só nota um jogador se não houver parede entre os dois.
@export var requires_line_of_sight: bool = true

@export_group("Movimento")
@export var move_speed: float = 2.8
@export var acceleration: float = 25.0
@export var friction: float = 44.0

@export_group("Ataque")
## Distância a partir da qual começa a investida (m).
@export var attack_range: float = 2.5
## Duração do aviso antes da investida (s).
@export var windup_time: float = 0.45
## Parte final do aviso em que a direção já está travada (s). Antes disso a
## mira acompanha o jogador.
@export var aim_lock_time: float = 0.2
@export var lunge_speed: float = 11.9
@export var lunge_time: float = 0.22
## Tempo parado e vulnerável depois da investida (s).
@export var recover_time: float = 0.6

@export_group("Dano recebido")
@export var hurt_time: float = 0.25
## Tempo atordoado depois de ter a investida bloqueada: janela de contra-ataque (s).
@export var stagger_time: float = 0.7
## Velocidade do recuo ao bater no escudo (m/s).
@export var blocked_recoil_speed: float = 9.4

@export_group("Ponto fraco")
## Golpes vindos de trás causam mais dano (vale para monstros e chefes).
@export var backstab_multiplier: float = 1.5
## Ângulo (graus, a partir da frente) a partir do qual o golpe conta como "pelas costas".
@export var backstab_angle: float = 120.0

@export_group("Recompensa")
## Experiência dada a quem derrotou este inimigo.
@export var xp_reward: int = 10
## Tipo do inimigo (usado por missões "derrote N do tipo X").
@export var kind: StringName = &"basic_enemy"
@export var death_fade_time: float = 0.4

@export_group("Aparência")
## Modelo com esqueleto e animações (KayKit). Vazio = cubo provisório.
@export var model_scene: PackedScene
@export var model_scale: float = 1.0
## Com modelo, o corpo fica um pouco mais no chão antes de sumir (animação de morte).
@export var model_death_time: float = 1.4

## Animação por estado (modelo com esqueleto).
const ANIMS: Dictionary = {
	State.IDLE: "Idle", State.CHASE: "Running_A", State.WINDUP: "1H_Melee_Attack_Stab",
	State.LUNGE: "1H_Melee_Attack_Stab", State.RECOVER: "Idle_Combat", State.HURT: "Hit_A",
	State.STAGGER: "Hit_B", State.DEAD: "Death_C_Skeletons",
}
const LOOPING_ANIMS: Array[String] = ["Idle", "Running_A", "Idle_Combat"]

var state: State = State.IDLE
var target: Player = null
## Para onde o inimigo está virado (a seta mostra). Define o que é "costas".
var facing: Vector3 = Vector3.BACK

var _state_time: float = 0.0
var _lunge_direction: Vector3 = Vector3.ZERO
var _flash_time: float = 0.0
## Último jogador que causou dano: recebe a experiência na morte.
var _last_attacker: Player = null
## Onde o inimigo começou (volta para cá quando o jogador continua após morrer).
var _spawn_position: Vector3 = Vector3.ZERO
var _body_material: StandardMaterial3D
## Duração do atordoamento atual (bloqueio de investida ou Golpe de escudo).
var _stagger_duration: float = 0.0
## Provocado: segue este jogador até o tempo acabar, mesmo longe.
var _taunted_by: Player = null
var _taunt_left: float = 0.0
var _telegraph_material: StandardMaterial3D
var _skin: Node3D
var _anim: AnimationPlayer
var _overlay: StandardMaterial3D
var _anim_state: int = -1
## Efeitos de status ativos. Criado no _ready.
var status: StatusEffects

@onready var health: HealthComponent = $HealthComponent
@onready var _hitbox: Hitbox = $LungeHitbox
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _body_shape: CollisionShape3D = $CollisionShape
@onready var _model: Node3D = $Model
@onready var _body: MeshInstance3D = $Model/BodyPlaceholder
@onready var _health_bar: HealthBar3D = $HealthBar
@onready var _telegraph: MeshInstance3D = $LungeTelegraph


func _ready() -> void:
	add_to_group(GROUP)
	_stagger_duration = stagger_time
	_body_material = (_body.material_override as StandardMaterial3D).duplicate()
	_body.material_override = _body_material
	_telegraph_material = (_telegraph.material_override as StandardMaterial3D).duplicate()
	_telegraph.material_override = _telegraph_material
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	_hitbox.hit_blocked.connect(_on_lunge_blocked)
	_health_bar.visible = true
	_spawn_position = global_position
	health.damage_modifier = _apply_backstab
	_build_telegraph()
	_build_skin()
	status = StatusEffects.attach(self, health, TEXT_HEIGHT + 0.35)
	status.effect_started.connect(_on_status_started)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_taunt_left = maxf(_taunt_left - delta, 0.0)
	if _taunt_left > 0.0 and _is_valid_target(_taunted_by):
		target = _taunted_by
	var vertical: float = velocity.y
	velocity.y = 0.0
	var scared_of: Node3D = status.fear_source()
	if scared_of and state != State.DEAD and state != State.STAGGER:
		# Medo: foge de quem assustou e não ataca.
		if state != State.CHASE:
			_change_state(State.CHASE)
		var away: Vector3 = _flat(global_position - scared_of.global_position).normalized()
		velocity = velocity.move_toward(away * move_speed * status.speed_multiplier(), acceleration * delta)
		facing = away if away != Vector3.ZERO else facing
	else:
		_process_state(delta)
	_update_facing()
	velocity.y = vertical - GRAVITY * delta if not is_on_floor() else minf(vertical, 0.0)
	move_and_slide()
	_update_visuals(delta)


func _process_state(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
			if not (_taunt_left > 0.0 and _is_valid_target(_taunted_by)):
				target = _find_target(detect_radius)
			if target:
				_change_state(State.CHASE)
		State.CHASE:
			_process_chase(delta)
		State.WINDUP:
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
			if not is_aim_locked():
				_aim_at_target()
			if _state_time >= windup_time:
				_start_lunge()
		State.LUNGE:
			velocity = _lunge_direction * lunge_speed * status.speed_multiplier()
			if _state_time >= lunge_time:
				_change_state(State.RECOVER)
		State.RECOVER:
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
			if _state_time >= recover_time:
				_change_state(State.CHASE)
		State.HURT:
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
			if _state_time >= hurt_time:
				_change_state(State.CHASE)
		State.STAGGER:
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
			if _state_time >= _stagger_duration:
				_change_state(State.CHASE)
		State.DEAD:
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
			if _skin:
				# A animação de morte desmonta o esqueleto; depois some.
				if _state_time >= model_death_time:
					queue_free()
			else:
				var t: float = clampf(_state_time / death_fade_time, 0.0, 1.0)
				_model.scale = Vector3(1.0, 1.0 - 0.9 * t, 1.0)
				if _state_time >= death_fade_time:
					queue_free()


## Vira para o alvo enquanto persegue/prepara; na investida, para a direção dela.
## Atordoado ou ferido, mantém a direção (as costas ficam expostas).
func _update_facing() -> void:
	var wanted := Vector3.ZERO
	match state:
		State.CHASE, State.WINDUP:
			if _is_valid_target(target):
				wanted = _flat(target.global_position - global_position)
		State.LUNGE:
			wanted = _lunge_direction
	if wanted.length() > 0.001:
		facing = wanted.normalized()
	_model.rotation.y = Player.yaw_of(facing)


## Golpe de trás causa mais dano. "Trás" = mais de backstab_angle graus da frente.
func _apply_backstab(info: DamageInfo) -> void:
	if not is_instance_valid(info.source) or not (info.source is Node3D):
		return
	var to_attacker: Vector3 = _flat((info.source as Node3D).global_position - global_position)
	if to_attacker.length() < 0.001:
		return
	if rad_to_deg(facing.angle_to(to_attacker.normalized())) >= backstab_angle:
		info.amount = roundi(info.amount * backstab_multiplier)
		info.backstab = true


func _process_chase(delta: float) -> void:
	var taunted: bool = _taunt_left > 0.0 and _is_valid_target(_taunted_by)
	if not taunted and (not _is_valid_target(target) or global_position.distance_to(target.global_position) > lose_radius):
		target = _find_target(detect_radius)
		if target == null:
			_change_state(State.IDLE)
			return
	var to_target: Vector3 = _flat(target.global_position - global_position)
	if to_target.length() <= attack_range:
		_change_state(State.WINDUP)
		_aim_at_target()
		return
	velocity = velocity.move_toward(to_target.normalized() * move_speed * status.speed_multiplier(), acceleration * delta)


## Troca o cubo provisório pelo modelo com esqueleto (se houver).
func _build_skin() -> void:
	if model_scene == null:
		return
	_skin = model_scene.instantiate() as Node3D
	_skin.name = "Skin"
	_skin.rotation.y = PI  # modelos olham para +Z; o jogo usa -Z
	_skin.scale = Vector3.ONE * model_scale
	_model.add_child(_skin)
	_body.visible = false
	_overlay = StandardMaterial3D.new()
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.albedo_color = Color(1, 1, 1, 0)
	for mesh: Node in _skin.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = _overlay
	var players: Array[Node] = _skin.find_children("*", "AnimationPlayer", true, false)
	_anim = players[0] as AnimationPlayer if not players.is_empty() else null


## Animação do estado (reinicia ao trocar de estado; ajusta ao tempo do golpe).
func _update_animation() -> void:
	if _anim == null:
		return
	var name: String = ANIMS.get(state, "Idle")
	if state == _anim_state or not _anim.has_animation(name):
		if state == State.CHASE:
			_anim.speed_scale = clampf(_flat(velocity).length() / maxf(move_speed, 0.1), 0.5, 1.3)
		return
	if state == State.LUNGE and _anim.current_animation == name:
		_anim_state = state  # a investida continua o mesmo golpe da preparação
		return
	_anim_state = state
	var anim: Animation = _anim.get_animation(name)
	if LOOPING_ANIMS.has(name):
		anim.loop_mode = Animation.LOOP_LINEAR
	var fit: float = 0.0
	match state:
		State.WINDUP:
			fit = windup_time + lunge_time
		State.HURT:
			fit = hurt_time
	_anim.speed_scale = clampf(anim.length / fit, 0.3, 3.0) if fit > 0.0 else 1.0
	_anim.play(name, 0.1)


## Animação tocando agora ("" sem modelo). Usado por testes.
func current_animation() -> String:
	return _anim.current_animation if _anim else ""


## Força do inimigo (masmorras): vida, dano da investida e experiência.
func scale_stats(max_hp: int, damage: int, xp: int) -> void:
	health.max_health = max_hp
	health.current_health = max_hp
	health.health_changed.emit(max_hp, max_hp)
	_hitbox.damage = damage
	xp_reward = xp


## Atordoa por `seconds` (não age; costas expostas). Golpe de escudo, bloqueio.
func apply_stun(seconds: float) -> void:
	if health.is_dead:
		return
	_stagger_duration = seconds
	_change_state(State.STAGGER)
	status.apply(StatusEffects.STUN, seconds)


## Provocado: passa a atacar `by` por `seconds`, mesmo longe ou fora de visão.
func apply_taunt(by: Player, seconds: float) -> void:
	if health.is_dead:
		return
	_taunted_by = by
	_taunt_left = seconds
	status.apply(StatusEffects.TAUNT, seconds, 0.0, by)
	target = by
	if state == State.IDLE:
		_change_state(State.CHASE)


func is_taunted_by(player: Player) -> bool:
	return _taunt_left > 0.0 and _taunted_by == player


## Volta ao lugar de origem com vida cheia, sem alvo (jogador continuou após morrer).
func reset_to_spawn() -> void:
	if health.is_dead:
		return
	global_position = _spawn_position
	velocity = Vector3.ZERO
	target = null
	_last_attacker = null
	_taunt_left = 0.0
	health.revive()
	_change_state(State.IDLE)


## true na parte final do aviso: a direção mostrada no chão não muda mais.
func is_aim_locked() -> bool:
	return state == State.WINDUP and _state_time >= windup_time - aim_lock_time


func _aim_at_target() -> void:
	if _is_valid_target(target):
		var aim: Vector3 = _flat(target.global_position - global_position)
		if aim.length() > 0.001:
			_lunge_direction = aim.normalized()


## A investida sai exatamente na direção que o aviso mostrou (travada), não
## para onde o jogador está agora: é isso que torna a esquiva possível.
func _start_lunge() -> void:
	if _lunge_direction == Vector3.ZERO:
		_change_state(State.RECOVER)
		return
	_change_state(State.LUNGE)
	_hitbox.activate()


## Faixa do tamanho do caminho da investida, calculada dos próprios valores de
## velocidade e duração (mudar no Inspetor já ajusta o aviso). A malha é um
## plano no chão; aqui só se define o tamanho.
func _build_telegraph() -> void:
	var length: float = lunge_speed * lunge_time + LUNGE_HALF_WIDTH
	var plane := PlaneMesh.new()
	plane.size = Vector2(LUNGE_HALF_WIDTH * 2.0, length)
	# Começa nos pés e vai para a frente (-Z do nó).
	plane.center_offset = Vector3(0, 0, -length / 2.0 + LUNGE_HALF_WIDTH)
	_telegraph.mesh = plane
	_telegraph.visible = false


func _change_state(new_state: State) -> void:
	if state == State.LUNGE:
		_hitbox.deactivate()
	# A direção só vale do aviso até o fim da investida.
	if new_state != State.WINDUP and new_state != State.LUNGE:
		_lunge_direction = Vector3.ZERO
	state = new_state
	_state_time = 0.0


## O jogador vivo mais próximo dentro do raio. Pensado para o co-op:
## o inimigo escolhe entre todos os jogadores do grupo, não "o" jogador.
func _find_target(radius: float) -> Player:
	var best: Player = null
	var best_distance: float = radius
	for node: Node in get_tree().get_nodes_in_group(Player.GROUP):
		var candidate := node as Player
		if not _is_valid_target(candidate):
			continue
		var distance: float = global_position.distance_to(candidate.global_position)
		if distance <= best_distance and _can_see(candidate):
			best = candidate
			best_distance = distance
	return best


func _can_see(candidate: Player) -> bool:
	if not requires_line_of_sight:
		return true
	var eye := Vector3.UP * EYE_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(
		global_position + eye, candidate.global_position + eye, SIGHT_BLOCKING_MASK)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _is_valid_target(candidate: Player) -> bool:
	return is_instance_valid(candidate) and not candidate.health.is_dead


func _on_damaged(info: DamageInfo) -> void:
	if health.is_dead:
		return
	if info.over_time:
		_show_damage_number(info)
		return
	velocity = info.knockback
	_flash_time = 0.08
	_show_damage_number(info)
	if info.source is Player:
		_last_attacker = info.source
	if target == null and info.source is Player:
		target = info.source
	_change_state(State.HURT)


func _on_lunge_blocked(_target: Hurtbox) -> void:
	if state != State.LUNGE:
		return
	velocity = -_lunge_direction * blocked_recoil_speed
	_stagger_duration = stagger_time
	_change_state(State.STAGGER)


func _on_died() -> void:
	_flash_time = 0.08
	_hurtbox.set_deferred("monitorable", false)
	# Corpo desaparecendo não pode bloquear outros inimigos nem jogadores.
	_body_shape.set_deferred("disabled", true)
	_change_state(State.DEAD)
	# No co-op a divisão da experiência será decidida pelo host (Fase 7).
	if is_instance_valid(_last_attacker):
		_last_attacker.on_enemy_defeated(kind, xp_reward)
	died.emit()


## Número do dano: maior e mais amarelado quanto maior o dano; laranja nas
## costas. Criado como filho de quem bateu (se ainda existir), para não sumir
## junto com o inimigo que morreu nesse golpe.
func _show_damage_number(info: DamageInfo) -> void:
	var owner_node: Node = info.source if is_instance_valid(info.source) else self
	var size: int = clampi(8 + info.amount / 4, 8, 18) + (2 if info.backstab else 0)
	var color: Color = Color.WHITE.lerp(Color(1.0, 0.85, 0.3), clampf(info.amount / 40.0, 0.0, 1.0))
	if info.backstab:
		color = Color(1.0, 0.55, 0.2)  # laranja: acerto pelas costas
	var jitter := Vector3(randf_range(-0.35, 0.35), 0.0, randf_range(-0.35, 0.35))
	FloatingText.spawn(owner_node, str(info.amount), global_position + Vector3.UP * TEXT_HEIGHT + jitter, color, size)


## A barra de vida fica sempre visível enquanto o inimigo está vivo.
func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.visible = current > 0
	_health_bar.set_ratio(float(current) / float(maximum))


## Apresentação provisória: só lê o estado, nunca muda regras de jogo.
func _update_visuals(delta: float) -> void:
	_flash_time = maxf(_flash_time - delta, 0.0)
	_telegraph.visible = state == State.WINDUP and _lunge_direction != Vector3.ZERO
	if _telegraph.visible:
		_telegraph.global_rotation = Vector3(0, Player.yaw_of(_lunge_direction), 0)
		_telegraph_material.albedo_color = TELEGRAPH_LOCKED_COLOR if is_aim_locked() else TELEGRAPH_TRACKING_COLOR
	_update_animation()
	if _overlay:
		_overlay.albedo_color = _overlay_color()
	if state == State.DEAD:
		return
	if _flash_time > 0.0:
		_body_material.albedo_color = Color.WHITE
		_body.scale = Vector3.ONE
	elif state == State.STAGGER:
		_body_material.albedo_color = STAGGER_COLOR.lerp(Color(0.55, 0.85, 1.0), 0.7) if status.has(StatusEffects.FREEZE) else STAGGER_COLOR
		_body.scale = Vector3.ONE
	elif state == State.WINDUP:
		_body_material.albedo_color = WINDUP_COLOR
		var pulse: float = 1.0 + 0.15 * sin(_state_time * 30.0)
		_body.scale = Vector3(pulse, pulse, pulse)
	else:
		var fx: Color = status.tint()
		_body_material.albedo_color = BODY_COLOR.lerp(Color(fx.r, fx.g, fx.b), fx.a)
		_body.scale = Vector3.ONE


## Cor por cima do modelo com esqueleto: mesmos avisos do cubo (piscar, preparação, efeitos).
func _overlay_color() -> Color:
	if state == State.DEAD:
		return Color(1, 1, 1, 0)
	if _flash_time > 0.0:
		return Color(1, 1, 1, 0.7)
	if status.has(StatusEffects.FREEZE):
		return Color(0.55, 0.85, 1.0, 0.55)
	if state == State.WINDUP:
		return Color(1.0, 0.5, 0.1, 0.25 + 0.2 * sin(_state_time * 30.0))
	return status.tint()


## Congelar para o inimigo como um atordoamento (costas expostas), com cor azul.
func _on_status_started(id: StringName) -> void:
	if id == StatusEffects.FREEZE and not health.is_dead:
		_stagger_duration = status.remaining(StatusEffects.FREEZE)
		_change_state(State.STAGGER)


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
