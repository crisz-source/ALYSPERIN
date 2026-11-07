class_name Interactable
extends Area2D
## Área que torna um objeto "usável" com a tecla de interagir (F).
##
## O objeto dono (porta, alavanca, placa, baú no futuro) registra em `handler`
## a função que diz o que acontece; ela recebe quem interagiu e devolve uma
## mensagem para mostrar (ou "" para nenhuma). Quem procura objetos por perto
## é o jogador (InteractionDetector); esta área só existe para ser encontrada.

signal interacted(by: Player)

## Verbo mostrado no aviso acima do objeto: "[F] <prompt_text>".
@export var prompt_text: String = "Usar"
## Onde o aviso aparece, relativo ao objeto (px).
@export var prompt_offset: Vector2 = Vector2(0, -24)
## Desligado = o jogador não vê aviso nem consegue usar.
@export var enabled: bool = true

## func(by: Player) -> String. Definido pelo dono no _ready dele.
var handler: Callable


func _ready() -> void:
	monitoring = false
	monitorable = true


func prompt_position() -> Vector2:
	return global_position + prompt_offset


## Chamado pelo jogador. Devolve a mensagem a mostrar ("" = nenhuma).
func interact(by: Player) -> String:
	if not enabled:
		return ""
	interacted.emit(by)
	return handler.call(by) if handler.is_valid() else ""
