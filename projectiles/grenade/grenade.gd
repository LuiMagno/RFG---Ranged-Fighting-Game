extends CharacterBody2D
class_name Grenade

# Granada: arco com gravidade; após o fusível, dano em área (não acerta o dono no voo).

@export var fuse_time: float = 4.0
@export var remote_detonate_arm_time: float = 1.0
@export var explosion_radius: float = 220.0
@export var explosion_damage: int = 32
@export var knockback_horizontal: float = 520.0
@export var knockback_up: float = 220.0
@export var gravity_accel: float = 1650.0
@export var bounce_damping: float = 0.38

var _owner: Player
var _fuse_left: float = 0.0
var _exploded: bool = false
var _alive_s: float = 0.0
var _manual_detonate_requested: bool = false
var _explosion_scene: PackedScene = preload("res://projectiles/explosion/explosion.tscn")

@onready var _body: Polygon2D = $Body


func get_owner_player() -> Player:
	return _owner


func _ready() -> void:
	add_to_group("grenades")


func setup(owner_player: Player, throw_velocity: Vector2) -> void:
	_owner = owner_player
	if _owner != null:
		add_collision_exception_with(_owner)
	velocity = throw_velocity
	_fuse_left = fuse_time
	_alive_s = 0.0
	_manual_detonate_requested = false


func remote_detonate() -> void:
	# Detonação manual (re-acionar).
	_manual_detonate_requested = true
	if _alive_s >= remote_detonate_arm_time:
		_explode()


func _physics_process(delta: float) -> void:
	_alive_s += delta
	_fuse_left -= delta
	velocity.y += gravity_accel * delta
	var col := move_and_collide(velocity * delta)
	if col:
		velocity = velocity.bounce(col.get_normal()) * bounce_damping
		global_position += col.get_normal() * 2.5
		SfxManager.play("grenade_bounce", global_position, 1.0, -6.0)

	if _manual_detonate_requested and _alive_s >= remote_detonate_arm_time:
		_explode()
		return

	if _fuse_left <= 0.0:
		_explode()
		return

	var rect := get_viewport_rect()
	if not rect.has_point(global_position):
		_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var center := global_position
	SfxManager.play("explosion", center)
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner:
			continue
		var feet := pl.global_position
		var dist := center.distance_to(feet)
		if dist > explosion_radius + 28.0:
			continue
		pl.take_damage(explosion_damage)
		SfxManager.play("hit_heavy", feet, 1.0, -4.0)
		var away := feet - center
		if away.length_squared() < 4.0:
			away = Vector2.RIGHT * (1.0 if center.x < feet.x else -1.0)
		else:
			away = away.normalized()
		pl.apply_knockback(Vector2(away.x * knockback_horizontal, -knockback_up))

	for n in get_tree().get_nodes_in_group("esqueleto_mirror_clones"):
		if not (n is EsqueletoMirrorClone):
			continue
		var mc := n as EsqueletoMirrorClone
		if not mc.is_alive():
			continue
		if center.distance_to(mc.global_position) > explosion_radius + 20.0:
			continue
		mc.take_damage(1)

	# Interação: a explosão pode "pegar" projéteis do pistoleiro
	# e redirecionar/triplicar.
	if _owner != null and is_instance_valid(_owner) and _owner.is_pistoleiro():
		for n in get_tree().get_nodes_in_group("arrows"):
			if not (n is Arrow):
				continue
			var ar := n as Arrow
			if ar.is_queued_for_deletion():
				continue
			if ar.get_owner_player() != _owner:
				continue
			if center.distance_to(ar.global_position) > explosion_radius:
				continue
			ar.apply_grenade_explosion_boost(center, 3)

	for i in range(5):
		var puff := _explosion_scene.instantiate() as Node2D
		get_tree().current_scene.add_child(puff)
		puff.global_position = center + Vector2(randf_range(-28.0, 28.0), randf_range(-22.0, 22.0))
		puff.set("lifetime", 0.08 + randf() * 0.03)
		puff.set("start_scale", 2.8 + randf() * 0.5)
		puff.set("end_scale", 8.0 + randf() * 1.2)

	queue_free()
