class_name PlayerCamera
extends Camera2D
## Câmera que segue o jogador, com tremida curta para dar peso aos impactos.
##
## A tremida mexe só no offset (deslocamento visual), nunca na posição: a câmera
## continua centrada no personagem e a lógica do jogo não é afetada.

var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0


## strength em pixels; o tremor diminui até zero ao longo de duration segundos.
func shake(strength: float, duration: float) -> void:
	if strength < _current_strength():
		return
	_shake_strength = strength
	_shake_duration = duration
	_shake_time_left = duration


## Prende a câmera dentro do retângulo do mapa (em pixels do mundo), para
## nunca mostrar o vazio fora da área.
func set_world_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	# Sem isto, ao nascer perto da borda a câmera "desliza" do centro até o limite.
	reset_smoothing()


func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var amount: float = _current_strength()
	# Arredonda para pixels inteiros: tremida fracionária borra a pixel art.
	var wanted := Vector2(randf_range(-amount, amount), randf_range(-amount, amount)).round()
	offset = _clamp_offset_to_limits(wanted)


## A Godot aplica os limites só à posição, não ao offset: perto da borda a
## tremida mostraria alguns pixels de vazio. Aqui o offset é limitado para a
## vista continuar dentro do mapa.
func _clamp_offset_to_limits(wanted: Vector2) -> Vector2:
	var base_center: Vector2 = get_screen_center_position() - offset
	var half_view: Vector2 = get_viewport_rect().size / (2.0 * zoom)
	var low: Vector2 = Vector2(limit_left, limit_top) + half_view - base_center
	var high: Vector2 = Vector2(limit_right, limit_bottom) - half_view - base_center
	# ceil/floor mantêm o pixel inteiro sem passar do limite; min/max com 0
	# garantem que "sem tremida" sempre é permitido.
	return Vector2(
		clampf(wanted.x, minf(ceilf(low.x), 0.0), maxf(floorf(high.x), 0.0)),
		clampf(wanted.y, minf(ceilf(low.y), 0.0), maxf(floorf(high.y), 0.0)))


func _current_strength() -> float:
	if _shake_duration <= 0.0:
		return 0.0
	return _shake_strength * (_shake_time_left / _shake_duration)
