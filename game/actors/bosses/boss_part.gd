class_name BossPart
extends Hurtbox
## Parte destrutível de um chefe (bulbo, chicote, casca, boca, cerne).
## Recebe o golpe e repassa ao chefe, que aplica resistências, tira da vida
## total e da vida desta parte. part_max_hp = 0: parte que não quebra (cerne).

@export var part_id: StringName
@export var part_max_hp: int = 0
## Multiplicador de dano nesta parte (ex.: cerne exposto = crítico).
@export var damage_scale: float = 1.0

var part_hp: int = 0
var broken: bool = false
var boss: Node


func _ready() -> void:
	part_hp = part_max_hp
	super._ready()


func receive_hit(info: DamageInfo) -> bool:
	if not is_instance_valid(boss):
		return false
	var ok: bool = boss.apply_part_hit(self, info)
	if ok:
		hit_received.emit(info)
	return ok


## Desliga a parte (quebrada ou ainda escondida, como o cerne).
func set_hittable(value: bool) -> void:
	set_deferred("monitorable", value)
