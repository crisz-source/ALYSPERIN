class_name Player
extends CharacterBody2D
## Personagem controlável: movimento, combo, defesa, esquiva, dano, morte,
## itens (inventário/equipamento) e progressão (nível e atributos).
##
## Organizado como uma máquina de estados simples: em cada momento o personagem
## está em exatamente um estado (andando, atacando, defendendo...), e cada
## estado decide o que é permitido. Isso evita combinações impossíveis como
## "atacando e esquivando ao mesmo tempo".

signal died
## Um golpe passou por dentro da invencibilidade da esquiva.
signal dodge_succeeded
## Um objeto pediu para mostrar um texto (placa, porta trancada...). O HUD escuta.
signal message_requested(text: String)
## O jogador descartou um item: a área decide onde ele aparece no chão.
signal item_dropped(stack: ItemStack, at_position: Vector2)
## Disciplina escolhida/trocada: habilidades e bônus mudaram (HUD refaz a barra).
signal discipline_changed(discipline: DisciplineData)
## Itens colocados na barra de habilidades mudaram.
signal hotbar_changed
## Um NPC quer conversar: a área abre a caixa de diálogo e chama on_finished no fim.
signal dialogue_requested(speaker: String, lines: Array[String], on_finished: Callable)

enum State { MOVE, ATTACK, BLOCK, DODGE, HURT, ABILITY, DEAD }

const GROUP: StringName = &"players"
const COMBO_LENGTH: int = 3
const PLACEHOLDER_COLOR := Color(0.36, 0.62, 0.92)
const DEAD_COLOR := Color(0.35, 0.35, 0.4)
const SHIELD_COLOR := Color(0.75, 0.85, 1.0, 0.85)
const FINISHER_SWING_TINT := Color(1.0, 0.75, 0.45)
const DODGE_SUCCESS_TEXT := "Esquiva perfeita!"
const DODGE_SUCCESS_COLOR := Color(0.55, 0.95, 1.0)
const LEVEL_UP_COLOR := Color(1.0, 0.85, 0.35)
const BROKEN_COLOR := Color(1.0, 0.45, 0.35)
const MSG_HEALTH_FULL := "A vida já está cheia."
const MSG_MANA_FULL := "A mana já está cheia."
const MSG_INVENTORY_FULL := "Inventário cheio."
const NO_MANA_COLOR := Color(0.5, 0.7, 1.0)

@export_group("Movimento")
## Velocidade máxima, em pixels por segundo (16 px = 1 tile).
@export var max_speed: float = 90.0
## Quanto a velocidade cresce por segundo ao começar a andar.
@export var acceleration: float = 900.0
## Quanto a velocidade cai por segundo ao soltar as teclas.
@export var friction: float = 1100.0

@export_group("Ataque")
## Preparação antes da lâmina causar dano (s).
@export var attack_windup: float = 0.06
## Janela em que a lâmina causa dano (s).
@export var attack_active: float = 0.10
## Recuperação depois do golpe; pode ser cancelada pela esquiva ou defesa (s).
@export var attack_recovery: float = 0.14
## Fração da velocidade normal permitida durante o ataque (0 = fica parado).
@export_range(0.0, 1.0) var attack_move_multiplier: float = 0.3

@export_group("Combo")
## Multiplicador do dano da arma em cada golpe do combo (1º, 2º, 3º = finalizador).
@export var combo_damage_multiplier: Array[float] = [1.0, 1.0, 2.0]
## Empurrão de cada golpe no inimigo (px/s), antes do multiplicador da arma.
@export var combo_knockback: Array[float] = [140.0, 140.0, 260.0]
## Passo à frente que o personagem dá em cada golpe (px/s).
@export var combo_step_impulse: Array[float] = [40.0, 40.0, 110.0]
## Tempo depois de um golpe em que clicar de novo continua o combo (s).
@export var combo_window: float = 0.25
## O finalizador demora mais para sair e para se recuperar: é o preço do dano maior.
@export var finisher_extra_windup: float = 0.05
@export var finisher_extra_recovery: float = 0.12
## Alcance do finalizador em relação ao golpe normal.
@export var finisher_reach_scale: float = 1.25

@export_group("Sem arma")
## Dano do soco (sem arma equipada).
@export var unarmed_damage: int = 4
@export var unarmed_reach_scale: float = 0.7
@export var unarmed_knockback_multiplier: float = 0.6

@export_group("Defesa")
## Fração da velocidade normal enquanto defende.
## (Ângulo protegido e empurrão vêm do escudo equipado: ShieldData.)
@export_range(0.0, 1.0) var block_move_multiplier: float = 0.4

@export_group("Esquiva")
@export var dodge_speed: float = 230.0
@export var dodge_duration: float = 0.24
## Parte inicial da esquiva em que o personagem não toma dano (s).
@export var dodge_invulnerability: float = 0.18
## Tempo mínimo entre o início de uma esquiva e a próxima (s).
@export var dodge_cooldown: float = 0.45

@export_group("Dano recebido")
## Tempo atordoado depois de levar um golpe (s).
@export var hurt_duration: float = 0.18
## Invulnerabilidade depois de levar um golpe, para não morrer em sequência (s).
@export var post_hit_invulnerability: float = 0.7

@export_group("Habilidades")
## Habilidades da barra: posições 0-8 = teclas 1-9, 9-20 = F1-F12. Vazio = sem habilidade.
@export var abilities: Array[AbilityData] = []

@export_group("Hitstop (pausa de impacto)")
@export var hitstop_hit: float = 0.05
@export var hitstop_finisher: float = 0.09
@export var hitstop_hurt: float = 0.07
@export var hitstop_block: float = 0.04

## Direção para onde o personagem está virado: sempre uma das 4 cardeais.
var facing: Vector2 = Vector2.DOWN
var state: State = State.MOVE

var _state_time: float = 0.0
var _dodge_direction: Vector2 = Vector2.ZERO
var _dodge_cooldown_left: float = 0.0
var _flash_time: float = 0.0
var _shield_flash_time: float = 0.0
var _blink_clock: float = 0.0
## Golpe atual do combo: 0, 1 ou 2 (finalizador).
var _combo_step: int = 0
var _combo_window_left: float = 0.0
var _attack_windup_now: float = 0.0
var _attack_active_now: float = 0.0
var _attack_recovery_now: float = 0.0
## Vida máxima sem bônus de Vigor (o valor configurado no HealthComponent).
var _base_max_health: int = 0
var _block_direction: Vector2 = Vector2.DOWN
## Consumíveis arrastados para a barra (mesma posição das habilidades; null = vazio).
## Guarda o TIPO de item: a tecla usa a primeira pilha dele na bolsa.
var hotbar_items: Array[ItemData] = []
## Uma mensagem por esquiva, mesmo que dois inimigos acertem a mesma esquiva.
var _dodge_success_this_dodge: bool = false
## Objeto usável mais próximo (o que recebe o "[E]"), ou null.
var focused_interactable: Interactable = null
## true enquanto uma tela (inventário) estiver aberta: o personagem ignora comandos.
var input_blocked: bool = false
## Onde o jogador volta ao continuar depois da morte (início da área).
var respawn_point: Vector2 = Vector2.ZERO
## Invulnerabilidade ao voltar, para não morrer de novo no mesmo instante (s).
var respawn_invulnerability: float = 1.5
## Segundos restantes de recarga por habilidade (mesma posição da lista).
var _ability_cooldowns: Array[float] = []
var _active_ability: AbilityData = null
## A habilidade em andamento já fez efeito (disparou/curou)?
var _ability_fired: bool = false
## Disciplina escolhida (null = nenhuma ainda).
var discipline: DisciplineData = null
var _base_max_mana: int = 0
## Desgaste fracionário do escudo (Guardião gasta metade: 1 ponto a cada 2 bloqueios).
var _shield_wear_accumulator: float = 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var inventory: Inventory = $Inventory
@onready var equipment: Equipment = $Equipment
@onready var stats: CharacterStats = $CharacterStats
@onready var mana: ManaComponent = $ManaComponent
@onready var quest_log: QuestLog = $QuestLog
@onready var _input: PlayerInput = $PlayerInput
@onready var _facing_indicator: Node2D = $FacingIndicator
@onready var _body: Polygon2D = $BodyPlaceholder
@onready var _attack_pivot: Node2D = $AttackPivot
@onready var _sword_hitbox: Hitbox = $AttackPivot/SwordHitbox
@onready var _swing_visual: CanvasItem = $AttackPivot/SwingPlaceholder
@onready var _shield_visual: Polygon2D = $AttackPivot/ShieldPlaceholder
@onready var _camera: PlayerCamera = $Camera
@onready var _interaction_detector: Area2D = $InteractionDetector
@onready var _interact_prompt: Label = $InteractPrompt
@onready var _spin_hitbox: Hitbox = $SpinHitbox
@onready var _spin_visual: Polygon2D = $SpinPlaceholder


func _ready() -> void:
	assert(combo_damage_multiplier.size() == COMBO_LENGTH and combo_knockback.size() == COMBO_LENGTH \
		and combo_step_impulse.size() == COMBO_LENGTH,
		"Player: listas do combo precisam ter %d valores cada" % COMBO_LENGTH)
	add_to_group(GROUP)
	_facing_indicator.rotation = facing.angle()
	_swing_visual.visible = false
	_shield_visual.visible = false
	health.block_filter = _is_hit_blocked
	health.damaged.connect(_on_damaged)
	health.blocked.connect(_on_blocked)
	health.hit_ignored.connect(_on_hit_ignored)
	health.died.connect(_on_died)
	_sword_hitbox.hit_landed.connect(_on_sword_hit)
	_interact_prompt.top_level = true
	_interact_prompt.visible = false
	_base_max_health = health.max_health
	_base_max_mana = mana.max_mana
	quest_log.inventory = inventory
	inventory.changed.connect(quest_log.refresh_collect)
	respawn_point = global_position
	stats.leveled_up.connect(_on_leveled_up)
	_ability_cooldowns.resize(abilities.size())
	_ability_cooldowns.fill(0.0)
	hotbar_items.resize(PlayerInput.ABILITY_SLOTS)
	_spin_hitbox.hit_landed.connect(_on_ability_hit)
	_spin_visual.visible = false


func _physics_process(delta: float) -> void:
	_input.poll(delta)
	if input_blocked:
		_input.clear()
	_state_time += delta
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	_combo_window_left = maxf(_combo_window_left - delta, 0.0)
	for i in _ability_cooldowns.size():
		_ability_cooldowns[i] = maxf(_ability_cooldowns[i] - delta, 0.0)
	_update_focus()
	match state:
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			_process_attack(delta)
		State.BLOCK:
			_process_block(delta)
		State.DODGE:
			_process_dodge()
		State.HURT:
			_process_hurt(delta)
		State.ABILITY:
			_process_ability(delta)
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	_update_visuals(delta)


## A área avisa o tamanho do mapa; o jogador repassa para a própria câmera.
func set_camera_bounds(bounds: Rect2) -> void:
	_camera.set_world_bounds(bounds)


## Dano do golpe `step` do combo com a arma atual, Força e estado da arma.
func current_attack_damage(step: int) -> int:
	var weapon: WeaponData = equipment.weapon_data()
	var base: float = float(weapon.damage) if weapon else float(unarmed_damage)
	if weapon and equipment.weapon.is_broken():
		base *= weapon.broken_damage_multiplier
	var discipline_bonus: float = 1.0 + (discipline.damage_bonus if discipline else 0.0)
	return maxi(roundi(base * combo_damage_multiplier[step] * stats.damage_multiplier() * discipline_bonus), 1)


## Volta à vida no ponto indicado, com vida cheia. Itens, equipamento e
## experiência são mantidos (nada é recarregado).
func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	health.revive()
	mana.restore_full()
	health.grant_invulnerability(respawn_invulnerability)
	input_blocked = false
	_change_state(State.MOVE)
	_camera.reset_smoothing()


## Aplica a Disciplina: bônus de vida/mana e troca das habilidades.
func apply_discipline(new_discipline: DisciplineData) -> void:
	discipline = new_discipline
	abilities = discipline.abilities.duplicate()
	_ability_cooldowns.resize(abilities.size())
	_ability_cooldowns.fill(0.0)
	_apply_growth()
	discipline_changed.emit(discipline)


## Experiência ganha (ex.: inimigo derrotado).
func gain_xp(amount: int) -> void:
	stats.add_xp(amount)


## Chamado pelo inimigo derrotado por este jogador.
func on_enemy_defeated(kind: StringName, xp: int) -> void:
	gain_xp(xp)
	quest_log.notify_kill(kind)


func request_dialogue(speaker: String, lines: Array[String], on_finished: Callable = Callable()) -> void:
	dialogue_requested.emit(speaker, lines, on_finished)


## Entrega a missão: tira os itens pedidos (coleta), dá experiência e itens.
## Recompensa que não couber na bolsa cai no chão.
func turn_in_quest(quest: QuestData) -> void:
	# Concluir ANTES de tirar os itens: a conclusão confere o objetivo, e na
	# coleta ele é contado na própria bolsa.
	var last_step: QuestStep = quest_log.current_step(quest)
	if not quest_log.complete(quest):
		return
	if last_step.objective == QuestStep.Objective.COLLECT:
		_remove_items(last_step.target_item, last_step.required_count)
	gain_xp(quest.reward_xp)
	for reward: ItemStack in quest.reward_items:
		var piece: ItemStack = reward.copy()
		var left: int = inventory.add(piece)
		if left > 0:
			piece.count = left
			item_dropped.emit(piece, global_position + facing * 14.0)
	_say("Missão concluída: %s" % quest.title)


## Etapa cumprida com continuação: entrega os itens da etapa (se for coleta) e
## passa para a próxima. Sem recompensa ainda — ela vem ao entregar a missão.
func advance_quest(quest: QuestData) -> void:
	var step: QuestStep = quest_log.current_step(quest)
	if not quest_log.advance(quest):
		return
	if step.objective == QuestStep.Objective.COLLECT:
		_remove_items(step.target_item, step.required_count)


func _remove_items(item: ItemData, amount: int) -> void:
	var remaining: int = amount
	for i in inventory.slots.size():
		var stack: ItemStack = inventory.get_slot(i)
		if remaining > 0 and stack and stack.item == item:
			remaining -= inventory.remove(i, remaining).count


# --- Itens -----------------------------------------------------------------
# As ações devolvem a mensagem para mostrar ("" = nenhuma) e também a emitem em
# message_requested, para o HUD mostrar igual não importa quem chamou.

## Usa ou equipa o item da vaga: consumível é gasto; arma/escudo vai para o
## equipamento e o que estava equipado volta para a mesma vaga.
func use_inventory_slot(index: int) -> String:
	var stack: ItemStack = inventory.get_slot(index)
	if stack == null or state == State.DEAD:
		return ""
	var message := ""
	if stack.item is ConsumableData:
		message = _consume(index, stack.item as ConsumableData)
	elif stack.item is WeaponData or stack.item is ShieldData:
		inventory.set_slot(index, equipment.equip(stack))
	return _say(message)


func unequip_weapon() -> String:
	return _unequip(equipment.weapon, equipment.unequip_weapon)


func unequip_shield() -> String:
	return _unequip(equipment.shield, equipment.unequip_shield)


## Joga fora o item da vaga; a área o coloca no chão (se ninguém escutar, some).
func discard_inventory_slot(index: int) -> void:
	var stack: ItemStack = inventory.get_slot(index)
	if stack == null:
		return
	inventory.set_slot(index, null)
	item_dropped.emit(stack, global_position + facing * 14.0)


## Pega um item do mundo. Devolve quantos NÃO couberam.
func pick_up(stack: ItemStack) -> int:
	return inventory.add(stack)


## Gasta o item só se ele tiver efeito (vida/mana não cheias).
func _consume(index: int, item: ConsumableData) -> String:
	var heals: bool = item.heal_amount > 0 and health.current_health < health.max_health
	var restores: bool = item.mana_amount > 0 and mana.current() < mana.max_mana
	if not heals and not restores:
		return MSG_MANA_FULL if item.mana_amount > 0 and item.heal_amount == 0 else MSG_HEALTH_FULL
	if heals:
		health.heal(item.heal_amount)
	if restores:
		mana.restore(item.mana_amount)
	inventory.remove(index, 1)
	return ""


func _unequip(stack: ItemStack, remove_from_equipment: Callable) -> String:
	if stack == null:
		return ""
	if inventory.is_full():
		return _say(MSG_INVENTORY_FULL)
	remove_from_equipment.call()
	inventory.add(stack)
	return ""


func _say(message: String) -> String:
	if not message.is_empty():
		message_requested.emit(message)
	return message


# --- Estados ---------------------------------------------------------------

func _process_move(delta: float) -> void:
	if _try_start_dodge():
		return
	if _input.has_interact():
		_input.consume_interact()
		if focused_interactable:
			_interact_with(focused_interactable)
			return
	# Defesa vence o ataque: segurando o botão direito, cliques são ignorados.
	if _can_block():
		_start_block()
		return
	if _try_start_ability():
		return
	if _input.has_attack():
		_start_attack()
		return
	_apply_movement(_input.move_direction, max_speed, delta)
	if _input.move_direction != Vector2.ZERO:
		_set_facing(to_cardinal(_input.move_direction))


func _process_attack(delta: float) -> void:
	var active_start: float = _attack_windup_now
	var recovery_start: float = active_start + _attack_active_now
	var attack_end: float = recovery_start + _attack_recovery_now

	if _state_time >= active_start and _state_time < recovery_start and not _sword_hitbox.is_active:
		_sword_hitbox.activate()
		_swing_visual.visible = true
	elif _state_time >= recovery_start and _sword_hitbox.is_active:
		_sword_hitbox.deactivate()
		_swing_visual.visible = false

	# Cancelamento: na recuperação, esquiva ou defesa interrompem o golpe.
	if _state_time >= recovery_start:
		if _try_start_dodge():
			return
		if _can_block():
			_start_block()
			return
	_apply_movement(_input.move_direction, max_speed * attack_move_multiplier, delta)
	if _state_time >= attack_end:
		var was_finisher: bool = _combo_step == COMBO_LENGTH - 1
		_change_state(State.MOVE)
		# Depois do finalizador o combo recomeça do primeiro golpe.
		_combo_window_left = 0.0 if was_finisher else combo_window
		# Golpe guardado sai no mesmo quadro: esperar o próximo quadro gastaria
		# mais um pedaço do buffer e o comando poderia expirar.
		if _input.has_attack():
			_start_attack()


func _process_block(delta: float) -> void:
	if _try_start_dodge():
		return
	if not _can_block():
		_change_state(State.MOVE)
		return
	_update_block_direction()
	_apply_movement(_input.move_direction, max_speed * block_move_multiplier, delta)


func _process_ability(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	var spin := _active_ability as SpinSlashData
	if spin:
		var active: bool = _state_time >= spin.active_start and _state_time < spin.active_end
		if active and not _spin_hitbox.is_active:
			_spin_hitbox.activate()
		elif not active and _spin_hitbox.is_active:
			_spin_hitbox.deactivate()
		_spin_visual.visible = active
		_spin_visual.rotation = _state_time * TAU * 3.0
		if _state_time >= spin.duration:
			_change_state(State.MOVE)
		return
	var bolt := _active_ability as ProjectileSpellData
	if bolt:
		if not _ability_fired and _state_time >= bolt.cast_time:
			_ability_fired = true
			var aim: Vector2 = _aim_direction()
			_set_facing(to_cardinal(aim))
			Projectile.fire(self, _attack_pivot.global_position + aim * 8.0, aim, bolt)
		if _state_time >= bolt.cast_time + 0.08:
			_change_state(State.MOVE)
		return
	var heal_spell := _active_ability as HealSpellData
	if heal_spell:
		if not _ability_fired and _state_time >= heal_spell.cast_time:
			_ability_fired = true
			health.heal(heal_spell.heal_amount)
			FloatingText.spawn(self, "+%d" % heal_spell.heal_amount, global_position + Vector2(0, -30), Color(0.5, 1.0, 0.5))
			_change_state(State.MOVE)
		return
	_change_state(State.MOVE)


func _process_dodge() -> void:
	velocity = _dodge_direction * dodge_speed
	if _state_time >= dodge_invulnerability:
		health.set_invulnerable(false)
	if _state_time >= dodge_duration:
		velocity = _dodge_direction * max_speed
		_change_state(State.MOVE)


func _process_hurt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if _state_time >= hurt_duration:
		_change_state(State.MOVE)


# --- Transições ------------------------------------------------------------

func _change_state(new_state: State) -> void:
	# Limpeza do estado que está saindo: nada pode "vazar" para o próximo.
	if state == State.ATTACK:
		_sword_hitbox.deactivate()
		_swing_visual.visible = false
		_attack_pivot.scale = Vector2.ONE
	elif state == State.BLOCK:
		_shield_visual.visible = false
	elif state == State.DODGE:
		health.set_invulnerable(false)
	elif state == State.ABILITY:
		_spin_hitbox.deactivate()
		_spin_visual.visible = false
		_active_ability = null
	state = new_state
	_state_time = 0.0


func _start_attack() -> void:
	_input.consume_attack()
	var continues_combo: bool = _combo_window_left > 0.0 and _combo_step < COMBO_LENGTH - 1
	_combo_step = _combo_step + 1 if continues_combo else 0
	_combo_window_left = 0.0
	var is_finisher: bool = _combo_step == COMBO_LENGTH - 1

	var aim: Vector2 = _aim_direction()
	_attack_pivot.rotation = aim.angle()
	_attack_pivot.scale = Vector2.ONE * (finisher_reach_scale if is_finisher else 1.0)
	_set_facing(to_cardinal(aim))

	var weapon: WeaponData = equipment.weapon_data()
	var timing: float = weapon.timing_scale if weapon else 1.0
	_attack_pivot.scale *= weapon.reach_scale if weapon else unarmed_reach_scale
	_sword_hitbox.damage = current_attack_damage(_combo_step)
	_sword_hitbox.knockback_force = combo_knockback[_combo_step] \
		* (weapon.knockback_multiplier if weapon else unarmed_knockback_multiplier)
	_swing_visual.modulate = FINISHER_SWING_TINT if is_finisher else Color.WHITE
	_attack_windup_now = (attack_windup + (finisher_extra_windup if is_finisher else 0.0)) * timing
	_attack_active_now = attack_active * timing
	_attack_recovery_now = (attack_recovery + (finisher_extra_recovery if is_finisher else 0.0)) * timing

	_change_state(State.ATTACK)
	velocity = aim * combo_step_impulse[_combo_step]


func _start_block() -> void:
	_change_state(State.BLOCK)
	_shield_visual.visible = true
	_update_block_direction()


## Habilidades: liberada pelo nível e fora da recarga. Tecla de habilidade
## bloqueada avisa em que nível ela libera.
func _try_start_ability() -> bool:
	var slot: int = _input.pending_ability()
	if slot == -1:
		return false
	_input.consume_ability(slot)
	if hotbar_items[slot] != null:
		use_hotbar_item(slot)
		return false
	if slot >= abilities.size() or abilities[slot] == null:
		return false
	var ability: AbilityData = abilities[slot]
	if not is_ability_unlocked(slot):
		_say("%s: liberada no nível %d." % [ability.display_name, ability.unlock_level])
		return false
	if _ability_cooldowns[slot] > 0.0:
		return false
	if not mana.spend(ability.mana_cost):
		FloatingText.spawn(self, "Sem mana", global_position + Vector2(0, -30), NO_MANA_COLOR)
		return false
	_ability_cooldowns[slot] = ability.cooldown
	_change_state(State.ABILITY)
	_active_ability = ability
	_ability_fired = false
	var spin := ability as SpinSlashData
	if spin:
		_spin_hitbox.damage = maxi(roundi(current_attack_damage(0) * spin.damage_multiplier), 1)
		_spin_hitbox.knockback_force = spin.knockback
	return true


## Coloca um consumível num espaço vazio da barra (sem habilidade). Devolve false se não pode.
func assign_hotbar_item(slot: int, item: ItemData) -> bool:
	if slot < 0 or slot >= hotbar_items.size() or not (item is ConsumableData):
		return false
	if slot < abilities.size() and abilities[slot] != null:
		return false
	hotbar_items[slot] = item
	hotbar_changed.emit()
	return true


func clear_hotbar_slot(slot: int) -> void:
	if slot >= 0 and slot < hotbar_items.size() and hotbar_items[slot] != null:
		hotbar_items[slot] = null
		hotbar_changed.emit()


## Usa a primeira pilha do item na bolsa. O espaço continua na barra mesmo com 0
## (mostra x0) para o jogador não precisar arrastar de novo quando achar mais.
func use_hotbar_item(slot: int) -> String:
	var item: ItemData = hotbar_items[slot]
	for i in inventory.slots.size():
		var stack: ItemStack = inventory.get_slot(i)
		if stack and stack.item == item:
			return use_inventory_slot(i)
	return _say("Você não tem %s." % item.display_name)


func is_ability_unlocked(slot: int) -> bool:
	return slot < abilities.size() and abilities[slot] != null and stats.level >= abilities[slot].unlock_level


## 0 = pronta, 1 = acabou de usar.
func ability_cooldown_ratio(slot: int) -> float:
	if slot >= abilities.size() or abilities[slot] == null or abilities[slot].cooldown <= 0.0:
		return 0.0
	return _ability_cooldowns[slot] / abilities[slot].cooldown


func _try_start_dodge() -> bool:
	if not _input.has_dodge() or _dodge_cooldown_left > 0.0:
		return false
	_input.consume_dodge()
	_dodge_direction = _input.move_direction.normalized() if _input.move_direction != Vector2.ZERO else facing
	_set_facing(to_cardinal(_dodge_direction))
	_dodge_cooldown_left = dodge_cooldown
	_dodge_success_this_dodge = false
	_change_state(State.DODGE)
	health.set_invulnerable(true)
	return true


func _interact_with(target: Interactable) -> void:
	var message: String = target.interact(self)
	if not message.is_empty():
		message_requested.emit(message)


# --- Reações ---------------------------------------------------------------

## Chamado pelo HealthComponent antes de aplicar dano: devolve true se o golpe
## veio de dentro do ângulo protegido pelo escudo.
func _is_hit_blocked(info: DamageInfo) -> bool:
	if state != State.BLOCK:
		return false
	var from_direction: Vector2
	if is_instance_valid(info.source) and info.source is Node2D:
		from_direction = global_position.direction_to((info.source as Node2D).global_position)
	else:
		from_direction = -info.knockback.normalized()
	var shield: ShieldData = equipment.shield_data()
	var in_front: bool = from_direction == Vector2.ZERO \
		or absf(_block_direction.angle_to(from_direction)) <= deg_to_rad(shield.block_half_angle + _block_angle_bonus())
	if not in_front:
		return false
	# Escudo quebrado ainda segura parte do golpe: o dano passa reduzido.
	if equipment.shield.is_broken():
		info.amount = ceili(info.amount * shield.broken_damage_through)
		return false
	return true


func _on_blocked(info: DamageInfo) -> void:
	velocity = info.knockback * equipment.shield_data().knockback_multiplier
	_shield_wear_accumulator += discipline.shield_wear_multiplier if discipline else 1.0
	while _shield_wear_accumulator >= 1.0:
		_shield_wear_accumulator -= 1.0
		if equipment.shield.wear(1):
			FloatingText.spawn(self, "Escudo quebrou!", global_position + Vector2(0, -30), BROKEN_COLOR)
	equipment.notify_wear()
	_shield_flash_time = 0.08
	_camera.shake(1.5, 0.08)
	Hitstop.request(hitstop_block)


## Golpe ignorado pela invulnerabilidade: só conta como esquiva perfeita se
## veio durante o rolamento (não durante a invulnerabilidade pós-dano).
func _on_hit_ignored(_info: DamageInfo) -> void:
	if state != State.DODGE or _dodge_success_this_dodge:
		return
	_dodge_success_this_dodge = true
	FloatingText.spawn(self, DODGE_SUCCESS_TEXT, global_position + Vector2(0, -30), DODGE_SUCCESS_COLOR)
	dodge_succeeded.emit()


func _on_ability_hit(_target: Hurtbox) -> void:
	if equipment.weapon and equipment.weapon.wear(1):
		FloatingText.spawn(self, "Arma quebrou!", global_position + Vector2(0, -30), BROKEN_COLOR)
	equipment.notify_wear()
	Hitstop.request(hitstop_hit)


func _on_sword_hit(_target: Hurtbox) -> void:
	if equipment.weapon:
		if equipment.weapon.wear(1):
			FloatingText.spawn(self, "Arma quebrou!", global_position + Vector2(0, -30), BROKEN_COLOR)
		equipment.notify_wear()
	var is_finisher: bool = _combo_step == COMBO_LENGTH - 1
	Hitstop.request(hitstop_finisher if is_finisher else hitstop_hit)
	if is_finisher:
		_camera.shake(2.0, 0.1)


func _on_damaged(info: DamageInfo) -> void:
	if health.is_dead:
		return
	health.grant_invulnerability(post_hit_invulnerability)
	velocity = info.knockback
	_flash_time = 0.08
	FloatingText.spawn(self, str(info.amount), global_position + Vector2(0, -34), Color(1.0, 0.35, 0.3), 10)
	_camera.shake(3.0, 0.15)
	Hitstop.request(hitstop_hurt)
	_change_state(State.HURT)


func _on_died() -> void:
	_flash_time = 0.0
	_camera.shake(5.0, 0.25)
	_change_state(State.DEAD)
	died.emit()


# --- Auxiliares ------------------------------------------------------------

## Escolhe o objeto usável mais próximo dentro do alcance e posiciona o aviso.
func _update_focus() -> void:
	var best: Interactable = null
	var best_distance: float = INF
	if state != State.DEAD:
		for area: Area2D in _interaction_detector.get_overlapping_areas():
			var candidate := area as Interactable
			if candidate == null or not candidate.enabled:
				continue
			var distance: float = global_position.distance_squared_to(candidate.global_position)
			if distance < best_distance:
				best = candidate
				best_distance = distance
	focused_interactable = best
	_interact_prompt.visible = best != null
	if best:
		_interact_prompt.text = "[F] " + best.prompt_text
		_interact_prompt.global_position = (best.prompt_position() - _interact_prompt.get_combined_minimum_size() / 2.0).round()


func _block_angle_bonus() -> float:
	return discipline.block_angle_bonus if discipline else 0.0


func _can_block() -> bool:
	return _input.defend_held and equipment.shield != null


## Vida e mana máximas = base + crescimento por nível (+ bônus provisório da Disciplina).
func _apply_growth() -> void:
	var discipline_health: int = discipline.bonus_health if discipline else 0
	var discipline_mana: int = discipline.bonus_mana if discipline else 0
	health.set_max_health(_base_max_health + discipline_health + stats.bonus_max_health())
	mana.set_max_mana(_base_max_mana + discipline_mana + stats.bonus_max_mana())


func _on_leveled_up(new_level: int) -> void:
	_apply_growth()
	FloatingText.spawn(self, "Nível %d!" % new_level, global_position + Vector2(0, -40), LEVEL_UP_COLOR)


func _aim_direction() -> Vector2:
	var aim: Vector2 = _attack_pivot.global_position.direction_to(_input.aim_position)
	return aim if aim != Vector2.ZERO else facing


func _update_block_direction() -> void:
	_block_direction = _aim_direction()
	_attack_pivot.rotation = _block_direction.angle()
	_set_facing(to_cardinal(_block_direction))


func _apply_movement(direction: Vector2, speed: float, delta: float) -> void:
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func _set_facing(new_facing: Vector2) -> void:
	if new_facing == facing:
		return
	facing = new_facing
	_facing_indicator.rotation = facing.angle()


## Apresentação provisória: só lê o estado, nunca muda regras de jogo.
func _update_visuals(delta: float) -> void:
	_flash_time = maxf(_flash_time - delta, 0.0)
	_shield_flash_time = maxf(_shield_flash_time - delta, 0.0)
	_shield_visual.color = Color.WHITE if _shield_flash_time > 0.0 else SHIELD_COLOR
	if state == State.DEAD:
		_body.color = DEAD_COLOR
		_body.modulate.a = 1.0
		return
	_body.color = Color.WHITE if _flash_time > 0.0 else PLACEHOLDER_COLOR
	if state == State.DODGE:
		_body.modulate.a = 0.45
	elif health.is_invulnerable():
		# Pisca enquanto invulnerável após dano (alterna a cada 1/15 s).
		_blink_clock += delta
		_body.modulate.a = 0.35 if int(_blink_clock * 15.0) % 2 == 0 else 1.0
	else:
		_blink_clock = 0.0
		_body.modulate.a = 1.0
	_body.scale.y = 0.7 if state == State.DODGE else 1.0


## Converte qualquer direção na cardeal mais próxima. Em diagonal exata
## (teclado), o lado horizontal vence, porque o sprite de perfil lê melhor.
static func to_cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) >= absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP
