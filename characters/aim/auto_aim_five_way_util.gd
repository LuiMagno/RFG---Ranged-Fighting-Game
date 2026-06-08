extends RefCounted
class_name AutoAimFiveWayUtil


static func find_valid_opponent(shooter: Player) -> Player:
	for node in shooter.get_tree().get_nodes_in_group("players"):
		if not (node is Player):
			continue
		var other := node as Player
		if other.player_id == shooter.player_id:
			continue
		if not is_instance_valid(other) or other.hp <= 0:
			continue
		return other
	return null


static func quantize_slot_from_angle(
	aim_angle_deg: float,
	up_threshold: float,
	up_diagonal_threshold: float,
	forward_threshold: float,
	down_diagonal_threshold: float,
	down_threshold: float
) -> FiveWayAimUtil.Direction:
	if aim_angle_deg > up_threshold:
		return FiveWayAimUtil.Direction.UP
	if aim_angle_deg > up_diagonal_threshold:
		return FiveWayAimUtil.Direction.UP_FORWARD
	if aim_angle_deg > forward_threshold:
		return FiveWayAimUtil.Direction.UP_FORWARD
	if aim_angle_deg > down_diagonal_threshold:
		return FiveWayAimUtil.Direction.FORWARD
	if aim_angle_deg > down_threshold:
		return FiveWayAimUtil.Direction.DOWN_FORWARD
	return FiveWayAimUtil.Direction.DOWN


static func aim_at_target(
	muzzle_global: Vector2,
	target_global: Vector2,
	player_id: int,
	up_threshold: float,
	up_diagonal_threshold: float,
	forward_threshold: float,
	down_diagonal_threshold: float,
	down_threshold: float
) -> Dictionary:
	var raw := target_global - muzzle_global
	if raw.length_squared() <= 0.0001:
		var fallback := FiveWayAimUtil.direction_to_vector(FiveWayAimUtil.Direction.FORWARD, player_id)
		return {
			"direction": fallback,
			"slot": FiveWayAimUtil.Direction.FORWARD,
			"raw_vector": Vector2.ZERO,
			"raw_angle_deg": 0.0,
			"target_global": target_global,
		}
	var clamped := FreeAimUtil.clamp_to_opponent_hemisphere(raw, player_id)
	var raw_angle_deg := ThreeWayAimUtil.signed_aim_angle_deg(clamped, player_id)
	var slot := quantize_slot_from_angle(
		raw_angle_deg,
		up_threshold,
		up_diagonal_threshold,
		forward_threshold,
		down_diagonal_threshold,
		down_threshold
	)
	var direction := FiveWayAimUtil.direction_to_vector(slot, player_id)
	return {
		"direction": direction,
		"slot": slot,
		"raw_vector": raw,
		"raw_angle_deg": raw_angle_deg,
		"target_global": target_global,
	}
