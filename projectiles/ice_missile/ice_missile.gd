extends Arrow
class_name IceMissile

@export var field_lifetime: float = 10.0
@export var freeze_duration: float = 2.0
@export var field_radius: float = 120.0

var _field_scene: PackedScene = preload("res://projectiles/ice_field/ice_field.tscn")
var _detonated: bool = false


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
	# Projétil reto (sem teleguiado): gravidade 0, sem ricochete, sem dano no impacto.
	super.setup(
		owner_player,
		initial_velocity,
		0.0,
		0,
		0,
		size_multiplier,
		false,
		cluster_spread_deg
	)


func remote_detonate() -> void:
	if _detonated:
		return
	_detonated = true
	_spawn_field_and_die()


func _spawn_field_and_die() -> void:
	var f := _field_scene.instantiate() as Node2D
	if f != null:
		get_tree().current_scene.add_child(f)
		f.global_position = global_position
		f.set("lifetime", field_lifetime)
		f.set("freeze_duration", freeze_duration)
		f.set("radius", field_radius)
		f.set("owner_player", get_owner_player())
	queue_free()
