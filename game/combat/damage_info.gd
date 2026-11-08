class_name DamageInfo
extends RefCounted
## Pacote de informação de um golpe: quanto dano, para onde empurra e quem causou.
##
## Viaja do Hitbox (quem bate) até o HealthComponent (quem apanha). Ter um objeto
## único facilita acrescentar campos depois (elemento mágico, crítico, quebra de
## escudo) sem mudar a assinatura de todas as funções. No co-op, é este pacote
## que o host vai validar e replicar.

var amount: int = 0
## Direção e força do empurrão no chão (plano X/Z), em metros por segundo.
var knockback: Vector3 = Vector3.ZERO
## Nó que causou o dano (pode ser liberado antes do pacote ser lido: checar com is_instance_valid).
var source: Node = null
## Marcado pelo HealthComponent quando quem apanha bloqueou o golpe (sem dano).
var blocked: bool = false
## Marcado quando o golpe acertou pelas costas (dano maior).
var backstab: bool = false
## Dano contínuo (queimadura, veneno): não é bloqueado, ignora invulnerabilidade,
## não empurra e não interrompe quem apanha.
var over_time: bool = false
## Elemento do golpe (&"fire", &"ice", &"lightning", &"earth", &"light", &"dark")
## ou vazio = físico neutro. Chefes usam para fraquezas/resistências.
var element: StringName = &""


func _init(p_amount: int = 0, p_knockback: Vector3 = Vector3.ZERO, p_source: Node = null) -> void:
	amount = p_amount
	knockback = p_knockback
	source = p_source
