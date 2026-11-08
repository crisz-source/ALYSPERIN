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
## Espaços da barra de habilidades, na ordem: teclas 1-9 e depois F1-F12.
const ABILITY_ACTIONS: Array[String] = [
	"ability_1", "ability_2", "ability_3", "ability_4", "ability_5", "ability_6", "ability_7", "ability_8", "ability_9",
	"ability_f1", "ability_f2", "ability_f3", "ability_f4", "ability_f5", "ability_f6",
	"ability_f7", "ability_f8", "ability_f9", "ability_f10", "ability_f11", "ability_f12",
]
const ABILITY_SLOTS: int = 21
## Nome da tecla de cada espaço (mostrado na barra).
const ABILITY_KEY_LABELS: Array[String] = [
	"1", "2", "3", "4", "5", "6", "7", "8", "9",
	"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
]

## Direção desejada de movimento. Comprimento entre 0 e 1 (diagonal já normalizada).
var move_direction: Vector2 = Vector2.ZERO
## Direção da mira no chão (para onde a câmera olha). Lida da câmera em poll();
## no co-op, a entrada de rede preenche este mesmo campo.
var aim_direction: Vector3 = Vector3.FORWARD
## Câmera que define a mira (definida pelo Player).
var camera_rig: PlayerCamera
## Defesa: vale enquanto o botão estiver segurado (sem buffer).
var defend_held: bool = false

var _attack_buffer: float = 0.0
var _dodge_buffer: float = 0.0
var _interact_buffer: float = 0.0
## Criado já preenchido na declaração (e não no _ready): assim também vale
## quando o script é trocado num nó que já está na cena (entrada de rede/testes).
var _ability_buffers: Array[float] = _zeroed(ABILITY_SLOTS)


static func _zeroed(count: int) -> Array[float]:
	var list: Array[float] = []
	list.resize(count)
	list.fill(0.0)
	return list


## Atualiza as intenções. O Player chama isto no início do próprio quadro de
## física, para nunca ler um valor atrasado em um quadro.
func poll(delta: float) -> void:
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if camera_rig:
		aim_direction = camera_rig.flat_forward()
	defend_held = Input.is_action_pressed("defend")
	_attack_buffer = BUFFER_TIME if Input.is_action_just_pressed("attack") else maxf(_attack_buffer - delta, 0.0)
	_dodge_buffer = BUFFER_TIME if Input.is_action_just_pressed("dodge") else maxf(_dodge_buffer - delta, 0.0)
	_interact_buffer = BUFFER_TIME if Input.is_action_just_pressed("interact") else maxf(_interact_buffer - delta, 0.0)
	for i in ABILITY_SLOTS:
		_ability_buffers[i] = BUFFER_TIME if Input.is_action_just_pressed(ABILITY_ACTIONS[i]) else maxf(_ability_buffers[i] - delta, 0.0)


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


## Primeiro espaço de habilidade guardado no buffer (0..20), ou -1.
func pending_ability() -> int:
	for i in ABILITY_SLOTS:
		if _ability_buffers[i] > 0.0:
			return i
	return -1


func consume_ability(slot: int) -> void:
	_ability_buffers[slot] = 0.0
