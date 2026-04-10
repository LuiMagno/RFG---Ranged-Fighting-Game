extends CharacterBody2D
class_name Fireball

@export var min_radius: float = 9.0
@export var max_radius: float = 26.0
@export var min_damage: int = 10
@export var max_damage: int = 38
@export var knockback_x: float = 480.0
@export var knockback_up: float = 200.0
@export var max_lifetime: float = 7.0

var _owner: Player
var _damage: int = 10
var _life_left: float = 0.0

var _explosion_scene: PackedScene = preload("res://scenes/Explosion.tscn")


func setup(owner_player: Player, initial_velocity: Vector2, charge_t: float) -> void:
	var body_poly := get_node_or_null("Body") as Polygon2D
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D

	_owner = owner_player
	if _owner != null:
		add_collision_exception_with(_owner)
	self.velocity = initial_velocity
	_life_left = max_lifetime
	charge_t = clampf(charge_t, 0.0, 1.0)
	_damage = int(lerpf(float(min_damage), float(max_damage), charge_t))
	var r := lerpf(min_radius, max_radius, charge_t)
	if col != null and col.shape != null:
		col.shape = col.shape.duplicate(true)
	if col != null and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = r
	if body_poly != null:
		body_poly.scale = Vector2.ONE * (r / 10.0)


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()
		return

	var collision := move_and_collide(velocity * delta)
	if velocity.length_squared() > 0.001:
		rotation = velocity.angle()

	if collision:
		var collider := collision.get_collider()
		if collider is Player:
			var victim := collider as Player
			if victim != _owner:
				victim.take_damage(_damage)
				var dir_x := 1.0 if velocity.x >= -0.01 else -1.0
				victim.apply_knockback(Vector2(dir_x * knockback_x, -knockback_up))
			_spawn_hit_fx(collision.get_position())
			queue_free()
			return
		_spawn_hit_fx(collision.get_position())
		queue_free()
		return

	var rect := get_viewport_rect()
	if not rect.has_point(global_position):
		queue_free()


func _spawn_hit_fx(world_pos: Vector2) -> void:
	var e := _explosion_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(e)
	e.global_position = world_pos
	e.set("lifetime", 0.06)
	e.set("start_scale", 1.8)
	e.set("end_scale", 4.2)
