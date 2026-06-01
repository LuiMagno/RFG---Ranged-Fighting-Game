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

const CAM_ESQUELETO_FEIXE_FIRE := preload("res://levels/duel/camera/presets/esqueleto_feixe_fire.tres")
const CAM_ESQUELETO_FEIXE_HIT := preload("res://levels/duel/camera/presets/esqueleto_feixe_hit.tres")
const CAM_ESQUELETO_ULT_CHUVA_ARM := preload("res://levels/duel/camera/presets/esqueleto_ult_chuva_arm.tres")
const CAM_HIT_LIGHT := preload("res://levels/duel/camera/presets/hit_light.tres")
const CLUTCH_HP_RATIO := 0.15
const CLUTCH_AMBIENT_SHAKE := 2.5
const BONE_RAIN_SPAWN_Y := 24.0

const VS_ROUND_DURATION_S := 60.0
const VS_ROUNDS_TO_WIN := 3

const STAGE_NORMAL_BG := Color(0.12, 0.13, 0.15, 1)
const STAGE_NORMAL_GROUND := Color(0.18, 0.2, 0.23, 1)
const STAGE_NORMAL_DIVIDER := Color(1, 1, 1, 0.18)

const TIERED_ABYSS_SCENE := preload("res://levels/duel/arenas/tiered_abyss.tscn")
const STAGE_TIERED_BG := Color(0.09, 0.1, 0.14, 1)
const STAGE_TIERED_P1_SPAWN := Vector2(220, 735)
const STAGE_TIERED_P2_SPAWN := Vector2(1700, 735)
const STAGE_TIERED_HALF_GAP_EXTRA := 52.0
const STAGE_TIERED_PIT_DAMAGE := 30
const STAGE_TIERED_PIT_CD := 0.85

const OLD_FACTORY_SCENE := preload("res://levels/duel/arenas/old_factory.tscn")
const STAGE_FACTORY_BG := Color(0.14, 0.12, 0.10, 1)
const STAGE_FACTORY_P1_SPAWN := Vector2(140, 735)
const STAGE_FACTORY_P2_SPAWN := Vector2(1780, 735)
const STAGE_FACTORY_HALF_GAP_EXTRA := 88.0
const STAGE_FACTORY_PIT_DAMAGE := 30
const STAGE_FACTORY_PIT_CD := 0.85

@onready var left_player: Player = $LeftPlayer
@onready var right_player: Player = $RightPlayer
@onready var _stage_background: ColorRect = $Background
@onready var _stage_ground: ColorRect = $Ground
@onready var _stage_mid_divider: ColorRect = $MidDivider
@onready var _ground_body: StaticBody2D = $GroundBody
@onready var _arena_variant_root: Node2D = $ArenaVariantRoot
@onready var p1_hp_label: Label = $UI/P1HP
@onready var p2_hp_label: Label = $UI/P2HP
@onready var p1_hp_bar: ProgressBar = $UI/P1HPBar
@onready var p2_hp_bar: ProgressBar = $UI/P2HPBar
@onready var p1_special_label: Label = $UI/P1Special
@onready var p2_special_label: Label = $UI/P2Special
@onready var p1_archer_spike_label: Label = $UI/P1ArcherSpike
@onready var p2_archer_spike_label: Label = $UI/P2ArcherSpike
@onready var p1_skill_hints: Label = $UI/P1SkillHints
@onready var p2_skill_hints: Label = $UI/P2SkillHints
@onready var _vs_hud: Control = $UI/VsHud
@onready var _vs_timer_label: Label = $UI/VsHud/VsTimerLabel
@onready var _vs_p1_character_label: Label = $UI/VsHud/VsP1CharacterLabel
@onready var _vs_p2_character_label: Label = $UI/VsHud/VsP2CharacterLabel
@onready var _vs_score_label: Label = $UI/VsHud/VsScoreLabel
@onready var _vs_intro_root: Control = $VsIntroLayer/Root
@onready var _vs_intro_name_label: Label = $VsIntroLayer/Root/TopCenter/NameLabel
@onready var _vs_round_banner_root: Control = $VsRoundBannerLayer/BannerRoot
@onready var _vs_round_banner_label: Label = $VsRoundBannerLayer/BannerRoot/BannerCenter/RoundBannerLabel
@onready var _vs_match_end_menu: VsMatchEndMenu = $VsMatchEndLayer
@onready var _camera_system: CameraSystem = $CameraRig/CameraSystem

# Flecha especial do arqueiro no ar (segundo disparo fragmenta).
var _archer_carriers: Dictionary = {}
var _active_grenades: Dictionary = {}
var _active_ice: Dictionary = {}
var _bone_rain_gen_p1 := 0
var _bone_rain_gen_p2 := 0
var _bone_rain_running: Dictionary = {}
## ULT fases 1–2 (acionamento + animação): ambos parados até `enter_ult_efeito_phase`.
var _ult_armagem_animacao_active := false
var _ult_armagem_owner: Player = null
var _ult_armagem_opponent: Player = null
var _ult_armagem_owner_input_saved := true
var _ult_armagem_opponent_input_saved := true
var _p1_ult_active := false
var _p1_ult_time_left := 0.0
var _p1_ult_super_phase := false
var _p2_ult_active := false
var _p2_ult_time_left := 0.0
var _p2_ult_super_phase := false
var _training_loop_running: bool = false
var _training_ko_camera_active: bool = false
var _training_p2_spawn: Vector2

var _vs_p1_spawn: Vector2
var _vs_p2_spawn: Vector2
var _vs_round_time_left: float = 0.0
var _vs_round_playing: bool = false
var _vs_resolving_round: bool = false
var _vs_round_interstitial_active: bool = false
var _vs_match_end_menu_open: bool = false
var _p1_rounds_won: int = 0
var _p2_rounds_won: int = 0
var _vs_match_intro_done: bool = false
var _bone_rain_ambient_active: bool = false

var _tiered_arena_inst: Node2D
var _factory_arena_inst: Node2D
var _tiered_pits_wired: bool = false
var _factory_pit_wired: bool = false
var _pit_cd_p1: float = 0.0
var _pit_cd_p2: float = 0.0


func _enter_tree() -> void:
	_assign_player_scripts_from_run_config()


func _exit_tree() -> void:
	if _camera_system != null:
		_camera_system.reset_to_default()
	else:
		Engine.time_scale = 1.0
	RunConfig.clear_shoot_mouse_bindings_for_menu()


func _apply_stage_from_run_config() -> void:
	match RunConfig.stage:
		RunConfig.Stage.TIERED_ABYSS:
			_apply_stage_tiered_abyss()
		RunConfig.Stage.OLD_FACTORY:
			_apply_stage_old_factory()
		_:
			_apply_stage_normal()


func _hide_variant_arenas() -> void:
	if is_instance_valid(_tiered_arena_inst):
		_tiered_arena_inst.visible = false
		_set_tiered_pits_monitoring(false)
	if is_instance_valid(_factory_arena_inst):
		_factory_arena_inst.visible = false
		_set_factory_pit_monitoring(false)


func _apply_stage_normal() -> void:
	_stage_background.color = STAGE_NORMAL_BG
	_stage_ground.visible = true
	_stage_ground.color = STAGE_NORMAL_GROUND
	_stage_mid_divider.color = STAGE_NORMAL_DIVIDER
	_ground_body.collision_layer = 1
	_hide_variant_arenas()
	left_player.set_arena_horizontal_split(1920.0, 960.0, 0.0)
	right_player.set_arena_horizontal_split(1920.0, 960.0, 0.0)


func _apply_stage_tiered_abyss() -> void:
	_stage_background.color = STAGE_TIERED_BG
	_stage_ground.visible = false
	_stage_mid_divider.color = Color(1, 1, 1, 0.38)
	_ground_body.collision_layer = 0
	_hide_variant_arenas()
	_ensure_tiered_arena_instance()
	_tiered_arena_inst.visible = true
	_set_tiered_pits_monitoring(true)
	_connect_tiered_pit_signals_once()
	left_player.set_arena_horizontal_split(1920.0, 960.0, STAGE_TIERED_HALF_GAP_EXTRA)
	right_player.set_arena_horizontal_split(1920.0, 960.0, STAGE_TIERED_HALF_GAP_EXTRA)
	left_player.position = STAGE_TIERED_P1_SPAWN
	right_player.position = STAGE_TIERED_P2_SPAWN


func _apply_stage_old_factory() -> void:
	_stage_background.color = STAGE_FACTORY_BG
	_stage_ground.visible = false
	_stage_mid_divider.color = Color(1, 1, 1, 0.38)
	_ground_body.collision_layer = 0
	_hide_variant_arenas()
	_ensure_factory_arena_instance()
	_factory_arena_inst.visible = true
	_set_factory_pit_monitoring(true)
	_connect_factory_pit_signal_once()
	left_player.set_arena_horizontal_split(1920.0, 960.0, STAGE_FACTORY_HALF_GAP_EXTRA)
	right_player.set_arena_horizontal_split(1920.0, 960.0, STAGE_FACTORY_HALF_GAP_EXTRA)
	left_player.position = STAGE_FACTORY_P1_SPAWN
	right_player.position = STAGE_FACTORY_P2_SPAWN


func _ensure_tiered_arena_instance() -> void:
	if is_instance_valid(_tiered_arena_inst):
		return
	_tiered_arena_inst = TIERED_ABYSS_SCENE.instantiate()
	_arena_variant_root.add_child(_tiered_arena_inst)


func _ensure_factory_arena_instance() -> void:
	if is_instance_valid(_factory_arena_inst):
		return
	_factory_arena_inst = OLD_FACTORY_SCENE.instantiate()
	_arena_variant_root.add_child(_factory_arena_inst)


func _set_tiered_pits_monitoring(active: bool) -> void:
	if not is_instance_valid(_tiered_arena_inst):
		return
	var pl := _tiered_arena_inst.get_node_or_null("PitLeft") as Area2D
	var pr := _tiered_arena_inst.get_node_or_null("PitRight") as Area2D
	if pl != null:
		pl.monitoring = active
	if pr != null:
		pr.monitoring = active


func _connect_tiered_pit_signals_once() -> void:
	if _tiered_pits_wired or not is_instance_valid(_tiered_arena_inst):
		return
	var pl := _tiered_arena_inst.get_node_or_null("PitLeft") as Area2D
	var pr := _tiered_arena_inst.get_node_or_null("PitRight") as Area2D
	if pl != null and not pl.body_entered.is_connected(_on_tiered_pit_left_entered):
		pl.body_entered.connect(_on_tiered_pit_left_entered)
	if pr != null and not pr.body_entered.is_connected(_on_tiered_pit_right_entered):
		pr.body_entered.connect(_on_tiered_pit_right_entered)
	_tiered_pits_wired = true


func _set_factory_pit_monitoring(active: bool) -> void:
	if not is_instance_valid(_factory_arena_inst):
		return
	var pc := _factory_arena_inst.get_node_or_null("PitCenter") as Area2D
	if pc != null:
		pc.monitoring = active


func _connect_factory_pit_signal_once() -> void:
	if _factory_pit_wired or not is_instance_valid(_factory_arena_inst):
		return
	var pc := _factory_arena_inst.get_node_or_null("PitCenter") as Area2D
	if pc != null and not pc.body_entered.is_connected(_on_factory_pit_center_entered):
		pc.body_entered.connect(_on_factory_pit_center_entered)
	_factory_pit_wired = true


func _on_tiered_pit_left_entered(body: Node2D) -> void:
	_handle_arena_pit(body, 1)


func _on_tiered_pit_right_entered(body: Node2D) -> void:
	_handle_arena_pit(body, 2)


func _on_factory_pit_center_entered(body: Node2D) -> void:
	_handle_arena_pit(body, -1)


func _handle_arena_pit(body: Node2D, expect_player_id: int) -> void:
	if not (body is Player):
		return
	var p := body as Player
	var stage := RunConfig.stage
	if stage != RunConfig.Stage.TIERED_ABYSS and stage != RunConfig.Stage.OLD_FACTORY:
		return
	if expect_player_id > 0 and p.player_id != expect_player_id:
		return
	var pid := p.player_id
	if pid == 1:
		if _pit_cd_p1 > 0.0:
			return
		_pit_cd_p1 = STAGE_TIERED_PIT_CD if stage == RunConfig.Stage.TIERED_ABYSS else STAGE_FACTORY_PIT_CD
	else:
		if _pit_cd_p2 > 0.0:
			return
		_pit_cd_p2 = STAGE_TIERED_PIT_CD if stage == RunConfig.Stage.TIERED_ABYSS else STAGE_FACTORY_PIT_CD
	var sp: Vector2
	var dmg: int
	if stage == RunConfig.Stage.TIERED_ABYSS:
		sp = STAGE_TIERED_P1_SPAWN if pid == 1 else STAGE_TIERED_P2_SPAWN
		dmg = STAGE_TIERED_PIT_DAMAGE
	else:
		sp = STAGE_FACTORY_P1_SPAWN if pid == 1 else STAGE_FACTORY_P2_SPAWN
		dmg = STAGE_FACTORY_PIT_DAMAGE
	p.apply_pit_fall_penalty(sp, dmg)


## Reaplica teclas + eventos de comando conforme `RunConfig` (útil se mudares input em pausa no treino).
func apply_input_map_from_run_config() -> void:
	_ensure_input_map()
	_refresh_skill_hint_labels()


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
	_apply_stage_from_run_config()
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
	left_player.bone_rain_requested.connect(_on_bone_rain_requested)
	right_player.bone_rain_requested.connect(_on_bone_rain_requested)

	# UI updates come from signals (easy to swap for a real HUD later).
	left_player.health_changed.connect(_on_left_hp_changed)
	right_player.health_changed.connect(_on_right_hp_changed)
	left_player.special_buff_changed.connect(_on_left_special_buff_changed)
	right_player.special_buff_changed.connect(_on_right_special_buff_changed)
	left_player.ult_status_changed.connect(_on_left_ult_status_changed)
	right_player.ult_status_changed.connect(_on_right_ult_status_changed)
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
	_training_p2_spawn = right_player.position
	_apply_mode()
	if RunConfig.mode == RunConfig.Mode.VS_PLAYER:
		_vs_hud.visible = true
		_start_vs_round()
		if not _vs_match_intro_done:
			_vs_round_playing = false
			left_player.input_enabled = false
			right_player.input_enabled = false
			await _play_vs_match_intro()
			_vs_round_playing = true
			left_player.input_enabled = true
			right_player.input_enabled = true
	else:
		_vs_hud.visible = false


func blocks_vs_pause_menu() -> bool:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return false
	if _ult_armagem_animacao_active:
		return true
	return _vs_match_end_menu_open or _vs_round_interstitial_active or _vs_resolving_round or (
		_camera_system != null and _camera_system.is_ko_sequence_running()
	)


func rematch_vs_after_post_game() -> void:
	_vs_match_end_menu_open = false
	_vs_match_end_menu.close_menu()
	_p1_rounds_won = 0
	_p2_rounds_won = 0
	_vs_match_intro_done = false
	_start_vs_round()


func _process(delta: float) -> void:
	if RunConfig.stage == RunConfig.Stage.TIERED_ABYSS or RunConfig.stage == RunConfig.Stage.OLD_FACTORY:
		_pit_cd_p1 = maxf(0.0, _pit_cd_p1 - delta)
		_pit_cd_p2 = maxf(0.0, _pit_cd_p2 - delta)
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
	if _camera_system != null:
		_camera_system.reset_to_default()
	_update_clutch_state()
	_clear_vs_projectiles_and_carry_state()
	cancel_bone_rain_for_player(left_player)
	cancel_bone_rain_for_player(right_player)
	left_player.prepare_for_vs_round_respawn(_vs_p1_spawn)
	right_player.prepare_for_vs_round_respawn(_vs_p2_spawn)
	left_player.input_enabled = true
	right_player.input_enabled = true
	_vs_round_time_left = VS_ROUND_DURATION_S
	_vs_round_playing = true
	_refresh_vs_character_labels()
	_update_vs_hud()

func _play_vs_match_intro() -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER:
		return
	if _vs_match_intro_done:
		return
	if _camera_system == null or _vs_intro_root == null or _vs_intro_name_label == null:
		_vs_match_intro_done = true
		return

	_vs_round_interstitial_active = true
	_vs_intro_root.visible = true
	if _camera_system != null:
		_camera_system.set_letterbox(true, 0.0)

	var k1 := RunConfig.p1_character
	var k2 := RunConfig.p2_character
	var n1 := MenuThemeUtil.vs_character_name(k1)
	var n2 := MenuThemeUtil.vs_character_name(k2)
	var c1 := MenuThemeUtil.vs_character_accent_color(k1)
	var c2 := MenuThemeUtil.vs_character_accent_color(k2)

	var pan_in := 0.35
	var hold := 0.65
	var ret := 0.30
	var zoom := Vector2.ONE * 1.22
	match RunConfig.vs_intro_style:
		RunConfig.VsIntroStyle.A_FAST:
			pan_in = 0.25
			hold = 0.45
			ret = 0.25
			zoom = Vector2.ONE * 1.18
		RunConfig.VsIntroStyle.C_CINEMATIC:
			pan_in = 0.50
			hold = 0.90
			ret = 0.35
			zoom = Vector2.ONE * 1.28

	var one_total := pan_in + hold + ret
	var battle_callout_s := 0.75
	_camera_system.request_hit_stop(one_total * 2.0 + battle_callout_s + 0.10)

	await _vs_intro_focus_player(1, left_player, n1, c1, pan_in, hold, ret, zoom)
	await _vs_intro_focus_player(2, right_player, n2, c2, pan_in, hold, ret, zoom)
	await _vs_intro_battle_callout(battle_callout_s)

	_vs_intro_root.visible = false
	_vs_round_interstitial_active = false
	_vs_match_intro_done = true
	if _camera_system != null:
		_camera_system.set_letterbox(false, 0.12)
		_camera_system.reset_to_default()
	_update_clutch_state()


func _play_vs_round_short_intro(round_num: int) -> void:
	if RunConfig.mode != RunConfig.Mode.VS_PLAYER or round_num < 2:
		return
	_vs_round_interstitial_active = true
	_vs_round_banner_label.text = "ROUND %d" % round_num
	_vs_round_banner_root.visible = true
	if _camera_system != null:
		_camera_system.set_letterbox(true, 0.0)
	await get_tree().create_timer(0.5, true, false, true).timeout
	_vs_round_banner_root.visible = false
	_vs_round_interstitial_active = false
	if _camera_system != null:
		_camera_system.set_letterbox(false, 0.12)


func _vs_intro_focus_player(
	player_id: int,
	p: Player,
	name_text: String,
	accent: Color,
	pan_in: float,
	hold: float,
	ret: float,
	zoom: Vector2,
) -> void:
	if p == null or not is_instance_valid(p):
		return

	_vs_intro_name_label.text = "Jogador %d — %s" % [player_id, name_text]
	_vs_intro_name_label.add_theme_color_override("font_color", accent)

	_vs_intro_name_label.modulate = Color(1, 1, 1, 0)
	_vs_intro_name_label.scale = Vector2(1.10, 1.10)
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.set_parallel(true)
	tw.tween_property(_vs_intro_name_label, "modulate:a", 1.0, minf(0.18, pan_in)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_vs_intro_name_label, "scale", Vector2.ONE, minf(0.22, pan_in)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_camera_system.request_focus_hold_return(p, pan_in, zoom, hold, ret, 28.0)
	await get_tree().create_timer(pan_in + hold + ret, true, false, true).timeout


func _vs_intro_battle_callout(duration_s: float) -> void:
	if duration_s <= 0.0:
		return
	_vs_intro_name_label.text = "QUE COMECE A BATALHA!!!"
	_vs_intro_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_vs_intro_name_label.modulate = Color(1, 1, 1, 0)
	_vs_intro_name_label.scale = Vector2(1.25, 1.25)
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(_vs_intro_name_label, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_vs_intro_name_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(duration_s - 0.36, 0.05))
	tw.tween_property(_vs_intro_name_label, "modulate:a", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(duration_s, true, false, true).timeout


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
	_refresh_skill_hint_labels()


func _character_kind(p: Player) -> int:
	if p.is_ongma_epilef():
		return Player.CharacterKind.ONGMA_EPILEF
	if p.is_esqueleto():
		return Player.CharacterKind.ESQUELETO
	if p.is_mago():
		return Player.CharacterKind.MAGO
	if p.is_arqueiro():
		return Player.CharacterKind.ARQUEIRO
	if p.is_pistoleiro():
		return Player.CharacterKind.PISTOLEIRO
	return Player.CharacterKind.PISTOLEIRO


func _skill_hint_lines(player_id: int, kind: int, gamepad: bool) -> String:
	if gamepad:
		var base_pad_move := (
			"Mov analógico esq / D-pad · Mira analógico dir · A pulo · LB escudo · RB tiro · Y especial"
			+ " · Flutuar (no ar): gatilho RT cima / LT baixo"
		)
		var base_pad := base_pad_move + " · B dash"
		match kind:
			Player.CharacterKind.PISTOLEIRO:
				return base_pad + " · X granada"
			Player.CharacterKind.ARQUEIRO:
				return base_pad + " · L3 espinhos · Y especial (leque com combo)"
			Player.CharacterKind.MAGO:
				return base_pad + " · X gelo · R3 levitar · Y segure/solta orbe"
			Player.CharacterKind.ESQUELETO, Player.CharacterKind.ONGMA_EPILEF:
				return (
					base_pad_move
					+ " · X segure/solta feixe · Y buff de velocidade no tiro carregado · LB ULT (chuva de ossos)"
					+ " · Tiro carregado: segure/solte RB"
					+ " · B dash (direcção: stick esq. ou mira); duplo frente/trás não inicia dash"
					+ " · D-pad ↓ / stick esq. ↓ (no ar): queda"
				)
			_:
				return base_pad
	# Teclado+mouse: mesmo layout para P1 e P2 (no Vs só um usa teclado+mouse por vez).
	var base_kb_move := "Mov A/D · Espaço pulo · Q escudo · W/S flutuar (no ar) · Mouse mira e tiro"
	var base_kb := base_kb_move + " · Shift esq dash"
	match kind:
		Player.CharacterKind.PISTOLEIRO:
			return base_kb + " · F granada · G especial"
		Player.CharacterKind.ARQUEIRO:
			return base_kb + " · F espinhos · G especial (leque com combo)"
		Player.CharacterKind.MAGO:
			return base_kb + " · F gelo (F de novo detona) · C levitar · G segure e solte orbe"
		Player.CharacterKind.ESQUELETO, Player.CharacterKind.ONGMA_EPILEF:
			return (
				base_kb_move
				+ " · F segure/solta feixe · G buff de velocidade no tiro carregado · R chuva de ossos (ULT)"
				+ " · Shift dash (direcção: A/D ou mira); duplo A/D não inicia dash"
			)
		_:
			return base_kb


func _refresh_skill_hint_labels() -> void:
	if p1_skill_hints == null or p2_skill_hints == null:
		return
	if RunConfig.mode == RunConfig.Mode.TRAINING:
		p1_skill_hints.text = _skill_hint_lines(1, _character_kind(left_player), RunConfig.is_player_using_gamepad(1))
		p2_skill_hints.text = "Treino: boneco à direita é controlado pelo jogo (CPU)."
		return
	p1_skill_hints.text = _skill_hint_lines(1, _character_kind(left_player), RunConfig.is_player_using_gamepad(1))
	p2_skill_hints.text = _skill_hint_lines(2, _character_kind(right_player), RunConfig.is_player_using_gamepad(2))


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
	var victim := left_player if left_player.hp <= 0 else right_player
	var winner := right_player if winner_id == 2 else left_player
	await _camera_play_ko_round(victim, winner)
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
		var round_num := _p1_rounds_won + _p2_rounds_won + 1
		_start_vs_round()
		if round_num >= 2:
			_vs_round_playing = false
			left_player.input_enabled = false
			right_player.input_enabled = false
			await _play_vs_round_short_intro(round_num)
			left_player.input_enabled = true
			right_player.input_enabled = true
			_vs_round_playing = true
		_update_clutch_state()


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
	if _ult_armagem_animacao_active:
		return
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
	RunConfig.ensure_valid_input_scheme_pair()
	_ensure_move_vertical_actions("p1")
	_ensure_move_vertical_actions("p2")
	_ensure_ground_pound_action_exists("p1")
	_ensure_ground_pound_action_exists("p2")
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
	# Mago: levitar = p1_mage_float (C) / p2_mage_float (C no teclado+mouse); orbe = segurar G e soltar.
	_add_action_if_missing("p1_mage_float", KEY_C)
	_add_action_if_missing("p1_shield", KEY_Q)
	_add_action_if_missing("p1_ult", KEY_R)
	_ensure_dash_action("p1_dash", true)
	_ensure_ui_game_pause_input()

	_ensure_p2_action_shells_without_keys()
	_ensure_aim_action_quartet("p1")
	_ensure_aim_action_quartet("p2")
	_strip_keyboard_events_from_actions(_player_action_names("p2"))
	_strip_mouse_button_from_action("p2_shoot", MOUSE_BUTTON_LEFT)
	if RunConfig.p2_input_scheme == RunConfig.InputScheme.KEYBOARD_MOUSE:
		_ensure_p2_keyboard_mouse_shared_layout()

	_strip_joypad_events_from_actions(_player_action_names("p1"))
	_strip_joypad_events_from_actions(_player_action_names("p2"))
	if RunConfig.p1_input_scheme == RunConfig.InputScheme.GAMEPAD:
		_strip_keyboard_events_from_actions(_player_action_names("p1"))
		_strip_mouse_button_from_action("p1_shoot", MOUSE_BUTTON_LEFT)
		_add_gamepad_mappings_for_player("p1", RunConfig.p1_joy_device)
	if RunConfig.p2_input_scheme == RunConfig.InputScheme.GAMEPAD:
		_add_gamepad_mappings_for_player("p2", RunConfig.p2_joy_device)

	_strip_mouse_button_from_action("p1_shoot", MOUSE_BUTTON_LEFT)
	_strip_mouse_button_from_action("p2_shoot", MOUSE_BUTTON_LEFT)
	if RunConfig.p1_input_scheme == RunConfig.InputScheme.KEYBOARD_MOUSE:
		_ensure_action_has_mouse_button("p1_shoot", MOUSE_BUTTON_LEFT)
	if RunConfig.p2_input_scheme == RunConfig.InputScheme.KEYBOARD_MOUSE:
		_ensure_action_has_mouse_button("p2_shoot", MOUSE_BUTTON_LEFT)


func _ensure_p2_action_shells_without_keys() -> void:
	for n: String in [
		"p2_left",
		"p2_right",
		"p2_jump",
		"p2_hover_up",
		"p2_hover_down",
		"p2_shoot",
		"p2_grenade",
		"p2_archer_spike",
		"p2_special",
		"p2_mage_float",
		"p2_shield",
		"p2_ult",
		"p2_dash",
		"p2_move_up",
		"p2_move_down",
		"p2_down",
	]:
		if not InputMap.has_action(n):
			InputMap.add_action(n)


## Garante `p1_down` / `p2_down` (queda / ground pound no ar). Teclado: **S** (igual a hover “baixo”; no ar o combate trata a prioridade).
func _ensure_ground_pound_action_exists(prefix: String) -> void:
	var an: StringName = StringName("%s_down" % prefix)
	if not InputMap.has_action(an):
		InputMap.add_action(an)
	_ensure_action_has_key(an, KEY_S)


## Movimento vertical no comando (stick Y + D-pad ↑/↓): só mapeado em `_add_gamepad_mappings_for_player`; usado no duplo toque em `Player`.
func _ensure_move_vertical_actions(prefix: String) -> void:
	var dz := 0.15
	for s in ["move_up", "move_down"]:
		var an: StringName = StringName("%s_%s" % [prefix, s])
		if not InputMap.has_action(an):
			InputMap.add_action(an, dz)


## P2 em teclado+mouse usa o mesmo mapa WASD + mouse que o P1 (exclusivo: o outro jogador fica em controle).
func _ensure_p2_keyboard_mouse_shared_layout() -> void:
	_add_action_if_missing("p2_left", KEY_A)
	_add_action_if_missing("p2_right", KEY_D)
	_add_action_if_missing("p2_jump", KEY_SPACE)
	_add_action_if_missing("p2_hover_up", KEY_W)
	_add_action_if_missing("p2_hover_down", KEY_S)
	if not InputMap.has_action("p2_shoot"):
		InputMap.add_action("p2_shoot")
	_strip_key_from_action("p2_shoot", KEY_F)
	_strip_key_from_action("p2_shoot", KEY_L)
	_add_action_if_missing("p2_grenade", KEY_F)
	_add_action_if_missing("p2_archer_spike", KEY_F)
	_strip_key_from_action("p2_special", KEY_C)
	_add_action_if_missing("p2_special", KEY_G)
	_add_action_if_missing("p2_mage_float", KEY_C)
	_add_action_if_missing("p2_shield", KEY_Q)
	_add_action_if_missing("p2_ult", KEY_R)
	_ensure_dash_action("p2_dash", true)
	_add_action_if_missing("p2_down", KEY_S)


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
		p + "ult",
		p + "dash",
		p + "aim_left",
		p + "aim_right",
		p + "aim_up",
		p + "aim_down",
		p + "move_up",
		p + "move_down",
		p + "down",
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
	# Vertical de locomoção (duplo toque): stick esquerdo Y + D-pad ↑/↓ (não confundir com hover = gatilhos).
	InputMap.action_add_event(p + "move_up", _joy_motion(device, JOY_AXIS_LEFT_Y, -1.0))
	InputMap.action_add_event(p + "move_up", _joy_btn(device, JOY_BUTTON_DPAD_UP))
	InputMap.action_add_event(p + "move_down", _joy_motion(device, JOY_AXIS_LEFT_Y, 1.0))
	InputMap.action_add_event(p + "move_down", _joy_btn(device, JOY_BUTTON_DPAD_DOWN))
	# Ground pound (ar): mesmo eixo de “baixo” que o movimento vertical, ação `*_down` separada em `Player._down_action_just_pressed`.
	InputMap.action_add_event(p + "down", _joy_btn(device, JOY_BUTTON_DPAD_DOWN))
	InputMap.action_add_event(p + "down", _joy_motion(device, JOY_AXIS_LEFT_Y, 1.0))
	# Hover na flutuação: gatilhos (evita D-pad vertical em conflito com menus / movimento).
	InputMap.action_add_event(p + "hover_up", _joy_motion(device, JOY_AXIS_TRIGGER_RIGHT, 1.0))
	InputMap.action_add_event(p + "hover_down", _joy_motion(device, JOY_AXIS_TRIGGER_LEFT, 1.0))
	# Mira: stick direito → get_vector nas ações aim_*.
	InputMap.action_add_event(p + "aim_left", _joy_motion(device, JOY_AXIS_RIGHT_X, -1.0))
	InputMap.action_add_event(p + "aim_right", _joy_motion(device, JOY_AXIS_RIGHT_X, 1.0))
	InputMap.action_add_event(p + "aim_up", _joy_motion(device, JOY_AXIS_RIGHT_Y, -1.0))
	InputMap.action_add_event(p + "aim_down", _joy_motion(device, JOY_AXIS_RIGHT_Y, 1.0))
	# Xbox-like, por jogador. Esqueleto/Ongma: RB tiro, X feixe, Y buff, B dash (acção p*_dash); L3/R3 = spike/mago.
	InputMap.action_add_event(p + "shoot", _joy_btn(device, JOY_BUTTON_RIGHT_SHOULDER))
	InputMap.action_add_event(p + "jump", _joy_btn(device, JOY_BUTTON_A))
	InputMap.action_add_event(p + "dash", _joy_btn(device, JOY_BUTTON_B))
	InputMap.action_add_event(p + "special", _joy_btn(device, JOY_BUTTON_Y))
	InputMap.action_add_event(p + "shield", _joy_btn(device, JOY_BUTTON_LEFT_SHOULDER))
	InputMap.action_add_event(p + "ult", _joy_btn(device, JOY_BUTTON_LEFT_SHOULDER))
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


func _strip_keyboard_events_from_actions(action_names: Array) -> void:
	for an in action_names:
		if not InputMap.has_action(an):
			continue
		var to_remove: Array = []
		for ev in InputMap.action_get_events(an):
			if ev is InputEventKey:
				to_remove.append(ev)
		for ev in to_remove:
			InputMap.action_erase_event(an, ev)


func _strip_mouse_button_from_action(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		return
	var to_remove: Array = []
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventMouseButton and int((ev as InputEventMouseButton).button_index) == button_index:
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
	# pos, vel, gravity, bounces, damage, size, flags
	var feixe_fired := false
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
		if shot_flags.get("esqueleto_feixe", false):
			feixe_fired = true
		_spawn_one_arrow(owner_player, pos, vel, shot_flags, gravity, bounces, damage, size)
	if feixe_fired:
		_camera_apply_preset(CAM_ESQUELETO_FEIXE_FIRE)

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
	if not shot_flags.is_empty():
		arrow.set_shot_flags(shot_flags)
	if want_homing and arrow.has_method("set_homing_target"):
		var target := left_player
		if owner_player == left_player:
			target = right_player
		arrow.call("set_homing_target", target)
	if is_carrier:
		_archer_carriers[owner_player] = arrow
		arrow.tree_exiting.connect(_on_archer_carrier_tree_exiting.bind(owner_player, arrow))
	arrow.hit_player.connect(_on_arrow_hit_player.bind(arrow))

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

func _shot_flags_skip_light_hit(flags: Dictionary) -> bool:
	return (
		flags.get("esqueleto_feixe", false)
		or flags.get("esqueleto_chuva_osso", false)
		or flags.get("spike_shot", false)
		or flags.get("spike_volley", false)
		or flags.get("archer_split", false)
	)


func _on_arrow_hit_player(victim: Player, _damage: int, arrow: Arrow) -> void:
	if arrow == null or victim == null:
		return
	if victim.hp <= 0:
		return
	if _vs_resolving_round or _training_ko_camera_active:
		return
	var flags := arrow.get_shot_flags()
	if flags.get("esqueleto_feixe", false):
		_camera_apply_preset(CAM_ESQUELETO_FEIXE_HIT, arrow.velocity)
		return
	if _shot_flags_skip_light_hit(flags):
		return
	_camera_apply_preset(CAM_HIT_LIGHT, arrow.velocity)


func _camera_play_ko_round(victim: Player, winner: Player) -> void:
	if _camera_system == null or victim == null or winner == null:
		return
	await _camera_system.play_ko_round_sequence(victim, winner, int(RunConfig.ko_camera_impact_style))


func _try_training_ko_camera() -> void:
	if _training_ko_camera_active or RunConfig.mode != RunConfig.Mode.TRAINING:
		return
	if right_player.hp > 0:
		return
	call_deferred("_run_training_ko_camera")


func _run_training_ko_camera() -> void:
	if _training_ko_camera_active or RunConfig.mode != RunConfig.Mode.TRAINING:
		return
	if right_player.hp > 0:
		return
	_training_ko_camera_active = true
	right_player.input_enabled = false
	left_player.input_enabled = false
	await _camera_play_ko_round(right_player, left_player)
	if _camera_system != null:
		_camera_system.reset_to_default()
	right_player.prepare_for_vs_round_respawn(_training_p2_spawn)
	_on_right_hp_changed(right_player.hp)
	right_player.input_enabled = true
	left_player.input_enabled = true
	_training_ko_camera_active = false


func _camera_apply_preset(preset: CameraEffectPreset, direction: Vector2 = Vector2.ZERO) -> void:
	if _camera_system == null or preset == null:
		return
	_camera_system.request_apply_preset(preset, direction)


func cancel_bone_rain_for_player(p: Player) -> void:
	if p == null:
		return
	if p.player_id == 1:
		_bone_rain_gen_p1 += 1
	else:
		_bone_rain_gen_p2 += 1
	if _bone_rain_ambient_active:
		_bone_rain_ambient_active = false
		_refresh_ambient_shake()
	_end_ult_armagem_animacao()


func is_ult_armagem_animacao_active() -> bool:
	return _ult_armagem_animacao_active


func is_ult_super_focus_active() -> bool:
	return is_ult_armagem_animacao_active()


func _begin_ult_armagem_animacao(owner: Player, opponent: Player, duration_s: float) -> void:
	_ult_armagem_animacao_active = true
	_ult_armagem_owner = owner
	_ult_armagem_opponent = opponent
	_ult_armagem_owner_input_saved = owner.input_enabled if owner != null else true
	_ult_armagem_opponent_input_saved = opponent.input_enabled if opponent != null else true
	if owner != null:
		owner.input_enabled = false
		owner.stall_for(duration_s)
	if opponent != null:
		opponent.input_enabled = false
		opponent.stall_for(duration_s)
	if _camera_system != null:
		_camera_system.set_super_focus_active(true)


func _end_ult_armagem_animacao() -> void:
	if _ult_armagem_owner != null and is_instance_valid(_ult_armagem_owner):
		_ult_armagem_owner.clear_stall()
		if _ult_armagem_animacao_active:
			_ult_armagem_owner.input_enabled = _ult_armagem_owner_input_saved
	if _ult_armagem_opponent != null and is_instance_valid(_ult_armagem_opponent):
		_ult_armagem_opponent.clear_stall()
		if _ult_armagem_animacao_active:
			_ult_armagem_opponent.input_enabled = _ult_armagem_opponent_input_saved
	_ult_armagem_animacao_active = false
	_ult_armagem_owner = null
	_ult_armagem_opponent = null
	if _camera_system != null:
		_camera_system.set_super_focus_active(false)
		_camera_system.cancel_dominant_effect()
	if Engine.time_scale <= 0.01:
		Engine.time_scale = 1.0


func _bone_rain_gen_for(p: Player) -> int:
	return _bone_rain_gen_p1 if p.player_id == 1 else _bone_rain_gen_p2


func _get_opponent_player(p: Player) -> Player:
	if p == left_player:
		return right_player
	if p == right_player:
		return left_player
	return null


func _on_bone_rain_requested(owner: Player) -> void:
	if not owner is EsqueletoPlayer or _vs_resolving_round:
		return
	if _bone_rain_running.get(owner, false):
		return
	var ep := owner as EsqueletoPlayer
	var armagem_anim_s := ep.esqueleto_skill_ult_chuva_ossos_fase_armagem_animacao_s
	var super_zoom := Vector2.ONE * ep.esqueleto_skill_ult_chuva_ossos_super_zoom
	var opponent := _get_opponent_player(owner)
	_bone_rain_running[owner] = true
	var gen := _bone_rain_gen_for(owner)
	# Fases 1–2: acionamento + animação (câmera) — ambos parados.
	_begin_ult_armagem_animacao(owner, opponent, armagem_anim_s)
	if _camera_system != null:
		_camera_system.show_super_highlight(armagem_anim_s)
	_camera_apply_preset(CAM_ESQUELETO_ULT_CHUVA_ARM)
	if _camera_system != null:
		await _camera_system.play_ult_super_focus_sequence(
			owner,
			armagem_anim_s,
			super_zoom,
			ep.esqueleto_skill_ult_super_pan_fraction,
			ep.esqueleto_skill_ult_super_hold_fraction,
			ep.esqueleto_skill_ult_super_return_fraction,
		)
	else:
		var super_ok := await _wait_bone_rain_phase(armagem_anim_s, gen, owner)
		if not super_ok:
			_bone_rain_running[owner] = false
			_end_ult_armagem_animacao()
			return
	if not is_instance_valid(owner) or _bone_rain_gen_for(owner) != gen or _vs_resolving_round:
		_bone_rain_running[owner] = false
		if _camera_system != null:
			_camera_system.hide_super_highlight()
			await _camera_system.return_to_arena_framing()
		_end_ult_armagem_animacao()
		return
	# Fase 3: efeito (chuva) — liberta movimento dos dois.
	if owner is EsqueletoPlayer:
		(owner as EsqueletoPlayer).enter_ult_efeito_phase()
	if _camera_system != null:
		_camera_system.hide_super_highlight()
	_end_ult_armagem_animacao()
	await _run_esqueleto_bone_rain(owner)
	_bone_rain_running[owner] = false


func _wait_bone_rain_phase(seconds: float, gen: int, owner: Player) -> bool:
	if seconds <= 0.0:
		return _bone_rain_gen_for(owner) == gen and not _vs_resolving_round
	var elapsed := 0.0
	while elapsed < seconds:
		if _vs_resolving_round or _bone_rain_gen_for(owner) != gen:
			return false
		var step := minf(0.05, seconds - elapsed)
		await get_tree().create_timer(step, true, false, true).timeout
		elapsed += step
	return _bone_rain_gen_for(owner) == gen and not _vs_resolving_round


func _run_esqueleto_bone_rain(owner: Player) -> void:
	var ep := owner as EsqueletoPlayer
	if ep == null:
		return
	var gen := _bone_rain_gen_for(owner)
	var duration := ep.esqueleto_skill_ult_chuva_ossos_duracao_s
	var interval := maxf(0.04, ep.esqueleto_skill_ult_chuva_ossos_intervalo_s)
	var time_left := duration
	_bone_rain_ambient_active = true
	if _camera_system != null:
		_camera_system.set_ambient_shake(ep.esqueleto_skill_ult_chuva_ossos_shake_intensidade)
	while time_left > 0.0 and not _vs_resolving_round and _bone_rain_gen_for(owner) == gen:
		var xr := owner.get_enemy_half_x_range()
		if xr.y > xr.x:
			var x := randf_range(xr.x, xr.y)
			_spawn_bone_rain_projectile(
				owner,
				Vector2(x, BONE_RAIN_SPAWN_Y),
				Vector2(0.0, ep.esqueleto_skill_ult_chuva_ossos_velocidade_queda),
				ep.esqueleto_skill_ult_chuva_ossos_dano,
			)
		await get_tree().create_timer(interval, true, false, true).timeout
		time_left -= interval
	_bone_rain_ambient_active = false
	_refresh_ambient_shake()


func _spawn_bone_rain_projectile(
	owner_player: Player,
	spawn_position: Vector2,
	initial_velocity: Vector2,
	damage: int,
) -> void:
	var ep := owner_player as EsqueletoPlayer
	var flags := {"esqueleto_chuva_osso": true}
	if ep != null:
		flags["knockback_x"] = ep.esqueleto_skill_ult_chuva_ossos_knockback_x
		flags["knockback_up"] = ep.esqueleto_skill_ult_chuva_ossos_knockback_up
	_spawn_one_arrow(
		owner_player,
		spawn_position,
		initial_velocity,
		flags,
		0.0,
		0,
		damage,
		0.85,
	)

func _player_in_clutch(p: Player) -> bool:
	if p == null or p.max_hp <= 0 or p.hp <= 0:
		return false
	return float(p.hp) / float(p.max_hp) < CLUTCH_HP_RATIO


func _should_show_clutch() -> bool:
	if _vs_resolving_round or _vs_round_interstitial_active or _ult_armagem_animacao_active:
		return false
	if _camera_system != null and _camera_system.is_ko_sequence_running():
		return false
	return _player_in_clutch(left_player) or _player_in_clutch(right_player)


func _refresh_ambient_shake() -> void:
	if _camera_system == null:
		return
	if _bone_rain_ambient_active:
		return
	if _should_show_clutch():
		_camera_system.set_ambient_shake(CLUTCH_AMBIENT_SHAKE)
	else:
		_camera_system.set_ambient_shake(0.0)


func _update_clutch_state() -> void:
	if _camera_system == null:
		return
	_camera_system.set_clutch_overlay(_should_show_clutch())
	_refresh_ambient_shake()


func _on_left_hp_changed(hp: int) -> void:
	p1_hp_label.text = "P1 HP: %d" % hp
	p1_hp_bar.value = hp
	_check_vs_ko_after_hp_change()
	_update_clutch_state()

func _on_right_hp_changed(hp: int) -> void:
	p2_hp_label.text = "P2 HP: %d" % hp
	p2_hp_bar.value = hp
	_check_vs_ko_after_hp_change()
	_try_training_ko_camera()
	_update_clutch_state()

func _on_left_ult_status_changed(active: bool, time_left: float, super_phase: bool = false) -> void:
	_p1_ult_active = active
	_p1_ult_time_left = time_left
	_p1_ult_super_phase = super_phase
	_refresh_left_esqueleto_status_label()


func _on_right_ult_status_changed(active: bool, time_left: float, super_phase: bool = false) -> void:
	_p2_ult_active = active
	_p2_ult_time_left = time_left
	_p2_ult_super_phase = super_phase
	_refresh_right_esqueleto_status_label()


func _refresh_left_esqueleto_status_label() -> void:
	if not left_player is EsqueletoPlayer:
		return
	var s1 := RunConfig.get_shoot_hint_token_for_player(1)
	if _p1_ult_active:
		p1_special_label.visible = true
		if _p1_ult_super_phase:
			p1_special_label.text = "P1: SUPER!"
		else:
			p1_special_label.text = "P1: ULT — chuva de ossos (%.1f s)" % _p1_ult_time_left
		return
	var ep := left_player as EsqueletoPlayer
	if ep.is_buff_velocidade_tiro_ativo():
		p1_special_label.visible = true
		p1_special_label.text = (
			"P1: Buff ativo — tiros carregados mais rápidos (%.1f s) · solte %s para disparar"
			% [ep.get_buff_velocidade_tiro_tempo_restante_s(), s1]
		)
	else:
		p1_special_label.visible = false
		p1_special_label.text = ""


func _refresh_right_esqueleto_status_label() -> void:
	if not right_player is EsqueletoPlayer:
		return
	var s2 := RunConfig.get_shoot_hint_token_for_player(2)
	if _p2_ult_active:
		p2_special_label.visible = true
		if _p2_ult_super_phase:
			p2_special_label.text = "P2: SUPER!"
		else:
			p2_special_label.text = "P2: ULT — chuva de ossos (%.1f s)" % _p2_ult_time_left
		return
	var ep := right_player as EsqueletoPlayer
	if ep.is_buff_velocidade_tiro_ativo():
		p2_special_label.visible = true
		p2_special_label.text = (
			"P2: Buff ativo — tiros carregados mais rápidos (%.1f s) · solte %s para disparar"
			% [ep.get_buff_velocidade_tiro_tempo_restante_s(), s2]
		)
	else:
		p2_special_label.visible = false
		p2_special_label.text = ""


func _on_left_special_buff_changed(active: bool, uses_left: int, time_left: float) -> void:
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
		if _p1_ult_active:
			_refresh_left_esqueleto_status_label()
			return
		p1_special_label.visible = active
		if active:
			p1_special_label.text = (
				"P1: Buff ativo — tiros carregados mais rápidos (%.1f s) · solte %s para disparar"
				% [time_left, s1]
			)
		else:
			p1_special_label.text = ""
	else:
		p1_special_label.visible = false
		p1_special_label.text = ""

func _on_right_special_buff_changed(active: bool, uses_left: int, time_left: float) -> void:
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
		if _p2_ult_active:
			_refresh_right_esqueleto_status_label()
			return
		p2_special_label.visible = active
		if active:
			p2_special_label.text = (
				"P2: Buff ativo — tiros carregados mais rápidos (%.1f s) · solte %s para disparar"
				% [time_left, s2]
			)
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
