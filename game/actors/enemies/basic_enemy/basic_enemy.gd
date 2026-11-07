class_name BasicEnemy
extends CharacterBody2D
## Inimigo básico de teste (PROVISÓRIO: sem arte, sem identidade definida).
##
## Comportamento: fica parado até ver um jogador; persegue; ao chegar perto,
## avisa o ataque (fica laranja e pulsa) e dá uma investida em linha reta.
## Depois da investida fica vulnerável por um instante. Apanhar interrompe
## qualquer ação. O aviso existe para que a esquiva seja uma resposta justa.

signal died

enum State { IDLE, CHASE, WINDUP, LUNGE, RECOVER, HURT, DEAD }

const BODY_COLOR := Color(0.78, 0.25, 0.25)
const WINDUP_COLOR := Color(1.0, 0.6, 0.15)

@export_group("Percepção")
## Distância em que o inimigo nota um jogador (px).
@export var detect_radius: float = 130.0
## Distância em que desiste da perseguição (px).
@export var lose_radius: float = 220.0

@export_group("Movimento")
@export var move_speed: float = 45.0
@export var acceleration: float = 400.0
@export var friction: float = 700.0

@export_group("Ataque")
## Distância a partir da qual começa a investida (px).
@export var attack_range: float = 40.0
## Duração do aviso antes da investida (s).
@export var windup_time: float = 0.45
@export var lunge_speed: float = 190.0
@export var lunge_time: float = 0.22
## Tempo parado e vulnerável depois da investida (s).
@export var recover_time: float = 0.6

@export_group("Dano recebido")
@export var hurt_time: float = 0.25
@export var death_fade_time: float = 0.4

var state: State = State.IDLE
var target: Player = null

var _state_time: float = 0.0
var _lunge_direction: Vector2 = Vector2.ZERO
var _flash_time: float = 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var _hitbox: Hitbox = $LungeHitbox
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _body_shape: CollisionShape2D = $CollisionShape
@onready var _body: Polygon2D = $BodyPlaceholder
@onready var _health_bar: Node2D = $HealthBar
@onready var _health_bar_fill: ColorRect = $HealthBar/Fill


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	_health_bar.visible = false


func _physics_process(delta: float) -> void:
	_state_time += delta
	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			target = _find_target(detect_radius)
			if target:
				_change_state(State.CHASE)
		State.CHASE:
			_process_chase(delta)
		State.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			if _state_time >= windup_time:
				_start_lunge()
		State.LUNGE:
			velocity = _lunge_direction * lunge_speed
			if _state_time >= lunge_time:
				_change_state(State.RECOVER)
		State.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			if _state_time >= recover_time:
				_change_state(State.CHASE)
		State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			if _state_time >= hurt_time:
				_change_state(State.CHASE)
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			modulate.a = 1.0 - clampf(_state_time / death_fade_time, 0.0, 1.0)
			if _state_time >= death_fade_time:
				queue_free()
	move_and_slide()
	_update_visuals(delta)


func _process_chase(delta: float) -> void:
	if not _is_valid_target(target) or global_position.distance_to(target.global_position) > lose_radius:
		target = _find_target(detect_radius)
		if target == null:
			_change_state(State.IDLE)
			return
	var to_target: Vector2 = target.global_position - global_position
	if to_target.length() <= attack_range:
		_change_state(State.WINDUP)
		return
	velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)


func _start_lunge() -> void:
	var aim: Vector2 = global_position.direction_to(target.global_position) if _is_valid_target(target) else Vector2.ZERO
	if aim == Vector2.ZERO:
		_change_state(State.RECOVER)
		return
	_lunge_direction = aim
	_change_state(State.LUNGE)
	_hitbox.activate()


func _change_state(new_state: State) -> void:
	if state == State.LUNGE:
		_hitbox.deactivate()
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
		if distance <= best_distance:
			best = candidate
			best_distance = distance
	return best


func _is_valid_target(candidate: Player) -> bool:
	return is_instance_valid(candidate) and not candidate.health.is_dead


func _on_damaged(info: DamageInfo) -> void:
	if health.is_dead:
		return
	velocity = info.knockback
	_flash_time = 0.08
	if target == null and info.source is Player:
		target = info.source
	_change_state(State.HURT)


func _on_died() -> void:
	_flash_time = 0.08
	_hurtbox.set_deferred("monitorable", false)
	# Corpo desvanecendo não pode bloquear outros inimigos nem jogadores.
	_body_shape.set_deferred("disabled", true)
	_change_state(State.DEAD)
	died.emit()


func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.visible = current < maximum and current > 0
	_health_bar_fill.scale.x = float(current) / float(maximum)


## Apresentação provisória: só lê o estado, nunca muda regras de jogo.
func _update_visuals(delta: float) -> void:
	_flash_time = maxf(_flash_time - delta, 0.0)
	if _flash_time > 0.0:
		_body.color = Color.WHITE
		_body.scale = Vector2.ONE
	elif state == State.WINDUP:
		_body.color = WINDUP_COLOR
		var pulse: float = 1.0 + 0.15 * sin(_state_time * 30.0)
		_body.scale = Vector2(pulse, pulse)
	else:
		_body.color = BODY_COLOR
		_body.scale = Vector2.ONE
