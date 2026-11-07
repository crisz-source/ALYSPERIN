class_name BasicEnemy
extends CharacterBody2D
## Inimigo básico de teste (PROVISÓRIO: sem arte, sem identidade definida).
##
## Comportamento: fica parado até ver um jogador; persegue; ao chegar perto,
## avisa o ataque (fica laranja e pulsa) e dá uma investida em linha reta.
## Depois da investida fica vulnerável por um instante. Apanhar interrompe
## qualquer ação. O aviso existe para que a esquiva (ou a defesa) seja uma
## resposta justa: durante a preparação aparece no chão o caminho exato da
## investida; a mira acompanha o jogador e trava no fim da preparação.
## Investida bloqueada pelo escudo deixa o inimigo atordoado.

signal died

enum State { IDLE, CHASE, WINDUP, LUNGE, RECOVER, HURT, STAGGER, DEAD }

const BODY_COLOR := Color(0.78, 0.25, 0.25)
const WINDUP_COLOR := Color(1.0, 0.6, 0.15)
const STAGGER_COLOR := Color(0.55, 0.5, 0.7)
const TELEGRAPH_TRACKING_COLOR := Color(1.0, 0.2, 0.15, 0.22)
const TELEGRAPH_LOCKED_COLOR := Color(1.0, 0.2, 0.15, 0.5)
## Metade do tamanho da LungeHitbox (14x14): a faixa cobre tudo que a investida toca.
const LUNGE_HALF_WIDTH: float = 7.0
## Camada "world" (paredes): é o que bloqueia a visão.
const SIGHT_BLOCKING_MASK: int = 1
## A visão sai da altura do tronco, não dos pés.
const EYE_OFFSET := Vector2(0, -8)

@export_group("Percepção")
## Distância em que o inimigo nota um jogador (px).
@export var detect_radius: float = 130.0
## Distância em que desiste da perseguição (px).
@export var lose_radius: float = 220.0
## Só nota um jogador se não houver parede entre os dois.
@export var requires_line_of_sight: bool = true

@export_group("Movimento")
@export var move_speed: float = 45.0
@export var acceleration: float = 400.0
@export var friction: float = 700.0

@export_group("Ataque")
## Distância a partir da qual começa a investida (px).
@export var attack_range: float = 40.0
## Duração do aviso antes da investida (s).
@export var windup_time: float = 0.45
## Parte final do aviso em que a direção já está travada (s). Antes disso a
## mira acompanha o jogador.
@export var aim_lock_time: float = 0.2
@export var lunge_speed: float = 190.0
@export var lunge_time: float = 0.22
## Tempo parado e vulnerável depois da investida (s).
@export var recover_time: float = 0.6

@export_group("Dano recebido")
@export var hurt_time: float = 0.25
## Tempo atordoado depois de ter a investida bloqueada: janela de contra-ataque (s).
@export var stagger_time: float = 0.7
## Velocidade do recuo ao bater no escudo (px/s).
@export var blocked_recoil_speed: float = 150.0
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
@onready var _telegraph: Polygon2D = $LungeTelegraph


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	_hitbox.hit_blocked.connect(_on_lunge_blocked)
	_health_bar.visible = false
	_build_telegraph()


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
			if not is_aim_locked():
				_aim_at_target()
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
		State.STAGGER:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			if _state_time >= stagger_time:
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
		_aim_at_target()
		return
	velocity = velocity.move_toward(to_target.normalized() * move_speed, acceleration * delta)


## true na parte final do aviso: a direção mostrada no chão não muda mais.
func is_aim_locked() -> bool:
	return state == State.WINDUP and _state_time >= windup_time - aim_lock_time


func _aim_at_target() -> void:
	if _is_valid_target(target):
		var aim: Vector2 = global_position.direction_to(target.global_position)
		if aim != Vector2.ZERO:
			_lunge_direction = aim


## A investida sai exatamente na direção que o aviso mostrou (travada), não
## para onde o jogador está agora: é isso que torna a esquiva possível.
func _start_lunge() -> void:
	if _lunge_direction == Vector2.ZERO:
		_change_state(State.RECOVER)
		return
	_change_state(State.LUNGE)
	_hitbox.activate()


## Faixa do tamanho do caminho da investida, calculada dos próprios valores de
## velocidade e duração (mudar no Inspetor já ajusta o aviso).
func _build_telegraph() -> void:
	var length: float = lunge_speed * lunge_time + LUNGE_HALF_WIDTH
	var w: float = LUNGE_HALF_WIDTH
	_telegraph.polygon = PackedVector2Array([
		Vector2(-w, -w), Vector2(length, -w), Vector2(length, w), Vector2(-w, w)])
	_telegraph.visible = false


func _change_state(new_state: State) -> void:
	if state == State.LUNGE:
		_hitbox.deactivate()
	# A direção só vale do aviso até o fim da investida.
	if new_state != State.WINDUP and new_state != State.LUNGE:
		_lunge_direction = Vector2.ZERO
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
	var query := PhysicsRayQueryParameters2D.create(
		global_position + EYE_OFFSET, candidate.global_position + EYE_OFFSET, SIGHT_BLOCKING_MASK)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


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


func _on_lunge_blocked(_target: Hurtbox) -> void:
	if state != State.LUNGE:
		return
	velocity = -_lunge_direction * blocked_recoil_speed
	_change_state(State.STAGGER)


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
	_telegraph.visible = state == State.WINDUP and _lunge_direction != Vector2.ZERO
	if _telegraph.visible:
		_telegraph.rotation = _lunge_direction.angle()
		_telegraph.color = TELEGRAPH_LOCKED_COLOR if is_aim_locked() else TELEGRAPH_TRACKING_COLOR
	if _flash_time > 0.0:
		_body.color = Color.WHITE
		_body.scale = Vector2.ONE
	elif state == State.STAGGER:
		_body.color = STAGGER_COLOR
		_body.scale = Vector2.ONE
	elif state == State.WINDUP:
		_body.color = WINDUP_COLOR
		var pulse: float = 1.0 + 0.15 * sin(_state_time * 30.0)
		_body.scale = Vector2(pulse, pulse)
	else:
		_body.color = BODY_COLOR
		_body.scale = Vector2.ONE
