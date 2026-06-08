extends RefCounted
class_name AimAssistUtil


static func wrap_angle_deg(angle: float) -> float:
	var a := fmod(angle + 180.0, 360.0)
	if a < 0.0:
		a += 360.0
	return a - 180.0


static func apply(
	base_direction: Vector2,
	muzzle_global: Vector2,
	target_global: Vector2,
	player_id: int,
	angle_window: float,
	strength: float,
	max_correction: float
) -> Dictionary:
	var player_dir := base_direction
	if player_dir.length_squared() <= 0.0001:
		player_dir = FreeAimUtil.forward_for_player(player_id)
	else:
		player_dir = player_dir.normalized()

	var to_target := target_global - muzzle_global
	var target_dir := player_dir
	if to_target.length_squared() > 0.0001:
		target_dir = to_target.normalized()

	var player_angle := ThreeWayAimUtil.signed_aim_angle_deg(player_dir, player_id)
	var target_angle := ThreeWayAimUtil.signed_aim_angle_deg(target_dir, player_id)
	var delta := wrap_angle_deg(target_angle - player_angle)
	var angular_diff := absf(delta)

	if angular_diff > angle_window or strength <= 0.0001:
		return {
			"applied": false,
			"player_dir": player_dir,
			"target_dir": target_dir,
			"final_dir": player_dir,
			"angular_diff": angular_diff,
			"correction_deg": 0.0,
			"player_angle_deg": player_angle,
			"target_angle_deg": target_angle,
			"final_angle_deg": player_angle,
		}

	var correction_deg := clampf(delta * strength, -max_correction, max_correction)
	var final_angle := player_angle + correction_deg
	var final_vel := FreeAimUtil.compute_shot_velocity(1.0, final_angle, player_id)
	var final_dir := player_dir
	if final_vel.length_squared() > 0.0001:
		final_dir = final_vel.normalized()

	return {
		"applied": true,
		"player_dir": player_dir,
		"target_dir": target_dir,
		"final_dir": final_dir,
		"angular_diff": angular_diff,
		"correction_deg": correction_deg,
		"player_angle_deg": player_angle,
		"target_angle_deg": target_angle,
		"final_angle_deg": final_angle,
	}
