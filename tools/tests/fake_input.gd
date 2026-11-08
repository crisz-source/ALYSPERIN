extends PlayerInput
## Entrada controlada pelo teste: mesma interface que a entrada de rede usará.

func poll(delta: float) -> void:
	_attack_buffer = maxf(_attack_buffer - delta, 0.0)
	_dodge_buffer = maxf(_dodge_buffer - delta, 0.0)
	_interact_buffer = maxf(_interact_buffer - delta, 0.0)
	for i in ABILITY_SLOTS:
		_ability_buffers[i] = maxf(_ability_buffers[i] - delta, 0.0)


func press_attack() -> void:
	_attack_buffer = BUFFER_TIME


func press_dodge() -> void:
	_dodge_buffer = BUFFER_TIME


func press_interact() -> void:
	_interact_buffer = BUFFER_TIME


func press_ability(slot: int) -> void:
	if _ability_buffers.is_empty():
		_ability_buffers.resize(ABILITY_SLOTS)
		_ability_buffers.fill(0.0)
	_ability_buffers[slot] = BUFFER_TIME
