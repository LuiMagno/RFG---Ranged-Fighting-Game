extends CharacterBody2D
class_name Arrow

# Projectile that:
# - Simulates basic projectile motion with gravity
# - Detects collisions via physics collision (for ricochet normals)
# - Damages players and destroys itself
# - Cleans up when it leaves the screen or times out

signal hit_player(victim: Player, damage: int)

var _explosion_scene := preload("res://projectiles/explosion/explosion.tscn")

# Damage dealt on player hit.
@export var damage := 20

# NOTE: "gravity" is a native member in some nodes in Godot, so we avoid that name.
@export var gravity_accel := 1200.0
@export var knockback_x := 520.0
@export var knockback_up := 220.0
@export_range(0, 5, 1) var bounces_left := 0
@export var bounce_damping := 0.95
@export var max_lifetime := 6.0

var _owner: Player
var _shot_flags: Dictionary = {}
var _life_left: float = 0.0
@onready var _body_poly: Polygon2D = $Body
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
var _base_radius: float = 10.0
var _pending_size_multiplier: float = 1.0
var _initialized := false
var _is_archer_carrier: bool = false
var _cluster_spread_deg: float = 7.0
var _split_done: bool = false
var _grenade_boosted: bool = false

@export var grenade_boost_impulse: float = 720.0
@export var grenade_boost_max_speed: float = 1400.0
@export var grenade_boost_spread_deg: float = 6.0

func setup(
	owner_player: Player,
	initial_velocity: Vector2,
	gravity_override: float = INF,
	bounces_override: int = -1,
	damage_override: int = -1,
	size_multiplier: float = 1.0,
	is_archer_carrier: bool = false,
	cluster_spread_deg: float = 7.0
) -> void:
	_owner = owner_player
	# Prevent self-collision (especially important for large projectiles).
	if _owner != null:
		add_collision_exception_with(_owner)
	velocity = initial_velocity
	_life_left = max_lifetime
	_pending_size_multiplier = size_multiplier
	_is_archer_carrier = is_archer_carrier
	_cluster_spread_deg = cluster_spread_deg
	_split_done = false
	if gravity_override != INF:
		gravity_accel = gravity_override
	if bounces_override >= 0:
		bounces_left = bounces_override
	if damage_override >= 0:
		damage = damage_override
	if is_archer_carrier:
		_body_poly.modulate = Color(1.0, 0.82, 0.35, 1.0)
	if _initialized:
		_apply_size_multiplier(_pending_size_multiplier)


func get_owner_player() -> Player:
	return _owner


func set_shot_flags(flags: Dictionary) -> void:
	_shot_flags = flags.duplicate()


func get_shot_flags() -> Dictionary:
	return _shot_flags


func apply_grenade_explosion_boost(explosion_center: Vector2, multiply: int = 3) -> void:
	# Só aplica uma vez por projétil, pra não virar "infinite machine" com várias explosões.
	if _grenade_boosted:
		return
	_grenade_boosted = true
	multiply = maxi(1, multiply)

	var away := global_position - explosion_center
	if away.length_squared() < 0.01:
		away = Vector2.RIGHT if velocity.x >= 0.0 else Vector2.LEFT
	var dir := away.normalized()

	# Feel: empurra o projétil para fora (impulso), preservando parte do movimento atual.
	# Depois clamp no max_speed para não ficar "insano".
	var base_vel := velocity + dir * grenade_boost_impulse
	var spd := base_vel.length()
	if grenade_boost_max_speed > 0.0 and spd > grenade_boost_max_speed:
		base_vel = base_vel * (grenade_boost_max_speed / spd)
	velocity = base_vel
	if velocity.length_squared() > 0.001:
		rotation = velocity.angle()

	if multiply <= 1:
		return

	var parent := get_parent()
	if parent == null:
		return

	var ang := deg_to_rad(grenade_boost_spread_deg)
	var offsets: Array[float] = []
	# Para 3x: duas cópias em -spread/+spread.
	if multiply == 2:
		offsets = [-ang]
	else:
		offsets = [-ang, ang]
	# Se alguém configurar multiply > 3, preenche alternando lados.
	while offsets.size() < (multiply - 1):
		var k := offsets.size() + 1
		var side := -1.0 if (k % 2) == 1 else 1.0
		offsets.append(side * ang * ceilf(float(k) * 0.5))

	for off in offsets:
		var cp := duplicate() as Arrow
		if cp == null:
			continue
		parent.add_child(cp)
		cp.global_position = global_position
		# Reaplica setup pra garantir exceções de colisão e tamanho corretos.
		cp.setup(_owner, base_vel.rotated(off), gravity_accel, bounces_left, damage, _pending_size_multiplier, false, _cluster_spread_deg)
		cp._grenade_boosted = true


func perform_archer_split() -> bool:
	if not _is_archer_carrier or _split_done:
		return false
	_split_done = true
	queue_free()
	return true


func _ready() -> void:
	_initialized = true
	add_to_group("arrows")
	# Ensure per-instance shapes so scaling one arrow doesn't affect others.
	if _collision_shape.shape != null:
		_collision_shape.shape = _collision_shape.shape.duplicate(true)
	if _collision_shape.shape is CircleShape2D:
		_base_radius = (_collision_shape.shape as CircleShape2D).radius
	_apply_size_multiplier(_pending_size_multiplier)


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return

	# Projectile motion
	velocity.y += gravity_accel * delta
	var collision := move_and_collide(velocity * delta)

	# Point the arrow in the direction it's traveling.
	if velocity.length_squared() > 0.001:
		rotation = velocity.angle()

	if collision:
		var collider := collision.get_collider()
		if collider is Arrow:
			var other := collider as Arrow
			# Flechas do mesmo dono podem nascer/ficar próximas (ex.: fragmentação do arqueiro).
			# Não devem se destruir nem ricochetear entre si.
			if other._owner != null and _owner != null and other._owner == _owner:
				add_collision_exception_with(other)
				other.add_collision_exception_with(self)
				return
			# Cancel only if the arrows are from different owners.
			if other._owner != null and _owner != null and other._owner != _owner:
				_spawn_explosion(collision.get_position())
				if not other.is_queued_for_deletion():
					other.queue_free()
				queue_free()
				return

		if collider is ArcherSpike:
			var sp := collider as ArcherSpike
			if sp.is_queued_for_deletion():
				return
			if sp.get_owner_player() != null and _owner != null and sp.get_owner_player() == _owner:
				add_collision_exception_with(sp)
				sp.add_collision_exception_with(self)
				return
			sp.hit_by_arrow()
			queue_free()
			return

		if collider is Player:
			var victim := collider as Player
			if victim != _owner:
				if victim.try_block_arrow_with_shield(self):
					return
				victim.take_damage(damage)
				var dir_x := 1.0
				if velocity.x < -0.01:
					dir_x = -1.0
				victim.apply_knockback(Vector2(dir_x * knockback_x, -knockback_up))
				hit_player.emit(victim, damage)
			queue_free()
			return

		# Ricochet once (or more if configured), then die on next impact.
		if bounces_left > 0:
			bounces_left -= 1
			velocity = velocity.bounce(collision.get_normal()) * bounce_damping
			# Nudge out of the collider to avoid immediate re-collision.
			global_position += collision.get_normal() * 2.0
		else:
			queue_free()
			return

	var rect := get_viewport_rect()
	if not rect.has_point(global_position):
		queue_free()


func _spawn_explosion(world_pos: Vector2) -> void:
	var e := _explosion_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(e)
	e.global_position = world_pos


func _apply_size_multiplier(mult: float) -> void:
	mult = maxf(0.1, mult)
	_body_poly.scale = Vector2.ONE * mult
	if _collision_shape.shape is CircleShape2D:
		(_collision_shape.shape as CircleShape2D).radius = _base_radius * mult


func reflect_from_shield(deflector: Player) -> void:
	var prev := _owner
	if prev != null and is_instance_valid(prev):
		remove_collision_exception_with(prev)
	_owner = deflector
	if _owner != null:
		add_collision_exception_with(_owner)
	var reflected := -velocity * 0.92
	if reflected.length_squared() < 12000.0:
		reflected = (Vector2.RIGHT * 960.0) if deflector.player_id == 1 else (Vector2.LEFT * 960.0)
	velocity = reflected
	if velocity.length_squared() > 0.001:
		rotation = velocity.angle()
