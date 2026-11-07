class_name DamageInfo
extends RefCounted
## Pacote de informação de um golpe: quanto dano, para onde empurra e quem causou.
##
## Viaja do Hitbox (quem bate) até o HealthComponent (quem apanha). Ter um objeto
## único facilita acrescentar campos depois (elemento mágico, crítico, quebra de
## escudo) sem mudar a assinatura de todas as funções. No co-op, é este pacote
## que o host vai validar e replicar.

var amount: int = 0
## Direção e força do empurrão, em pixels por segundo.
var knockback: Vector2 = Vector2.ZERO
## Nó que causou o dano (pode ser liberado antes do pacote ser lido: checar com is_instance_valid).
var source: Node = null


func _init(p_amount: int = 0, p_knockback: Vector2 = Vector2.ZERO, p_source: Node = null) -> void:
	amount = p_amount
	knockback = p_knockback
	source = p_source
