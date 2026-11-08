class_name Player
extends CharacterBody3D
## Personagem controlável (3D, terceira pessoa): movimento, combo, defesa,
## esquiva, dano, morte, itens (inventário/equipamento), progressão, habilidades.
##
## Organizado como uma máquina de estados simples: em cada momento o personagem
## está em exatamente um estado (andando, atacando, defendendo...), e cada
## estado decide o que é permitido.
##
## Toda a lógica de combate acontece no chão (plano X/Z); a altura (Y) só é
## usada pela gravidade. Escala: 1 metro = 1 tile da versão 2D (16 px).

signal died
## Um golpe passou por dentro da invencibilidade da esquiva.
signal dodge_succeeded
## Um objeto pediu para mostrar um texto (placa, porta trancada...). O HUD escuta.
signal message_requested(text: String)
## O jogador descartou um item: a área decide onde ele aparece no chão.
signal item_dropped(stack: ItemStack, at_position: Vector3)
## Classe escolhida/trocada: habilidades mudaram (HUD refaz a barra).
signal class_changed(player_class: ClassData)
## Itens colocados na barra de habilidades mudaram.
signal hotbar_changed
## Um NPC quer conversar: a área abre a caixa de diálogo e chama on_finished no fim.
signal dialogue_requested(speaker: String, lines: Array[String], on_finished: Callable)

enum State { MOVE, ATTACK, BLOCK, DODGE, HURT, ABILITY, DEAD }

const GROUP: StringName = &"players"
const COMBO_LENGTH: int = 3
const GRAVITY: float = 20.0
## Camada de cor por cima do corpo (alfa = intensidade). Vale para qualquer
## modelo, provisório ou de arte, porque não mexe nos materiais dele.
const TINT_NONE := Color(1, 1, 1, 0)
const TINT_HIT := Color(1, 1, 1, 0.75)
const TINT_DEAD := Color(0.2, 0.2, 0.25, 0.65)
const TINT_HEAL_SELECTED := Color(0.45, 1.0, 0.5, 0.45)
## Animação de parado do modelo de arte (se o modelo tiver).
const IDLE_ANIMATION := &"idle"
const SHIELD_COLOR := Color(0.75, 0.85, 1.0, 0.85)
const SWING_COLOR := Color(1.0, 1.0, 0.85, 0.6)
const FINISHER_SWING_TINT := Color(1.0, 0.75, 0.45, 0.7)
const DODGE_SUCCESS_TEXT := "Esquiva perfeita!"
const DODGE_SUCCESS_COLOR := Color(0.55, 0.95, 1.0)
const BLOCK_SUCCESS_TEXT := "Defesa bem-sucedida!"
const BLOCK_SUCCESS_COLOR := Color(0.75, 0.85, 1.0)
const LEVEL_UP_COLOR := Color(1.0, 0.85, 0.35)
## Duração do texto "Nível N!" (os outros textos flutuantes duram 0,9 s).
const LEVEL_UP_TEXT_TIME: float = 1.9
const BROKEN_COLOR := Color(1.0, 0.45, 0.35)
const MSG_HEALTH_FULL := "A vida já está cheia."
const MSG_MANA_FULL := "A mana já está cheia."
const MSG_INVENTORY_FULL := "Inventário cheio."
const NO_MANA_COLOR := Color(0.5, 0.7, 1.0)
## Distância máxima para selecionar um aliado com a mira (m).
const HEAL_TARGET_RANGE: float = 25.0
## Camadas que a mira de cura enxerga: mundo (bloqueia) e jogadores/aliados.
const HEAL_TARGET_MASK: int = 1 | 2
## Altura (acima dos pés) onde aparecem textos flutuantes.
const TEXT_HEIGHT: float = 2.1
## Passivo Muralha (Guardião): duração e redução de dano da Firmeza.
const FIRMEZA_TIME: float = 3.0
const FIRMEZA_REDUCTION: float = 0.3

@export_group("Movimento")
## Velocidade máxima (m/s).
@export var max_speed: float = 5.6
## Quanto a velocidade cresce por segundo ao começar a andar.
@export var acceleration: float = 56.0
## Quanto a velocidade cai por segundo ao soltar as teclas.
@export var friction: float = 69.0

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
## Empurrão de cada golpe no inimigo (m/s), antes do multiplicador da arma.
@export var combo_knockback: Array[float] = [8.75, 8.75, 16.25]
## Passo à frente que o personagem dá em cada golpe (m/s).
@export var combo_step_impulse: Array[float] = [2.5, 2.5, 6.9]
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
@export var dodge_speed: float = 14.4
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

## Direção (no chão) para onde o personagem está virado.
var facing: Vector3 = Vector3.FORWARD
var state: State = State.MOVE

var _state_time: float = 0.0
var _dodge_direction: Vector3 = Vector3.ZERO
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
## Vida máxima sem crescimento de nível (o valor configurado no HealthComponent).
var _base_max_health: int = 0
var _block_direction: Vector3 = Vector3.FORWARD
## Consumíveis arrastados para a barra (mesma posição das habilidades; null = vazio).
## Guarda o TIPO de item: a tecla usa a primeira pilha dele na bolsa.
var hotbar_items: Array[ItemData] = []
## Uma mensagem por esquiva, mesmo que dois inimigos acertem a mesma esquiva.
var _dodge_success_this_dodge: bool = false
## Objeto usável mais próximo (o que recebe o "[F]"), ou null.
var focused_interactable: Interactable = null
## true enquanto uma tela (inventário, diálogo...) estiver aberta: ignora comandos
## e a câmera solta o mouse.
var input_blocked: bool = false
## Onde o jogador volta ao continuar depois da morte (início da área).
var respawn_point: Vector3 = Vector3.ZERO
## Invulnerabilidade ao voltar, para não morrer de novo no mesmo instante (s).
var respawn_invulnerability: float = 1.5
## Segundos restantes de recarga por habilidade (mesma posição da lista).
var _ability_cooldowns: Array[float] = []
var _active_ability: AbilityData = null
## A habilidade em andamento já fez efeito (disparou/curou)?
var _ability_fired: bool = false
## Classe escolhida (null = nenhuma ainda).
var player_class: ClassData = null
## Passivo Muralha (Guardião): tempo restante de Firmeza (menos dano).
var _firmeza_left: float = 0.0
## Modo de seleção de cura (Luz curativa): a habilidade, a tecla e os aliados marcados.
var _heal_targeting: HealSpellData = null
var _heal_slot: int = -1
var _heal_selection: Array[Node3D] = []
## Botão direito: borda de "apertou agora" e recarga da habilidade secundária.
var _defend_held_last: bool = false
var _defend_pressed: bool = false
var _secondary_cooldown_left: float = 0.0
var _base_max_mana: int = 0
var _tint_material: StandardMaterial3D
## Corpo visível agora: o boneco provisório ou o modelo da classe.
var _body: Node3D
var _class_model: Node3D
var _heal_selected: bool = false
## Efeitos de status ativos (lentidão, veneno...). Criado no _ready.
var status: StatusEffects
## Ressurreição (solo): revive a si mesmo uma vez (recarrega ao continuar/entrar em masmorra).
var self_revive_available: bool = true
var _support_target: Node3D = null
## Teto da masmorra (Dungeon Sync). 0 = sem teto. O personagem nunca é alterado:
## as contas usam effective_level() e effective_gs_of().
var sync_level_cap: int = 0
var sync_gs_cap: int = 0
## Elemento do óleo passado na arma e quanto tempo ainda dura.
var weapon_element: StringName = &""
var _weapon_element_left: float = 0.0
## Nome mostrado de cada elemento.
const ELEMENT_NAMES: Dictionary = {&"fire": "Fogo", &"ice": "Gelo", &"lightning": "Raio", &"earth": "Terra", &"light": "Luz", &"dark": "Trevas"}
## GS em que o dano da arma não muda (itens iniciais).
const GS_BASE: int = 100
var _swing_material: StandardMaterial3D
var _shield_material: StandardMaterial3D

@onready var health: HealthComponent = $HealthComponent
@onready var inventory: Inventory = $Inventory
@onready var equipment: Equipment = $Equipment
@onready var stats: CharacterStats = $CharacterStats
@onready var mana: ManaComponent = $ManaComponent
@onready var quest_log: QuestLog = $QuestLog
@onready var _input: PlayerInput = $PlayerInput
@onready var _model: Node3D = $Model
@onready var _placeholder: Node3D = $Model/Placeholder
@onready var _placeholder_sword: Node3D = $Model/RightHand/SwordPlaceholder
@onready var _right_hand: Node3D = $Model/RightHand
@onready var _left_hand: Node3D = $Model/LeftHand
@onready var _attack_pivot: Node3D = $AttackPivot
@onready var _sword_hitbox: Hitbox = $AttackPivot/SwordHitbox
@onready var _swing_visual: MeshInstance3D = $AttackPivot/SwingPlaceholder
@onready var _shield_visual: MeshInstance3D = $AttackPivot/ShieldPlaceholder
@onready var _camera: PlayerCamera = $CameraRig
@onready var _interaction_detector: Area3D = $InteractionDetector
@onready var _interact_prompt: Label3D = $InteractPrompt
@onready var _spin_hitbox: Hitbox = $SpinHitbox
@onready var _spin_visual: MeshInstance3D = $SpinPlaceholder


func _ready() -> void:
	assert(combo_damage_multiplier.size() == COMBO_LENGTH and combo_knockback.size() == COMBO_LENGTH \
		and combo_step_impulse.size() == COMBO_LENGTH,
		"Player: listas do combo precisam ter %d valores cada" % COMBO_LENGTH)
	add_to_group(GROUP)
	# Materiais próprios desta instância (piscar não pode afetar outro personagem).
	_tint_material = StandardMaterial3D.new()
	_tint_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tint_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tint_material.albedo_color = TINT_NONE
	_set_body_model(null)
	equipment.changed.connect(_refresh_held_models)
	_refresh_held_models()
	_swing_material = (_swing_visual.material_override as StandardMaterial3D).duplicate()
	_swing_visual.material_override = _swing_material
	_shield_material = (_shield_visual.material_override as StandardMaterial3D).duplicate()
	_shield_visual.material_override = _shield_material
	_swing_visual.visible = false
	_shield_visual.visible = false
	_camera.player = self
	_input.camera_rig = _camera
	health.block_filter = _is_hit_blocked
	health.damage_modifier = _apply_damage_modifiers
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
	status = StatusEffects.attach(self, health, TEXT_HEIGHT + 0.25)
	_set_facing(facing)


func _physics_process(delta: float) -> void:
	_input.poll(delta)
	if input_blocked:
		_input.clear()
	_defend_pressed = _input.defend_held and not _defend_held_last
	_defend_held_last = _input.defend_held
	_secondary_cooldown_left = maxf(_secondary_cooldown_left - delta, 0.0)
	_state_time += delta
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	_combo_window_left = maxf(_combo_window_left - delta, 0.0)
	_firmeza_left = maxf(_firmeza_left - delta, 0.0)
	if _weapon_element_left > 0.0:
		_weapon_element_left -= delta
		if _weapon_element_left <= 0.0:
			weapon_element = &""
			_say("O óleo da arma acabou.")
	for i in _ability_cooldowns.size():
		_ability_cooldowns[i] = maxf(_ability_cooldowns[i] - delta, 0.0)
	_update_focus()
	# A lógica trabalha só no chão; a altura é tratada pela gravidade no fim.
	var vertical: float = velocity.y
	velocity.y = 0.0
	if state == State.DEAD or not _process_status_control(delta):
		_process_state(delta)
	velocity.y = vertical - GRAVITY * delta if not is_on_floor() else minf(vertical, 0.0)
	move_and_slide()
	_update_visuals(delta)


## Congelado/atordoado: não age. Com medo: foge de quem assustou, sem agir.
## Devolve true quando o efeito tomou o controle neste quadro.
func _process_status_control(delta: float) -> bool:
	var scared_of: Node3D = status.fear_source()
	if not status.is_disabled() and scared_of == null:
		return false
	cancel_heal_targeting()
	if state != State.MOVE:
		_change_state(State.MOVE)
	_input.clear()
	if status.is_disabled():
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		return true
	var away: Vector3 = flat(global_position - scared_of.global_position)
	if away.length() < 0.01:
		away = -facing
	_apply_movement(away.normalized(), max_speed * 0.8, delta)
	_set_facing(away)
	return true


func _process_state(delta: float) -> void:
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
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)


# --- Leitura para a animação (PlayerAnimator) -------------------------------

## Tempo desde que o estado atual começou (s).
func state_time() -> float:
	return _state_time


## Golpe atual do combo (0, 1 ou 2 = finalizador).
func combo_step() -> int:
	return _combo_step


## Duração das fases do golpe atual: x = preparação, y = golpe, z = recuperação (s).
func attack_phase_times() -> Vector3:
	return Vector3(_attack_windup_now, _attack_active_now, _attack_recovery_now)


## Habilidade em uso (estado ABILITY) ou null.
func active_ability() -> AbilityData:
	return _active_ability


## A câmera que o jogador usa (HUD/testes podem precisar dela).
func camera_rig() -> PlayerCamera:
	return _camera


## Dano do golpe `step` do combo com a arma atual, nível e estado da arma.
func current_attack_damage(step: int) -> int:
	var weapon: WeaponData = equipment.weapon_data()
	var base: float = float(weapon.damage) if weapon else float(unarmed_damage)
	if weapon and equipment.weapon.is_broken():
		base *= weapon.broken_damage_multiplier
	if weapon:
		base *= gs_damage_multiplier(effective_gs_of(weapon.gear_score))
	return maxi(roundi(base * combo_damage_multiplier[step] * stats.damage_multiplier(effective_level())), 1)


# --- Gear Score e Dungeon Sync ----------------------------------------------

## Multiplicador de dano da arma pelo GS: GS 100 = x1,0; cada +1000 = +1,0.
static func gs_damage_multiplier(gs: int) -> float:
	return 1.0 + float(gs - GS_BASE) / 1000.0


## GS de um item depois do teto da masmorra (o item em si não muda).
func effective_gs_of(gs: int) -> int:
	return mini(gs, sync_gs_cap) if sync_gs_cap > 0 else gs


## Espaços que contam no GS: arma, e escudo para quem usa escudo (Devoto: só arma).
func _gs_slots() -> Array[int]:
	var slots: Array[int] = []
	var weapon: WeaponData = equipment.weapon_data()
	slots.append(weapon.gear_score if weapon else 0)
	var uses_shield: bool = player_class.uses_shield if player_class else equipment.shield != null
	if uses_shield:
		var shield: ShieldData = equipment.shield_data()
		slots.append(shield.gear_score if shield else 0)
	return slots


## GS real do personagem (média dos espaços; vazio conta 0).
func gear_score() -> int:
	var slots: Array[int] = _gs_slots()
	var total: int = 0
	for gs: int in slots:
		total += gs
	return roundi(float(total) / slots.size())


## GS com o teto da masmorra aplicado item a item.
func effective_gear_score() -> int:
	var slots: Array[int] = _gs_slots()
	var total: int = 0
	for gs: int in slots:
		total += effective_gs_of(gs)
	return roundi(float(total) / slots.size())


## Nível usado nas contas (com o teto da masmorra, se houver).
func effective_level() -> int:
	return mini(stats.level, sync_level_cap) if sync_level_cap > 0 else stats.level


func is_synced() -> bool:
	return sync_level_cap > 0 or sync_gs_cap > 0


## Entra no Dungeon Sync: vida, mana, dano e habilidades passam a usar os tetos.
func apply_sync(level_cap: int, gs_cap: int) -> void:
	sync_level_cap = level_cap
	sync_gs_cap = gs_cap
	_apply_growth()


## Sai do Dungeon Sync: volta aos valores reais (nada do personagem foi alterado).
func clear_sync() -> void:
	sync_level_cap = 0
	sync_gs_cap = 0
	_apply_growth()


## Volta à vida no ponto indicado, com vida e mana cheias. Itens, equipamento e
## experiência são mantidos (nada é recarregado).
func respawn(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	health.revive()
	mana.restore_full()
	health.grant_invulnerability(respawn_invulnerability)
	input_blocked = false
	self_revive_available = true
	status.clear_all()
	_change_state(State.MOVE)


## Aplica a classe: equipamento inicial, habilidades e passivo. A base de
## vida/mana/dano não muda (igual para todos).
func apply_class(new_class: ClassData) -> void:
	cancel_heal_targeting()
	player_class = new_class
	equipment.weapon = new_class.starting_weapon.copy() if new_class.starting_weapon else null
	equipment.shield = new_class.starting_shield.copy() if new_class.uses_shield and new_class.starting_shield else null
	equipment.notify_wear()
	abilities = new_class.abilities.duplicate()
	_ability_cooldowns.resize(abilities.size())
	_ability_cooldowns.fill(0.0)
	_secondary_cooldown_left = 0.0
	_set_body_model(new_class.model_scene)
	_apply_growth()
	class_changed.emit(player_class)


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
			item_dropped.emit(piece, global_position + facing * 0.9)
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
		var refusal: String = equip_refusal(stack.item)
		if not refusal.is_empty():
			return _say(refusal)
		inventory.set_slot(index, equipment.equip(stack))
	return _say(message)


## Motivo para não poder equipar ("" = pode). Cada classe usa só as suas armas.
func equip_refusal(item: ItemData) -> String:
	if player_class == null:
		return ""
	if item is WeaponData and not player_class.allows_weapon(item as WeaponData):
		return "Sua classe não usa %s." % item.display_name
	if item is ShieldData and not player_class.uses_shield:
		return "Sua classe não usa escudo."
	return ""


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
	item_dropped.emit(stack, global_position + facing * 0.9)


## Pega um item do mundo. Devolve quantos NÃO couberam.
func pick_up(stack: ItemStack) -> int:
	return inventory.add(stack)


## Gasta o item só se ele tiver efeito (vida/mana não cheias).
func _consume(index: int, item: ConsumableData) -> String:
	if item.weapon_element != &"":
		if equipment.weapon == null:
			return "Equipe uma arma para usar o óleo."
		weapon_element = item.weapon_element
		_weapon_element_left = item.element_duration
		inventory.remove(index, 1)
		return "Arma com %s por %d s." % [ELEMENT_NAMES.get(weapon_element, String(weapon_element)), int(item.element_duration)]
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
	if _heal_targeting and _process_heal_targeting():
		return
	if _try_start_dodge():
		return
	if _input.has_interact():
		_input.consume_interact()
		if focused_interactable:
			_interact_with(focused_interactable)
			return
	if _try_secondary_ability():
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
	var move: Vector3 = _world_move()
	_apply_movement(move, max_speed, delta)
	if move != Vector3.ZERO:
		_set_facing(move)


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
	_apply_movement(_world_move(), max_speed * attack_move_multiplier, delta)
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
	_apply_movement(_world_move(), max_speed * block_move_multiplier, delta)


func _process_ability(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
	var spin := _active_ability as SpinSlashData
	if spin:
		var active: bool = _state_time >= spin.active_start and _state_time < spin.active_end
		if active and not _spin_hitbox.is_active:
			_spin_hitbox.activate()
		elif not active and _spin_hitbox.is_active:
			_spin_hitbox.deactivate()
		_spin_visual.visible = active
		_spin_visual.rotation.y = _state_time * TAU * 3.0
		if _state_time >= spin.duration:
			_change_state(State.MOVE)
		return
	var bash := _active_ability as ShieldBashData
	if bash:
		var active: bool = _state_time >= bash.active_start and _state_time < bash.active_end
		if active and not _sword_hitbox.is_active:
			_sword_hitbox.activate()
			_shield_visual.visible = true
		elif not active and _sword_hitbox.is_active:
			_sword_hitbox.deactivate()
		if _state_time >= bash.duration:
			_change_state(State.MOVE)
		return
	var support := _active_ability as SupportSpellData
	if support:
		if not _ability_fired and _state_time >= support.cast_time:
			_ability_fired = true
			_cast_support(support)
		if _state_time >= support.cast_time + 0.1:
			_change_state(State.MOVE)
		return
	if _active_ability is TauntData:
		if _state_time >= 0.2:
			_change_state(State.MOVE)
		return
	var bolt := _active_ability as ProjectileSpellData
	if bolt:
		if not _ability_fired and _state_time >= bolt.cast_time:
			_ability_fired = true
			var aim: Vector3 = _aim_direction()
			_set_facing(aim)
			Projectile.fire(self, _attack_pivot.global_position + aim * 0.5, aim, bolt)
		if _state_time >= bolt.cast_time + 0.08:
			_change_state(State.MOVE)
		return
	var heal_spell := _active_ability as HealSpellData
	if heal_spell:
		if not _ability_fired and _state_time >= heal_spell.cast_time:
			_ability_fired = true
			# Passivo Graça: cura com a vida cheia vira escudo de vida.
			if _has_passive(&"graca") and health.current_health >= health.max_health:
				health.add_shield(heal_spell.heal_amount / 2)
				FloatingText.spawn(self, "Escudo +%d" % (heal_spell.heal_amount / 2), global_position + Vector3.UP * (TEXT_HEIGHT + 0.3), Color(1.0, 0.95, 0.6))
			health.heal(heal_spell.heal_amount)
			FloatingText.spawn(self, "+%d" % heal_spell.heal_amount, global_position + Vector3.UP * TEXT_HEIGHT, Color(0.5, 1.0, 0.5))
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
	velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
	if _state_time >= hurt_duration:
		_change_state(State.MOVE)


# --- Transições ------------------------------------------------------------

func _change_state(new_state: State) -> void:
	# Limpeza do estado que está saindo: nada pode "vazar" para o próximo.
	if state == State.ATTACK:
		_sword_hitbox.deactivate()
		_swing_visual.visible = false
		_attack_pivot.scale = Vector3.ONE
	elif state == State.BLOCK:
		_shield_visual.visible = false
	elif state == State.DODGE:
		health.set_invulnerable(false)
	elif state == State.ABILITY:
		_spin_hitbox.deactivate()
		_spin_visual.visible = false
		_sword_hitbox.deactivate()
		_shield_visual.visible = false
		_attack_pivot.scale = Vector3.ONE
		_active_ability = null
	state = new_state
	_state_time = 0.0


func _start_attack() -> void:
	_input.consume_attack()
	var continues_combo: bool = _combo_window_left > 0.0 and _combo_step < COMBO_LENGTH - 1
	_combo_step = _combo_step + 1 if continues_combo else 0
	_combo_window_left = 0.0
	var is_finisher: bool = _combo_step == COMBO_LENGTH - 1

	var aim: Vector3 = _aim_direction()
	_attack_pivot.rotation.y = yaw_of(aim)
	_set_facing(aim)

	var weapon: WeaponData = equipment.weapon_data()
	var timing: float = weapon.timing_scale if weapon else 1.0
	var reach: float = (finisher_reach_scale if is_finisher else 1.0) * (weapon.reach_scale if weapon else unarmed_reach_scale)
	# Alcance só no chão: a altura da área de golpe não muda.
	_attack_pivot.scale = Vector3(reach, 1.0, reach)
	_sword_hitbox.damage = current_attack_damage(_combo_step)
	_sword_hitbox.element = weapon_element
	_sword_hitbox.knockback_force = combo_knockback[_combo_step] \
		* (weapon.knockback_multiplier if weapon else unarmed_knockback_multiplier)
	_swing_material.albedo_color = FINISHER_SWING_TINT if is_finisher else SWING_COLOR
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
		if stats.level >= ability.unlock_level:
			_say("%s: bloqueada pela sincronização (nível efetivo %d)." % [ability.display_name, effective_level()])
		else:
			_say("%s: liberada no nível %d." % [ability.display_name, ability.unlock_level])
		return false
	if not ability.is_implemented():
		_say("%s: ainda em desenvolvimento." % ability.display_name)
		return false
	var targeted_heal := ability as HealSpellData
	if targeted_heal and targeted_heal.requires_target:
		# Mesma tecla de novo = cancela. Mana e recarga só na confirmação (Espaço).
		if _heal_targeting == targeted_heal:
			cancel_heal_targeting()
		elif _ability_cooldowns[slot] <= 0.0:
			_start_heal_targeting(targeted_heal, slot)
		return false
	if ability is ShieldBashData and equipment.shield == null:
		_say("Golpe de escudo precisa de um escudo.")
		return false
	if _ability_cooldowns[slot] > 0.0:
		return false
	var support := ability as SupportSpellData
	if support and support.mechanic == SupportSpellData.Mechanic.REVIVE:
		_support_target = _fallen_ally(support.radius)
		if _support_target == null:
			_say("Nenhum aliado caído por perto.")
			return false
	if not mana.spend(ability.mana_cost):
		FloatingText.spawn(self, "Sem mana", global_position + Vector3.UP * TEXT_HEIGHT, NO_MANA_COLOR)
		return false
	_ability_cooldowns[slot] = ability.cooldown
	_change_state(State.ABILITY)
	_active_ability = ability
	_ability_fired = false
	var spin := ability as SpinSlashData
	if spin:
		_spin_hitbox.damage = maxi(roundi(current_attack_damage(0) * spin.damage_multiplier), 1)
		_spin_hitbox.knockback_force = spin.knockback
		_spin_hitbox.element = weapon_element
	var bash := ability as ShieldBashData
	if bash:
		var aim: Vector3 = _aim_direction()
		_attack_pivot.rotation.y = yaw_of(aim)
		_attack_pivot.scale = Vector3(0.8, 1.0, 0.8)
		_set_facing(aim)
		_sword_hitbox.damage = maxi(roundi(current_attack_damage(0) * bash.damage_multiplier), 1)
		_sword_hitbox.knockback_force = bash.knockback
	var taunt := ability as TauntData
	if taunt:
		_do_taunt(taunt)
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


## Habilidade do botão direito (classes sem escudo), ou null.
func secondary_ability() -> AbilityData:
	return player_class.secondary_ability if player_class else null


## 0 = pronta, 1 = acabou de usar.
func secondary_cooldown_ratio() -> float:
	var ability: AbilityData = secondary_ability()
	if ability == null or ability.cooldown <= 0.0:
		return 0.0
	return _secondary_cooldown_left / ability.cooldown


## Botão direito sem escudo: usa a habilidade secundária da disciplina.
func _try_secondary_ability() -> bool:
	var ability: AbilityData = secondary_ability()
	if not _defend_pressed or ability == null or equipment.shield != null:
		return false
	_defend_pressed = false
	if not is_instance_valid(ability) or not ability.is_implemented() or _secondary_cooldown_left > 0.0:
		return false
	if effective_level() < ability.unlock_level:
		_say("%s: liberada no nível %d." % [ability.display_name, ability.unlock_level])
		return false
	if not mana.spend(ability.mana_cost):
		FloatingText.spawn(self, "Sem mana", global_position + Vector3.UP * TEXT_HEIGHT, NO_MANA_COLOR)
		return false
	_secondary_cooldown_left = ability.cooldown
	_change_state(State.ABILITY)
	_active_ability = ability
	_ability_fired = false
	return true


func is_ability_unlocked(slot: int) -> bool:
	return slot < abilities.size() and abilities[slot] != null and effective_level() >= abilities[slot].unlock_level


## 0 = pronta, 1 = acabou de usar.
func ability_cooldown_ratio(slot: int) -> float:
	if slot >= abilities.size() or abilities[slot] == null or abilities[slot].cooldown <= 0.0:
		return 0.0
	return _ability_cooldowns[slot] / abilities[slot].cooldown


func _try_start_dodge() -> bool:
	if not _input.has_dodge() or _dodge_cooldown_left > 0.0:
		return false
	_input.consume_dodge()
	var move: Vector3 = _world_move()
	_dodge_direction = move.normalized() if move != Vector3.ZERO else facing
	_set_facing(_dodge_direction)
	_dodge_cooldown_left = dodge_cooldown
	_dodge_success_this_dodge = false
	_change_state(State.DODGE)
	health.set_invulnerable(true)
	return true


# --- Cura com seleção de aliados ----------------------------------------------

func is_heal_targeting() -> bool:
	return _heal_targeting != null


func heal_selection() -> Array[Node3D]:
	return _heal_selection


## Aliado (outro jogador ou aliado de teste) no centro da tela, ou null.
func ally_in_crosshair() -> Node3D:
	var cam: Camera3D = _camera.camera
	var center: Vector2 = cam.get_viewport().get_visible_rect().size / 2.0
	var from: Vector3 = cam.project_ray_origin(center)
	var query := PhysicsRayQueryParameters3D.create(from, from + cam.project_ray_normal(center) * HEAL_TARGET_RANGE, HEAL_TARGET_MASK)
	query.exclude = [get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var node := hit.get("collider") as Node3D
	if node == null or node == self or not ("health" in node):
		return null
	if not (node.is_in_group(AllyDummy.GROUP) or node is Player):
		return null
	return node if not (node.get("health") as HealthComponent).is_dead else null


func cancel_heal_targeting() -> void:
	if _heal_targeting == null:
		return
	for ally: Node3D in _heal_selection:
		if is_instance_valid(ally) and ally.has_method("set_heal_selected"):
			ally.call("set_heal_selected", false)
	_heal_selection.clear()
	_heal_targeting = null
	_heal_slot = -1


## Tinta o corpo ao ser selecionado para cura por outro jogador (co-op).
func set_heal_selected(value: bool) -> void:
	_heal_selected = value


## Troca o corpo visível: modelo da classe ou, sem modelo, o boneco provisório.
## Colisão, golpes e câmera não dependem do corpo, só a aparência muda.
func _set_body_model(scene: PackedScene) -> void:
	if _class_model:
		_class_model.queue_free()
		_class_model = null
	if scene:
		_class_model = scene.instantiate() as Node3D
		_class_model.name = "ClassModel"
		# Modelos importados olham para +Z; o jogo usa -Z como frente.
		_class_model.rotation.y = PI
		_model.add_child(_class_model)
		_play_idle(_class_model)
	_placeholder.visible = _class_model == null
	_body = _class_model if _class_model else _placeholder
	for mesh: Node in _body.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = _tint_material


static func _play_idle(model: Node) -> void:
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var anim_player := players[0] as AnimationPlayer
	if not anim_player.has_animation(IDLE_ANIMATION):
		return
	anim_player.get_animation(IDLE_ANIMATION).loop_mode = Animation.LOOP_LINEAR
	anim_player.play(IDLE_ANIMATION)


## Mostra nas mãos o modelo da arma e do escudo equipados (se o item tiver).
## Só aparência: o golpe continua vindo da SwordHitbox, a defesa do escudo equipado.
func _refresh_held_models() -> void:
	var weapon_model: Node3D = _hold(_right_hand, equipment.weapon)
	_hold(_left_hand, equipment.shield)
	_placeholder_sword.visible = weapon_model == null


func _hold(hand: Node3D, stack: ItemStack) -> Node3D:
	for old: Node in hand.get_children():
		if old == _placeholder_sword:
			continue
		hand.remove_child(old)
		old.queue_free()
	if stack == null or stack.item == null or stack.item.model_scene == null:
		return null
	var data: ItemData = stack.item
	var model := data.model_scene.instantiate() as Node3D
	model.name = String(data.id)
	model.position = data.model_offset
	model.rotation.y = deg_to_rad(data.model_yaw_degrees)
	model.scale = Vector3.ONE * data.model_scale
	hand.add_child(model)
	for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = _tint_material
	return model


## Modelo segurado agora em uma das mãos (null = nada). Usado por testes.
func held_model(right: bool) -> Node3D:
	var hand: Node3D = _right_hand if right else _left_hand
	for child: Node in hand.get_children():
		if child != _placeholder_sword:
			return child as Node3D
	return null


## Modelo de arte em uso (null = boneco provisório). Usado por testes.
func class_model() -> Node3D:
	return _class_model


func _start_heal_targeting(ability: HealSpellData, slot: int) -> void:
	cancel_heal_targeting()
	_heal_targeting = ability
	_heal_slot = slot


## Durante a seleção: passar a mira por um aliado já o marca (fica esverdeado;
## sem clicar), Espaço cura os marcados, botão direito cancela. Clique não ataca
## nesse modo. Devolve true se usou o comando do quadro.
func _process_heal_targeting() -> bool:
	if input_blocked:
		cancel_heal_targeting()
		return false
	if _input.defend_held:
		cancel_heal_targeting()
		return true
	var ally: Node3D = ally_in_crosshair()
	if ally and not _heal_selection.has(ally):
		_toggle_heal_selection(ally)
	if _input.has_attack():
		_input.consume_attack()
		return true
	if _input.has_dodge():
		_input.consume_dodge()
		_confirm_heal()
		return true
	return false


func _toggle_heal_selection(ally: Node3D) -> void:
	var selected: bool = not _heal_selection.has(ally)
	if selected:
		_heal_selection.append(ally)
	else:
		_heal_selection.erase(ally)
	if ally.has_method("set_heal_selected"):
		ally.call("set_heal_selected", selected)


func _confirm_heal() -> void:
	_heal_selection = _heal_selection.filter(func(a: Node3D) -> bool: return is_instance_valid(a))
	if _heal_selection.is_empty():
		_say("Selecione um aliado primeiro.")
		return
	var ability: HealSpellData = _heal_targeting
	# Custo fixo por uso: o mesmo para 1 ou para vários aliados.
	if not mana.spend(ability.mana_cost):
		_say("Mana insuficiente (%d de mana)." % ability.mana_cost)
		return
	for ally: Node3D in _heal_selection:
		var ally_health: HealthComponent = ally.get("health")
		# Passivo Graça: curar quem está com a vida cheia vira escudo de vida.
		if _has_passive(&"graca") and ally_health.current_health >= ally_health.max_health:
			ally_health.add_shield(ability.heal_amount / 2)
			FloatingText.spawn(self, "Escudo +%d" % (ability.heal_amount / 2), ally.global_position + Vector3.UP * 2.4, Color(1.0, 0.95, 0.6))
		ally_health.heal(ability.heal_amount)
		FloatingText.spawn(self, "+%d" % ability.heal_amount, ally.global_position + Vector3.UP * 2.1, Color(0.5, 1.0, 0.5))
	_ability_cooldowns[_heal_slot] = ability.cooldown
	cancel_heal_targeting()


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
	var from_direction: Vector3
	if is_instance_valid(info.source) and info.source is Node3D:
		from_direction = flat((info.source as Node3D).global_position - global_position).normalized()
	else:
		from_direction = -flat(info.knockback).normalized()
	var shield: ShieldData = equipment.shield_data()
	# Postura inabalável: bloqueia por todos os lados.
	var half_angle: float = 180.0 if status.has(StatusEffects.STANCE) else shield.block_half_angle
	var in_front: bool = from_direction == Vector3.ZERO \
		or _block_direction.angle_to(from_direction) <= deg_to_rad(half_angle)
	if not in_front:
		return false
	# Escudo quebrado ainda segura parte do golpe: o dano passa reduzido.
	if equipment.shield.is_broken():
		info.amount = ceili(info.amount * shield.broken_damage_through)
		return false
	return true


func _on_blocked(info: DamageInfo) -> void:
	velocity = Vector3.ZERO if status.has(StatusEffects.STANCE) else info.knockback * equipment.shield_data().knockback_multiplier
	if equipment.shield.wear(1):
		FloatingText.spawn(self, "Escudo quebrou!", global_position + Vector3.UP * TEXT_HEIGHT, BROKEN_COLOR)
	# Passivo Muralha: bloquear dá Firmeza (menos dano por alguns segundos).
	if _has_passive(&"muralha"):
		if _firmeza_left <= 0.0:
			FloatingText.spawn(self, "Firmeza", global_position + Vector3.UP * (TEXT_HEIGHT + 0.5), Color(0.6, 0.75, 1.0))
		_firmeza_left = FIRMEZA_TIME
	equipment.notify_wear()
	FloatingText.spawn(self, BLOCK_SUCCESS_TEXT, global_position + Vector3.UP * TEXT_HEIGHT, BLOCK_SUCCESS_COLOR)
	_shield_flash_time = 0.08
	_camera.shake(1.5, 0.08)
	Hitstop.request(hitstop_block)


## Golpe ignorado pela invulnerabilidade: só conta como esquiva perfeita se
## veio durante o rolamento (não durante a invulnerabilidade pós-dano).
func _on_hit_ignored(_info: DamageInfo) -> void:
	if state != State.DODGE or _dodge_success_this_dodge:
		return
	_dodge_success_this_dodge = true
	FloatingText.spawn(self, DODGE_SUCCESS_TEXT, global_position + Vector3.UP * TEXT_HEIGHT, DODGE_SUCCESS_COLOR)
	dodge_succeeded.emit()


func _on_ability_hit(_target: Hurtbox) -> void:
	if equipment.weapon and equipment.weapon.wear(1):
		FloatingText.spawn(self, "Arma quebrou!", global_position + Vector3.UP * TEXT_HEIGHT, BROKEN_COLOR)
	equipment.notify_wear()
	Hitstop.request(hitstop_hit)


func _on_sword_hit(target: Hurtbox) -> void:
	# Golpe de escudo usa a mesma área de golpe: atordoa e não gasta a arma.
	var bash := _active_ability as ShieldBashData
	if state == State.ABILITY and bash:
		var enemy := target.owner as BasicEnemy
		if enemy:
			enemy.apply_stun(bash.stun_time)
		Hitstop.request(hitstop_hit)
		return
	if equipment.weapon:
		if equipment.weapon.wear(1):
			FloatingText.spawn(self, "Arma quebrou!", global_position + Vector3.UP * TEXT_HEIGHT, BROKEN_COLOR)
		equipment.notify_wear()
	var is_finisher: bool = _combo_step == COMBO_LENGTH - 1
	Hitstop.request(hitstop_finisher if is_finisher else hitstop_hit)
	if is_finisher:
		_camera.shake(2.0, 0.1)


func _on_damaged(info: DamageInfo) -> void:
	if info.over_time:
		# Queimadura/veneno: só o número, sem interromper nem empurrar.
		FloatingText.spawn(self, str(info.amount), global_position + Vector3.UP * (TEXT_HEIGHT + 0.3), Color(0.85, 0.6, 0.3), 8)
		return
	cancel_heal_targeting()
	if health.is_dead:
		return
	health.grant_invulnerability(post_hit_invulnerability)
	velocity = info.knockback
	_flash_time = 0.08
	FloatingText.spawn(self, str(info.amount), global_position + Vector3.UP * (TEXT_HEIGHT + 0.3), Color(1.0, 0.35, 0.3), 10)
	_camera.shake(3.0, 0.15)
	Hitstop.request(hitstop_hurt)
	_change_state(State.HURT)


func _on_died() -> void:
	if _can_self_revive():
		self_revive_available = false
		health.revive()
		health.current_health = maxi(health.max_health / 2, 1)
		health.health_changed.emit(health.current_health, health.max_health)
		health.grant_invulnerability(1.5)
		FloatingText.spawn(self, "Ressurreição!", global_position + Vector3.UP * (TEXT_HEIGHT + 0.4), Color(1.0, 0.95, 0.6))
		_change_state(State.MOVE)
		return
	_flash_time = 0.0
	_camera.shake(5.0, 0.25)
	_change_state(State.DEAD)
	died.emit()


# --- Habilidades de suporte -------------------------------------------------

## Você e os aliados vivos a até `radius` m de `center` (aliados de teste e outros jogadores).
func group_members(radius: float, center: Vector3) -> Array[Node3D]:
	var members: Array[Node3D] = []
	for group: StringName in [GROUP, AllyDummy.GROUP]:
		for node: Node in get_tree().get_nodes_in_group(group):
			var n := node as Node3D
			var hp: HealthComponent = n.get("health") if n else null
			if hp and not hp.is_dead and not members.has(n) and n.global_position.distance_to(center) <= radius:
				members.append(n)
	return members


func _fallen_ally(radius: float) -> Node3D:
	var best: Node3D = null
	for node: Node in get_tree().get_nodes_in_group(AllyDummy.GROUP) + get_tree().get_nodes_in_group(GROUP):
		var n := node as Node3D
		var hp: HealthComponent = n.get("health") if n and n != self else null
		if hp and hp.is_dead and n.global_position.distance_to(global_position) <= radius \
				and (best == null or n.global_position.distance_to(global_position) < best.global_position.distance_to(global_position)):
			best = n
	return best


func _can_self_revive() -> bool:
	if not self_revive_available:
		return false
	for a: AbilityData in abilities:
		var s := a as SupportSpellData
		if s and s.mechanic == SupportSpellData.Mechanic.REVIVE and effective_level() >= s.unlock_level:
			return true
	return false


func _cast_support(s: SupportSpellData) -> void:
	var text_at: Vector3 = global_position + Vector3.UP * (TEXT_HEIGHT + 0.4)
	match s.mechanic:
		SupportSpellData.Mechanic.SELF_EFFECT:
			status.apply(s.effect_id, s.duration, s.strength, self)
		SupportSpellData.Mechanic.GROUP_EFFECT:
			for m: Node3D in group_members(s.radius, global_position):
				var fx: StatusEffects = m.get("status")
				if fx:
					fx.apply(s.effect_id, s.duration, s.strength, self)
		SupportSpellData.Mechanic.DOME:
			SupportZone.spawn(self, SupportZone.Kind.DOME, s.radius, s.duration, 0, s.strength)
		SupportSpellData.Mechanic.ALLY_SHIELD:
			var target: Node3D = ally_in_crosshair()
			if target == null:
				target = self
			(target.get("health") as HealthComponent).add_shield(s.amount)
			FloatingText.spawn(self, "Escudo +%d" % s.amount, target.global_position + Vector3.UP * (TEXT_HEIGHT + 0.3), Color(1.0, 0.95, 0.6))
		SupportSpellData.Mechanic.HEAL_ZONE:
			SupportZone.spawn(self, SupportZone.Kind.HEAL, s.radius, s.duration, s.amount)
		SupportSpellData.Mechanic.REVIVE:
			if is_instance_valid(_support_target):
				var hp: HealthComponent = _support_target.get("health")
				hp.revive()
				hp.current_health = maxi(hp.max_health * s.amount / 100, 1)
				hp.health_changed.emit(hp.current_health, hp.max_health)
				FloatingText.spawn(self, "Levantou!", _support_target.global_position + Vector3.UP * (TEXT_HEIGHT + 0.3), Color(1.0, 0.95, 0.6))
			_support_target = null
		SupportSpellData.Mechanic.GROUP_HEAL:
			for m: Node3D in group_members(s.radius, global_position):
				var hp: HealthComponent = m.get("health")
				hp.heal(hp.max_health)
				var fx: StatusEffects = m.get("status")
				if fx:
					fx.clear_negative()
			FloatingText.spawn(self, "Milagre!", text_at, Color(1.0, 0.95, 0.6))


# --- Auxiliares ------------------------------------------------------------

## Escolhe o objeto usável mais próximo dentro do alcance e posiciona o aviso.
func _update_focus() -> void:
	var best: Interactable = null
	var best_distance: float = INF
	if state != State.DEAD:
		for area: Area3D in _interaction_detector.get_overlapping_areas():
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
		_interact_prompt.global_position = best.prompt_position()


func _has_passive(id: StringName) -> bool:
	return player_class != null and player_class.passive_id == id


## Modificadores de dano recebido do próprio jogador (passivos).
func _apply_damage_modifiers(info: DamageInfo) -> void:
	if _firmeza_left > 0.0:
		info.amount = ceili(info.amount * (1.0 - FIRMEZA_REDUCTION))


## Provocar: inimigos vivos no raio passam a atacar este jogador.
func _do_taunt(taunt: TauntData) -> void:
	var count := 0
	for node: Node in get_tree().get_nodes_in_group(BasicEnemy.GROUP):
		var enemy := node as BasicEnemy
		if enemy and not enemy.health.is_dead and enemy.global_position.distance_to(global_position) <= taunt.radius:
			enemy.apply_taunt(self, taunt.taunt_time)
			count += 1
	FloatingText.spawn(self, "Provocou %d" % count if count > 0 else "Ninguém por perto", global_position + Vector3.UP * TEXT_HEIGHT, Color(1.0, 0.6, 0.3))


func _can_block() -> bool:
	return _input.defend_held and equipment.shield != null


## Vida e mana máximas = base + crescimento por nível (igual para todas as classes).
func _apply_growth() -> void:
	health.set_max_health(_base_max_health + stats.bonus_max_health(effective_level()))
	mana.set_max_mana(_base_max_mana + stats.bonus_max_mana(effective_level()))


func _on_leveled_up(new_level: int) -> void:
	_apply_growth()
	# Subir de nível enche vida e mana (só ao subir; ganhar exp. não enche).
	health.heal(health.max_health)
	mana.restore_full()
	var level_text: FloatingText = FloatingText.spawn(self, "Nível %d!" % new_level, global_position + Vector3.UP * (TEXT_HEIGHT + 0.8), LEVEL_UP_COLOR)
	# Fica 1 s a mais que os outros textos, subindo mais devagar.
	level_text.lifetime = LEVEL_UP_TEXT_TIME
	level_text.rise_speed = 0.6
	# Filho do modelo (que gira com o personagem): as asas ficam sempre nas costas.
	_model.add_child(LevelUpEffect.new())


## Movimento pedido (teclas) convertido para o mundo, relativo à câmera:
## "para cima" = para onde a câmera olha.
func _world_move() -> Vector3:
	var input: Vector2 = _input.move_direction
	if input == Vector2.ZERO:
		return Vector3.ZERO
	var world: Vector3 = _camera.flat_right() * input.x - _camera.flat_forward() * input.y
	return world.limit_length(1.0)


func _aim_direction() -> Vector3:
	var aim: Vector3 = flat(_input.aim_direction)
	return aim.normalized() if aim.length() > 0.001 else facing


func _update_block_direction() -> void:
	_block_direction = _aim_direction()
	_attack_pivot.rotation.y = yaw_of(_block_direction)
	_set_facing(_block_direction)


func _apply_movement(direction: Vector3, speed: float, delta: float) -> void:
	speed *= status.speed_multiplier()
	if direction != Vector3.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)


func _set_facing(new_facing: Vector3) -> void:
	var f: Vector3 = flat(new_facing)
	if f.length() < 0.001:
		return
	facing = f.normalized()


## Apresentação provisória: só lê o estado, nunca muda regras de jogo.
func _update_visuals(delta: float) -> void:
	_flash_time = maxf(_flash_time - delta, 0.0)
	_shield_flash_time = maxf(_shield_flash_time - delta, 0.0)
	_shield_material.albedo_color = Color.WHITE if _shield_flash_time > 0.0 else SHIELD_COLOR
	if state == State.DEAD:
		_tint_material.albedo_color = TINT_DEAD
		_set_body_visible(true)
		return
	if _flash_time > 0.0:
		_tint_material.albedo_color = TINT_HIT
	elif _heal_selected:
		_tint_material.albedo_color = TINT_HEAL_SELECTED
	else:
		_tint_material.albedo_color = status.tint()
	if health.is_invulnerable() and state != State.DODGE:
		# Pisca enquanto invulnerável após dano (alterna a cada 1/15 s).
		_blink_clock += delta
		_set_body_visible(int(_blink_clock * 15.0) % 2 == 1)
	else:
		_blink_clock = 0.0
		_set_body_visible(true)


## Corpo e o que ele segura piscam juntos.
func _set_body_visible(value: bool) -> void:
	_body.visible = value
	_right_hand.visible = value
	_left_hand.visible = value


## Vetor só no chão (sem altura).
static func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Rotação em Y para um nó que "olha" para -Z apontar na direção dada.
static func yaw_of(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)
