extends RefCounted
class_name MirrorCloneCombatAi

## IA de combate leve para clones Mirror Image — explora, ataca, desvia.

enum State { PATROL, ENGAGE, DODGE, STRAFE }
enum Personality { PRESSER = 0, FEINTER = 1 }

const THREAT_RADIUS := 210.0
const THREAT_DOT := 0.42
const DASH_DURATION_S := 0.16


static func tick(ctx: Dictionary, delta: float) -> Dictionary:
	var state: int = int(ctx.get("state", State.PATROL))
	var result := {
		"state": state,
		"move_vel_x": 0.0,
		"want_jump": false,
		"want_dash": false,
		"dash_vel_x": 0.0,
		"want_shoot": false,
		"shoot_vel": Vector2.ZERO,
		"aim_dir": ctx.get("aim_dir", Vector2.RIGHT),
		"wander_target": ctx.get("wander_target", Vector2.ZERO),
		"pick_new_wander": false,
		"anim_override": "",
	}
	var clone_pos: Vector2 = ctx.get("clone_pos", Vector2.ZERO)
	var opponent: Player = ctx.get("opponent")
	var owner: Player = ctx.get("owner")
	var personality: int = int(ctx.get("personality", Personality.PRESSER))
	var on_floor: bool = bool(ctx.get("on_floor", true))
	var move_speed: float = float(ctx.get("move_speed", 210.0))
	var jump_speed: float = float(ctx.get("jump_speed", 620.0))
	var shot_speed: float = float(ctx.get("shot_speed", 420.0))
	var shot_cd_left: float = float(ctx.get("shot_cd_left", 0.0))
	var dash_cd_left: float = float(ctx.get("dash_cd_left", 0.0))
	var dash_time_left: float = float(ctx.get("dash_time_left", 0.0))
	var arena_x: Vector2 = ctx.get("arena_x", Vector2(36.0, 924.0))
	var aim_jitter: float = float(ctx.get("aim_jitter_deg", 4.0))
	var muzzle: Vector2 = ctx.get("muzzle_pos", clone_pos)
	var tree: SceneTree = ctx.get("tree")
	var profile: Dictionary = ctx.get("profile", {})
	var wander_target: Vector2 = ctx.get("wander_target", clone_pos)
	var owner_id := 1 if owner == null else owner.player_id

	shot_cd_left = maxf(0.0, shot_cd_left - delta)
	dash_cd_left = maxf(0.0, dash_cd_left - delta)
	dash_time_left = maxf(0.0, dash_time_left - delta)

	if dash_time_left > 0.0:
		result["state"] = State.DODGE
		result["dash_time_left"] = dash_time_left
		result["shot_cd_left"] = shot_cd_left
		result["dash_cd_left"] = dash_cd_left
		result["anim_override"] = "dash"
		return result

	var threat := _find_incoming_threat(clone_pos, owner, tree)
	if threat.get("active", false) and dash_cd_left <= 0.0 and on_floor:
		var dodge_x := _dodge_direction_x(clone_pos, threat, opponent, personality, owner_id)
		result["state"] = State.DODGE
		result["want_dash"] = true
		result["dash_vel_x"] = dodge_x * float(ctx.get("dash_speed", 500.0))
		result["dash_time_left"] = DASH_DURATION_S
		result["dash_cd_left"] = float(ctx.get("dash_cd_s", 1.15))
		result["shot_cd_left"] = shot_cd_left
		result["anim_override"] = "dash"
		if randf() < 0.35:
			result["want_jump"] = true
		return result

	var opponent_valid := opponent != null and is_instance_valid(opponent) and opponent.hp > 0
	var dist_x := 9999.0
	if opponent_valid:
		dist_x = absf(opponent.global_position.x - clone_pos.x)

	var engage_range := float(profile.get("engage_range", 720.0))
	var ideal_range := float(profile.get("ideal_range", 440.0))

	if opponent_valid and dist_x < engage_range:
		result["state"] = State.ENGAGE
		var aim := MirrorCloneCpuUtil.blend_aim(
			ctx.get("aim_dir", Vector2.RIGHT),
			muzzle,
			opponent,
			owner_id,
			float(profile.get("aim_blend", 0.7)),
			personality,
		)
		result["aim_dir"] = aim
		result["move_vel_x"] = _engage_move_x(
			clone_pos, opponent, ideal_range, move_speed, personality, arena_x, on_floor
		)
		if shot_cd_left <= 0.0 and _can_shoot_at(opponent, clone_pos, muzzle, ideal_range, dist_x):
			var seed := hash(str(ctx.get("instance_id", 0)) + ":" + str(Time.get_ticks_usec()))
			var vel := aim * shot_speed
			vel = MirrorCloneCpuUtil.jitter_direction(vel.normalized(), aim_jitter, seed) * shot_speed
			result["want_shoot"] = true
			result["shoot_vel"] = vel
			result["shot_cd_left"] = float(profile.get("shot_cd_s", 0.58))
			result["anim_override"] = "attack"
		else:
			result["shot_cd_left"] = shot_cd_left
		if on_floor and _should_engage_jump(clone_pos, opponent, personality):
			result["want_jump"] = true
			result["anim_override"] = "jump"
	else:
		result["state"] = State.PATROL
		result["shot_cd_left"] = shot_cd_left
		var pick_new := float(ctx.get("wander_pick_left", 0.0)) <= 0.0
		if pick_new or clone_pos.distance_to(wander_target) < 22.0:
			wander_target = MirrorCloneCpuUtil.pick_wander_target(
				clone_pos, arena_x, owner, opponent, personality
			)
			result["pick_new_wander"] = true
		result["wander_target"] = wander_target
		result["move_vel_x"] = MirrorCloneCpuUtil.compute_autonomous_velocity(
			clone_pos,
			wander_target,
			arena_x,
			move_speed,
			personality,
			owner,
			opponent,
			on_floor,
		).x
		if on_floor and MirrorCloneCpuUtil.should_autonomous_jump(
			personality, on_floor, result["move_vel_x"], wander_target, clone_pos, opponent
		):
			result["want_jump"] = true
			result["anim_override"] = "jump"

	result["dash_cd_left"] = dash_cd_left
	return result


static func _find_incoming_threat(clone_pos: Vector2, owner: Player, tree: SceneTree) -> Dictionary:
	var best := {"active": false, "dist": INF, "vel": Vector2.ZERO}
	if tree == null:
		return best
	for n in tree.get_nodes_in_group("arrows"):
		if not (n is Arrow):
			continue
		var arrow := n as Arrow
		if not is_instance_valid(arrow):
			continue
		var arrow_owner := arrow.get_owner_player()
		if arrow_owner == null or owner == null:
			continue
		if arrow_owner.player_id == owner.player_id:
			continue
		var vel: Vector2 = arrow.velocity
		if vel.length_squared() < 144.0:
			continue
		var to_clone := clone_pos - arrow.global_position
		var dist := to_clone.length()
		if dist > THREAT_RADIUS:
			continue
		if to_clone.normalized().dot(vel.normalized()) < THREAT_DOT:
			continue
		if dist < float(best["dist"]):
			best = {"active": true, "dist": dist, "vel": vel}
	return best


static func _dodge_direction_x(
	clone_pos: Vector2,
	threat: Dictionary,
	opponent: Player,
	personality: int,
	owner_id: int,
) -> float:
	var threat_vel: Vector2 = threat.get("vel", Vector2.ZERO)
	if threat_vel.length_squared() > 1.0:
		var lateral := signf(threat_vel.y) if absf(threat_vel.y) > 80.0 else 0.0
		if lateral == 0.0:
			lateral = 1.0 if randf() > 0.5 else -1.0
		return lateral
	if opponent != null and is_instance_valid(opponent):
		if personality == Personality.PRESSER:
			return MirrorCloneCpuUtil.opponent_horizontal_sign(clone_pos, opponent)
		return -MirrorCloneCpuUtil.opponent_horizontal_sign(clone_pos, opponent)
	return 1.0 if owner_id == 1 else -1.0


static func _engage_move_x(
	clone_pos: Vector2,
	opponent: Player,
	ideal_range: float,
	move_speed: float,
	personality: int,
	arena_x: Vector2,
	on_floor: bool,
) -> float:
	var dx := opponent.global_position.x - clone_pos.x
	var dist_x := absf(dx)
	var sign_to := signf(dx) if absf(dx) > 1.0 else (1.0 if personality == Personality.PRESSER else -1.0)
	var vel_x := 0.0
	if dist_x > ideal_range + 90.0:
		vel_x = sign_to * move_speed
	elif dist_x < ideal_range - 70.0:
		vel_x = -sign_to * move_speed * (0.85 if personality == Personality.FEINTER else 0.55)
	else:
		var strafe := sin(Time.get_ticks_msec() * 0.003 + float(personality) * 1.7)
		vel_x = strafe * move_speed * (0.72 if personality == Personality.FEINTER else 0.48)
	if on_floor:
		if clone_pos.x <= arena_x.x + 20.0:
			vel_x = maxf(vel_x, move_speed * 0.5)
		elif clone_pos.x >= arena_x.y - 20.0:
			vel_x = minf(vel_x, -move_speed * 0.5)
	return vel_x


static func _can_shoot_at(
	opponent: Player,
	clone_pos: Vector2,
	muzzle: Vector2,
	ideal_range: float,
	dist_x: float,
) -> bool:
	if opponent == null or not is_instance_valid(opponent):
		return false
	if dist_x > ideal_range + 320.0:
		return false
	var raw := opponent.global_position - muzzle
	if raw.length_squared() < 64.0:
		return false
	return true


static func _should_engage_jump(clone_pos: Vector2, opponent: Player, personality: int) -> bool:
	if opponent == null:
		return false
	var dy := opponent.global_position.y - clone_pos.y
	if dy < -50.0:
		return randf() < (0.04 if personality == Personality.PRESSER else 0.025)
	if absf(opponent.global_position.x - clone_pos.x) < 160.0:
		return randf() < 0.012
	return randf() < 0.006
