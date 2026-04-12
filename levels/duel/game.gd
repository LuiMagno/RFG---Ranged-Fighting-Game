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
const ESQUELETO_PLAYER_SCRIPT := "res://characters/esqueleto_player.gd"
const ONGMA_EPILEF_PLAYER_SCRIPT := "res://characters/ongma_epilef_player.gd"

const VS_ROUND_DURATION_S := 60.0
const VS_ROUNDS_TO_WIN := 3

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
@onready var _vs_hud: Control = $UI/VsHud
@onready var _vs_timer_label: Label = $UI/VsHud/VsTimerLabel
@onready var _vs_p1_character_label: Label = $UI/VsHud/VsP1CharacterLabel
@onready var _vs_p2_character_label: Label = $UI/VsHud/VsP2CharacterLabel
@onready var _vs_score_label: Label = $UI/VsHud/VsScoreLabel
@onready var _vs_round_banner_root: Control = $VsRoundBannerLayer/BannerRoot
@onready var _vs_round_banner_label: Label = $VsRoundBannerLayer/BannerRoot/BannerCenter/RoundBannerLabel
@onready var _vs_match_end_menu: VsMatchEndMenu = $VsMatchEndLayer

# Flecha especial do arqueiro no ar (segundo disparo fragmenta).
var _archer_carriers: Dictionary = {}
var _active_grenades: Dictionary = {}
var _active_ice: Dictionary = {}
var _training_loop_running: bool = false

var _vs_p1_spawn: Vector2
var _vs_p2_spawn: Vector2
var _vs_round_time_left: float = 0.0
var _vs_round_playing: bool = false
var _vs_resolving_round: bool = false
var _vs_round_interstitial_active: bool = false
var _vs_match_end_menu_open: bool = false
var _p1_rounds_won: int = 0
var _p2_rounds_won: int = 0


func _enter_tree() -> void:
	_assign_player_scripts_from_run_config()


func _exit_tree() -> void:
	RunConfig.clear_p1_shoot_mouse_binding()


## Reaplica teclas + eventos de comando conforme `RunConfig` (útil se mudares input em pausa no treino).
func apply_input_map_from_run_config() -> void:
	_ensure_input_map()


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
	elif kind == Player.CharacterKind.MAGO:
		path = MAGO_PLAYER_SCRIPT
	elif kind == Player.CharacterKind.ESQUELETO:
		path = ESQUELETO_PLAYER_SCRIPT
	elif kind == Player.CharacterKind.ONGMA_EPILEF:
		path = ONGMA_EPILEF_PLAYER_SCRIPT
	else:
		path = MAGO_PLAYER_SCRIPT
	var scr := load(path) as Script
	if scr != null and node.get_script() != scr:
		node.set_script(scr)


func _ready() -> void:
	apply_input_map_from_run_config()
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

	_vs_p1_spawn = left_player.position
	_vs_p2_spawn = right_player.position
	_apply_mode()
	if RunConfig.mode == RunConfig.Mode.VS_PLAYER:
		_vs_hud.visible = true
		_start_vs_round()
	else:
		_vs_hud.visible = false


func blocks_vs_pause_menu() -> bool:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return false
	return _vs_match_end_menu_open or _vs_round_interstitial_active or _vs_resolving_round


func rematch_vs_after_post_game() -> void:
	_vs_match_end_menu_open = false
	_vs_match_end_menu.close_menu()
	_p1_rounds_won = 0
	_p2_rounds_won = 0
	_start_vs_round()


func _process(delta: float) -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return
	if not _vs_round_playing or _vs_match_end_menu_open or _vs_resolving_round:
		return
	if get_tree().paused:
		return
	_vs_round_time_left -= delta
	_update_vs_hud()
	if _vs_round_time_left <= 0.0:
		_finish_vs_round_timeout()


func _start_vs_round() -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return
	_clear_vs_projectiles_and_carry_state()
	left_player.prepare_for_vs_round_respawn(_vs_p1_spawn)
	right_player.prepare_for_vs_round_respawn(_vs_p2_spawn)
	left_player.input_enabled = true
	right_player.input_enabled = true
	_vs_round_time_left = VS_ROUND_DURATION_S
	_vs_round_playing = true
	_refresh_vs_character_labels()
	_update_vs_hud()


func _clear_vs_projectiles_and_carry_state() -> void:
	_archer_carriers.clear()
	_active_grenades.clear()
	_active_ice.clear()
	for c in get_children():
		if (
			c is Arrow
			or c is Grenade
			or c is GravityOrb
			or c is ArcherSpike
			or c is Fireball
			or c is IceField
		):
			c.queue_free()


func _update_vs_hud() -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return
	var whole := maxi(0, ceili(_vs_round_time_left))
	var mn := whole / 60
	var sc := whole % 60
	_vs_timer_label.text = "%d:%02d" % [mn, sc]
	_vs_score_label.text = "Vitórias: %d — %d  (primeiro a %d)" % [_p1_rounds_won, _p2_rounds_won, VS_ROUNDS_TO_WIN]


func _refresh_vs_character_labels() -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return
	var k1 := RunConfig.p1_character
	var k2 := RunConfig.p2_character
	var n1 := MenuThemeUtil.vs_character_name(k1)
	var n2 := MenuThemeUtil.vs_character_name(k2)
	_vs_p1_character_label.text = "Jogador 1 — %s" % n1
	_vs_p1_character_label.add_theme_color_override("font_color", MenuThemeUtil.vs_character_accent_color(k1))
	_vs_p2_character_label.text = "Jogador 2 — %s" % n2
	_vs_p2_character_label.add_theme_color_override("font_color", MenuThemeUtil.vs_character_accent_color(k2))


func _check_vs_ko_after_hp_change() -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return
	if not _vs_round_playing or _vs_resolving_round or _vs_match_end_menu_open:
		return
	if left_player.hp <= 0:
		_finish_vs_round_ko(2)
	elif right_player.hp <= 0:
		_finish_vs_round_ko(1)


func _finish_vs_round_ko(winner_id: int) -> void:
	if _vs_resolving_round or not _vs_round_playing:
		return
	_vs_resolving_round = true
	_vs_round_playing = false
	left_player.input_enabled = false
	right_player.input_enabled = false
	await _show_round_banner_and_wait("Jogador %d vence o round!" % winner_id)
	if winner_id == 1:
		_p1_rounds_won += 1
	else:
		_p2_rounds_won += 1
	await _try_finish_match_or_continue()
	_vs_resolving_round = false


func _finish_vs_round_timeout() -> void:
	if _vs_resolving_round or not _vs_round_playing:
		return
	_vs_resolving_round = true
	_vs_round_playing = false
	left_player.input_enabled = false
	right_player.input_enabled = false
	var lh := left_player.hp
	var rh := right_player.hp
	var msg: String
	if lh > rh:
		msg = "Tempo! Jogador 1 vence o round (mais HP)."
	elif rh > lh:
		msg = "Tempo! Jogador 2 vence o round (mais HP)."
	else:
		msg = "Tempo esgotado — empate! Novo round."
	await _show_round_banner_and_wait(msg)
	if lh > rh:
		_p1_rounds_won += 1
	elif rh > lh:
		_p2_rounds_won += 1
	await _try_finish_match_or_continue()
	_vs_resolving_round = false


func _show_round_banner_and_wait(message: String) -> void:
	_vs_round_interstitial_active = true
	_vs_round_banner_label.text = message
	_vs_round_banner_root.visible = true
	await get_tree().create_timer(2.5).timeout
	_vs_round_banner_root.visible = false
	_vs_round_interstitial_active = false


func _try_finish_match_or_continue() -> void:
	_update_vs_hud()
	if _p1_rounds_won >= VS_ROUNDS_TO_WIN or _p2_rounds_won >= VS_ROUNDS_TO_WIN:
		var mw := 1 if _p1_rounds_won >= VS_ROUNDS_TO_WIN else 2
		_open_vs_match_end(mw)
	else:
		_start_vs_round()


func _open_vs_match_end(match_winner_id: int) -> void:
	_vs_match_end_menu_open = true
	_vs_round_playing = false
	left_player.input_enabled = false
	right_player.input_enabled = false
	_vs_match_end_menu.open_for_match_winner(match_winner_id)


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
	_strip_key_from_action("p1_shoot", KEY_F)
	_add_action_if_missing("p1_grenade", KEY_F)
	_add_action_if_missing("p1_archer_spike", KEY_F)
	_strip_key_from_action("p1_special", KEY_C)
	_add_action_if_missing("p1_special", KEY_G)
	# Mago: levitar = p1_mage_float (C) / p2_mage_float (Y); orbe = segurar G e soltar.
	_add_action_if_missing("p1_mage_float", KEY_C)
	_add_action_if_missing("p1_shield", KEY_Q)
	_ensure_dash_action("p1_dash", true)
	_ensure_ui_game_pause_input()
	_ensure_p2_default_keyboard()

	_ensure_aim_action_quartet("p1")
	_ensure_aim_action_quartet("p2")
	_strip_joypad_events_from_actions(_player_action_names("p1"))
	_strip_joypad_events_from_actions(_player_action_names("p2"))
	if RunConfig.p1_input_scheme == RunConfig.InputScheme.GAMEPAD:
		_add_gamepad_mappings_for_player("p1", RunConfig.p1_joy_device)
	if RunConfig.p2_input_scheme == RunConfig.InputScheme.GAMEPAD:
		_add_gamepad_mappings_for_player("p2", RunConfig.p2_joy_device)

	if RunConfig.p1_input_scheme == RunConfig.InputScheme.KEYBOARD_MOUSE:
		_ensure_action_has_mouse_button("p1_shoot", MOUSE_BUTTON_LEFT)
	else:
		RunConfig.clear_p1_shoot_mouse_binding()

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


func _player_action_names(prefix: String) -> Array:
	var p := prefix + "_"
	return [
		p + "left",
		p + "right",
		p + "jump",
		p + "hover_up",
		p + "hover_down",
		p + "shoot",
		p + "grenade",
		p + "archer_spike",
		p + "special",
		p + "mage_float",
		p + "shield",
		p + "dash",
		p + "aim_left",
		p + "aim_right",
		p + "aim_up",
		p + "aim_down",
	]


func _ensure_aim_action_quartet(prefix: String) -> void:
	var dz := 0.35
	for s in ["aim_left", "aim_right", "aim_up", "aim_down"]:
		var an: StringName = StringName("%s_%s" % [prefix, s])
		if not InputMap.has_action(an):
			InputMap.add_action(an, dz)


func _strip_joypad_events_from_actions(action_names: Array) -> void:
	for an in action_names:
		if not InputMap.has_action(an):
			continue
		var to_remove: Array = []
		for ev in InputMap.action_get_events(an):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				to_remove.append(ev)
		for ev in to_remove:
			InputMap.action_erase_event(an, ev)


func _joy_btn(dev: int, button: JoyButton) -> InputEventJoypadButton:
	var j := InputEventJoypadButton.new()
	j.device = dev
	j.button_index = button
	return j


func _joy_motion(dev: int, axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	var m := InputEventJoypadMotion.new()
	m.device = dev
	m.axis = axis
	m.axis_value = axis_value
	return m


func _add_gamepad_mappings_for_player(prefix: String, device: int) -> void:
	var p := prefix + "_"
	# Movimento: stick esquerdo + D-pad horizontal (doc: get_axis em left/right).
	InputMap.action_add_event(p + "left", _joy_motion(device, JOY_AXIS_LEFT_X, -1.0))
	InputMap.action_add_event(p + "left", _joy_btn(device, JOY_BUTTON_DPAD_LEFT))
	InputMap.action_add_event(p + "right", _joy_motion(device, JOY_AXIS_LEFT_X, 1.0))
	InputMap.action_add_event(p + "right", _joy_btn(device, JOY_BUTTON_DPAD_RIGHT))
	# Hover na flutuação: gatilhos (evita D-pad vertical em conflito com menus / movimento).
	InputMap.action_add_event(p + "hover_up", _joy_motion(device, JOY_AXIS_TRIGGER_RIGHT, 1.0))
	InputMap.action_add_event(p + "hover_down", _joy_motion(device, JOY_AXIS_TRIGGER_LEFT, 1.0))
	# Mira: stick direito → get_vector nas ações aim_*.
	InputMap.action_add_event(p + "aim_left", _joy_motion(device, JOY_AXIS_RIGHT_X, -1.0))
	InputMap.action_add_event(p + "aim_right", _joy_motion(device, JOY_AXIS_RIGHT_X, 1.0))
	InputMap.action_add_event(p + "aim_up", _joy_motion(device, JOY_AXIS_RIGHT_Y, -1.0))
	InputMap.action_add_event(p + "aim_down", _joy_motion(device, JOY_AXIS_RIGHT_Y, 1.0))
	# Xbox-like: tiro RB, pulo A, dash B, especial Y, escudo LB, granada X, mago levitar R3, espinho L3.
	InputMap.action_add_event(p + "shoot", _joy_btn(device, JOY_BUTTON_RIGHT_SHOULDER))
	InputMap.action_add_event(p + "jump", _joy_btn(device, JOY_BUTTON_A))
	InputMap.action_add_event(p + "dash", _joy_btn(device, JOY_BUTTON_B))
	InputMap.action_add_event(p + "special", _joy_btn(device, JOY_BUTTON_Y))
	InputMap.action_add_event(p + "shield", _joy_btn(device, JOY_BUTTON_LEFT_SHOULDER))
	InputMap.action_add_event(p + "grenade", _joy_btn(device, JOY_BUTTON_X))
	InputMap.action_add_event(p + "mage_float", _joy_btn(device, JOY_BUTTON_RIGHT_STICK))
	InputMap.action_add_event(p + "archer_spike", _joy_btn(device, JOY_BUTTON_LEFT_STICK))


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


func _ensure_ui_game_pause_input() -> void:
	_add_action_if_missing("ui_game_pause", KEY_ENTER)
	if not InputMap.has_action("ui_game_pause"):
		return
	for e in InputMap.action_get_events("ui_game_pause"):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == JOY_BUTTON_START:
			return
	var jev := InputEventJoypadButton.new()
	jev.device = -1
	jev.button_index = JOY_BUTTON_START
	InputMap.action_add_event("ui_game_pause", jev)


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
		g = 0.0 if (owner_player.is_pistoleiro() or (owner_player is EsqueletoPlayer)) else arrow.gravity_accel
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
	_check_vs_ko_after_hp_change()

func _on_right_hp_changed(hp: int) -> void:
	p2_hp_label.text = "P2 HP: %d" % hp
	p2_hp_bar.value = hp
	_check_vs_ko_after_hp_change()

func _on_left_special_buff_changed(active: bool, uses_left: int, _time_left: float) -> void:
	var s1 := RunConfig.get_shoot_hint_token_for_player(1)
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
				p1_special_label.text = "P1: %s atirar de novo p/ 5 flechas" % s1
		else:
			p1_special_label.text = ""
	elif left_player is EsqueletoPlayer:
		p1_special_label.visible = active
		p1_special_label.text = ("P1: próximo tiro (%s) = 3 flechas" % s1) if active else ""
	else:
		p1_special_label.visible = false
		p1_special_label.text = ""

func _on_right_special_buff_changed(active: bool, uses_left: int, _time_left: float) -> void:
	var s2 := RunConfig.get_shoot_hint_token_for_player(2)
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
				p2_special_label.text = "P2: %s atirar de novo p/ 5 flechas" % s2
		else:
			p2_special_label.text = ""
	elif right_player is EsqueletoPlayer:
		p2_special_label.visible = active
		p2_special_label.text = ("P2: próximo tiro (%s) = 3 flechas" % s2) if active else ""
	else:
		p2_special_label.visible = false
		p2_special_label.text = ""


func _on_left_archer_spike_hud(remaining: int, volley_armed: bool) -> void:
	if not left_player.is_arqueiro():
		p1_archer_spike_label.visible = false
		p1_archer_spike_label.text = ""
		return
	var s1 := RunConfig.get_shoot_hint_token_for_player(1)
	p1_archer_spike_label.visible = remaining > 0 or volley_armed
	if volley_armed:
		p1_archer_spike_label.text = "P1 ESPINHOS: solte (%s) → 5 no chão (leque)" % s1
	elif remaining > 0:
		p1_archer_spike_label.text = "P1 ESPINHOS: %d tiro(s) buffado(s)" % remaining
	else:
		p1_archer_spike_label.text = ""


func _on_right_archer_spike_hud(remaining: int, volley_armed: bool) -> void:
	if not right_player.is_arqueiro():
		p2_archer_spike_label.visible = false
		p2_archer_spike_label.text = ""
		return
	var s2 := RunConfig.get_shoot_hint_token_for_player(2)
	p2_archer_spike_label.visible = remaining > 0 or volley_armed
	if volley_armed:
		p2_archer_spike_label.text = "P2 ESPINHOS: solte (%s) → 5 no chão (leque)" % s2
	elif remaining > 0:
		p2_archer_spike_label.text = "P2 ESPINHOS: %d tiro(s) buffado(s)" % remaining
	else:
		p2_archer_spike_label.text = ""
