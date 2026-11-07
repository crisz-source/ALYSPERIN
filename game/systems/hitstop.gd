extends Node
## Hitstop: congela o jogo por poucos centésimos de segundo no impacto de um
## golpe, para o acerto "pesar". Registrado como autoload com o nome Hitstop.
##
## Congela via Engine.time_scale = 0 e descongela olhando o relógio real a cada
## quadro (_process continua sendo chamado com time_scale = 0).
##
## Por que não usar um timer: timers que "ignoram time_scale" contam por outro
## relógio e disparavam antes do horário real (21 ms num pedido de 50 ms). Misturar
## os dois relógios deixava o jogo congelado para sempre. Ver worklog
## 2026-11-07-combate-area-f5.md.
##
## ATENÇÃO co-op (Fase 7): time_scale é global da máquina. Com vários jogadores,
## congelar o jogo inteiro a cada golpe de um deles fica ruim; nessa fase o
## hitstop deve virar efeito local (só no atacante/alvo). Todo pedido passa por
## request(), então a troca acontece só aqui.

## Desligar para testar sem pausas ou se o jogador preferir.
@export var enabled: bool = true

## Momento (relógio real, microssegundos) em que o congelamento acaba. 0 = solto.
var _frozen_until_usec: int = 0


func _ready() -> void:
	# Precisa rodar mesmo com o jogo pausado, senão não descongelaria.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Congela por `duration` segundos. Pedidos sobrepostos não somam: vale o que
## terminar mais tarde.
func request(duration: float) -> void:
	if not enabled or duration <= 0.0:
		return
	var until: int = Time.get_ticks_usec() + int(duration * 1_000_000.0)
	_frozen_until_usec = maxi(_frozen_until_usec, until)
	Engine.time_scale = 0.0


func is_frozen() -> bool:
	return _frozen_until_usec > 0


func _process(_delta: float) -> void:
	if _frozen_until_usec > 0 and Time.get_ticks_usec() >= _frozen_until_usec:
		_frozen_until_usec = 0
		Engine.time_scale = 1.0
