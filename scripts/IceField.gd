extends Area2D
class_name IceField

@export var lifetime: float = 10.0
@export var freeze_duration: float = 2.0
@export var radius: float = 120.0

var owner_player: Player

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _poly: Polygon2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_radius()


func _apply_radius() -> void:
	if _shape != null and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = radius
	if _poly != null:
		_poly.scale = Vector2.ONE * (radius / 120.0)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not (body is Player):
		return
	var pl := body as Player
	if owner_player != null and pl == owner_player:
		return
	pl.freeze_for(freeze_duration)
	queue_free()

