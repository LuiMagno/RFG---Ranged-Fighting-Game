extends RefCounted
class_name AutoAim360Util


static func find_valid_opponent(shooter: Player) -> Player:
	return AutoAimFiveWayUtil.find_valid_opponent(shooter)


static func aim_at_target(muzzle_global: Vector2, target_global: Vector2, player_id: int) -> Dictionary:
	var raw := target_global - muzzle_global
	if raw.length_squared() <= 0.0001:
		var fallback := FreeAimUtil.forward_for_player(player_id)
		return {
			"direction": fallback,
			"raw_vector": Vector2.ZERO,
			"angle_deg": 0.0,
			"target_global": target_global,
		}
	var direction := raw.normalized()
	var angle_deg := ThreeWayAimUtil.signed_aim_angle_deg(direction, player_id)
	return {
		"direction": direction,
		"raw_vector": raw,
		"angle_deg": angle_deg,
		"target_global": target_global,
	}
