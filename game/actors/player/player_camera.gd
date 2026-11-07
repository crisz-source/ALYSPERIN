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


func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var amount: float = _current_strength()
	# Arredonda para pixels inteiros: tremida fracionária borra a pixel art.
	offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount)).round()


func _current_strength() -> float:
	if _shake_duration <= 0.0:
		return 0.0
	return _shake_strength * (_shake_time_left / _shake_duration)
