extends CharacterBody2D
class_name EsqueletoTurret

## Torreta do Esqueleto: estacionária, sentinela móvel ou foguete kamikaze.

enum Mode { STATIONARY, SENTINEL, ROCKET_CHARGE, ROCKET_FLIGHT }

const TERRAIN_COLLISION_MASK := 49
const GRAVITY_ACCEL := 1500.0
const SENTINEL_Y_TOLERANCE_PX := 72.0
const SENTINEL_DISTANCE_DEADBAND_PX := 28.0
const LEG_SWING_SPEED := 11.0
const LEG_SWING_AMOUNT := 0.42
const ROCKET_HIT_RADIUS_PX := 26.0
const ROCKET_LAUNCH_SPEED := 140.0
const ROCKET_BOUNCE_DAMPING := 0.82
const PROJECTILE_PUSH_RADIUS_PX := 120.0
const PROJECTILE_PUSH_STRENGTH := 280.0

var _owner: Player
var _game: Node
var _mode: Mode = Mode.STATIONARY
var _hp: int = 30
var _shots_left: int = 5
var _fire_cooldown_left: float = 0.0
var _shot_damage: int = 20
var _shot_interval_s: float = 2.5
var _shot_speed: float = 420.0
var _settled: bool = false
var _walk_speed: float = 95.0
var _follow_range: float = 380.0
var _preferred_distance: float = 185.0
var _leg_phase: float = 0.0
var _rocket_charge_left: float = 0.0
var _rocket_accel: float = 1850.0
var _rocket_max_speed: float = 920.0
var _rocket_turn_rad_s: float = 1.65
var _rocket_bounces_left: int = 1
var _rocket_base_damage: int = 36
var _rocket_damage_bonus: int = 0
var _rocket_radius: float = 150.0
var _rocket_knockback_x: float = 520.0
var _rocket_knockback_up: float = 260.0
var _rocket_overcharge_speed_threshold: float = 220.0
var _rocket_speed_mul: float = 1.0
var _rocket_dir: Vector2 = Vector2.RIGHT
var _rocket_exploded: bool = false
var _charge_pulse: float = 0.0

var _explosion_scene: PackedScene = preload("res://projectiles/explosion/explosion.tscn")

@onready var _head_pivot: Node2D = $HeadPivot
@onready var _muzzle: Marker2D = $HeadPivot/Muzzle
@onready var _base_plate: Polygon2D = $BasePlate
@onready var _base_rim: Polygon2D = $BaseRim
@onready var _head_body: Polygon2D = $HeadPivot/HeadBody
@onready var _barrel: Polygon2D = $HeadPivot/Barrel
@onready var _barrel_tip: Polygon2D = $HeadPivot/BarrelTip
@onready var _thruster: Polygon2D = $HeadPivot/ThrusterFlame
@onready var _legs_root: Node2D = $LegsRoot
@onready var _leg_l_pivot: Node2D = $LegsRoot/LegLPivot
@onready var _leg_r_pivot: Node2D = $LegsRoot/LegRPivot


func setup(owner_player: Player, game: Node, config: Dictionary) -> void:
	_owner = owner_player
	_game = game
	_mode = Mode.STATIONARY
	_hp = int(config.get("vida", 30))
	_shots_left = int(config.get("disparos", 5))
	_shot_damage = int(config.get("dano_tiro", 20))
	_shot_interval_s = float(config.get("intervalo_disparo_s", 2.5))
	_shot_speed = float(config.get("velocidade_tiro", 420.0))
	if _owner != null:
		add_collision_exception_with(_owner)
	_apply_team_colors()
	_settled = is_on_floor()


func get_owner_player() -> Player:
	return _owner


func is_sentinel() -> bool:
	return _mode == Mode.SENTINEL


func is_rocket_mode() -> bool:
	return _mode == Mode.ROCKET_CHARGE or _mode == Mode.ROCKET_FLIGHT


func can_transform_to_sentinel() -> bool:
	return _mode == Mode.STATIONARY and _settled and _shots_left > 0 and not is_rocket_mode()


func can_transform_to_rocket() -> bool:
	return (
		(_mode == Mode.STATIONARY or _mode == Mode.SENTINEL)
		and _settled
		and not is_rocket_mode()
	)


func transform_to_sentinel(config: Dictionary) -> void:
	if not can_transform_to_sentinel():
		return
	_mode = Mode.SENTINEL
	_hp = mini(_hp, int(config.get("vida", 20)))
	_shots_left = int(config.get("disparos", 10))
	_shot_damage = int(config.get("dano_tiro", 11))
	_shot_interval_s = float(config.get("intervalo_disparo_s", 1.15))
	_shot_speed = float(config.get("velocidade_tiro", _shot_speed))
	_walk_speed = float(config.get("walk_speed", 95.0))
	_follow_range = float(config.get("follow_range", 380.0))
	_preferred_distance = float(config.get("preferred_distance", 185.0))
	_fire_cooldown_left = 0.08
	if _legs_root != null:
		_legs_root.visible = true
		_legs_root.modulate.a = 0.0
		_legs_root.scale = Vector2.ONE
		var tween := create_tween()
		tween.tween_property(_legs_root, "modulate:a", 1.0, 0.2)
	if _head_pivot != null:
		_head_pivot.position.y = -4.0
	add_to_group("esqueleto_turret_sentinels")
	SfxManager.play("hit_heavy", global_position, 0.72, -6.0)


func begin_rocket_transform(config: Dictionary) -> void:
	if not can_transform_to_rocket():
		return
	var shot_energy := _shots_left
	_shots_left = 0
	_mode = Mode.ROCKET_CHARGE
	_rocket_charge_left = float(config.get("charge_s", 0.3))
	_rocket_base_damage = int(config.get("dano_base", 36))
	_rocket_radius = float(config.get("raio", 150.0))
	_rocket_knockback_x = float(config.get("knockback_x", 520.0))
	_rocket_knockback_up = float(config.get("knockback_up", 260.0))
	_rocket_accel = float(config.get("aceleracao", 1850.0))
	_rocket_max_speed = float(config.get("vel_max", 920.0))
	_rocket_turn_rad_s = deg_to_rad(float(config.get("tracking_graus_s", 95.0)))
	_rocket_bounces_left = int(config.get("ricochetes", 1))
	_rocket_overcharge_speed_threshold = float(config.get("sobrecarga_vel_inimigo", 220.0))
	_rocket_damage_bonus = shot_energy * int(config.get("bonus_dano_por_tiro", 4))
	_rocket_speed_mul = 1.0 + shot_energy * float(config.get("bonus_vel_por_tiro", 0.1))
	velocity = Vector2.ZERO
	_charge_pulse = 0.0
	if _thruster != null:
		_thruster.visible = true
		_thruster.modulate.a = 0.35
	if _legs_root != null and _legs_root.visible:
		var tween := create_tween()
		tween.tween_property(_legs_root, "scale", Vector2(0.35, 0.5), _rocket_charge_left)
	if _barrel != null:
		_barrel.color = Color(0.95, 0.42, 0.18, 1.0)
	if _barrel_tip != null:
		_barrel_tip.color = Color(1.0, 0.72, 0.22, 1.0)
	SfxManager.play("ult_start", global_position, 0.42, -10.0)


func take_damage(amount: int) -> void:
	if amount <= 0 or _rocket_exploded:
		return
	_hp -= amount
	if _hp <= 0:
		_destroy()


func _ready() -> void:
	add_to_group("esqueleto_turrets")
	collision_mask = TERRAIN_COLLISION_MASK
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(46.0)
	_apply_team_colors()


func _physics_process(delta: float) -> void:
	if _mode == Mode.ROCKET_CHARGE:
		_process_rocket_charge(delta)
		return
	if _mode == Mode.ROCKET_FLIGHT:
		_process_rocket_flight(delta)
		return
	if not _settled:
		_process_falling(delta)
		return
	if _mode == Mode.SENTINEL:
		_process_sentinel_movement(delta)
	_process_combat(delta)


func _process_rocket_charge(delta: float) -> void:
	velocity = Vector2.ZERO
	_rocket_charge_left -= delta
	_charge_pulse += delta * 18.0
	if _thruster != null:
		_thruster.modulate.a = 0.35 + sin(_charge_pulse) * 0.2
		_thruster.scale.x = 0.8 + sin(_charge_pulse * 1.4) * 0.25
	_update_aim_visual()
	if _rocket_charge_left <= 0.0:
		_launch_rocket()


func _launch_rocket() -> void:
	_mode = Mode.ROCKET_FLIGHT
	floor_snap_length = 0.0
	_rocket_dir = Vector2.RIGHT if (_owner != null and _owner.player_id == 1) else Vector2.LEFT
	var opponent := _find_opponent()
	if opponent != null:
		var aim := _target_offset(opponent)
		if aim.length_squared() > 1.0:
			_rocket_dir = aim.normalized()
	_head_pivot.rotation = _rocket_dir.angle()
	velocity = _rocket_dir * ROCKET_LAUNCH_SPEED * _rocket_speed_mul
	if _thruster != null:
		_thruster.visible = true
		_thruster.modulate.a = 0.95
	SfxManager.play("shoot_magic", global_position, 1.05, -4.0)


func _process_rocket_flight(delta: float) -> void:
	var opponent := _find_opponent()
	if opponent != null:
		var to_enemy := _target_offset(opponent)
		if to_enemy.length_squared() > 4.0:
			var desired := to_enemy.normalized()
			var current := velocity.normalized() if velocity.length_squared() > 1.0 else desired
			var ang_diff := current.angle_to(desired)
			var max_turn := _rocket_turn_rad_s * delta
			velocity = velocity.rotated(clampf(ang_diff, -max_turn, max_turn))
			_rocket_dir = velocity.normalized() if velocity.length_squared() > 1.0 else desired
	if velocity.length_squared() < 1.0:
		velocity = _rocket_dir * ROCKET_LAUNCH_SPEED
	var max_spd := _rocket_max_speed * _rocket_speed_mul
	var spd := velocity.length()
	if spd < max_spd:
		velocity += velocity.normalized() * _rocket_accel * delta if spd > 0.01 else _rocket_dir * _rocket_accel * delta
		spd = velocity.length()
		if spd > max_spd:
			velocity = velocity.normalized() * max_spd
	_head_pivot.rotation = velocity.angle() if velocity.length_squared() > 1.0 else _head_pivot.rotation
	if _thruster != null:
		_thruster.rotation = PI
		_thruster.scale.x = 0.9 + clampf(spd / max_spd, 0.0, 1.0) * 0.55
	var prev_pos := global_position
	move_and_slide()
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col == null:
			continue
		if _rocket_bounces_left > 0:
			_rocket_bounces_left -= 1
			var n := col.get_normal()
			velocity = velocity.bounce(n) * ROCKET_BOUNCE_DAMPING
			global_position += n * 3.0
			_rocket_dir = velocity.normalized() if velocity.length_squared() > 1.0 else _rocket_dir
			SfxManager.play("ricochet", global_position, 1.0, -6.0)
			return
		_rocket_explode(null)
		return
	if global_position.distance_to(prev_pos) < 0.5 and spd > 120.0:
		_rocket_explode(null)
		return
	var hit := _find_rocket_hit_player()
	if hit != null:
		_rocket_explode(hit)


func _find_rocket_hit_player() -> Player:
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner or pl.hp <= 0:
			continue
		var rect := pl.get_body_collision_rect() if pl.has_method("get_body_collision_rect") else Rect2(pl.global_position - Vector2(12, 24), Vector2(24, 48))
		if rect.get_center().distance_to(global_position) <= ROCKET_HIT_RADIUS_PX + rect.size.length() * 0.15:
			return pl
	return null


func _rocket_explode(direct_hit: Player) -> void:
	if _rocket_exploded:
		return
	_rocket_exploded = true
	var center := global_position
	var radius := _rocket_radius
	var damage := _rocket_base_damage + _rocket_damage_bonus
	var overcharge := false
	if direct_hit != null and direct_hit.velocity.length() >= _rocket_overcharge_speed_threshold:
		overcharge = true
		radius *= 1.35
		damage = int(round(float(damage) * 1.25))
	SfxManager.play("explosion", center, 1.0 if overcharge else 0.92, -2.0 if overcharge else 0.0)
	for i in range(3 if overcharge else 2):
		var puff := _explosion_scene.instantiate() as Node2D
		if puff == null or get_tree().current_scene == null:
			continue
		get_tree().current_scene.add_child(puff)
		puff.global_position = center + Vector2(randf_range(-18.0, 18.0), randf_range(-14.0, 14.0))
		if overcharge:
			puff.scale = Vector2.ONE * 1.2
	_push_nearby_projectiles(center, radius)
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner:
			continue
		var feet := pl.global_position
		if center.distance_to(feet) > radius + 28.0:
			continue
		pl.take_damage(damage)
		SfxManager.play("hit_heavy", feet, 1.0, -4.0)
		var away := feet - center
		if away.length_squared() < 4.0:
			away = _rocket_dir if _rocket_dir.length_squared() > 0.01 else Vector2.RIGHT
		else:
			away = away.normalized()
		pl.apply_knockback(Vector2(away.x * _rocket_knockback_x, -_rocket_knockback_up))
	queue_free()


func _push_nearby_projectiles(center: Vector2, blast_radius: float) -> void:
	var push_radius := maxf(blast_radius, PROJECTILE_PUSH_RADIUS_PX)
	for n in get_tree().get_nodes_in_group("arrows"):
		_push_node_if_near(n, center, push_radius)
	for n in get_tree().get_nodes_in_group("grenades"):
		_push_node_if_near(n, center, push_radius)


func _push_node_if_near(node: Node, center: Vector2, push_radius: float) -> void:
	if node == self or not is_instance_valid(node) or not (node is CharacterBody2D):
		return
	var body := node as CharacterBody2D
	if body.global_position.distance_to(center) > push_radius:
		return
	var away: Vector2 = body.global_position - center
	if away.length_squared() < 1.0:
		away = _rocket_dir
	else:
		away = away.normalized()
	body.velocity += away * PROJECTILE_PUSH_STRENGTH


func _process_falling(delta: float) -> void:
	velocity.y += GRAVITY_ACCEL * delta
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	move_and_slide()
	if is_on_floor():
		velocity = Vector2.ZERO
		_settled = true
		_fire_cooldown_left = _shot_interval_s


func _process_sentinel_movement(delta: float) -> void:
	var opponent := _find_opponent()
	var move_dir := 0.0
	if opponent != null:
		var offset := _target_offset(opponent)
		if absf(offset.y) <= SENTINEL_Y_TOLERANCE_PX:
			var horiz_dist := absf(offset.x)
			if horiz_dist > _follow_range:
				move_dir = signf(offset.x)
			elif horiz_dist > _preferred_distance + SENTINEL_DISTANCE_DEADBAND_PX:
				move_dir = signf(offset.x)
			elif horiz_dist < _preferred_distance - SENTINEL_DISTANCE_DEADBAND_PX:
				move_dir = -signf(offset.x)
	velocity.x = move_dir * _walk_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY_ACCEL * delta
	move_and_slide()
	_animate_legs(delta, move_dir)


func _animate_legs(delta: float, move_dir: float) -> void:
	if _leg_l_pivot == null or _leg_r_pivot == null:
		return
	if absf(move_dir) < 0.01:
		_leg_l_pivot.rotation = lerpf(_leg_l_pivot.rotation, 0.0, 8.0 * delta)
		_leg_r_pivot.rotation = lerpf(_leg_r_pivot.rotation, 0.0, 8.0 * delta)
		return
	_leg_phase += delta * LEG_SWING_SPEED * signf(move_dir)
	var swing := sin(_leg_phase) * LEG_SWING_AMOUNT
	_leg_l_pivot.rotation = swing
	_leg_r_pivot.rotation = -swing


func _process_combat(delta: float) -> void:
	_update_aim_visual()
	if _shots_left <= 0:
		return
	_fire_cooldown_left -= delta
	if _fire_cooldown_left > 0.0:
		return
	var opponent := _find_opponent()
	if opponent == null:
		_fire_cooldown_left = 0.35
		return
	_fire_at(opponent)
	_shots_left -= 1
	if _shots_left <= 0:
		queue_free()
	else:
		_fire_cooldown_left = _shot_interval_s


func _update_aim_visual() -> void:
	if _head_pivot == null:
		return
	var opponent := _find_opponent()
	if opponent == null:
		return
	var to_enemy := _target_offset(opponent)
	if to_enemy.length_squared() < 1.0:
		return
	_head_pivot.rotation = to_enemy.angle()


func _target_offset(opponent: Player) -> Vector2:
	if opponent.has_method("get_body_collision_rect"):
		var body_rect: Rect2 = opponent.get_body_collision_rect()
		if body_rect.size.length_squared() > 1.0:
			return body_rect.get_center() - global_position
	return opponent.global_position - global_position


func _find_opponent() -> Player:
	if _owner == null:
		return null
	return AutoAimFiveWayUtil.find_valid_opponent(_owner)


func _fire_at(opponent: Player) -> void:
	if _game == null or not _game.has_method("spawn_esqueleto_turret_shot"):
		return
	var muzzle_global := _head_pivot.global_position if _muzzle == null else _muzzle.global_position
	var aim := opponent.global_position - muzzle_global
	if opponent.has_method("get_body_collision_rect"):
		var body_rect: Rect2 = opponent.get_body_collision_rect()
		if body_rect.size.length_squared() > 1.0:
			aim = body_rect.get_center() - muzzle_global
	if aim.length_squared() < 1.0:
		aim = Vector2.RIGHT if (_owner != null and _owner.player_id == 1) else Vector2.LEFT
	else:
		aim = aim.normalized()
	var vel := aim * _shot_speed
	_game.call("spawn_esqueleto_turret_shot", _owner, muzzle_global, vel, _shot_damage)


func _apply_team_colors() -> void:
	var base := Color(0.78, 0.74, 0.66, 1.0)
	var rim := Color(0.42, 0.38, 0.34, 1.0)
	var head := Color(0.86, 0.82, 0.74, 1.0)
	var barrel_c := Color(0.58, 0.54, 0.48, 1.0)
	var tip := Color(0.92, 0.88, 0.62, 1.0)
	var bone := Color(0.86, 0.82, 0.74, 1.0)
	var bone_dark := Color(0.72, 0.68, 0.6, 1.0)
	if _owner != null and _owner.player_id == 2:
		base = Color(0.66, 0.72, 0.78, 1.0)
		rim = Color(0.34, 0.38, 0.44, 1.0)
		head = Color(0.74, 0.80, 0.86, 1.0)
		barrel_c = Color(0.48, 0.52, 0.58, 1.0)
		tip = Color(0.62, 0.78, 0.92, 1.0)
		bone = Color(0.74, 0.80, 0.86, 1.0)
		bone_dark = Color(0.58, 0.66, 0.74, 1.0)
	if _base_plate != null:
		_base_plate.color = base
	if _base_rim != null:
		_base_rim.color = rim
	if _head_body != null:
		_head_body.color = head
	if _mode != Mode.ROCKET_CHARGE and _mode != Mode.ROCKET_FLIGHT:
		if _barrel != null:
			_barrel.color = barrel_c
		if _barrel_tip != null:
			_barrel_tip.color = tip
	if _legs_root != null:
		for child in _legs_root.get_children():
			_color_leg_tree(child, bone, bone_dark)


func _color_leg_tree(node: Node, bone: Color, bone_dark: Color) -> void:
	if node is Polygon2D:
		if node.name.contains("Foot"):
			node.color = bone_dark
		else:
			node.color = bone
	for child in node.get_children():
		_color_leg_tree(child, bone, bone_dark)


func _destroy() -> void:
	if _rocket_exploded:
		return
	SfxManager.play("explosion_small", global_position)
	var e := _explosion_scene.instantiate() as Node2D
	if e != null and get_tree().current_scene != null:
		get_tree().current_scene.add_child(e)
		e.global_position = global_position
	queue_free()
