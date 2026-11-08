class_name PlayerAnimator
extends Node
## Animação por código do jogador (PROVISÓRIA até existirem modelos com
## animações): move as mãos (arma e escudo) e inclina o corpo conforme o
## estado do Player.
##
## Só apresentação: lê o estado e os tempos do Player e nunca muda regra de
## jogo (dano, alcance, tempos, colisão). Dono único do transform do nó Model
## e das mãos; o Player não escreve neles.
##
## Convenção de ângulos das mãos (radianos, frente = -Z, arma em pé = +Y):
##   x negativo = inclina a arma para a frente (-PI/2 = apontando para a frente);
##   y = gira para os lados (negativo = para a direita, positivo = para a esquerda).

## Quão rápido a pose atual alcança a pose desejada (1/s). Alto = mais seco.
const FOLLOW_RATE: float = 30.0
const RIGHT_REST_POS := Vector3(0.45, 0.85, -0.15)
const LEFT_REST_POS := Vector3(-0.45, 0.85, -0.15)
## Escudo à frente do corpo ao defender.
const LEFT_BLOCK_POS := Vector3(-0.12, 0.95, -0.5)
const LEFT_BASH_POS := Vector3(-0.1, 0.95, -0.85)
const RIGHT_RAISED_POS := Vector3(0.4, 1.25, -0.25)
## Inclinações do corpo (radianos).
const STRIKE_LEAN: float = -0.12
const DODGE_LEAN: float = -0.45
const HURT_LEAN: float = 0.3
const DEATH_ROLL: float = -1.45
const DEATH_FALL_TIME: float = 0.45
const WALK_SWING: float = 0.35
const WALK_STEP_RATE: float = 9.0
const WALK_BOB: float = 0.04
const IDLE_BREATH: float = 0.012
const DODGE_SQUASH: float = 0.6

## Golpes do combo: [preparação, fim do golpe] (rotação da mão direita).
const COMBO_POSES: Array[Array] = [
	[Vector3(-1.3, -1.1, 0.0), Vector3(-1.4, 1.1, 0.0)],   # 1: direita -> esquerda
	[Vector3(-1.3, 1.0, 0.0), Vector3(-1.4, -1.2, 0.0)],   # 2: esquerda -> direita
	[Vector3(0.6, 0.0, 0.0), Vector3(-2.1, 0.0, 0.0)],     # 3: de cima para baixo
]

## Modelo com esqueleto (KayKit): animações por estado. [nome, repete?]
const ANIM_IDLE := "Idle"
const ANIM_RUN := "Running_A"
const ANIM_COMBO_1H: Array[String] = ["1H_Melee_Attack_Slice_Diagonal", "1H_Melee_Attack_Slice_Horizontal", "1H_Melee_Attack_Chop"]
const ANIM_COMBO_2H: Array[String] = ["2H_Melee_Attack_Slice", "2H_Melee_Attack_Stab", "2H_Melee_Attack_Chop"]
const LOOPING: Array[String] = ["Idle", "Running_A", "Blocking", "2H_Melee_Idle", "Spellcasting"]
## Velocidade máxima de uma animação ao encaixar num tempo curto (senão vira borrão).
const MAX_ANIM_SPEED: float = 3.0
const RUN_THRESHOLD: float = 0.4

var _player: Player
var _model: Node3D
var _anim_key: String = ""
var _last_state_time: float = 0.0
var _right: Node3D
var _left: Node3D
var _clock: float = 0.0
var _walk_phase: float = 0.0

# Pose atual (seguida suavemente).
var _right_pos: Vector3 = RIGHT_REST_POS
var _right_rot: Vector3 = Vector3.ZERO
var _left_pos: Vector3 = LEFT_REST_POS
var _left_rot: Vector3 = Vector3.ZERO
var _lean: Vector3 = Vector3.ZERO


func _ready() -> void:
	_player = get_parent() as Player
	assert(_player != null, "PlayerAnimator precisa ser filho do Player")
	_model = _player.get_node("Model")
	_right = _player.get_node("Model/RightHand")
	_left = _player.get_node("Model/LeftHand")


func _process(delta: float) -> void:
	update_pose(delta)


## Calcula e aplica a pose deste instante (público para os testes).
func update_pose(delta: float) -> void:
	_clock += delta
	var anim_player: AnimationPlayer = _skeletal_player()
	if anim_player:
		_update_skeletal(anim_player)
		return
	var target := _target_pose()
	var w: float = 1.0 - exp(-FOLLOW_RATE * delta)
	_right_pos = _right_pos.lerp(target.right_pos, w)
	_right_rot = _right_rot.lerp(target.right_rot, w)
	_left_pos = _left_pos.lerp(target.left_pos, w)
	_left_rot = _left_rot.lerp(target.left_rot, w)
	_lean = _lean.lerp(target.lean, w)
	_right.position = _right_pos
	_right.rotation = _right_rot
	_left.position = _left_pos
	_left.rotation = _left_rot
	_model.rotation = Vector3(_lean.x, Player.yaw_of(_player.facing) + target.spin, _lean.z)
	_model.position = Vector3(0.0, target.bob, 0.0)
	_model.scale = Vector3(1.0, DODGE_SQUASH if _player.state == Player.State.DODGE else 1.0, 1.0)


# --- Modelo com esqueleto (KayKit) ----------------------------------------------

func _skeletal_player() -> AnimationPlayer:
	var model: Node3D = _player.class_model()
	if model == null:
		return null
	var found: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	return found[0] as AnimationPlayer if not found.is_empty() else null


## Animação do estado atual: [nome, duração para encaixar (0 = velocidade normal)].
func skeletal_animation() -> Array:
	var p: Player = _player
	var ability: AbilityData = p.active_ability()
	match p.state:
		Player.State.MOVE:
			var moving: bool = Player.flat(p.velocity).length() > RUN_THRESHOLD
			return [ANIM_RUN if moving else ANIM_IDLE, 0.0]
		Player.State.ATTACK:
			var combo: Array[String] = ANIM_COMBO_1H if p.equipment.shield != null else ANIM_COMBO_2H
			var t: Vector3 = p.attack_phase_times()
			return [combo[clampi(p.combo_step(), 0, combo.size() - 1)], t.x + t.y + t.z]
		Player.State.BLOCK:
			return ["Blocking", 0.0]
		Player.State.DODGE:
			return ["Dodge_Forward", p.dodge_duration]
		Player.State.HURT:
			return ["Hit_A", p.hurt_duration]
		Player.State.DEAD:
			return ["Death_A", 0.0]
		Player.State.ABILITY:
			if ability is SpinSlashData:
				return ["2H_Melee_Attack_Spin", (ability as SpinSlashData).duration]
			if ability is ShieldBashData:
				return ["Block_Attack", (ability as ShieldBashData).duration]
			if ability is TauntData:
				return ["Cheer", 0.6]
			if ability is ProjectileSpellData:
				return ["Spellcast_Shoot", (ability as ProjectileSpellData).cast_time + 0.08]
			if ability is HealSpellData:
				return ["Spellcast_Raise", (ability as HealSpellData).cast_time + 0.1]
			if ability is SupportSpellData:
				return ["Spellcast_Raise", (ability as SupportSpellData).cast_time + 0.1]
	return [ANIM_IDLE, 0.0]


func _update_skeletal(anim_player: AnimationPlayer) -> void:
	# O corpo só gira para a frente do jogador; poses e inclinações vêm das animações.
	_model.rotation = Vector3(0.0, Player.yaw_of(_player.facing), 0.0)
	_model.position = Vector3.ZERO
	_model.scale = Vector3.ONE
	var spec: Array = skeletal_animation()
	var anim_name: String = spec[0]
	if not anim_player.has_animation(anim_name):
		anim_name = ANIM_IDLE
	var t: float = _player.state_time()
	var key: String = "%d|%d|%s" % [_player.state, _player.combo_step(), anim_name]
	# Mesmo estado recomeçado (ex.: golpe seguinte do combo) também reinicia.
	var restarted: bool = t < _last_state_time
	_last_state_time = t
	if key == _anim_key and not restarted:
		if anim_name == ANIM_RUN:
			anim_player.speed_scale = clampf(Player.flat(_player.velocity).length() / _player.max_speed * 1.2, 0.6, 1.4)
		return
	_anim_key = key
	var anim: Animation = anim_player.get_animation(anim_name)
	if LOOPING.has(anim_name):
		anim.loop_mode = Animation.LOOP_LINEAR
	var fit: float = spec[1]
	anim_player.speed_scale = clampf(anim.length / fit, 0.25, MAX_ANIM_SPEED) if fit > 0.0 else 1.0
	anim_player.play(anim_name, 0.08 if fit == 0.0 else 0.03)
	if fit > 0.0:
		anim_player.seek(0.0, true)


## Animação tocando agora no modelo com esqueleto ("" se não houver). Usado por testes.
func current_animation() -> String:
	var anim_player: AnimationPlayer = _skeletal_player()
	return anim_player.current_animation if anim_player else ""


class Pose:
	var right_pos: Vector3 = RIGHT_REST_POS
	var right_rot: Vector3 = Vector3.ZERO
	var left_pos: Vector3 = LEFT_REST_POS
	var left_rot: Vector3 = Vector3.ZERO
	## Inclinação do corpo: x = frente/trás, z = lados.
	var lean: Vector3 = Vector3.ZERO
	## Giro extra em volta do eixo vertical (Giro cortante).
	var spin: float = 0.0
	var bob: float = 0.0


func _target_pose() -> Pose:
	var pose := Pose.new()
	var t: float = _player.state_time()
	match _player.state:
		Player.State.MOVE:
			_pose_move(pose)
		Player.State.ATTACK:
			_pose_attack(pose, t)
		Player.State.BLOCK:
			pose.left_pos = LEFT_BLOCK_POS
			pose.right_pos = RIGHT_REST_POS + Vector3(0, -0.1, 0.1)
			pose.right_rot = Vector3(-0.4, 0.0, 0.0)
		Player.State.DODGE:
			pose.lean.x = DODGE_LEAN
			pose.right_rot = Vector3(0.5, 0.0, 0.0)
		Player.State.HURT:
			pose.lean.x = HURT_LEAN
			pose.right_rot = Vector3(0.4, 0.0, 0.3)
		Player.State.ABILITY:
			_pose_ability(pose, t)
		Player.State.DEAD:
			pose.lean.z = DEATH_ROLL * clampf(t / DEATH_FALL_TIME, 0.0, 1.0)
			pose.right_rot = Vector3(0.0, 0.0, -0.8)
	return pose


func _pose_move(pose: Pose) -> void:
	var speed_ratio: float = clampf(Player.flat(_player.velocity).length() / _player.max_speed, 0.0, 1.0)
	if speed_ratio > 0.05:
		_walk_phase += get_process_delta_time() * WALK_STEP_RATE * speed_ratio
	var swing: float = sin(_walk_phase) * WALK_SWING * speed_ratio
	pose.right_rot.x = swing
	pose.left_rot.x = -swing
	pose.bob = absf(sin(_walk_phase)) * WALK_BOB * speed_ratio
	var breath: float = sin(_clock * 2.0) * IDLE_BREATH
	pose.right_pos.y += breath
	pose.left_pos.y += breath


func _pose_attack(pose: Pose, t: float) -> void:
	var times: Vector3 = _player.attack_phase_times()  # preparação, golpe, recuperação
	var keys: Array = COMBO_POSES[clampi(_player.combo_step(), 0, COMBO_POSES.size() - 1)]
	var windup: Vector3 = keys[0]
	var strike: Vector3 = keys[1]
	var finisher: bool = _player.combo_step() == COMBO_POSES.size() - 1
	if t < times.x:
		pose.right_rot = Vector3.ZERO.lerp(windup, _ease_out(t / maxf(times.x, 0.001)))
	elif t < times.x + times.y:
		var k: float = (t - times.x) / maxf(times.y, 0.001)
		pose.right_rot = windup.lerp(strike, _ease_in_out(k))
		pose.lean.x = STRIKE_LEAN * (1.6 if finisher else 1.0) * k
	else:
		var k: float = clampf((t - times.x - times.y) / maxf(times.z, 0.001), 0.0, 1.0)
		pose.right_rot = strike.lerp(Vector3.ZERO, _ease_in_out(k))
		pose.lean.x = STRIKE_LEAN * (1.6 if finisher else 1.0) * (1.0 - k)
	if finisher:
		pose.right_pos = RIGHT_REST_POS + Vector3(-0.15, 0.25, -0.1)
	# Durante o golpe o pulso não segue a pose suavizada: seria lento demais.
	_right_rot = pose.right_rot


func _pose_ability(pose: Pose, t: float) -> void:
	var ability: AbilityData = _player.active_ability()
	if ability is SpinSlashData:
		var spin := ability as SpinSlashData
		pose.right_rot = Vector3(-PI / 2.0, -PI / 2.0, 0.0)  # arma estendida para a direita
		pose.spin = -TAU * clampf(t / maxf(spin.duration, 0.001), 0.0, 1.0)
	elif ability is ShieldBashData:
		var bash := ability as ShieldBashData
		var k: float = clampf(t / maxf(bash.active_end, 0.001), 0.0, 1.0)
		pose.left_pos = LEFT_BLOCK_POS.lerp(LEFT_BASH_POS, _ease_out(k))
		pose.lean.x = STRIKE_LEAN * k
	elif ability is TauntData:
		pose.right_pos = RIGHT_RAISED_POS
		pose.right_rot = Vector3(0.0, 0.0, 0.3)
		pose.lean.x = HURT_LEAN * 0.5
	elif ability is ProjectileSpellData:
		pose.right_rot = Vector3(-PI / 2.0, 0.0, 0.0)  # aponta para a frente
		pose.right_pos = RIGHT_REST_POS + Vector3(-0.1, 0.2, -0.2)
	elif ability is HealSpellData or ability is SupportSpellData:
		pose.right_pos = RIGHT_RAISED_POS
		pose.right_rot = Vector3(-0.15, 0.0, 0.0)  # cajado erguido
	if pose.spin != 0.0:
		_right_rot = pose.right_rot


static func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 2.0)


static func _ease_in_out(k: float) -> float:
	k = clampf(k, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)
