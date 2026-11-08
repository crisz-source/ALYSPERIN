class_name PlayerCamera
extends Node3D
## Câmera em terceira pessoa: este nó gira na horizontal (yaw), o filho Pitch
## na vertical, e um braço com colisão (SpringArm3D) afasta a câmera sem
## atravessar paredes.
##
## O mouse gira a câmera. O mouse fica "preso" durante o jogo e é solto
## automaticamente quando o jogador não pode agir (inventário, diálogo, morte).
## Esc solta manualmente; clicar prende de novo.
## A tremida mexe só no deslocamento da lente, nunca na posição.

@export var mouse_sensitivity: float = 0.004
@export var min_pitch_degrees: float = -65.0
@export var max_pitch_degrees: float = 15.0
## Converte a força de tremida da versão 2D (pixels) para metros.
@export var shake_scale: float = 0.025
## Distância da câmera (roda do mouse): mais perto / mais longe para ver o ambiente.
@export var min_distance: float = 3.5
@export var max_distance: float = 14.0
@export var zoom_step: float = 1.0

## Quem a câmera segue; usado para saber se o jogador pode agir.
var player: Player
var _manual_release: bool = false
var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
## Distância desejada; o braço chega nela suavemente.
var target_distance: float = 6.5

@onready var _pitch: Node3D = $Pitch
@onready var camera: Camera3D = $Pitch/SpringArm/Camera
@onready var _arm: SpringArm3D = $Pitch/SpringArm


func _ready() -> void:
	target_distance = _arm.spring_length


## Para frente da câmera, no chão (sem inclinação): direção dos golpes.
func flat_forward() -> Vector3:
	var f: Vector3 = -global_basis.z
	f.y = 0.0
	return f.normalized() if f.length() > 0.001 else Vector3.FORWARD


func flat_right() -> Vector3:
	var r: Vector3 = global_basis.x
	r.y = 0.0
	return r.normalized() if r.length() > 0.001 else Vector3.RIGHT


## Gira a câmera para olhar numa direção (ex.: ao nascer, ou em testes).
func face(direction: Vector3) -> void:
	if direction.length() > 0.001:
		rotation.y = atan2(-direction.x, -direction.z)


## strength na escala antiga (pixels); o tremor diminui até zero em duration segundos.
func shake(strength: float, duration: float) -> void:
	if strength < _current_strength():
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_time_left = duration


func reset_smoothing() -> void:
	pass  # mantido pela interface antiga; a câmera 3D não suaviza a posição


func _unhandled_input(event: InputEvent) -> void:
	if not _can_control():
		return
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-motion.relative.x * mouse_sensitivity)
		_pitch.rotation.x = clampf(_pitch.rotation.x - motion.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and ((event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_UP
			or (event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_DOWN):
		zoom((event as InputEventMouseButton).button_index == MOUSE_BUTTON_WHEEL_DOWN)
	elif event.is_action_pressed("pause"):
		_manual_release = not _manual_release
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and _manual_release:
		_manual_release = false
		get_viewport().set_input_as_handled()


## Afasta (true) ou aproxima (false) um passo.
func zoom(out: bool) -> void:
	target_distance = clampf(target_distance + (zoom_step if out else -zoom_step), min_distance, max_distance)


func _process(delta: float) -> void:
	_arm.spring_length = move_toward(_arm.spring_length, target_distance, 12.0 * delta)
	var wants_capture: bool = _can_control() and not _manual_release
	var mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED if wants_capture else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mode and DisplayServer.get_name() != "headless":
		Input.mouse_mode = mode
	if _shake_time_left <= 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var amount: float = _current_strength() * shake_scale
	camera.h_offset = randf_range(-amount, amount)
	camera.v_offset = randf_range(-amount, amount)


func _can_control() -> bool:
	return player != null and not player.input_blocked and not player.health.is_dead


func _current_strength() -> float:
	if _shake_duration <= 0.0:
		return 0.0
	return _shake_strength * (_shake_time_left / _shake_duration)
