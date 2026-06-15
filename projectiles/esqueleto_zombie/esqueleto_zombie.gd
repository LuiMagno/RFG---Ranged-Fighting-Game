extends CharacterBody2D
class_name EsqueletoZombie

## Zumbi invocado pelo Esqueleto: persegue o inimigo, agarra (slow) ou explode ao re-activar a skill.

enum State { FALLING, WALKING, LATCHED }

const TERRAIN_COLLISION_MASK := 49
const GRAVITY_ACCEL := 1500.0
const LATCH_Y_TOLERANCE_PX := 40.0

var _owner: Player
var _state: State = State.FALLING
var _hp: int = 25
var _walk_speed: float = 160.0
var _grab_radius: float = 48.0
var _slow_mul: float = 0.55
var _explosion_radius: float = 160.0
var _explosion_damage: int = 22
var _explosion_knockback_x: float = 420.0
var _explosion_knockback_up: float = 180.0
var _latch_offset: Vector2 = Vector2(-22.0, -4.0)
var _victim: Player = null
var _exploded: bool = false

var _explosion_scene: PackedScene = preload("res://projectiles/explosion/explosion.tscn")

@onready var _visual_root: Node2D = $VisualRoot
@onready var _body: Polygon2D = $VisualRoot/Body
@onready var _head: Polygon2D = $VisualRoot/Head
@onready var _arm_l: Polygon2D = $VisualRoot/ArmL
@onready var _arm_r: Polygon2D = $VisualRoot/ArmR


func setup(owner_player: Player, config: Dictionary) -> void:
	_owner = owner_player
	_hp = int(config.get("vida", 25))
	_walk_speed = float(config.get("walk_speed", 160.0))
	_grab_radius = float(config.get("grab_radius", 48.0))
	_slow_mul = float(config.get("slow_mul", 0.55))
	_explosion_radius = float(config.get("explosion_radius", 160.0))
	_explosion_damage = int(config.get("explosion_damage", 22))
	_explosion_knockback_x = float(config.get("explosion_knockback_x", 420.0))
	_explosion_knockback_up = float(config.get("explosion_knockback_up", 180.0))
	if _owner != null:
		add_collision_exception_with(_owner)
		if _owner.player_id == 2:
			_latch_offset.x = 22.0
	_apply_team_colors()
	_state = State.FALLING if not is_on_floor() else State.WALKING


func get_owner_player() -> Player:
	return _owner


func get_latched_victim() -> Player:
	return _victim


func take_damage(amount: int) -> void:
	if amount <= 0 or _exploded:
		return
	_hp -= amount
	if _hp <= 0:
		_destroy_quiet()


func remote_detonate() -> void:
	if _exploded:
		return
	_explode()


func _ready() -> void:
	add_to_group("esqueleto_zombies")
	collision_mask = TERRAIN_COLLISION_MASK
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(46.0)
	_apply_team_colors()


func _physics_process(delta: float) -> void:
	match _state:
		State.FALLING:
			_process_falling(delta)
		State.WALKING:
			_process_walking(delta)
		State.LATCHED:
			_process_latched(delta)


func _process_falling(delta: float) -> void:
	velocity.y += GRAVITY_ACCEL * delta
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	move_and_slide()
	if is_on_floor():
		velocity = Vector2.ZERO
		_state = State.WALKING


func _process_walking(delta: float) -> void:
	var opponent := _find_opponent()
	if opponent == null:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		velocity.y += GRAVITY_ACCEL * delta
		move_and_slide()
		return
	if _can_latch(opponent):
		_begin_latch(opponent)
		return
	var dir := signf(opponent.global_position.x - global_position.x)
	if absf(dir) < 0.01:
		dir = 1.0 if (_owner != null and _owner.player_id == 1) else -1.0
	velocity.x = dir * _walk_speed
	velocity.y += GRAVITY_ACCEL * delta
	move_and_slide()
	_update_facing(dir)


func _process_latched(delta: float) -> void:
	if _victim == null or not is_instance_valid(_victim) or _victim.hp <= 0:
		_clear_latch_slow()
		queue_free()
		return
	global_position = _victim.global_position + _latch_offset
	velocity = Vector2.ZERO
	_victim.set_esqueleto_zombie_slow_mul(_slow_mul)
	var face := signf(_victim.global_position.x - global_position.x)
	if absf(face) > 0.01:
		_update_facing(face)


func _find_opponent() -> Player:
	if _owner == null:
		return null
	return AutoAimFiveWayUtil.find_valid_opponent(_owner)


func _can_latch(opponent: Player) -> bool:
	var delta_p := opponent.global_position - global_position
	if absf(delta_p.y) > LATCH_Y_TOLERANCE_PX:
		return false
	return delta_p.length() <= _grab_radius


func _begin_latch(opponent: Player) -> void:
	_state = State.LATCHED
	_victim = opponent
	velocity = Vector2.ZERO
	global_position = opponent.global_position + _latch_offset
	opponent.set_esqueleto_zombie_slow_mul(_slow_mul)


func _clear_latch_slow() -> void:
	if _victim != null and is_instance_valid(_victim):
		_victim.set_esqueleto_zombie_slow_mul(1.0)
	_victim = null


func _update_facing(dir_x: float) -> void:
	if _visual_root == null:
		return
	_visual_root.scale.x = -1.0 if dir_x < 0.0 else 1.0


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	_clear_latch_slow()
	var center := global_position
	SfxManager.play("explosion", center)
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner:
			continue
		var feet := pl.global_position
		if center.distance_to(feet) > _explosion_radius + 28.0:
			continue
		pl.take_damage(_explosion_damage)
		SfxManager.play("hit_heavy", feet, 1.0, -4.0)
		var away := feet - center
		if away.length_squared() < 4.0:
			away = Vector2.RIGHT * (1.0 if center.x < feet.x else -1.0)
		else:
			away = away.normalized()
		pl.apply_knockback(Vector2(away.x * _explosion_knockback_x, -_explosion_knockback_up))
	for i in range(4):
		var puff := _explosion_scene.instantiate() as Node2D
		if puff == null or get_tree().current_scene == null:
			continue
		get_tree().current_scene.add_child(puff)
		puff.global_position = center + Vector2(randf_range(-24.0, 24.0), randf_range(-18.0, 18.0))
	queue_free()


func _destroy_quiet() -> void:
	_clear_latch_slow()
	SfxManager.play("explosion_small", global_position)
	queue_free()


func _apply_team_colors() -> void:
	var body_c := Color(0.52, 0.68, 0.42, 1.0)
	var head_c := Color(0.62, 0.78, 0.5, 1.0)
	var limb_c := Color(0.45, 0.58, 0.38, 1.0)
	if _owner != null and _owner.player_id == 2:
		body_c = Color(0.42, 0.58, 0.68, 1.0)
		head_c = Color(0.5, 0.66, 0.76, 1.0)
		limb_c = Color(0.38, 0.5, 0.6, 1.0)
	if _body != null:
		_body.color = body_c
	if _head != null:
		_head.color = head_c
	if _arm_l != null:
		_arm_l.color = limb_c
	if _arm_r != null:
		_arm_r.color = limb_c


func _exit_tree() -> void:
	_clear_latch_slow()
