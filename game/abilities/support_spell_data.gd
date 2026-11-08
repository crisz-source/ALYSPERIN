class_name SupportSpellData
extends AbilityData
## Habilidade de proteção/suporte (níveis altos do Guardião e do Devoto).
## Um só tipo de dado com a mecânica escolhida em `mechanic`; quem executa é o
## Player (_cast_support). Números provisórios.

enum Mechanic {
	SELF_EFFECT,   ## efeito de status em si mesmo (Postura inabalável, Bastião eterno)
	GROUP_EFFECT,  ## efeito em si e nos aliados do raio (Muralha compartilhada)
	DOME,          ## cúpula parada que protege quem está dentro (Fortaleza viva)
	ALLY_SHIELD,   ## escudo de vida no aliado da mira, ou em si (Bênção de proteção)
	HEAL_ZONE,     ## área no chão que cura quem está dentro (Círculo de cura)
	REVIVE,        ## levanta um aliado caído (Ressurreição)
	GROUP_HEAL,    ## cura total do grupo e limpa efeitos negativos (Milagre)
}

@export var mechanic: Mechanic = Mechanic.SELF_EFFECT
## Efeito de status aplicado (SELF_EFFECT / GROUP_EFFECT / DOME).
@export var effect_id: StringName
## Força do efeito (ex.: 0,3 = 30% menos dano).
@export var strength: float = 0.0
## Duração do efeito ou da área (s).
@export var duration: float = 6.0
## Raio da área ou do alcance (m).
@export var radius: float = 8.0
## Quantidade: escudo (ALLY_SHIELD), cura por segundo (HEAL_ZONE),
## porcentagem da vida ao reviver (REVIVE).
@export var amount: int = 0
## Tempo até o efeito sair, depois de apertar a tecla (s).
@export var cast_time: float = 0.25


func is_implemented() -> bool:
	return true
