extends RefCounted
class_name ThreeWayAimUtil

enum Direction { UP_FORWARD, FORWARD, DOWN_FORWARD }


static func direction_label(slot: Direction) -> String:
	match slot:
		Direction.UP_FORWARD:
			return "UP_FORWARD"
		Direction.DOWN_FORWARD:
			return "DOWN_FORWARD"
		_:
			return "FORWARD"


static func direction_to_vector(slot: Direction, player_id: int) -> Vector2:
	if player_id == 1:
		match slot:
			Direction.UP_FORWARD:
				return Vector2(1.0, -1.0).normalized()
			Direction.DOWN_FORWARD:
				return Vector2(1.0, 1.0).normalized()
			_:
				return Vector2.RIGHT
	match slot:
		Direction.UP_FORWARD:
			return Vector2(-1.0, -1.0).normalized()
		Direction.DOWN_FORWARD:
			return Vector2(-1.0, 1.0).normalized()
		_:
			return Vector2.LEFT


static func signed_aim_angle_deg(dir: Vector2, player_id: int) -> float:
	if dir.length_squared() <= 0.0001:
		return 0.0
	var d := dir.normalized()
	var forward := FreeAimUtil.forward_for_player(player_id)
	var signed_from_axis := forward.angle_to(d)
	if player_id == 1:
		return -rad_to_deg(signed_from_axis)
	return rad_to_deg(signed_from_axis)


static func quantize_slot_from_angle(aim_angle_deg: float, upper_threshold: float, lower_threshold: float) -> Direction:
	if aim_angle_deg > upper_threshold:
		return Direction.UP_FORWARD
	if aim_angle_deg < lower_threshold:
		return Direction.DOWN_FORWARD
	return Direction.FORWARD


static func quantize(
	raw: Vector2,
	player_id: int,
	deadzone: float,
	upper_threshold: float,
	lower_threshold: float,
	last_direction: Vector2
) -> Dictionary:
	if raw.length() < deadzone:
		return {
			"direction": last_direction,
			"slot": slot_from_direction(last_direction, player_id),
			"raw_clamped": Vector2.ZERO,
			"raw_angle_deg": 0.0,
			"in_deadzone": true,
		}
	var clamped := FreeAimUtil.clamp_to_opponent_hemisphere(raw, player_id)
	var raw_angle_deg := signed_aim_angle_deg(clamped, player_id)
	var slot := quantize_slot_from_angle(raw_angle_deg, upper_threshold, lower_threshold)
	var direction := direction_to_vector(slot, player_id)
	return {
		"direction": direction,
		"slot": slot,
		"raw_clamped": clamped,
		"raw_angle_deg": raw_angle_deg,
		"in_deadzone": false,
	}


static func slot_from_direction(dir: Vector2, player_id: int) -> Direction:
	if dir.length_squared() <= 0.0001:
		return Direction.FORWARD
	var d := dir.normalized()
	var forward := FreeAimUtil.forward_for_player(player_id)
	if is_equal_approx(d.dot(forward), 1.0):
		return Direction.FORWARD
	if player_id == 1:
		if d.y < 0.0:
			return Direction.UP_FORWARD
		return Direction.DOWN_FORWARD
	if d.y < 0.0:
		return Direction.UP_FORWARD
	return Direction.DOWN_FORWARD
