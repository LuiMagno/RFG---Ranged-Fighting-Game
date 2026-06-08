extends RefCounted
class_name FreeAimUtil


static func forward_for_player(player_id: int) -> Vector2:
	return Vector2.RIGHT if player_id == 1 else Vector2.LEFT


## Limita ao hemisfério voltado para o adversário (180°). Input "para trás" vira cima/baixo no arco.
static func clamp_to_opponent_hemisphere(dir: Vector2, player_id: int) -> Vector2:
	if dir.length_squared() <= 0.0001:
		return forward_for_player(player_id)
	var d := dir
	if player_id == 1:
		if d.x < 0.0:
			d.x = 0.0
	else:
		if d.x > 0.0:
			d.x = 0.0
	if d.length_squared() <= 0.0001:
		return forward_for_player(player_id)
	return d.normalized()


static func read_locomotion_aim_vector(player_id: int, gamepad: bool) -> Vector2:
	var prefix := "p1" if player_id == 1 else "p2"
	if gamepad:
		return Input.get_vector(
			prefix + "_left",
			prefix + "_right",
			prefix + "_move_up",
			prefix + "_move_down",
			0.0
		)
	return Input.get_vector(
		prefix + "_left",
		prefix + "_right",
		prefix + "_hover_up",
		prefix + "_hover_down",
		0.0
	)


static func read_gamepad_aim(player_id: int) -> Vector2:
	var prefix := "p1" if player_id == 1 else "p2"
	return Input.get_vector(
		prefix + "_aim_left",
		prefix + "_aim_right",
		prefix + "_aim_up",
		prefix + "_aim_down",
		0.0
	)


static func apply_gamepad_tuning(
	raw: Vector2,
	deadzone: float,
	sensitivity: float,
	smoothing: float,
	delta: float,
	current_dir: Vector2
) -> Vector2:
	var v := raw * sensitivity
	if v.length_squared() > 1.0001:
		v = v.limit_length(1.0)
	if v.length() < deadzone:
		return current_dir
	var target := v.normalized()
	if smoothing <= 0.0001:
		return target
	var tau := maxf(smoothing, 0.0001)
	var alpha := 1.0 - exp(-delta / tau)
	var blended := current_dir.lerp(target, alpha)
	if blended.length_squared() > 0.0001:
		return blended.normalized()
	return target


static func read_mouse_aim(muzzle_global: Vector2, mouse_global: Vector2, player_id: int) -> Vector2:
	var raw := mouse_global - muzzle_global
	if raw.length_squared() <= 0.0001:
		return forward_for_player(player_id)
	return clamp_to_opponent_hemisphere(raw, player_id)


static func compute_shot_velocity(speed: float, launch_angle_deg: float, player_id: int) -> Vector2:
	var sign_x := 1.0 if player_id == 1 else -1.0
	var angle := deg_to_rad(launch_angle_deg)
	var vx := cos(angle) * speed * sign_x
	var vy := -sin(angle) * speed
	return Vector2(vx, vy)
