extends RefCounted
class_name MirrorCloneCpuUtil

## Personalidades dos clones Mirror Image — comportamentos opostos para confundir o inimigo.

enum Personality { PRESSER = 0, FEINTER = 1 }


static func get_profile(personality: int, tuning: Dictionary) -> Dictionary:
	var base_blend := float(tuning.get("aim_blend", 0.55))
	var base_jitter := float(tuning.get("aim_jitter_deg", 4.0))
	var base_stagger := float(tuning.get("shot_stagger_s", 0.04))
	var base_rare := float(tuning.get("rare_shot_chance", 0.35))
	var move_bias := float(tuning.get("move_bias_px", 28.0))
	if personality == Personality.PRESSER:
		return {
			"label": "presser",
			"move_bias_sign": 1.0,
			"move_bias_px": move_bias,
			"aim_blend": minf(base_blend * 1.28, 0.95),
			"aim_jitter_deg": base_jitter * 0.65,
			"shot_stagger_s": 0.0,
			"pos_lerp_mul": 1.22,
			"overshoot_px": 14.0,
			"lateral_wobble_px": 0.0,
			"rare_shot_chance": minf(base_rare * 1.3, 0.55),
			"rare_jitter_mul": 0.85,
			"feint_charge": false,
			"distraction_shot_chance": 0.0,
			"distraction_jitter_deg": 0.0,
			"skip_echo_shot_chance": 0.0,
			"move_speed_mul": 1.1,
			"wander_interval_mul": 0.85,
			"engage_range": 780.0,
			"ideal_range": 380.0,
			"shot_cd_s": 0.52,
			"dash_cd_s": 1.05,
		}
	return {
		"label": "feinter",
		"move_bias_sign": -1.0,
		"move_bias_px": move_bias * 0.72,
		"aim_blend": base_blend * 0.52,
		"aim_jitter_deg": base_jitter * 1.55,
		"shot_stagger_s": base_stagger * 2.0,
		"pos_lerp_mul": 0.76,
		"overshoot_px": 5.0,
		"lateral_wobble_px": 14.0,
		"rare_shot_chance": base_rare * 0.85,
		"rare_jitter_mul": 2.1,
		"feint_charge": true,
		"distraction_shot_chance": 0.32,
		"distraction_jitter_deg": 22.0,
		"skip_echo_shot_chance": 0.12,
		"move_speed_mul": 0.92,
		"wander_interval_mul": 1.35,
		"engage_range": 680.0,
		"ideal_range": 500.0,
		"shot_cd_s": 0.68,
		"dash_cd_s": 0.92,
	}


static func opponent_horizontal_sign(from_pos: Vector2, opponent: Player) -> float:
	if opponent == null or not is_instance_valid(opponent):
		return 0.0
	var dx := opponent.global_position.x - from_pos.x
	if absf(dx) < 4.0:
		return 0.0
	return signf(dx)


static func compute_echo_target(
	snap_pos: Vector2,
	lateral_offset_x: float,
	echo_vel: Vector2,
	global_pos: Vector2,
	opponent: Player,
	profile: Dictionary,
	move_drift_x: float,
	wobble_phase: float,
	delta: float,
) -> Dictionary:
	var target_pos := snap_pos + Vector2(lateral_offset_x, 0.0)
	var toward := opponent_horizontal_sign(snap_pos, opponent)
	var desired_drift := (
		toward
		* float(profile.get("move_bias_sign", 0.0))
		* float(profile.get("move_bias_px", 0.0))
	)
	var new_drift := lerpf(move_drift_x, desired_drift, clampf(5.5 * delta, 0.0, 1.0))
	target_pos.x += new_drift
	var wobble := float(profile.get("lateral_wobble_px", 0.0))
	if wobble > 0.001:
		target_pos.x += sin(wobble_phase * 2.4) * wobble * 0.35
	var overshoot := float(profile.get("overshoot_px", 0.0))
	if echo_vel.length_squared() > 6400.0 and overshoot > 0.001:
		target_pos += echo_vel.normalized() * overshoot * 0.22
	return {"pos": target_pos, "drift_x": new_drift}


static func personality_aim_bias_rad(personality: int) -> float:
	if personality == Personality.PRESSER:
		return deg_to_rad(4.0)
	return deg_to_rad(-10.0)


static func blend_aim(
	echo_aim: Vector2,
	muzzle_global: Vector2,
	opponent: Player,
	owner_id: int,
	aim_blend: float,
	personality: int,
) -> Vector2:
	if echo_aim.length_squared() <= 0.0001:
		echo_aim = FreeAimUtil.forward_for_player(owner_id)
	if opponent == null or not is_instance_valid(opponent) or opponent.hp <= 0:
		return echo_aim.normalized()
	var toward: Vector2 = LockOnFaceUtil.aim_at_target(
		muzzle_global,
		opponent.global_position,
		owner_id,
	).get("direction", echo_aim)
	if toward.length_squared() <= 0.0001:
		return echo_aim.normalized()
	toward = toward.rotated(personality_aim_bias_rad(personality))
	var blend := clampf(aim_blend, 0.0, 1.0)
	return echo_aim.normalized().lerp(toward.normalized(), blend).normalized()


static func jitter_direction(dir: Vector2, jitter_deg: float, seed: int) -> Vector2:
	if dir.length_squared() <= 0.0001 or jitter_deg <= 0.0001:
		return dir
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var jitter_rad := deg_to_rad(jitter_deg)
	var offset := rng.randf_range(-jitter_rad, jitter_rad)
	return dir.normalized().rotated(offset)


static func apply_cpu_aim_to_velocity(
	base_vel: Vector2,
	muzzle_global: Vector2,
	opponent: Player,
	owner_id: int,
	echo_aim: Vector2,
	aim_blend: float,
	jitter_deg: float,
	personality: int,
	seed: int,
) -> Vector2:
	var speed := base_vel.length()
	if speed < 1.0:
		return base_vel
	var dir := blend_aim(echo_aim, muzzle_global, opponent, owner_id, aim_blend, personality)
	dir = jitter_direction(dir, jitter_deg, seed)
	return dir * speed


static func distraction_shot_velocity(
	base_speed: float,
	muzzle_global: Vector2,
	opponent: Player,
	owner_id: int,
	jitter_deg: float,
	seed: int,
) -> Vector2:
	if opponent == null or not is_instance_valid(opponent) or base_speed < 1.0:
		return Vector2.ZERO
	var toward: Vector2 = LockOnFaceUtil.aim_at_target(
		muzzle_global,
		opponent.global_position,
		owner_id,
	).get("direction", FreeAimUtil.forward_for_player(owner_id))
	toward = jitter_direction(toward, jitter_deg, seed)
	return toward * base_speed


static func rare_shot_velocity(
	muzzle_global: Vector2,
	opponent: Player,
	owner_id: int,
	speed: float,
	personality: int,
	jitter_deg: float,
	jitter_mul: float,
	seed: int,
) -> Vector2:
	if opponent == null or not is_instance_valid(opponent):
		return Vector2.ZERO
	var toward: Vector2 = LockOnFaceUtil.aim_at_target(
		muzzle_global,
		opponent.global_position,
		owner_id,
	).get("direction", FreeAimUtil.forward_for_player(owner_id))
	toward = toward.rotated(personality_aim_bias_rad(personality))
	toward = jitter_direction(toward, jitter_deg * jitter_mul, seed)
	return toward * speed


static func roll_rare_shot(chance: float) -> bool:
	return randf() < clampf(chance, 0.0, 1.0)


static func roll_chance(chance: float) -> bool:
	return randf() < clampf(chance, 0.0, 1.0)


static func pick_wander_target(
	current_pos: Vector2,
	arena_x: Vector2,
	owner: Player,
	opponent: Player,
	personality: int,
) -> Vector2:
	var min_x := arena_x.x
	var max_x := arena_x.y
	if max_x <= min_x + 8.0:
		return current_pos
	var forward_x := max_x if owner != null and owner.player_id == 1 else min_x
	var back_x := min_x if owner != null and owner.player_id == 1 else max_x
	var target_x := current_pos.x
	if personality == Personality.PRESSER:
		if opponent != null and is_instance_valid(opponent) and randf() < 0.62:
			var opp_x := clampf(opponent.global_position.x, min_x, max_x)
			target_x = lerpf(current_pos.x, opp_x, randf_range(0.25, 0.72))
		elif randf() < 0.7:
			target_x = lerpf(current_pos.x, forward_x, randf_range(0.35, 0.9))
		else:
			target_x = randf_range(min_x, max_x)
	else:
		if randf() < 0.58:
			target_x = lerpf(current_pos.x, back_x, randf_range(0.22, 0.75))
		elif opponent != null and is_instance_valid(opponent) and randf() < 0.35:
			var away := current_pos.x + signf(current_pos.x - opponent.global_position.x) * 80.0
			target_x = away
		else:
			target_x = randf_range(min_x, max_x)
	return Vector2(clampf(target_x, min_x, max_x), current_pos.y)


static func compute_autonomous_velocity(
	current_pos: Vector2,
	wander_target: Vector2,
	arena_x: Vector2,
	move_speed: float,
	personality: int,
	owner: Player,
	opponent: Player,
	on_floor: bool,
) -> Vector2:
	var vel := Vector2.ZERO
	var min_x := arena_x.x
	var max_x := arena_x.y
	var to := wander_target - current_pos
	if absf(to.x) > 10.0:
		vel.x = signf(to.x) * move_speed
	elif opponent != null and is_instance_valid(opponent):
		var press_sign := opponent_horizontal_sign(current_pos, opponent)
		if personality == Personality.PRESSER:
			vel.x = press_sign * move_speed * 0.55
		else:
			vel.x = -press_sign * move_speed * 0.42
	if on_floor:
		if current_pos.x <= min_x + 18.0:
			vel.x = maxf(vel.x, move_speed * 0.65)
		elif current_pos.x >= max_x - 18.0:
			vel.x = minf(vel.x, -move_speed * 0.65)
	return vel


static func should_autonomous_jump(
	personality: int,
	on_floor: bool,
	velocity_x: float,
	wander_target: Vector2,
	current_pos: Vector2,
	opponent: Player,
) -> bool:
	if not on_floor:
		return false
	if absf(wander_target.y - current_pos.y) > 40.0:
		return randf() < 0.08
	if absf(wander_target.x - current_pos.x) > 120.0 and absf(velocity_x) > 40.0:
		return randf() < 0.035
	if personality == Personality.PRESSER and opponent != null and is_instance_valid(opponent):
		if absf(opponent.global_position.x - current_pos.x) < 180.0:
			return randf() < 0.018
	if personality == Personality.FEINTER:
		return randf() < 0.012
	return randf() < 0.008


static func clamp_x_to_arena(x: float, arena_x: Vector2) -> float:
	return clampf(x, arena_x.x, arena_x.y)

