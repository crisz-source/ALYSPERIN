class_name Crosshair
extends Control
## Mira no centro da tela (estilo jogos de ação com câmera livre).
##
## Dois visuais: livre (quatro marquinhas brancas, abertas) e "mirando" (fecha e
## fica vermelha) quando há um inimigo no centro da tela. NÃO trava no inimigo:
## só indica; os golpes continuam saindo para onde a câmera olha.
## Quem decide se há inimigo na mira é o HUD (raio a partir da câmera).

const IDLE_COLOR := Color(1.0, 1.0, 1.0, 0.75)
const TARGET_COLOR := Color(1.0, 0.3, 0.25, 0.95)
const IDLE_GAP: float = 6.0
const TARGET_GAP: float = 3.0
const TICK_LENGTH: float = 4.0

var targeted: bool = false:
	set(value):
		if value != targeted:
			targeted = value
			queue_redraw()
## Abertura atual (anima entre as duas posições).
var _gap: float = IDLE_GAP


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(24, 24)


func _process(delta: float) -> void:
	var wanted: float = TARGET_GAP if targeted else IDLE_GAP
	if not is_equal_approx(_gap, wanted):
		_gap = move_toward(_gap, wanted, 40.0 * delta)
		queue_redraw()


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var color: Color = TARGET_COLOR if targeted else IDLE_COLOR
	# Quatro marquinhas apontando para o centro.
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(c + dir * _gap, c + dir * (_gap + TICK_LENGTH), color, 1.0)
	if targeted:
		# Cantos fechando sobre o alvo + ponto central.
		var r: float = _gap + TICK_LENGTH + 1.0
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var p: Vector2 = c + corner * r
			draw_line(p, p - Vector2(corner.x * 3.0, 0), color, 1.0)
			draw_line(p, p - Vector2(0, corner.y * 3.0), color, 1.0)
		draw_rect(Rect2(c - Vector2.ONE, Vector2(2, 2)), color)
	else:
		draw_rect(Rect2(c - Vector2(0.5, 0.5), Vector2(1, 1)), color)
