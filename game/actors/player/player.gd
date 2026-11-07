class_name Player
extends CharacterBody2D
## Personagem controlável: movimento, combo de espada, defesa, esquiva, dano e morte.
##
## Organizado como uma máquina de estados simples: em cada momento o personagem
## está em exatamente um estado (andando, atacando, defendendo...), e cada
## estado decide o que é permitido. Isso evita combinações impossíveis como
## "atacando e esquivando ao mesmo tempo".

signal died

enum State { MOVE, ATTACK, BLOCK, DODGE, HURT, DEAD }

const GROUP: StringName = &"players"
const COMBO_LENGTH: int = 3
const PLACEHOLDER_COLOR := Color(0.36, 0.62, 0.92)
const DEAD_COLOR := Color(0.35, 0.35, 0.4)
const SHIELD_COLOR := Color(0.75, 0.85, 1.0, 0.85)
const FINISHER_SWING_TINT := Color(1.0, 0.75, 0.45)

@export_group("Movimento")
## Velocidade máxima, em pixels por segundo (16 px = 1 tile).
@export var max_speed: float = 90.0
## Quanto a velocidade cresce por segundo ao começar a andar.
@export var acceleration: float = 900.0
## Quanto a velocidade cai por segundo ao soltar as teclas.
@export var friction: float = 1100.0

@export_group("Ataque")
## Preparação antes da lâmina causar dano (s).
@export var attack_windup: float = 0.06
## Janela em que a lâmina causa dano (s).
@export var attack_active: float = 0.10
## Recuperação depois do golpe; pode ser cancelada pela esquiva ou defesa (s).
@export var attack_recovery: float = 0.14
## Fração da velocidade normal permitida durante o ataque (0 = fica parado).
@export_range(0.0, 1.0) var attack_move_multiplier: float = 0.3

@export_group("Combo")
## Dano de cada golpe do combo (1º, 2º, 3º = finalizador).
@export var combo_damage: Array[int] = [10, 10, 20]
## Empurrão de cada golpe no inimigo (px/s).
@export var combo_knockback: Array[float] = [140.0, 140.0, 260.0]
## Passo à frente que o personagem dá em cada golpe (px/s).
@export var combo_step_impulse: Array[float] = [40.0, 40.0, 110.0]
## Tempo depois de um golpe em que clicar de novo continua o combo (s).
@export var combo_window: float = 0.25
## O finalizador demora mais para sair e para se recuperar: é o preço do dano maior.
@export var finisher_extra_windup: float = 0.05
@export var finisher_extra_recovery: float = 0.12
## Alcance do finalizador em relação ao golpe normal.
@export var finisher_reach_scale: float = 1.25

@export_group("Defesa")
## Fração da velocidade normal enquanto defende.
@export_range(0.0, 1.0) var block_move_multiplier: float = 0.4
## Metade do ângulo protegido pelo escudo, à frente da mira (graus).
@export_range(0.0, 180.0) var block_half_angle: float = 75.0
## Quanto do empurrão do golpe ainda chega ao defender.
@export_range(0.0, 1.0) var block_knockback_multiplier: float = 0.35

@export_group("Esquiva")
@export var dodge_speed: float = 230.0
@export var dodge_duration: float = 0.24
## Parte inicial da esquiva em que o personagem não toma dano (s).
@export var dodge_invulnerability: float = 0.18
## Tempo mínimo entre o início de uma esquiva e a próxima (s).
@export var dodge_cooldown: float = 0.45

@export_group("Dano recebido")
## Tempo atordoado depois de levar um golpe (s).
@export var hurt_duration: float = 0.18
## Invulnerabilidade depois de levar um golpe, para não morrer em sequência (s).
@export var post_hit_invulnerability: float = 0.7

@export_group("Hitstop (pausa de impacto)")
@export var hitstop_hit: float = 0.05
@export var hitstop_finisher: float = 0.09
@export var hitstop_hurt: float = 0.07
@export var hitstop_block: float = 0.04

## Direção para onde o personagem está virado: sempre uma das 4 cardeais.
var facing: Vector2 = Vector2.DOWN
var state: State = State.MOVE

var _state_time: float = 0.0
var _dodge_direction: Vector2 = Vector2.ZERO
var _dodge_cooldown_left: float = 0.0
var _flash_time: float = 0.0
var _shield_flash_time: float = 0.0
var _blink_clock: float = 0.0
## Golpe atual do combo: 0, 1 ou 2 (finalizador).
var _combo_step: int = 0
var _combo_window_left: float = 0.0
var _attack_windup_now: float = 0.0
var _attack_recovery_now: float = 0.0
var _block_direction: Vector2 = Vector2.DOWN

@onready var health: HealthComponent = $HealthComponent
@onready var _input: PlayerInput = $PlayerInput
@onready var _facing_indicator: Node2D = $FacingIndicator
@onready var _body: Polygon2D = $BodyPlaceholder
@onready var _attack_pivot: Node2D = $AttackPivot
@onready var _sword_hitbox: Hitbox = $AttackPivot/SwordHitbox
@onready var _swing_visual: CanvasItem = $AttackPivot/SwingPlaceholder
@onready var _shield_visual: Polygon2D = $AttackPivot/ShieldPlaceholder
@onready var _camera: PlayerCamera = $Camera


func _ready() -> void:
	assert(combo_damage.size() == COMBO_LENGTH and combo_knockback.size() == COMBO_LENGTH \
		and combo_step_impulse.size() == COMBO_LENGTH,
		"Player: listas do combo precisam ter %d valores cada" % COMBO_LENGTH)
	add_to_group(GROUP)
	_facing_indicator.rotation = facing.angle()
	_swing_visual.visible = false
	_shield_visual.visible = false
	health.block_filter = _is_hit_blocked
	health.damaged.connect(_on_damaged)
	health.blocked.connect(_on_blocked)
	health.died.connect(_on_died)
	_sword_hitbox.hit_landed.connect(_on_sword_hit)


func _physics_process(delta: float) -> void:
	_input.poll(delta)
	_state_time += delta
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	_combo_window_left = maxf(_combo_window_left - delta, 0.0)
	match state:
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			_process_attack(delta)
		State.BLOCK:
			_process_block(delta)
		State.DODGE:
			_process_dodge()
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	_update_visuals(delta)


## A área avisa o tamanho do mapa; o jogador repassa para a própria câmera.
func set_camera_bounds(bounds: Rect2) -> void:
	_camera.set_world_bounds(bounds)


# --- Estados ---------------------------------------------------------------

func _process_move(delta: float) -> void:
	if _try_start_dodge():
		return
	# Defesa vence o ataque: segurando o botão direito, cliques são ignorados.
	if _input.defend_held:
		_start_block()
		return
	if _input.has_attack():
		_start_attack()
		return
	_apply_movement(_input.move_direction, max_speed, delta)
	if _input.move_direction != Vector2.ZERO:
		_set_facing(to_cardinal(_input.move_direction))


func _process_attack(delta: float) -> void:
	var active_start: float = _attack_windup_now
	var recovery_start: float = active_start + attack_active
	var attack_end: float = recovery_start + _attack_recovery_now

	if _state_time >= active_start and _state_time < recovery_start and not _sword_hitbox.is_active:
		_sword_hitbox.activate()
		_swing_visual.visible = true
	elif _state_time >= recovery_start and _sword_hitbox.is_active:
		_sword_hitbox.deactivate()
		_swing_visual.visible = false

	# Cancelamento: na recuperação, esquiva ou defesa interrompem o golpe.
	if _state_time >= recovery_start:
		if _try_start_dodge():
			return
		if _input.defend_held:
			_start_block()
			return
	_apply_movement(_input.move_direction, max_speed * attack_move_multiplier, delta)
	if _state_time >= attack_end:
		var was_finisher: bool = _combo_step == COMBO_LENGTH - 1
		_change_state(State.MOVE)
		# Depois do finalizador o combo recomeça do primeiro golpe.
		_combo_window_left = 0.0 if was_finisher else combo_window
		# Golpe guardado sai no mesmo quadro: esperar o próximo quadro gastaria
		# mais um pedaço do buffer e o comando poderia expirar.
		if _input.has_attack():
			_start_attack()


func _process_block(delta: float) -> void:
	if _try_start_dodge():
		return
	if not _input.defend_held:
		_change_state(State.MOVE)
		return
	_update_block_direction()
	_apply_movement(_input.move_direction, max_speed * block_move_multiplier, delta)


func _process_dodge() -> void:
	velocity = _dodge_direction * dodge_speed
	if _state_time >= dodge_invulnerability:
		health.set_invulnerable(false)
	if _state_time >= dodge_duration:
		velocity = _dodge_direction * max_speed
		_change_state(State.MOVE)


func _process_hurt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if _state_time >= hurt_duration:
		_change_state(State.MOVE)


# --- Transições ------------------------------------------------------------

func _change_state(new_state: State) -> void:
	# Limpeza do estado que está saindo: nada pode "vazar" para o próximo.
	if state == State.ATTACK:
		_sword_hitbox.deactivate()
		_swing_visual.visible = false
		_attack_pivot.scale = Vector2.ONE
	elif state == State.BLOCK:
		_shield_visual.visible = false
	elif state == State.DODGE:
		health.set_invulnerable(false)
	state = new_state
	_state_time = 0.0


func _start_attack() -> void:
	_input.consume_attack()
	var continues_combo: bool = _combo_window_left > 0.0 and _combo_step < COMBO_LENGTH - 1
	_combo_step = _combo_step + 1 if continues_combo else 0
	_combo_window_left = 0.0
	var is_finisher: bool = _combo_step == COMBO_LENGTH - 1

	var aim: Vector2 = _aim_direction()
	_attack_pivot.rotation = aim.angle()
	_attack_pivot.scale = Vector2.ONE * (finisher_reach_scale if is_finisher else 1.0)
	_set_facing(to_cardinal(aim))

	_sword_hitbox.damage = combo_damage[_combo_step]
	_sword_hitbox.knockback_force = combo_knockback[_combo_step]
	_swing_visual.modulate = FINISHER_SWING_TINT if is_finisher else Color.WHITE
	_attack_windup_now = attack_windup + (finisher_extra_windup if is_finisher else 0.0)
	_attack_recovery_now = attack_recovery + (finisher_extra_recovery if is_finisher else 0.0)

	_change_state(State.ATTACK)
	velocity = aim * combo_step_impulse[_combo_step]


func _start_block() -> void:
	_change_state(State.BLOCK)
	_shield_visual.visible = true
	_update_block_direction()


func _try_start_dodge() -> bool:
	if not _input.has_dodge() or _dodge_cooldown_left > 0.0:
		return false
	_input.consume_dodge()
	_dodge_direction = _input.move_direction.normalized() if _input.move_direction != Vector2.ZERO else facing
	_set_facing(to_cardinal(_dodge_direction))
	_dodge_cooldown_left = dodge_cooldown
	_change_state(State.DODGE)
	health.set_invulnerable(true)
	return true


# --- Reações ---------------------------------------------------------------

## Chamado pelo HealthComponent antes de aplicar dano: devolve true se o golpe
## veio de dentro do ângulo protegido pelo escudo.
func _is_hit_blocked(info: DamageInfo) -> bool:
	if state != State.BLOCK:
		return false
	var from_direction: Vector2
	if is_instance_valid(info.source) and info.source is Node2D:
		from_direction = global_position.direction_to((info.source as Node2D).global_position)
	else:
		from_direction = -info.knockback.normalized()
	if from_direction == Vector2.ZERO:
		return true
	return absf(_block_direction.angle_to(from_direction)) <= deg_to_rad(block_half_angle)


func _on_blocked(info: DamageInfo) -> void:
	velocity = info.knockback * block_knockback_multiplier
	_shield_flash_time = 0.08
	_camera.shake(1.5, 0.08)
	Hitstop.request(hitstop_block)


func _on_sword_hit(_target: Hurtbox) -> void:
	var is_finisher: bool = _combo_step == COMBO_LENGTH - 1
	Hitstop.request(hitstop_finisher if is_finisher else hitstop_hit)
	if is_finisher:
		_camera.shake(2.0, 0.1)


func _on_damaged(info: DamageInfo) -> void:
	if health.is_dead:
		return
	health.grant_invulnerability(post_hit_invulnerability)
	velocity = info.knockback
	_flash_time = 0.08
	_camera.shake(3.0, 0.15)
	Hitstop.request(hitstop_hurt)
	_change_state(State.HURT)


func _on_died() -> void:
	_flash_time = 0.0
	_camera.shake(5.0, 0.25)
	_change_state(State.DEAD)
	died.emit()


# --- Auxiliares ------------------------------------------------------------

func _aim_direction() -> Vector2:
	var aim: Vector2 = _attack_pivot.global_position.direction_to(_input.aim_position)
	return aim if aim != Vector2.ZERO else facing


func _update_block_direction() -> void:
	_block_direction = _aim_direction()
	_attack_pivot.rotation = _block_direction.angle()
	_set_facing(to_cardinal(_block_direction))


func _apply_movement(direction: Vector2, speed: float, delta: float) -> void:
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func _set_facing(new_facing: Vector2) -> void:
	if new_facing == facing:
		return
	facing = new_facing
	_facing_indicator.rotation = facing.angle()


## Apresentação provisória: só lê o estado, nunca muda regras de jogo.
func _update_visuals(delta: float) -> void:
	_flash_time = maxf(_flash_time - delta, 0.0)
	_shield_flash_time = maxf(_shield_flash_time - delta, 0.0)
	_shield_visual.color = Color.WHITE if _shield_flash_time > 0.0 else SHIELD_COLOR
	if state == State.DEAD:
		_body.color = DEAD_COLOR
		_body.modulate.a = 1.0
		return
	_body.color = Color.WHITE if _flash_time > 0.0 else PLACEHOLDER_COLOR
	if state == State.DODGE:
		_body.modulate.a = 0.45
	elif health.is_invulnerable():
		# Pisca enquanto invulnerável após dano (alterna a cada 1/15 s).
		_blink_clock += delta
		_body.modulate.a = 0.35 if int(_blink_clock * 15.0) % 2 == 0 else 1.0
	else:
		_blink_clock = 0.0
		_body.modulate.a = 1.0
	_body.scale.y = 0.7 if state == State.DODGE else 1.0


## Converte qualquer direção na cardeal mais próxima. Em diagonal exata
## (teclado), o lado horizontal vence, porque o sprite de perfil lê melhor.
static func to_cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP
