extends RefCounted
class_name LockOnFaceUtil


static func find_valid_opponent(shooter: Player) -> Player:
	return AutoAimFiveWayUtil.find_valid_opponent(shooter)


static func face_sign_from_target(self_pos: Vector2, target_pos: Vector2) -> int:
	if target_pos.x > self_pos.x:
		return 1
	if target_pos.x < self_pos.x:
		return -1
	return 1


static func facing_label(face_sign: int) -> String:
	return "RIGHT" if face_sign > 0 else "LEFT"


static func aim_at_target(muzzle_global: Vector2, target_global: Vector2, player_id: int) -> Dictionary:
	return AutoAim360Util.aim_at_target(muzzle_global, target_global, player_id)
