extends RefCounted
class_name FiveWayAimUtil

enum Direction { UP, UP_FORWARD, FORWARD, DOWN_FORWARD, DOWN }


static func direction_label(slot: Direction) -> String:
	match slot:
		Direction.UP:
			return "UP"
		Direction.UP_FORWARD:
			return "UP_FORWARD"
		Direction.DOWN_FORWARD:
			return "DOWN_FORWARD"
		Direction.DOWN:
			return "DOWN"
		_:
			return "FORWARD"


static func direction_to_vector(slot: Direction, player_id: int) -> Vector2:
	match slot:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.FORWARD:
			return Vector2.RIGHT if player_id == 1 else Vector2.LEFT
	if player_id == 1:
		match slot:
			Direction.UP_FORWARD:
				return Vector2(1.0, -1.0).normalized()
			_:
				return Vector2(1.0, 1.0).normalized()
	match slot:
		Direction.UP_FORWARD:
			return Vector2(-1.0, -1.0).normalized()
		_:
			return Vector2(-1.0, 1.0).normalized()


static func quantize_slot_from_angle(
	aim_angle_deg: float,
	up_threshold: float,
	up_diagonal_threshold: float,
	down_diagonal_threshold: float,
	down_threshold: float
) -> Direction:
	if aim_angle_deg > up_threshold:
		return Direction.UP
	if aim_angle_deg > up_diagonal_threshold:
		return Direction.UP_FORWARD
	if aim_angle_deg > down_diagonal_threshold:
		return Direction.FORWARD
	if aim_angle_deg > down_threshold:
		return Direction.DOWN_FORWARD
	return Direction.DOWN


static func quantize(
	raw: Vector2,
	player_id: int,
	deadzone: float,
	up_threshold: float,
	up_diagonal_threshold: float,
	down_diagonal_threshold: float,
	down_threshold: float,
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
	var raw_angle_deg := ThreeWayAimUtil.signed_aim_angle_deg(clamped, player_id)
	var slot := quantize_slot_from_angle(
		raw_angle_deg,
		up_threshold,
		up_diagonal_threshold,
		down_diagonal_threshold,
		down_threshold
	)
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
	if is_equal_approx(d.y, -1.0):
		return Direction.UP
	if is_equal_approx(d.y, 1.0):
		return Direction.DOWN
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
