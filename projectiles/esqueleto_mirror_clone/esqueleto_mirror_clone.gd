extends CharacterBody2D
class_name EsqueletoMirrorClone

## Clone espectral — locomotion autônoma + eco leve (animação/tiros).

const ESQUELETO_SPRITE_FRAMES_PATH := "res://art/skeleton/esqueleto_sprite_frames.tres"
const BODY_SPRITE_OFFSET := Vector2(0, 12)
const BODY_SPRITE_SCALE := Vector2(2.8, 2.8)
const BODY_IDLE_ANIM := "idle_smoking"
const BODY_WALK_ANIM := "walk"
const BODY_DASH_ANIM := "dash"
const BODY_JUMP_ANIM := "jump"
const BODY_ATTACK_ANIM := "attack"
const BODY_MOVE_SPEED_THRESHOLD := 18.0
const WANDER_REACH_DIST := 22.0
const SPECTRAL_TINT := Color(0.72, 0.92, 1.12, 0.92)
const AIM_SMOOTH := 10.0
const CPU_AIM_SMOOTH := 12.0
const GRAVITY := 1800.0
const CombatAi := preload("res://characters/esqueleto/mirror_clone_combat_ai.gd")
const CpuUtil := preload("res://characters/esqueleto/mirror_clone_cpu_util.gd")

var _owner: Player
var _game: Node
var _lateral_offset_x := 0.0
var _last_echo_t := 0.0
var _aim_dir := Vector2.RIGHT
var _flip_h := false
var _feixe_charging := false
var _charge_t := 0.0
var _alive := true
var _sprite_ready := false
var _last_fired_event_t := -1.0
var _echo_freeze_left := 0.0
var _personality := 0
var _profile: Dictionary = {}
var _feint_charge_left := 0.0
var _echo_feixe_active := false
var _idle_shot_after_s := 1.0
var _rare_shot_cd_s := 5.0
var _rare_shot_cd_left := 0.0
var _current_anim := BODY_IDLE_ANIM
var _delayed_shots: Array[Dictionary] = []
var _arena_x_range := Vector2(36.0, 924.0)
var _wander_target := Vector2.ZERO
var _wander_pick_left := 0.0
var _move_speed := 210.0
var _jump_speed := 620.0
var _echo_move_blend := 0.12
var _dash_burst_left := 0.0
var _local_idle_s := 0.0
var _autonomous_active := true
var _combat_state := CombatAi.State.PATROL
var _shot_cd_left := 0.0
var _dash_cd_left := 0.0
var _dash_time_left := 0.0
var _dash_speed := 500.0
var _shot_speed := 420.0
var _pending_shoot_vel := Vector2.ZERO
var _wander_interval_mul := 1.0

var _explosion_scene: PackedScene = preload("res://projectiles/explosion/explosion.tscn")

@onready var _facing_root: Node2D = $FacingRoot
@onready var _body_sprite: AnimatedSprite2D = $FacingRoot/BodySprite
@onready var _glow_poly: Polygon2D = $FacingRoot/GlowPoly
@onready var _muzzle: Marker2D = $FacingRoot/Muzzle
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func setup(owner_player: Player, game: Node, lateral_offset_x: float) -> void:
	_owner = owner_player
	_game = game
	_lateral_offset_x = lateral_offset_x
	if _owner != null:
		add_collision_exception_with(_owner)
		_arena_x_range = _owner.get_own_half_x_range()
	_setup_body_sprite()
	_apply_spectral_colors()
	_wander_target = global_position
	_wander_pick_left = randf_range(0.2, 0.8)


func configure_cpu(personality: int, tuning: Dictionary) -> void:
	_personality = personality
	_profile = CpuUtil.get_profile(personality, tuning)
	_idle_shot_after_s = float(tuning.get("idle_shot_after_s", 1.0))
	_rare_shot_cd_s = float(tuning.get("rare_shot_cd_s", 5.0))
	_move_speed = float(tuning.get("move_speed", 210.0))
	_move_speed *= float(_profile.get("move_speed_mul", 1.0))
	_jump_speed = float(tuning.get("jump_speed", 620.0))
	_echo_move_blend = float(tuning.get("echo_move_blend", 0.12))
	_dash_speed = float(tuning.get("dash_speed", 500.0))
	_shot_speed = float(tuning.get("shot_speed", 420.0))
	_wander_interval_mul = float(_profile.get("wander_interval_mul", 1.0))


func set_arena_x_range(arena_x: Vector2) -> void:
	_arena_x_range = arena_x


func get_owner_player() -> Player:
	return _owner


func get_personality() -> int:
	return _personality


func get_personality_label() -> String:
	return String(_profile.get("label", "clone"))


func get_cpu_aim_blend() -> float:
	return float(_profile.get("aim_blend", 0.55))


func get_cpu_jitter_deg() -> float:
	return float(_profile.get("aim_jitter_deg", 4.0))


func get_aim_direction() -> Vector2:
	if _aim_dir.length_squared() <= 0.0001:
		return Vector2.RIGHT
	return _aim_dir.normalized()


func is_alive() -> bool:
	return _alive and not is_queued_for_deletion()


func get_last_echo_t() -> float:
	return _last_echo_t


func set_last_echo_t(t: float) -> void:
	_last_echo_t = t


func get_lateral_offset_x() -> float:
	return _lateral_offset_x


func set_lateral_offset_x(offset_x: float) -> void:
	_lateral_offset_x = offset_x


func freeze_echo(seconds: float) -> void:
	_echo_freeze_left = maxf(_echo_freeze_left, seconds)


func is_echo_frozen() -> bool:
	return _echo_freeze_left > 0.0


func can_fire_echo_event(event_t: float) -> bool:
	if event_t <= _last_fired_event_t + 0.001:
		return false
	_last_fired_event_t = event_t
	return true


func should_skip_echo_shot() -> bool:
	var chance := float(_profile.get("skip_echo_shot_chance", 0.0))
	return chance > 0.001 and CpuUtil.roll_chance(chance)


func should_fire_distraction_shot() -> bool:
	var chance := float(_profile.get("distraction_shot_chance", 0.0))
	return chance > 0.001 and CpuUtil.roll_chance(chance)


func get_distraction_jitter_deg() -> float:
	return float(_profile.get("distraction_jitter_deg", 22.0))


func consume_shot_stagger() -> float:
	return float(_profile.get("shot_stagger_s", 0.0))


func queue_delayed_echo_shot(delay_s: float, fire_fn: Callable) -> void:
	if delay_s <= 0.001:
		fire_fn.call()
		return
	_delayed_shots.append({"left": delay_s, "fn": fire_fn})


func can_attempt_rare_shot(_owner_idle_s: float) -> bool:
	if not _alive or is_echo_frozen() or _rare_shot_cd_left > 0.0:
		return false
	return _local_idle_s >= _idle_shot_after_s or _owner_idle_s >= _idle_shot_after_s


func start_rare_shot_cooldown() -> void:
	_rare_shot_cd_left = _rare_shot_cd_s


func get_rare_shot_chance() -> float:
	return float(_profile.get("rare_shot_chance", 0.35))


func get_rare_jitter_mul() -> float:
	return float(_profile.get("rare_jitter_mul", 1.0))


func consume_combat_shot_request() -> Vector2:
	var vel := _pending_shoot_vel
	_pending_shoot_vel = Vector2.ZERO
	return vel


func get_combat_state_label() -> String:
	match _combat_state:
		CombatAi.State.DODGE:
			return "dodge"
		CombatAi.State.ENGAGE:
			return "engage"
		CombatAi.State.STRAFE:
			return "strafe"
	return "patrol"


func take_damage(_amount: int) -> void:
	if not _alive:
		return
	_destroy_spectral()


func apply_echo_snapshot(snap: Dictionary, delta: float, opponent: Player = null) -> void:
	if not _alive or snap.is_empty():
		return
	if _echo_freeze_left > 0.0:
		return
	var snap_pos: Vector2 = snap.get("pos", global_position)
	snap_pos.x += _lateral_offset_x
	if _echo_move_blend > 0.001:
		global_position = global_position.lerp(
			snap_pos,
			clampf(_echo_move_blend * 8.0 * delta, 0.0, _echo_move_blend),
		)
	var echo_vel: Vector2 = snap.get("vel", Vector2.ZERO)
	var anim_name := String(snap.get("anim", BODY_IDLE_ANIM))
	if anim_name == BODY_DASH_ANIM:
		_dash_burst_left = maxf(_dash_burst_left, 0.2)
		if echo_vel.length_squared() > 400.0:
			velocity.x = lerpf(velocity.x, echo_vel.x * 0.72, 0.45)
		_sync_body_animation(BODY_DASH_ANIM)
	elif anim_name == BODY_JUMP_ANIM and is_on_floor():
		velocity.y = -_jump_speed * 0.92
		_sync_body_animation(BODY_JUMP_ANIM)
	elif anim_name == BODY_ATTACK_ANIM:
		_sync_body_animation(BODY_ATTACK_ANIM)
	_echo_feixe_active = bool(snap.get("feixe_charging", false))
	if _echo_feixe_active:
		_feixe_charging = true
		_charge_t = float(snap.get("charge_t", 0.0))
	elif _feint_charge_left <= 0.0:
		_feixe_charging = false
		_charge_t = 0.0
	var raw_aim: Vector2 = snap.get("aim_dir", _aim_dir)
	if raw_aim.length_squared() > 0.01:
		_aim_dir = _aim_dir.lerp(raw_aim.normalized(), clampf(AIM_SMOOTH * delta * 0.65, 0.0, 1.0))
	_update_visuals()


func tick_cpu(delta: float, owner: EsqueletoPlayer, opponent: Player, owner_idle_s: float) -> void:
	if not _alive:
		return
	if _echo_freeze_left > 0.0:
		_echo_freeze_left = maxf(0.0, _echo_freeze_left - delta)
		velocity = Vector2.ZERO
		return
	_rare_shot_cd_left = maxf(0.0, _rare_shot_cd_left - delta)
	_process_delayed_shots(delta)
	if owner == null:
		return
	_tick_local_idle(delta)
	_tick_combat_ai(delta, owner, opponent)
	_tick_feint_charge(delta, owner_idle_s)
	if absf(velocity.x) > 8.0 and _dash_time_left <= 0.0:
		_flip_h = velocity.x < 0.0 if owner.player_id == 1 else velocity.x > 0.0
	else:
		_sync_flip_from_aim(owner.player_id)
	_sync_move_anim_from_velocity()
	_update_visuals()


func _tick_local_idle(delta: float) -> void:
	if velocity.length() < BODY_MOVE_SPEED_THRESHOLD and is_on_floor():
		_local_idle_s += delta
	else:
		_local_idle_s = 0.0


func _tick_combat_ai(delta: float, owner: EsqueletoPlayer, opponent: Player) -> void:
	if not _autonomous_active:
		return
	var ctx := {
		"state": _combat_state,
		"clone_pos": global_position,
		"opponent": opponent,
		"owner": owner,
		"personality": _personality,
		"on_floor": is_on_floor(),
		"move_speed": _move_speed,
		"jump_speed": _jump_speed,
		"shot_speed": _shot_speed,
		"shot_cd_left": _shot_cd_left,
		"dash_cd_left": _dash_cd_left,
		"dash_time_left": _dash_time_left,
		"dash_speed": _dash_speed,
		"dash_cd_s": float(_profile.get("dash_cd_s", 1.1)),
		"arena_x": _arena_x_range,
		"aim_jitter_deg": get_cpu_jitter_deg(),
		"muzzle_pos": get_muzzle_global(),
		"tree": get_tree(),
		"profile": _profile,
		"wander_target": _wander_target,
		"wander_pick_left": _wander_pick_left,
		"aim_dir": _aim_dir,
		"instance_id": get_instance_id(),
	}
	var result := CombatAi.tick(ctx, delta)
	_combat_state = int(result.get("state", CombatAi.State.PATROL))
	_shot_cd_left = float(result.get("shot_cd_left", _shot_cd_left))
	_dash_cd_left = float(result.get("dash_cd_left", _dash_cd_left))
	_dash_time_left = float(result.get("dash_time_left", _dash_time_left))
	var aim: Vector2 = result.get("aim_dir", _aim_dir)
	if aim.length_squared() > 0.01:
		_aim_dir = _aim_dir.lerp(aim.normalized(), clampf(CPU_AIM_SMOOTH * delta, 0.0, 1.0))
	if bool(result.get("pick_new_wander", false)):
		var interval := 2.0 * _wander_interval_mul
		_wander_pick_left = randf_range(interval * 0.65, interval * 1.35)
	_wander_target = result.get("wander_target", _wander_target)
	_wander_pick_left = maxf(0.0, _wander_pick_left - delta)
	if bool(result.get("want_shoot", false)):
		_pending_shoot_vel = result.get("shoot_vel", Vector2.ZERO)
	if bool(result.get("want_dash", false)):
		velocity.x = float(result.get("dash_vel_x", 0.0))
		_dash_burst_left = CombatAi.DASH_DURATION_S
		_sync_body_animation(BODY_DASH_ANIM)
	elif _dash_time_left <= 0.0 and _dash_burst_left <= 0.0:
		var target_x := float(result.get("move_vel_x", 0.0))
		velocity.x = lerpf(velocity.x, target_x, clampf(10.0 * delta, 0.0, 1.0))
	if bool(result.get("want_jump", false)) and is_on_floor():
		velocity.y = -_jump_speed
		_sync_body_animation(BODY_JUMP_ANIM)
	var anim_override := String(result.get("anim_override", ""))
	if anim_override == "attack":
		_sync_body_animation(BODY_ATTACK_ANIM)
	if _dash_burst_left > 0.0:
		_dash_burst_left = maxf(0.0, _dash_burst_left - delta)


func physics_step(delta: float) -> void:
	if not _alive:
		return
	if _echo_freeze_left <= 0.0 and not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	global_position.x = CpuUtil.clamp_x_to_arena(global_position.x, _arena_x_range)
	if is_on_wall():
		_wander_pick_left = 0.0
	_update_visuals()


func _tick_feint_charge(delta: float, owner_idle_s: float) -> void:
	if not bool(_profile.get("feint_charge", false)):
		return
	if _echo_feixe_active:
		_feint_charge_left = 0.0
		return
	_feint_charge_left = maxf(0.0, _feint_charge_left - delta)
	if owner_idle_s < 0.45 and _local_idle_s < 0.45:
		if _feint_charge_left <= 0.0:
			_feixe_charging = false
			_charge_t = 0.0
		return
	if _feint_charge_left > 0.0:
		_feixe_charging = true
		return
	if randf() < 0.04 * delta:
		_feint_charge_left = randf_range(0.28, 0.62)
		_charge_t = randf_range(0.4, 0.92)
		_feixe_charging = true
		_sync_body_animation(BODY_ATTACK_ANIM)


func _process_delayed_shots(delta: float) -> void:
	var i := 0
	while i < _delayed_shots.size():
		_delayed_shots[i]["left"] = float(_delayed_shots[i].get("left", 0.0)) - delta
		if float(_delayed_shots[i].get("left", 0.0)) <= 0.0:
			var fn: Callable = _delayed_shots[i].get("fn", Callable())
			if fn.is_valid():
				fn.call()
			_delayed_shots.remove_at(i)
		else:
			i += 1


func _sync_flip_from_aim(player_id: int) -> void:
	if _aim_dir.length_squared() <= 0.0001:
		return
	if player_id == 1:
		_flip_h = _aim_dir.x < -0.05
	else:
		_flip_h = _aim_dir.x > 0.05


func _sync_move_anim_from_velocity() -> void:
	if not _sprite_ready or _body_sprite == null:
		return
	if _current_anim in [BODY_DASH_ANIM, BODY_JUMP_ANIM, BODY_ATTACK_ANIM]:
		if _current_anim == BODY_JUMP_ANIM and not is_on_floor():
			return
		if _current_anim == BODY_DASH_ANIM and _dash_burst_left > 0.0:
			return
		if _current_anim == BODY_ATTACK_ANIM and _feint_charge_left > 0.0:
			return
	var speed := absf(velocity.x)
	if speed >= BODY_MOVE_SPEED_THRESHOLD:
		if _current_anim != BODY_WALK_ANIM:
			_sync_body_animation(BODY_WALK_ANIM)
	elif _current_anim == BODY_WALK_ANIM:
		_sync_body_animation(BODY_IDLE_ANIM)


func _update_visuals() -> void:
	if _body_sprite != null and _sprite_ready:
		_body_sprite.flip_h = _flip_h
	if _glow_poly != null:
		_glow_poly.modulate.a = 0.16 + _charge_t * 0.28 if _feixe_charging else 0.12


func get_muzzle_global() -> Vector2:
	if _muzzle != null:
		return _muzzle.global_position
	var face := -1.0 if _flip_h else 1.0
	return global_position + Vector2(35.0 * face, -10.0)


func _ready() -> void:
	add_to_group("esqueleto_mirror_clones")
	_setup_body_sprite()
	_apply_spectral_colors()
	if _collision_shape != null and _collision_shape.shape != null:
		_collision_shape.shape = _collision_shape.shape.duplicate(true)


func _setup_body_sprite() -> void:
	if _body_sprite == null or _sprite_ready:
		return
	if not ResourceLoader.exists(ESQUELETO_SPRITE_FRAMES_PATH):
		return
	var frames := load(ESQUELETO_SPRITE_FRAMES_PATH) as SpriteFrames
	if frames == null:
		return
	_body_sprite.sprite_frames = frames
	_body_sprite.visible = true
	_body_sprite.offset = BODY_SPRITE_OFFSET
	_body_sprite.scale = BODY_SPRITE_SCALE
	_body_sprite.modulate = SPECTRAL_TINT
	_sprite_ready = true
	_sync_body_animation(BODY_IDLE_ANIM)


func _sync_body_animation(anim_name: String) -> void:
	if not _sprite_ready or _body_sprite.sprite_frames == null:
		return
	if not _body_sprite.sprite_frames.has_animation(anim_name):
		anim_name = BODY_IDLE_ANIM
	if not _body_sprite.sprite_frames.has_animation(anim_name):
		return
	_current_anim = anim_name
	if _body_sprite.animation != anim_name:
		_body_sprite.play(anim_name)


func _apply_spectral_colors() -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.94)
	if _glow_poly != null:
		_glow_poly.modulate = Color(0.55, 0.85, 1.2, 0.14)


func _destroy_spectral() -> void:
	if not _alive:
		return
	_alive = false
	_delayed_shots.clear()
	SfxManager.play("ricochet", global_position, 0.65, 8.0)
	for i in range(3):
		var puff := _explosion_scene.instantiate() as Node2D
		if puff == null or get_tree().current_scene == null:
			continue
		get_tree().current_scene.add_child(puff)
		puff.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-12.0, 6.0))
		puff.scale = Vector2.ONE * 0.55
		if puff is CanvasItem:
			(puff as CanvasItem).modulate = Color(0.5, 0.8, 1.2, 0.85)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)
