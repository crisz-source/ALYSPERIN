class_name PlayerInput
extends Node
## Traduz teclado e mouse em intenções do jogador.
##
## O Player nunca lê o teclado diretamente: ele pergunta a este nó o que o
## jogador quer fazer. No co-op (Fase 7), um jogador remoto terá um nó
## equivalente que preenche as mesmas variáveis com dados vindos da rede.

## Direção desejada de movimento. Comprimento entre 0 e 1 (diagonal já normalizada).
var move_direction: Vector2 = Vector2.ZERO


## Atualiza as intenções. O Player chama isto no início do próprio quadro de
## física, para nunca ler um valor atrasado em um quadro.
func poll() -> void:
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
