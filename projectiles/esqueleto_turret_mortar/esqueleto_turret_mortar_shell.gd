extends CharacterBody2D
class_name EsqueletoTurretMortarShell

@export var gravity_accel: float = 1500.0
@export var max_lifetime: float = 8.0

var _owner: Player
var _damage: int = 24
var _radius: float = 120.0
var _knockback_x: float = 380.0
var _knockback_up: float = 200.0
var _life_left: float = 8.0
var _exploded: bool = false

var _explosion_scene: PackedScene = preload("res://projectiles/explosion/explosion.tscn")


func setup(
	owner_player: Player,
	initial_velocity: Vector2,
	damage: int,
	blast_radius: float,
	knockback_x: float,
	knockback_up: float,
) -> void:
	_owner = owner_player
	velocity = initial_velocity
	_damage = damage
	_radius = blast_radius
	_knockback_x = knockback_x
	_knockback_up = knockback_up
	_life_left = max_lifetime
	if _owner != null:
		add_collision_exception_with(_owner)


func get_owner_player() -> Player:
	return _owner


func _ready() -> void:
	add_to_group("esqueleto_turret_mortar_shells")
	if has_node("CollisionShape2D"):
		var col := $CollisionShape2D as CollisionShape2D
		if col != null and col.shape != null:
			col.shape = col.shape.duplicate(true)


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		_explode(global_position)
		return

	velocity.y += gravity_accel * delta
	if velocity.length_squared() > 16.0:
		rotation = velocity.angle()

	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return

	var collider := collision.get_collider()
	if collider is Player:
		var victim := collider as Player
		if victim != _owner:
			_explode(collision.get_position())
			return
		add_collision_exception_with(victim)
		return

	if collider is EsqueletoTurret:
		var tur := collider as EsqueletoTurret
		if tur.get_owner_player() == _owner:
			add_collision_exception_with(tur)
			return
		_explode(collision.get_position())
		return

	_explode(collision.get_position())


func _explode(center: Vector2) -> void:
	if _exploded:
		return
	_exploded = true
	SfxManager.play("explosion", center, 0.88, -4.0)
	for i in range(2):
		var puff := _explosion_scene.instantiate() as Node2D
		if puff == null or get_tree().current_scene == null:
			continue
		get_tree().current_scene.add_child(puff)
		puff.global_position = center + Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, 10.0))
		puff.scale = Vector2.ONE * 1.05

	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner or pl.hp <= 0:
			continue
		var feet := pl.global_position
		if center.distance_to(feet) > _radius + 24.0:
			continue
		pl.take_damage(_damage)
		SfxManager.play("hit_heavy", feet, 0.9, -2.0)
		var away := feet - center
		if away.length_squared() < 4.0:
			away = Vector2.RIGHT if feet.x >= center.x else Vector2.LEFT
		else:
			away = away.normalized()
		pl.apply_knockback(Vector2(away.x * _knockback_x, -_knockback_up))

	queue_free()
