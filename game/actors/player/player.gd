class_name Player
extends CharacterBody2D
## Personagem controlável: movimento, ataque com espada, esquiva, dano e morte.
##
## Organizado como uma máquina de estados simples: em cada momento o personagem
## está em exatamente um estado (andando, atacando, esquivando...), e cada
## estado decide o que é permitido. Isso evita combinações impossíveis como
## "atacando e esquivando ao mesmo tempo".

signal died

enum State { MOVE, ATTACK, DODGE, HURT, DEAD }

const GROUP: StringName = &"players"
const PLACEHOLDER_COLOR := Color(0.36, 0.62, 0.92)
const DEAD_COLOR := Color(0.35, 0.35, 0.4)

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
## Recuperação depois do golpe; pode ser cancelada pela esquiva (s).
@export var attack_recovery: float = 0.14
## Fração da velocidade normal permitida durante o ataque (0 = fica parado).
@export_range(0.0, 1.0) var attack_move_multiplier: float = 0.3

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

## Direção para onde o personagem está virado: sempre uma das 4 cardeais.
var facing: Vector2 = Vector2.DOWN
var state: State = State.MOVE

var _state_time: float = 0.0
var _dodge_direction: Vector2 = Vector2.ZERO
var _dodge_cooldown_left: float = 0.0
var _flash_time: float = 0.0
var _blink_clock: float = 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var _input: PlayerInput = $PlayerInput
@onready var _facing_indicator: Node2D = $FacingIndicator
@onready var _body: Polygon2D = $BodyPlaceholder
@onready var _attack_pivot: Node2D = $AttackPivot
@onready var _sword_hitbox: Hitbox = $AttackPivot/SwordHitbox
@onready var _swing_visual: CanvasItem = $AttackPivot/SwingPlaceholder
@onready var _camera: PlayerCamera = $Camera


func _ready() -> void:
	add_to_group(GROUP)
	_facing_indicator.rotation = facing.angle()
	_swing_visual.visible = false
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_input.poll(delta)
	_state_time += delta
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	match state:
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DODGE:
			_process_dodge()
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	_update_visuals(delta)


# --- Estados ---------------------------------------------------------------

func _process_move(delta: float) -> void:
	if _try_start_dodge():
		return
	if _input.has_attack():
		_start_attack()
		return
	_apply_movement(_input.move_direction, max_speed, delta)
	if _input.move_direction != Vector2.ZERO:
		_set_facing(to_cardinal(_input.move_direction))


func _process_attack(delta: float) -> void:
	var active_start: float = attack_windup
	var recovery_start: float = attack_windup + attack_active
	var attack_end: float = recovery_start + attack_recovery

	if _state_time >= active_start and _state_time < recovery_start and not _sword_hitbox.is_active:
		_sword_hitbox.activate()
		_swing_visual.visible = true
	elif _state_time >= recovery_start and _sword_hitbox.is_active:
		_sword_hitbox.deactivate()
		_swing_visual.visible = false

	# Cancelamento: na recuperação, a esquiva interrompe o golpe.
	if _state_time >= recovery_start and _try_start_dodge():
		return
	_apply_movement(_input.move_direction, max_speed * attack_move_multiplier, delta)
	if _state_time >= attack_end:
		_change_state(State.MOVE)
		# Golpe guardado sai no mesmo quadro: esperar o próximo quadro gastaria
		# mais um pedaço do buffer e o comando poderia expirar.
		if _input.has_attack():
			_start_attack()


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
	elif state == State.DODGE:
		health.set_invulnerable(false)
	state = new_state
	_state_time = 0.0


func _start_attack() -> void:
	_input.consume_attack()
	var origin: Vector2 = _attack_pivot.global_position
	var aim: Vector2 = origin.direction_to(_input.aim_position)
	if aim == Vector2.ZERO:
		aim = facing
	_attack_pivot.rotation = aim.angle()
	_set_facing(to_cardinal(aim))
	_change_state(State.ATTACK)


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


func _on_damaged(info: DamageInfo) -> void:
	if health.is_dead:
		return
	health.grant_invulnerability(post_hit_invulnerability)
	velocity = info.knockback
	_flash_time = 0.08
	_camera.shake(3.0, 0.15)
	_change_state(State.HURT)


func _on_died() -> void:
	_flash_time = 0.0
	_camera.shake(5.0, 0.25)
	_change_state(State.DEAD)
	died.emit()


# --- Auxiliares ------------------------------------------------------------

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
