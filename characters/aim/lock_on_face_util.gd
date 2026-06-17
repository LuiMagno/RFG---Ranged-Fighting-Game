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


static func _as_lock_on_node(target: Variant) -> Node2D:
	if target == null or not (target is Node2D):
		return null
	var node := target as Node2D
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return null
	return node


static func is_valid_lock_on_target(shooter: Player, target: Variant) -> bool:
	var node := _as_lock_on_node(target)
	if shooter == null or node == null:
		return false
	if node is Player:
		var pl := node as Player
		if pl.player_id == shooter.player_id:
			return false
		return pl.hp > 0
	if node is EsqueletoMirrorClone:
		var mc := node as EsqueletoMirrorClone
		if not mc.is_alive():
			return false
		var owner := mc.get_owner_player()
		if owner == null or not is_instance_valid(owner):
			return false
		if owner.player_id == shooter.player_id:
			return false
		return owner.hp > 0
	return false


static func _collect_opponent_mirror_clones(shooter: Player) -> Array[EsqueletoMirrorClone]:
	var clones: Array[EsqueletoMirrorClone] = []
	var opponent := find_valid_opponent(shooter)
	if opponent == null:
		return clones
	for n in shooter.get_tree().get_nodes_in_group("esqueleto_mirror_clones"):
		if not (n is EsqueletoMirrorClone):
			continue
		var mc := n as EsqueletoMirrorClone
		if not is_valid_lock_on_target(shooter, mc):
			continue
		if mc.get_owner_player() != opponent:
			continue
		clones.append(mc)
	clones.sort_custom(func(a: EsqueletoMirrorClone, b: EsqueletoMirrorClone) -> bool:
		return a.global_position.x < b.global_position.x
	)
	return clones


static func collect_lock_on_candidates(shooter: Player) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var opponent := find_valid_opponent(shooter)
	if opponent != null:
		result.append(opponent)
	for mc in _collect_opponent_mirror_clones(shooter):
		result.append(mc)
	return result


static func label_for_target(shooter: Player, target: Variant) -> String:
	var node := _as_lock_on_node(target)
	if node == null:
		return ""
	if node is Player:
		return "P%d" % (node as Player).player_id
	if node is EsqueletoMirrorClone:
		var clones := _collect_opponent_mirror_clones(shooter)
		if clones.size() >= 2:
			if node == clones[0]:
				return "Clone_L"
			if node == clones[1]:
				return "Clone_R"
		return "Clone"
	return "?"


static func resolve_lock_on_target(shooter: Player, current: Variant) -> Node2D:
	var target := _as_lock_on_node(current)
	if target != null and is_valid_lock_on_target(shooter, target):
		return target
	var candidates := collect_lock_on_candidates(shooter)
	if candidates.is_empty():
		return null
	return candidates[0]


static func next_lock_on_target(shooter: Player, current: Variant) -> Node2D:
	var candidates := collect_lock_on_candidates(shooter)
	if candidates.is_empty():
		return null
	var target := _as_lock_on_node(current)
	if target == null or not is_valid_lock_on_target(shooter, target):
		return candidates[0]
	var idx := candidates.find(target)
	if idx < 0:
		return candidates[0]
	return candidates[(idx + 1) % candidates.size()]
