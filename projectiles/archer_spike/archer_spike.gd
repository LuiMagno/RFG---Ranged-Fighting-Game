extends CharacterBody2D
class_name ArcherSpike

## Projétil do arqueiro (buff): voa com gravidade; ao acertar o cenário, gruda e vira espinho.
## Inimigo que encosta: toma dano e o espinho some. Flecha inimiga também remove o espinho.

enum State { FLYING, STUCK }

const LAYER_PROJECTILE := 2
const LAYER_STUCK := 8
const MASK_FLYING := 3

@export var contact_damage: int = 10
@export var flying_damage: int = 12
@export var max_fly_time: float = 4.0
@export var max_stuck_time: float = 55.0
@export var gravity_accel: float = 1200.0

var _owner: Player
var _state: State = State.FLYING
var _fly_left: float = 0.0
var _stuck_left: float = 0.0

@onready var _body: Polygon2D = $Body
@onready var _hurt: Area2D = $HurtZone

var _explosion_scene: PackedScene = preload("res://projectiles/explosion/explosion.tscn")


func setup(owner_player: Player, initial_velocity: Vector2) -> void:
	_owner = owner_player
	if _owner != null:
		add_collision_exception_with(_owner)
	velocity = initial_velocity
	_fly_left = max_fly_time
	collision_layer = LAYER_PROJECTILE
	collision_mask = MASK_FLYING
	_hurt.monitoring = false
	_body.modulate = Color(0.45, 0.85, 0.42, 1.0)


func is_stuck() -> bool:
	return _state == State.STUCK


func get_owner_player() -> Player:
	return _owner


func _ready() -> void:
	_hurt.body_entered.connect(_on_hurt_body_entered)


func _physics_process(delta: float) -> void:
	if _state == State.FLYING:
		_process_flying(delta)
	else:
		_process_stuck(delta)


func _process_flying(delta: float) -> void:
	_fly_left -= delta
	if _fly_left <= 0.0:
		queue_free()
		return

	velocity.y += gravity_accel * delta
	if velocity.length_squared() > 0.001:
		rotation = velocity.angle()

	var col := move_and_collide(velocity * delta)
	if col == null:
		var rect := get_viewport_rect()
		if not rect.has_point(global_position):
			queue_free()
		return

	var collider := col.get_collider()

	if collider is Player:
		var pl := collider as Player
		if pl != _owner:
			pl.take_damage(flying_damage)
			var dir_x := 1.0 if velocity.x < -0.01 else -1.0
			pl.apply_knockback(Vector2(dir_x * 420.0, -160.0))
		queue_free()
		return

	if collider is Arrow:
		_resolve_arrow_collision(collider as Arrow)
		return

	if collider is Grenade:
		velocity = velocity.bounce(col.get_normal()) * 0.65
		global_position += col.get_normal() * 2.5
		return

	if collider is ArcherSpike:
		_resolve_spike_collision(collider as ArcherSpike)
		return

	_stick(col)


func _resolve_arrow_collision(arrow: Arrow) -> void:
	if arrow._owner != null and _owner != null and arrow._owner == _owner:
		add_collision_exception_with(arrow)
		arrow.add_collision_exception_with(self)
		return
	_spawn_small_fx(global_position)
	if not arrow.is_queued_for_deletion():
		arrow.queue_free()
	queue_free()


func _resolve_spike_collision(other: ArcherSpike) -> void:
	var oo := other.get_owner_player()
	if oo != null and _owner != null and oo == _owner:
		add_collision_exception_with(other)
		other.add_collision_exception_with(self)
		return
	_spawn_small_fx((global_position + other.global_position) * 0.5)
	if not other.is_queued_for_deletion():
		other.queue_free()
	queue_free()


func _stick(col: KinematicCollision2D) -> void:
	_state = State.STUCK
	velocity = Vector2.ZERO
	_stuck_left = max_stuck_time
	var n := col.get_normal()
	global_position = col.get_position() - n * 3.0
	rotation = n.angle() + PI * 0.5
	collision_layer = LAYER_STUCK
	collision_mask = 0
	_hurt.monitoring = true
	_body.modulate = Color(0.55, 0.95, 0.5, 1.0)


func _process_stuck(delta: float) -> void:
	_stuck_left -= delta
	if _stuck_left <= 0.0:
		queue_free()


func _on_hurt_body_entered(body: Node2D) -> void:
	if _state != State.STUCK:
		return
	if body is Player:
		var p := body as Player
		if p == _owner:
			return
		p.take_damage(contact_damage)
		var away := p.global_position - global_position
		if away.length_squared() > 4.0:
			p.apply_knockback(away.normalized() * 180.0 + Vector2(0, -80.0))
		else:
			p.apply_knockback(Vector2(0, -100.0))
		queue_free()


func hit_by_arrow() -> void:
	_spawn_small_fx(global_position)
	queue_free()


func _spawn_small_fx(world_pos: Vector2) -> void:
	var e := _explosion_scene.instantiate() as Node2D
	e.set("lifetime", 0.06)
	e.set("start_scale", 0.9)
	e.set("end_scale", 2.2)
	get_tree().current_scene.add_child(e)
	e.global_position = world_pos
