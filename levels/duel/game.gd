extends Node2D
class_name Game

# Main game coordinator:
# - Listens to players' "shoot_requested" signals
# - Spawns arrows
# - (Later) can host UI, score, win/lose, rounds, etc.

@export var arrow_scene: PackedScene
@export var homing_missile_scene: PackedScene
@export var ice_missile_scene: PackedScene
@export var gravity_orb_scene: PackedScene
@export var grenade_scene: PackedScene
@export var archer_spike_scene: PackedScene

const PISTOLEIRO_PLAYER_SCRIPT := "res://characters/pistoleiro_player.gd"
const ARQUEIRO_PLAYER_SCRIPT := "res://characters/arqueiro_player.gd"
const MAGO_PLAYER_SCRIPT := "res://characters/mago_player.gd"

@onready var left_player: Player = $LeftPlayer
@onready var right_player: Player = $RightPlayer
@onready var p1_hp_label: Label = $UI/P1HP
@onready var p2_hp_label: Label = $UI/P2HP
@onready var p1_hp_bar: ProgressBar = $UI/P1HPBar
@onready var p2_hp_bar: ProgressBar = $UI/P2HPBar
@onready var p1_special_label: Label = $UI/P1Special
@onready var p2_special_label: Label = $UI/P2Special
@onready var p1_archer_spike_label: Label = $UI/P1ArcherSpike
@onready var p2_archer_spike_label: Label = $UI/P2ArcherSpike
@onready var training_panel: Control = get_node_or_null("UI/TrainingPanel") as Control
@onready var training_chk_dummy: CheckBox = get_node_or_null("UI/TrainingPanel/VBox/ChkDummyShoot") as CheckBox
@onready var training_btn_menu: Button = get_node_or_null("UI/TrainingPanel/VBox/BtnBackToMenu") as Button

# Flecha especial do arqueiro no ar (segundo clique em atirar fragmenta).
var _archer_carriers: Dictionary = {}
var _active_grenades: Dictionary = {}
var _active_ice: Dictionary = {}
var _training_loop_running: bool = false


func _enter_tree() -> void:
	_assign_player_scripts_from_run_config()


func _exit_tree() -> void:
	RunConfig.clear_p1_shoot_mouse_binding()


func _assign_player_scripts_from_run_config() -> void:
	var lp := get_node_or_null("LeftPlayer")
	if lp != null:
		_assign_player_script(lp, RunConfig.p1_character)
	var rp := get_node_or_null("RightPlayer")
	if rp == null:
		_fix_player_ids_after_script_assign(lp, null)
		return
	var right_kind := RunConfig.p2_character
	if RunConfig.mode == RunConfig.Mode.TRAINING:
		right_kind = Player.CharacterKind.PISTOLEIRO
	_assign_player_script(rp, right_kind)
	# set_script() zera exports para o default do novo script; player_id precisa bater com o lado da arena.
	_fix_player_ids_after_script_assign(lp, rp)


func _fix_player_ids_after_script_assign(left: Node, right: Node) -> void:
	if left is Player:
		(left as Player).player_id = 1
	if right is Player:
		(right as Player).player_id = 2


func _assign_player_script(node: Node, kind: int) -> void:
	var path := ARQUEIRO_PLAYER_SCRIPT
	if kind == Player.CharacterKind.PISTOLEIRO:
		path = PISTOLEIRO_PLAYER_SCRIPT
	elif kind == Player.CharacterKind.ARQUEIRO:
		path = ARQUEIRO_PLAYER_SCRIPT
	else:
		path = MAGO_PLAYER_SCRIPT
	var scr := load(path) as Script
	if scr != null and node.get_script() != scr:
		node.set_script(scr)


func _ready() -> void:
	_ensure_input_map()
	# Centralized wiring keeps Player and Arrow decoupled from "game rules".
	left_player.shoot_requested.connect(_spawn_arrow)
	left_player.shots_requested.connect(_spawn_shots)
	right_player.shoot_requested.connect(_spawn_arrow)
	left_player.special_requested.connect(_spawn_p1_special)
	right_player.special_requested.connect(_spawn_p1_special)
	left_player.archer_split_now_requested.connect(_on_archer_split_now_requested)
	right_player.archer_split_now_requested.connect(_on_archer_split_now_requested)
	left_player.grenade_requested.connect(_spawn_grenade)
	right_player.grenade_requested.connect(_spawn_grenade)
	left_player.grenade_detonate_requested.connect(_on_grenade_detonate_requested)
	right_player.grenade_detonate_requested.connect(_on_grenade_detonate_requested)
	left_player.mage_ice_requested.connect(_spawn_ice_missile)
	right_player.mage_ice_requested.connect(_spawn_ice_missile)
	left_player.mage_ice_detonate_requested.connect(_on_ice_detonate_requested)
	right_player.mage_ice_detonate_requested.connect(_on_ice_detonate_requested)
	left_player.mage_orb_requested.connect(_spawn_gravity_orb)
	right_player.mage_orb_requested.connect(_spawn_gravity_orb)

	# UI updates come from signals (easy to swap for a real HUD later).
	left_player.health_changed.connect(_on_left_hp_changed)
	right_player.health_changed.connect(_on_right_hp_changed)
	left_player.special_buff_changed.connect(_on_left_special_buff_changed)
	right_player.special_buff_changed.connect(_on_right_special_buff_changed)
	left_player.archer_spike_hud_changed.connect(_on_left_archer_spike_hud)
	right_player.archer_spike_hud_changed.connect(_on_right_archer_spike_hud)
	_on_left_hp_changed(left_player.hp)
	_on_right_hp_changed(right_player.hp)
	_on_left_special_buff_changed(false, 0, 0.0)
	_on_right_special_buff_changed(false, 0, 0.0)
	_on_left_archer_spike_hud(0, false)
	_on_right_archer_spike_hud(0, false)

	_setup_training_menu_ui()
	_apply_mode()


func _setup_training_menu_ui() -> void:
	var is_training := RunConfig.mode == RunConfig.Mode.TRAINING
	if training_panel != null:
		training_panel.visible = is_training
	if not is_training:
		return
	if training_chk_dummy != null:
		training_chk_dummy.button_pressed = RunConfig.training_dummy_shoot
		training_chk_dummy.toggled.connect(_on_training_dummy_toggled)
	if training_btn_menu != null:
		training_btn_menu.pressed.connect(_on_training_back_to_menu_pressed)


func _on_training_back_to_menu_pressed() -> void:
	RunConfig.clear_p1_shoot_mouse_binding()
	get_tree().change_scene_to_file("res://ui/menu.tscn")


func _on_training_dummy_toggled(pressed: bool) -> void:
	RunConfig.training_dummy_shoot = pressed


func _apply_mode() -> void:
	# Default: both players are human-controlled.
	left_player.input_enabled = true
	right_player.input_enabled = true

	if RunConfig.mode == RunConfig.Mode.TRAINING:
		# Training: right player is a dummy (pistoleiro straight shots).
		right_player.input_enabled = false
		_start_training_dummy_loop()

func _start_training_dummy_loop() -> void:
	if _training_loop_running:
		return
	_training_loop_running = true
	_training_dummy_loop()

func _training_dummy_loop() -> void:
	# Fire a projectile every N seconds toward Player 1 for dodging practice.
	call_deferred("_training_dummy_loop_async")

func _training_dummy_loop_async() -> void:
	while is_inside_tree() and RunConfig.mode == RunConfig.Mode.TRAINING:
		await get_tree().create_timer(RunConfig.training_dummy_interval).timeout
		if not is_inside_tree():
			return
		if RunConfig.training_dummy_shoot:
			_fire_training_dummy_shot()
	_training_loop_running = false

func _fire_training_dummy_shot() -> void:
	# Simple straight shot from dummy toward player 1.
	var from := right_player.get_node("Muzzle") as Marker2D
	var origin := from.global_position
	var target := left_player.global_position + Vector2(0, -20)
	var dir := (target - origin).normalized()
	var speed := 900.0
	var vel := dir * speed
	_spawn_one_arrow(right_player, origin, vel, {}, 0.0, 0, -1, 1.0)

func _ensure_input_map() -> void:
	# Some environments/projects fail to import InputMap from project.godot on first load.
	# To keep this prototype runnable, we ensure required actions exist at runtime.
	_add_action_if_missing("p1_left", KEY_A)
	_add_action_if_missing("p1_right", KEY_D)
	_add_action_if_missing("p1_jump", KEY_SPACE)
	_add_action_if_missing("p1_hover_up", KEY_W)
	_add_action_if_missing("p1_hover_down", KEY_S)
	if not InputMap.has_action("p1_shoot"):
		InputMap.add_action("p1_shoot")
	# Tiro básico P1: só rato. Tira F do project.godot se existir (F = skills, não tiro).
	_ensure_action_has_mouse_button("p1_shoot", MOUSE_BUTTON_LEFT)
	_strip_key_from_action("p1_shoot", KEY_F)
	_add_action_if_missing("p1_grenade", KEY_F)
	_add_action_if_missing("p1_archer_spike", KEY_F)
	_strip_key_from_action("p1_special", KEY_C)
	_add_action_if_missing("p1_special", KEY_G)
	# Mago: levitar = p1_mage_float (C) / p2_mage_float (Y); orbe = segurar G e soltar.
	_add_action_if_missing("p1_mage_float", KEY_C)
	_add_action_if_missing("p1_shield", KEY_Q)
	_ensure_dash_action("p1_dash", true)
	_add_action_if_missing("ui_game_pause", KEY_ENTER)
	_ensure_p2_default_keyboard()

## P2 no mesmo teclado (vs local): setas + L tiro; não remover teclas.
func _ensure_p2_default_keyboard() -> void:
	_add_action_if_missing("p2_left", KEY_LEFT)
	_add_action_if_missing("p2_right", KEY_RIGHT)
	_add_action_if_missing("p2_jump", KEY_UP)
	_add_action_if_missing("p2_hover_up", KEY_I)
	_add_action_if_missing("p2_hover_down", KEY_K)
	if not InputMap.has_action("p2_shoot"):
		InputMap.add_action("p2_shoot")
	_ensure_action_has_key("p2_shoot", KEY_L)
	_add_action_if_missing("p2_grenade", KEY_J)
	_add_action_if_missing("p2_archer_spike", KEY_U)
	_add_action_if_missing("p2_special", KEY_O)
	_add_action_if_missing("p2_shield", KEY_SLASH)
	_add_action_if_missing("p2_mage_float", KEY_Y)
	_ensure_dash_action("p2_dash", false)


func _ensure_dash_action(action_name: StringName, left_shift: bool) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var want_loc := KEY_LOCATION_LEFT if left_shift else KEY_LOCATION_RIGHT
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey:
			var ke := e as InputEventKey
			if ke.keycode == KEY_SHIFT and ke.location == want_loc:
				return
	var ev := InputEventKey.new()
	ev.keycode = KEY_SHIFT
	ev.location = want_loc
	InputMap.action_add_event(action_name, ev)

func _strip_key_from_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		return
	var to_remove: Array = []
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey and (ev as InputEventKey).keycode == keycode:
			to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action_name, ev)

func _add_action_if_missing(action_name: StringName, keycode: int) -> void:
	if InputMap.has_action(action_name):
		_ensure_action_has_key(action_name, keycode)
		return

	InputMap.add_action(action_name)
	_ensure_action_has_key(action_name, keycode)

func _ensure_action_has_key(action_name: StringName, keycode: int) -> void:
	# Adds the key if it's not already bound.
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey and (e as InputEventKey).keycode == keycode:
			return

	var ev := InputEventKey.new()
	ev.keycode = keycode as Key
	InputMap.action_add_event(action_name, ev)

func _ensure_action_has_mouse_button(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for e in InputMap.action_get_events(action_name):
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == button_index:
			return

	var ev := InputEventMouseButton.new()
	ev.button_index = button_index as MouseButton
	InputMap.action_add_event(action_name, ev)

func _spawn_arrow(owner_player: Player, spawn_position: Vector2, initial_velocity: Vector2, shot_flags: Dictionary) -> void:
	if shot_flags.get("spike_volley", false) and owner_player is ArqueiroPlayer:
		_spawn_archer_spike_volley(owner_player, spawn_position, initial_velocity)
		return
	if arrow_scene == null:
		push_error("Game: 'arrow_scene' is not assigned. Set it in main.tscn inspector.")
		return

	_spawn_one_arrow(owner_player, spawn_position, initial_velocity, shot_flags)


func _spawn_grenade(owner_player: Player, spawn_position: Vector2, throw_velocity: Vector2) -> void:
	if grenade_scene == null:
		push_error("Game: 'grenade_scene' não está atribuído em main.tscn.")
		return
	var gr := grenade_scene.instantiate() as Grenade
	if gr == null:
		return
	add_child(gr)
	gr.global_position = spawn_position
	gr.setup(owner_player, throw_velocity)
	_active_grenades[owner_player] = gr
	gr.tree_exiting.connect(_on_grenade_tree_exiting.bind(owner_player, gr))
	if owner_player is PistoleiroPlayer:
		(owner_player as PistoleiroPlayer).set_grenade_active(true)


func _spawn_ice_missile(owner_player: Player, spawn_position: Vector2, initial_velocity: Vector2) -> void:
	if ice_missile_scene == null:
		push_error("Game: 'ice_missile_scene' não está atribuído em main.tscn.")
		return
	var im := ice_missile_scene.instantiate() as IceMissile
	if im == null:
		return
	add_child(im)
	im.global_position = spawn_position
	im.setup(owner_player, initial_velocity, 0.0, 0, 0, 1.0, false, 7.0)
	_active_ice[owner_player] = im
	im.tree_exiting.connect(_on_ice_tree_exiting.bind(owner_player, im))
	if owner_player is MagoPlayer:
		(owner_player as MagoPlayer).set_ice_active(true)


func _on_ice_tree_exiting(owner_player: Player, im: IceMissile) -> void:
	if _active_ice.get(owner_player) != im:
		return
	_active_ice.erase(owner_player)
	if owner_player is MagoPlayer:
		(owner_player as MagoPlayer).set_ice_active(false)


func _on_ice_detonate_requested(owner_player: Player) -> void:
	var im: IceMissile = _active_ice.get(owner_player)
	if im == null or not is_instance_valid(im):
		_active_ice.erase(owner_player)
		return
	im.remote_detonate()


func _spawn_gravity_orb(owner_player: Player, spawn_position: Vector2, charge_t: float) -> void:
	if gravity_orb_scene == null:
		push_error("Game: 'gravity_orb_scene' não está atribuído em main.tscn.")
		return
	var target := right_player
	if owner_player == right_player:
		target = left_player
	var aim := Vector2.RIGHT if owner_player.player_id == 1 else Vector2.LEFT
	if target != null and is_instance_valid(target):
		var to_t := target.global_position + Vector2(0.0, -18.0) - spawn_position
		if to_t.length_squared() > 1.0:
			aim = to_t.normalized()
	var orb := gravity_orb_scene.instantiate() as GravityOrb
	if orb == null:
		return
	add_child(orb)
	orb.global_position = spawn_position
	orb.setup(owner_player, aim * 320.0)
	orb.set_charge_t(charge_t)


func _on_grenade_tree_exiting(owner_player: Player, gr: Grenade) -> void:
	if _active_grenades.get(owner_player) != gr:
		return
	_active_grenades.erase(owner_player)
	if owner_player is PistoleiroPlayer:
		(owner_player as PistoleiroPlayer).set_grenade_active(false)


func _on_grenade_detonate_requested(owner_player: Player) -> void:
	var gr: Grenade = _active_grenades.get(owner_player)
	if gr == null or not is_instance_valid(gr):
		_active_grenades.erase(owner_player)
		# Fallback: em alguns casos o Dictionary pode não bater; procura granada ativa do dono.
		for n in get_tree().get_nodes_in_group("grenades"):
			if n is Grenade:
				var g2 := n as Grenade
				if g2.get_owner_player() == owner_player:
					gr = g2
					_active_grenades[owner_player] = gr
					break
	if gr == null or not is_instance_valid(gr):
		return
	gr.remote_detonate()


func _spawn_shots(owner_player: Player, shots: Array) -> void:
	# shots is an Array[Dictionary] with optional keys:
	# pos, vel, gravity, bounces, damage, size
	for s in shots:
		if typeof(s) != TYPE_DICTIONARY:
			continue
		var pos: Vector2 = s.get("pos", Vector2.ZERO)
		var vel: Vector2 = s.get("vel", Vector2.ZERO)
		var gravity: float = s.get("gravity", INF)
		var bounces: int = s.get("bounces", -1)
		var damage: int = s.get("damage", -1)
		var size: float = s.get("size", 1.0)
		var shot_flags: Dictionary = s.get("flags", {})
		_spawn_one_arrow(owner_player, pos, vel, shot_flags, gravity, bounces, damage, size)

func _spawn_one_arrow(
	owner_player: Player,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	shot_flags: Dictionary,
	gravity_override: float = INF,
	bounces_override: int = -1,
	damage_override: int = -1,
	size_multiplier: float = 1.0
) -> void:
	if shot_flags.get("spike_shot", false) and owner_player is ArqueiroPlayer:
		if archer_spike_scene == null:
			push_error("Game: 'archer_spike_scene' não está atribuído em main.tscn.")
			return
		var sp := archer_spike_scene.instantiate() as ArcherSpike
		if sp == null:
			return
		add_child(sp)
		sp.global_position = spawn_position
		sp.setup(owner_player, initial_velocity)
		return

	var want_homing := owner_player.is_mago()
	if want_homing and homing_missile_scene == null:
		push_error("Game: 'homing_missile_scene' não está atribuído em main.tscn.")
		want_homing = false
	if (not want_homing) and arrow_scene == null:
		return

	var arrow: Arrow = null
	if want_homing:
		arrow = homing_missile_scene.instantiate() as Arrow
	else:
		arrow = arrow_scene.instantiate() as Arrow
	if arrow == null:
		return
	add_child(arrow)
	arrow.global_position = spawn_position

	# Default behavior by owner if overrides not provided.
	var g := gravity_override
	var b := bounces_override
	if g == INF:
		g = 0.0 if owner_player.is_pistoleiro() else arrow.gravity_accel
	if b < 0:
		b = 1 if owner_player.is_pistoleiro() else 0

	var is_carrier: bool = false
	if shot_flags.get("archer_split", false):
		is_carrier = owner_player is ArqueiroPlayer
	var cluster_spread: float = 7.0
	if owner_player is ArqueiroPlayer:
		cluster_spread = (owner_player as ArqueiroPlayer).archer_split_spread_deg
	if is_carrier:
		size_multiplier = maxf(size_multiplier, 1.12)

	arrow.setup(owner_player, initial_velocity, g, b, damage_override, size_multiplier, is_carrier, cluster_spread)
	if want_homing and arrow.has_method("set_homing_target"):
		var target := left_player
		if owner_player == left_player:
			target = right_player
		arrow.call("set_homing_target", target)
	if is_carrier:
		_archer_carriers[owner_player] = arrow
		arrow.tree_exiting.connect(_on_archer_carrier_tree_exiting.bind(owner_player, arrow))
	arrow.hit_player.connect(_on_arrow_hit_player)

func _spawn_p1_special(_owner_player: Player, _spawn_position: Vector2) -> void:
	# Player handles special-buff state; this signal is kept for future UI/SFX hooks.
	pass


func _on_archer_carrier_tree_exiting(player: Player, arrow: Arrow) -> void:
	if _archer_carriers.get(player) != arrow:
		return
	_archer_carriers.erase(player)
	if player.is_archer_waiting_split_click():
		player.archer_carrier_cancelled()


func _on_archer_split_now_requested(player: Player) -> void:
	var arr: Arrow = _archer_carriers.get(player)
	if arr == null or not is_instance_valid(arr):
		return
	# Faz o split aqui mesmo (mais confiável que depender de sinal).
	var at_pos := arr.global_position
	var vel := arr.velocity
	_spawn_archer_split_fragments(player, at_pos, vel)
	arr.queue_free()
	_archer_carriers.erase(player)
	player.archer_after_manual_split()

func _spawn_archer_spike_volley(owner_player: Player, at_pos: Vector2, cluster_vel: Vector2) -> void:
	if archer_spike_scene == null:
		push_error("Game: 'archer_spike_scene' não está atribuído.")
		return
	var speed := cluster_vel.length()
	if speed < 80.0:
		speed = owner_player.min_launch_speed
	var base_ang := cluster_vel.angle()
	var spread_deg: float = 7.0
	if owner_player is ArqueiroPlayer:
		spread_deg = (owner_player as ArqueiroPlayer).archer_split_spread_deg
	for i in range(5):
		var off := spread_deg * float(i - 2)
		var dir := Vector2.RIGHT.rotated(base_ang + deg_to_rad(off))
		var v := dir * speed
		var spawn_pt := at_pos + dir * 8.0
		var sp := archer_spike_scene.instantiate() as ArcherSpike
		if sp == null:
			continue
		add_child(sp)
		sp.global_position = spawn_pt
		sp.setup(owner_player, v)


func _spawn_archer_split_fragments(owner_player: Player, at_pos: Vector2, cluster_vel: Vector2) -> void:
	var speed := cluster_vel.length()
	if speed < 80.0:
		speed = owner_player.min_launch_speed
	var base_ang := cluster_vel.angle()
	var b := 0
	var child_gravity: float = owner_player.projectile_gravity_accel
	var spread_deg: float = 7.0
	if owner_player is ArqueiroPlayer:
		spread_deg = (owner_player as ArqueiroPlayer).archer_split_spread_deg
	for i in range(5):
		var off := spread_deg * float(i - 2)
		var dir := Vector2.RIGHT.rotated(base_ang + deg_to_rad(off))
		var v := dir * speed
		var spawn_pt := at_pos + dir * 8.0
		_spawn_one_arrow(owner_player, spawn_pt, v, {}, child_gravity, b, -1, 1.0)


## (Old special burst removed)

func _on_arrow_hit_player(_victim: Player, _damage: int) -> void:
	# Intentionally empty for now. Victim prints remaining HP in Player.take_damage().
	pass

func _on_left_hp_changed(hp: int) -> void:
	p1_hp_label.text = "P1 HP: %d" % hp
	p1_hp_bar.value = hp

func _on_right_hp_changed(hp: int) -> void:
	p2_hp_label.text = "P2 HP: %d" % hp
	p2_hp_bar.value = hp

func _on_left_special_buff_changed(active: bool, uses_left: int, _time_left: float) -> void:
	if left_player.is_pistoleiro():
		p1_special_label.visible = active
		if active:
			p1_special_label.text = "P1 SPECIAL - usos: %d" % uses_left
		else:
			p1_special_label.text = ""
	elif left_player.is_arqueiro():
		p1_special_label.visible = active
		if active:
			if uses_left >= 2:
				p1_special_label.text = "P1: mire e solte o tiro especial"
			else:
				p1_special_label.text = "P1: clique atirar de novo p/ 5 flechas"
		else:
			p1_special_label.text = ""
	else:
		p1_special_label.visible = false
		p1_special_label.text = ""

func _on_right_special_buff_changed(active: bool, uses_left: int, _time_left: float) -> void:
	if right_player.is_pistoleiro():
		p2_special_label.visible = active
		if active:
			p2_special_label.text = "P2 SPECIAL - usos: %d" % uses_left
		else:
			p2_special_label.text = ""
	elif right_player.is_arqueiro():
		p2_special_label.visible = active
		if active:
			if uses_left >= 2:
				p2_special_label.text = "P2: mire e solte o tiro especial"
			else:
				p2_special_label.text = "P2: clique atirar de novo p/ 5 flechas"
		else:
			p2_special_label.text = ""
	else:
		p2_special_label.visible = false
		p2_special_label.text = ""


func _on_left_archer_spike_hud(remaining: int, volley_armed: bool) -> void:
	if not left_player.is_arqueiro():
		p1_archer_spike_label.visible = false
		p1_archer_spike_label.text = ""
		return
	p1_archer_spike_label.visible = remaining > 0 or volley_armed
	if volley_armed:
		p1_archer_spike_label.text = "P1 ESPINHOS: solte o tiro → 5 no chão (leque)"
	elif remaining > 0:
		p1_archer_spike_label.text = "P1 ESPINHOS: %d tiro(s) buffado(s)" % remaining
	else:
		p1_archer_spike_label.text = ""


func _on_right_archer_spike_hud(remaining: int, volley_armed: bool) -> void:
	if not right_player.is_arqueiro():
		p2_archer_spike_label.visible = false
		p2_archer_spike_label.text = ""
		return
	p2_archer_spike_label.visible = remaining > 0 or volley_armed
	if volley_armed:
		p2_archer_spike_label.text = "P2 ESPINHOS: solte o tiro → 5 no chão (leque)"
	elif remaining > 0:
		p2_archer_spike_label.text = "P2 ESPINHOS: %d tiro(s) buffado(s)" % remaining
	else:
		p2_archer_spike_label.text = ""
