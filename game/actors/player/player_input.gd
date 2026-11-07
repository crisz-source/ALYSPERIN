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
## Teclas de habilidade (ações ability_1 .. ability_6).
const ABILITY_SLOTS: int = 6

## Direção desejada de movimento. Comprimento entre 0 e 1 (diagonal já normalizada).
var move_direction: Vector2 = Vector2.ZERO
## Ponto do mundo para onde o jogador está mirando (cursor do mouse).
var aim_position: Vector2 = Vector2.ZERO
## Defesa: vale enquanto o botão estiver segurado (sem buffer).
var defend_held: bool = false

var _attack_buffer: float = 0.0
var _dodge_buffer: float = 0.0
var _interact_buffer: float = 0.0
var _ability_buffers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]


## Atualiza as intenções. O Player chama isto no início do próprio quadro de
## física, para nunca ler um valor atrasado em um quadro.
func poll(delta: float) -> void:
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var viewport: Viewport = get_viewport()
	aim_position = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	defend_held = Input.is_action_pressed("defend")
	_attack_buffer = BUFFER_TIME if Input.is_action_just_pressed("attack") else maxf(_attack_buffer - delta, 0.0)
	_dodge_buffer = BUFFER_TIME if Input.is_action_just_pressed("dodge") else maxf(_dodge_buffer - delta, 0.0)
	_interact_buffer = BUFFER_TIME if Input.is_action_just_pressed("interact") else maxf(_interact_buffer - delta, 0.0)
	for i in ABILITY_SLOTS:
		var action: String = "ability_%d" % (i + 1)
		_ability_buffers[i] = BUFFER_TIME if Input.is_action_just_pressed(action) else maxf(_ability_buffers[i] - delta, 0.0)


## Zera todas as intenções (ex.: com uma tela de menu aberta).
func clear() -> void:
	move_direction = Vector2.ZERO
	defend_held = false
	_attack_buffer = 0.0
	_dodge_buffer = 0.0
	_interact_buffer = 0.0
	_ability_buffers.fill(0.0)


func has_attack() -> bool:
	return _attack_buffer > 0.0


func has_dodge() -> bool:
	return _dodge_buffer > 0.0


func has_interact() -> bool:
	return _interact_buffer > 0.0


## Consome o comando para que um clique não gere duas ações.
func consume_attack() -> void:
	_attack_buffer = 0.0


func consume_dodge() -> void:
	_dodge_buffer = 0.0


func consume_interact() -> void:
	_interact_buffer = 0.0


## Primeira tecla de habilidade guardada no buffer (0..5), ou -1.
func pending_ability() -> int:
	for i in ABILITY_SLOTS:
		if _ability_buffers[i] > 0.0:
			return i
	return -1


func consume_ability(slot: int) -> void:
	_ability_buffers[slot] = 0.0
