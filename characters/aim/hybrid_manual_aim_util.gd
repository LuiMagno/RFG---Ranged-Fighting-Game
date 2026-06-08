extends RefCounted
class_name HybridManualAimUtil


static func read_vertical_input(player_id: int, gamepad: bool) -> float:
	var prefix := "p1" if player_id == 1 else "p2"
	if gamepad:
		return Input.get_axis(prefix + "_move_down", prefix + "_move_up")
	return Input.get_axis(prefix + "_hover_down", prefix + "_hover_up")


static func slot_from_vertical(
	vertical: float,
	up_threshold: float,
	down_threshold: float
) -> ThreeWayAimUtil.Direction:
	if vertical > up_threshold:
		return ThreeWayAimUtil.Direction.UP_FORWARD
	if vertical < down_threshold:
		return ThreeWayAimUtil.Direction.DOWN_FORWARD
	return ThreeWayAimUtil.Direction.FORWARD


static func sample(
	player_id: int,
	gamepad: bool,
	up_threshold: float,
	down_threshold: float
) -> Dictionary:
	var vertical := read_vertical_input(player_id, gamepad)
	var slot := slot_from_vertical(vertical, up_threshold, down_threshold)
	var direction := ThreeWayAimUtil.direction_to_vector(slot, player_id)
	return {
		"vertical": vertical,
		"slot": slot,
		"direction": direction,
	}
