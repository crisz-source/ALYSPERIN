class_name PlayerInput
extends Node
## Traduz teclado e mouse em intenções do jogador.
##
## O Player nunca lê o teclado diretamente: ele pergunta a este nó o que o
## jogador quer fazer. No co-op (Fase 7), um jogador remoto terá um nó
## equivalente que preenche as mesmas variáveis com dados vindos da rede.
##
## Input buffer: um clique de ataque ou esquiva fica "guardado" por
## BUFFER_TIME segundos. Se o personagem ainda estiver ocupado (no meio de
## outro golpe), a ação sai assim que ele ficar livre, em vez de ser perdida.

## Quanto tempo um comando apertado continua valendo, em segundos. Cobre um
## clique dado durante a lâmina ativa até o fim da recuperação do golpe.
const BUFFER_TIME: float = 0.2

## Direção desejada de movimento. Comprimento entre 0 e 1 (diagonal já normalizada).
var move_direction: Vector2 = Vector2.ZERO
## Ponto do mundo para onde o jogador está mirando (cursor do mouse).
var aim_position: Vector2 = Vector2.ZERO

var _attack_buffer: float = 0.0
var _dodge_buffer: float = 0.0


## Atualiza as intenções. O Player chama isto no início do próprio quadro de
## física, para nunca ler um valor atrasado em um quadro.
func poll(delta: float) -> void:
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var viewport: Viewport = get_viewport()
	aim_position = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	_attack_buffer = BUFFER_TIME if Input.is_action_just_pressed("attack") else maxf(_attack_buffer - delta, 0.0)
	_dodge_buffer = BUFFER_TIME if Input.is_action_just_pressed("dodge") else maxf(_dodge_buffer - delta, 0.0)


func has_attack() -> bool:
	return _attack_buffer > 0.0


func has_dodge() -> bool:
	return _dodge_buffer > 0.0


## Consome o comando para que um clique não gere duas ações.
func consume_attack() -> void:
	_attack_buffer = 0.0


func consume_dodge() -> void:
	_dodge_buffer = 0.0
