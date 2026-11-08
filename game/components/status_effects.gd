class_name StatusEffects
extends Node
## Efeitos de status de quem pode recebê-los (jogador, inimigo, chefe):
## lentidão, congelamento, queimadura, veneno, atordoamento, medo, provocação.
##
## Guarda só QUAIS efeitos estão ativos e por quanto tempo, e aplica o dano
## contínuo (queimadura/veneno) pelo HealthComponent. Quem decide o que cada
## efeito faz no corpo (andar mais devagar, fugir, não agir) é o dono, lendo
## speed_multiplier(), is_disabled(), fear_source() etc.
## Mostra o nome dos efeitos ativos acima da cabeça (texto provisório, sem ícone).

signal effect_started(id: StringName)
signal effect_ended(id: StringName)

const SLOW := &"slow"
const FREEZE := &"freeze"
const BURN := &"burn"
const POISON := &"poison"
const STUN := &"stun"
const FEAR := &"fear"
const TAUNT := &"taunt"
## Positivos (habilidades de proteção):
const STANCE := &"stance"      ## defendendo: bloqueia por todos os lados, sem empurrão
const PROTECT := &"protect"    ## recebe menos dano (strength = fração reduzida)
const UNDYING := &"undying"    ## não cai abaixo de 1 de vida
## Efeitos que o Milagre remove.
const NEGATIVE: Array[StringName] = [&"slow", &"freeze", &"burn", &"poison", &"stun", &"fear"]

## Nome mostrado e cor de cada efeito.
const INFO: Dictionary = {
	&"slow": ["Lento", Color(0.6, 0.75, 1.0)],
	&"freeze": ["Congelado", Color(0.55, 0.9, 1.0)],
	&"burn": ["Queimando", Color(1.0, 0.5, 0.2)],
	&"poison": ["Envenenado", Color(0.55, 0.95, 0.35)],
	&"stun": ["Atordoado", Color(1.0, 0.9, 0.4)],
	&"fear": ["Medo", Color(0.75, 0.5, 1.0)],
	&"taunt": ["Provocado", Color(1.0, 0.45, 0.3)],
	&"stance": ["Postura", Color(0.7, 0.85, 1.0)],
	&"protect": ["Protegido", Color(0.6, 0.8, 1.0)],
	&"undying": ["Inabalável", Color(1.0, 0.85, 0.4)],
}
## Dano contínuo: um tique a cada TICK_INTERVAL segundos.
const TICK_INTERVAL: float = 0.5
## Tinta por cima do corpo para os efeitos que mudam a aparência.
const TINTS: Dictionary = {
	&"freeze": Color(0.55, 0.85, 1.0, 0.55),
	&"burn": Color(1.0, 0.45, 0.1, 0.35),
	&"poison": Color(0.45, 0.9, 0.3, 0.35),
	&"fear": Color(0.6, 0.35, 0.9, 0.3),
}

var health: HealthComponent
## Altura do texto acima da origem do dono (m).
var text_height: float = 2.4

## id -> {time: s restantes, strength: float, source: Node, tick: s até o próximo tique}
var _effects: Dictionary = {}
var _label: Label3D


## Cria e prende o componente no dono (ex.: no _ready do Player/inimigo).
static func attach(owner_node: Node3D, owner_health: HealthComponent, height: float) -> StatusEffects:
	var fx := StatusEffects.new()
	fx.name = "StatusEffects"
	fx.health = owner_health
	fx.text_height = height
	if owner_health:
		owner_health.status = fx
	owner_node.add_child(fx)
	return fx


func _ready() -> void:
	_label = Label3D.new()
	_label.name = "StatusLabel"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = true
	_label.pixel_size = 0.0008
	_label.font_size = 20
	_label.outline_size = 6
	_label.position = Vector3(0, text_height, 0)
	_label.visible = false
	get_parent().add_child.call_deferred(_label)
	if health:
		health.died.connect(clear_all)


## Aplica (ou renova) um efeito. Renovar fica com a maior duração e a maior força.
## strength: lentidão = fração da velocidade perdida (0,4 = 40% mais lento);
## queimadura/veneno = dano por segundo.
func apply(id: StringName, duration: float, strength: float = 0.0, source: Node = null) -> void:
	if duration <= 0.0 or (health and health.is_dead):
		return
	assert(INFO.has(id), "StatusEffects: efeito desconhecido %s" % id)
	var fresh: bool = not _effects.has(id)
	var e: Dictionary = _effects.get(id, {"time": 0.0, "strength": 0.0, "source": null, "tick": TICK_INTERVAL})
	e.time = maxf(e.time, duration)
	e.strength = maxf(e.strength, strength)
	if source:
		e.source = source
	_effects[id] = e
	_refresh_label()
	if fresh:
		effect_started.emit(id)


func remove(id: StringName) -> void:
	if _effects.erase(id):
		_refresh_label()
		effect_ended.emit(id)


## Remove os efeitos negativos (Milagre).
func clear_negative() -> void:
	for id: StringName in NEGATIVE:
		remove(id)


func clear_all() -> void:
	for id: StringName in _effects.keys():
		remove(id)


func has(id: StringName) -> bool:
	return _effects.has(id)


func remaining(id: StringName) -> float:
	return float(_effects[id].time) if _effects.has(id) else 0.0


func active_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_effects.keys())
	return ids


## Força de um efeito ativo (0 se não houver).
func strength_of(id: StringName) -> float:
	return float(_effects[id].strength) if _effects.has(id) else 0.0


## Multiplica a velocidade de movimento (congelado = parado).
func speed_multiplier() -> float:
	if has(FREEZE) or has(STUN):
		return 0.0
	if has(SLOW):
		return clampf(1.0 - float(_effects[SLOW].strength), 0.1, 1.0)
	return 1.0


## Não pode agir (atacar, usar habilidade, andar).
func is_disabled() -> bool:
	return has(FREEZE) or has(STUN)


## De quem foge (medo) ou null.
func fear_source() -> Node3D:
	if not has(FEAR):
		return null
	var src: Variant = _effects[FEAR].source
	return src as Node3D if is_instance_valid(src) else null


## Cor por cima do corpo (alfa 0 = nenhuma). Congelado tem prioridade.
func tint() -> Color:
	for id: StringName in [FREEZE, BURN, POISON, FEAR]:
		if has(id):
			return TINTS[id]
	return Color(1, 1, 1, 0)


func _physics_process(delta: float) -> void:
	if _effects.is_empty():
		return
	for id: StringName in _effects.keys():
		var e: Dictionary = _effects[id]
		if id == BURN or id == POISON:
			e.tick -= delta
			if e.tick <= 0.0:
				e.tick += TICK_INTERVAL
				_damage_tick(id, e)
		e.time -= delta
		if e.time <= 0.0:
			remove(id)


func _damage_tick(id: StringName, e: Dictionary) -> void:
	if health == null or health.is_dead:
		return
	var amount: int = maxi(roundi(float(e.strength) * TICK_INTERVAL), 1)
	var info := DamageInfo.new(amount, Vector3.ZERO, e.source if is_instance_valid(e.source) else null)
	info.over_time = true
	info.element = &"fire" if id == BURN else &""
	health.apply_damage(info)


func _refresh_label() -> void:
	if _label == null:
		return
	var names: Array[String] = []
	var color := Color.WHITE
	for id: StringName in _effects.keys():
		names.append(INFO[id][0])
		color = INFO[id][1]
	_label.text = " · ".join(names)
	_label.modulate = color
	_label.visible = not names.is_empty()
